# DreamKIT SDV Service Examples

This document provides flexible SDV (Software Defined Vehicle) service examples that demonstrate how to translate various vehicle data sources into KUKSA VSS (Vehicle Signal Specification) signals through the KUKSA data broker.

## SDV Architecture Overview

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Source   │───▶│  DK Service  │───▶│  KUKSA Broker   │───▶│   dk_ivi UI     │
│  (Any System)   │    │  (Translator)│    │  (sdv-runtime)  │    │  (Dashboard)    │
└─────────────────┘    └──────────────┘    └─────────────────┘    └─────────────────┘
```

The DreamKIT service acts as a flexible translator that can:
- Read data from ANY source (CAN, HTTP API, sensors, files, databases, etc.)
- Transform it into VSS signals
- Publish to KUKSA data broker at `127.0.0.1:55555`
- Enable dk_ivi to display and control vehicle functions

## Example 1: HTTP API to VSS Bridge Service

### Use Case
Translate REST API vehicle data (from OEM backend, cloud services, or local APIs) into VSS signals.

### Service: `sdv-api-bridge`

**main.py**:
```python
import json
import time
import requests
import asyncio
from kuksa_client.grpc import VSSClient
from kuksa_client.grpc import Datapoint
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SDVApiBridge:
    def __init__(self, config):
        self.config = config
        self.kuksa_client = None
        self.running = False
        
    async def connect_kuksa(self):
        """Connect to KUKSA data broker"""
        try:
            self.kuksa_client = VSSClient("127.0.0.1", 55555)
            await self.kuksa_client.connect()
            logger.info("Connected to KUKSA data broker")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to KUKSA: {e}")
            return False
    
    async def fetch_vehicle_data(self):
        """Fetch data from external API"""
        try:
            api_url = self.config.get("api_url", "http://localhost:8080/vehicle/status")
            headers = self.config.get("headers", {})
            
            response = requests.get(api_url, headers=headers, timeout=5)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to fetch API data: {e}")
            return None
    
    async def translate_to_vss(self, api_data):
        """Translate API data to VSS signals"""
        vss_mappings = self.config.get("vss_mappings", {})
        vss_data = {}
        
        for api_field, vss_path in vss_mappings.items():
            if api_field in api_data:
                value = api_data[api_field]
                # Type conversion based on VSS specification
                if "Speed" in vss_path:
                    value = float(value)  # km/h
                elif "IsOn" in vss_path or "IsActive" in vss_path:
                    value = bool(value)
                elif "Temperature" in vss_path:
                    value = float(value)  # Celsius
                
                vss_data[vss_path] = value
        
        return vss_data
    
    async def publish_to_kuksa(self, vss_data):
        """Publish VSS data to KUKSA broker"""
        if not self.kuksa_client:
            return False
        
        try:
            for vss_path, value in vss_data.items():
                datapoint = Datapoint(value)
                await self.kuksa_client.set_current_values({vss_path: datapoint})
                logger.debug(f"Published {vss_path} = {value}")
            return True
        except Exception as e:
            logger.error(f"Failed to publish to KUKSA: {e}")
            return False
    
    async def run(self):
        """Main service loop"""
        logger.info("Starting SDV API Bridge Service")
        
        if not await self.connect_kuksa():
            logger.error("Cannot start without KUKSA connection")
            return
        
        self.running = True
        interval = self.config.get("update_interval", 5)
        
        while self.running:
            try:
                # Fetch data from API
                api_data = await self.fetch_vehicle_data()
                if api_data:
                    # Translate to VSS
                    vss_data = await self.translate_to_vss(api_data)
                    if vss_data:
                        # Publish to KUKSA
                        await self.publish_to_kuksa(vss_data)
                        logger.info(f"Updated {len(vss_data)} VSS signals")
                
                await asyncio.sleep(interval)
                
            except Exception as e:
                logger.error(f"Service loop error: {e}")
                await asyncio.sleep(interval)

async def main():
    # Read runtime configuration
    config_path = "/app/runtime/runtimecfg.json"
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        logger.info(f"Loaded config: {config}")
    except Exception as e:
        logger.error(f"Failed to load config: {e}")
        config = {}
    
    # Default configuration
    default_config = {
        "api_url": "http://example.com/api/vehicle/status",
        "update_interval": 5,
        "headers": {"Authorization": "Bearer token"},
        "vss_mappings": {
            "speed": "Vehicle.Speed",
            "engine_temp": "Vehicle.Powertrain.CombustionEngine.Temperature",
            "fuel_level": "Vehicle.Powertrain.FuelSystem.Level",
            "door_front_left": "Vehicle.Cabin.Door.Row1.DriverSide.IsOpen",
            "lights_headlight": "Vehicle.Body.Lights.Beam.Low.IsOn"
        }
    }
    
    # Merge with default config
    for key, value in default_config.items():
        if key not in config:
            config[key] = value
    
    # Start service
    service = SDVApiBridge(config)
    await service.run()

if __name__ == "__main__":
    asyncio.run(main())
```

**requirements.txt**:
```
kuksa-client
requests
asyncio
```

**Configuration Example**:
```json
{
  "api_url": "https://your-vehicle-api.com/status",
  "update_interval": 3,
  "headers": {
    "Authorization": "Bearer your-api-token",
    "Content-Type": "application/json"
  },
  "vss_mappings": {
    "vehicle_speed": "Vehicle.Speed",
    "engine_temperature": "Vehicle.Powertrain.CombustionEngine.Temperature",
    "fuel_percentage": "Vehicle.Powertrain.FuelSystem.Level",
    "left_door_open": "Vehicle.Cabin.Door.Row1.DriverSide.IsOpen",
    "headlights_on": "Vehicle.Body.Lights.Beam.Low.IsOn"
  }
}
```

## Example 2: IoT Sensor to VSS Bridge Service

### Use Case
Read data from IoT sensors (temperature, GPS, accelerometer) and map to VSS signals.

### Service: `sdv-iot-sensor`

**main.py**:
```python
import json
import time
import asyncio
import random
from kuksa_client.grpc import VSSClient, Datapoint
import logging

class SDVIoTSensorService:
    def __init__(self, config):
        self.config = config
        self.kuksa_client = None
        self.sensors = {}
        
    async def connect_kuksa(self):
        """Connect to KUKSA data broker"""
        try:
            self.kuksa_client = VSSClient("127.0.0.1", 55555)
            await self.kuksa_client.connect()
            logging.info("Connected to KUKSA data broker")
            return True
        except Exception as e:
            logging.error(f"Failed to connect to KUKSA: {e}")
            return False
    
    def read_gps_sensor(self):
        """Simulate GPS sensor reading"""
        # In real implementation, read from actual GPS device
        return {
            "latitude": random.uniform(37.7749, 37.7849),  # San Francisco area
            "longitude": random.uniform(-122.4294, -122.4194),
            "altitude": random.uniform(0, 100),
            "speed": random.uniform(0, 120)  # km/h
        }
    
    def read_environment_sensors(self):
        """Simulate environmental sensors"""
        # In real implementation, read from I2C/GPIO sensors
        return {
            "ambient_temperature": random.uniform(15, 35),  # Celsius
            "cabin_temperature": random.uniform(18, 28),
            "humidity": random.uniform(30, 70),  # %
            "air_pressure": random.uniform(950, 1050)  # hPa
        }
    
    def read_motion_sensors(self):
        """Simulate motion sensors (accelerometer, gyroscope)"""
        return {
            "acceleration_x": random.uniform(-2, 2),  # m/s²
            "acceleration_y": random.uniform(-2, 2),
            "acceleration_z": random.uniform(8, 12),  # ~9.8 + vehicle motion
            "angular_velocity_x": random.uniform(-5, 5),  # rad/s
            "angular_velocity_y": random.uniform(-5, 5),
            "angular_velocity_z": random.uniform(-5, 5)
        }
    
    async def collect_sensor_data(self):
        """Collect data from all configured sensors"""
        sensor_data = {}
        
        enabled_sensors = self.config.get("enabled_sensors", [])
        
        if "gps" in enabled_sensors:
            sensor_data.update(self.read_gps_sensor())
        
        if "environment" in enabled_sensors:
            sensor_data.update(self.read_environment_sensors())
        
        if "motion" in enabled_sensors:
            sensor_data.update(self.read_motion_sensors())
        
        return sensor_data
    
    async def publish_sensor_data(self, sensor_data):
        """Map sensor data to VSS and publish"""
        vss_mappings = self.config.get("vss_mappings", {})
        
        try:
            for sensor_key, vss_path in vss_mappings.items():
                if sensor_key in sensor_data:
                    value = sensor_data[sensor_key]
                    datapoint = Datapoint(value)
                    await self.kuksa_client.set_current_values({vss_path: datapoint})
                    logging.debug(f"Published {vss_path} = {value}")
        except Exception as e:
            logging.error(f"Failed to publish sensor data: {e}")
    
    async def run(self):
        """Main service loop"""
        logging.info("Starting SDV IoT Sensor Service")
        
        if not await self.connect_kuksa():
            return
        
        interval = self.config.get("update_interval", 2)
        
        while True:
            try:
                # Collect sensor data
                sensor_data = await self.collect_sensor_data()
                
                # Publish to KUKSA
                await self.publish_sensor_data(sensor_data)
                
                logging.info(f"Updated {len(sensor_data)} sensor readings")
                await asyncio.sleep(interval)
                
            except Exception as e:
                logging.error(f"Service error: {e}")
                await asyncio.sleep(interval)

async def main():
    # Load configuration
    try:
        with open("/app/runtime/runtimecfg.json", 'r') as f:
            config = json.load(f)
    except:
        config = {}
    
    # Default configuration
    default_config = {
        "enabled_sensors": ["gps", "environment", "motion"],
        "update_interval": 2,
        "vss_mappings": {
            "latitude": "Vehicle.CurrentLocation.Latitude",
            "longitude": "Vehicle.CurrentLocation.Longitude", 
            "altitude": "Vehicle.CurrentLocation.Altitude",
            "speed": "Vehicle.Speed",
            "ambient_temperature": "Vehicle.Exterior.AirTemperature",
            "cabin_temperature": "Vehicle.Cabin.HVAC.AmbientAirTemperature",
            "acceleration_x": "Vehicle.Acceleration.Longitudinal",
            "acceleration_y": "Vehicle.Acceleration.Lateral",
            "acceleration_z": "Vehicle.Acceleration.Vertical"
        }
    }
    
    for key, value in default_config.items():
        if key not in config:
            config[key] = value
    
    service = SDVIoTSensorService(config)
    await service.run()

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
```

## Example 3: Database to VSS Bridge Service

### Use Case
Read vehicle maintenance records, driver profiles, or fleet data from databases and expose as VSS signals.

### Service: `sdv-database-bridge`

**main.py**:
```python
import json
import asyncio
import sqlite3
from datetime import datetime
from kuksa_client.grpc import VSSClient, Datapoint
import logging

class SDVDatabaseService:
    def __init__(self, config):
        self.config = config
        self.kuksa_client = None
        self.db_connection = None
    
    async def connect_kuksa(self):
        try:
            self.kuksa_client = VSSClient("127.0.0.1", 55555)
            await self.kuksa_client.connect()
            return True
        except Exception as e:
            logging.error(f"KUKSA connection failed: {e}")
            return False
    
    def connect_database(self):
        """Connect to vehicle database"""
        try:
            db_path = self.config.get("database_path", "/app/runtime/vehicle_data.db")
            self.db_connection = sqlite3.connect(db_path)
            self.db_connection.row_factory = sqlite3.Row
            
            # Create sample tables if they don't exist
            self.create_sample_tables()
            self.populate_sample_data()
            return True
        except Exception as e:
            logging.error(f"Database connection failed: {e}")
            return False
    
    def create_sample_tables(self):
        """Create sample database schema"""
        cursor = self.db_connection.cursor()
        
        # Vehicle profile table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS vehicle_profile (
                id INTEGER PRIMARY KEY,
                make TEXT,
                model TEXT,
                year INTEGER,
                vin TEXT,
                mileage REAL
            )
        ''')
        
        # Driver preferences
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS driver_preferences (
                id INTEGER PRIMARY KEY,
                driver_name TEXT,
                preferred_temp REAL,
                seat_position INTEGER,
                mirror_settings TEXT
            )
        ''')
        
        # Maintenance records
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS maintenance (
                id INTEGER PRIMARY KEY,
                service_type TEXT,
                date TEXT,
                mileage REAL,
                next_service_due REAL
            )
        ''')
        
        self.db_connection.commit()
    
    def populate_sample_data(self):
        """Add sample data if tables are empty"""
        cursor = self.db_connection.cursor()
        
        # Check if data already exists
        cursor.execute("SELECT COUNT(*) FROM vehicle_profile")
        if cursor.fetchone()[0] == 0:
            # Insert sample vehicle data
            cursor.execute('''
                INSERT INTO vehicle_profile (make, model, year, vin, mileage)
                VALUES (?, ?, ?, ?, ?)
            ''', ("Tesla", "Model 3", 2023, "1HGBH41JXMN109186", 15420.5))
            
            cursor.execute('''
                INSERT INTO driver_preferences (driver_name, preferred_temp, seat_position, mirror_settings)
                VALUES (?, ?, ?, ?)
            ''', ("John Doe", 22.5, 3, '{"left": 45, "right": 42}'))
            
            cursor.execute('''
                INSERT INTO maintenance (service_type, date, mileage, next_service_due)
                VALUES (?, ?, ?, ?)
            ''', ("Oil Change", "2024-05-15", 15000, 20000))
            
            self.db_connection.commit()
    
    def query_vehicle_data(self):
        """Query current vehicle data from database"""
        cursor = self.db_connection.cursor()
        
        data = {}
        
        # Get vehicle profile
        cursor.execute("SELECT * FROM vehicle_profile LIMIT 1")
        vehicle = cursor.fetchone()
        if vehicle:
            data.update({
                "vehicle_make": vehicle["make"],
                "vehicle_model": vehicle["model"],
                "vehicle_year": vehicle["year"],
                "vehicle_vin": vehicle["vin"],
                "vehicle_mileage": vehicle["mileage"]
            })
        
        # Get driver preferences
        cursor.execute("SELECT * FROM driver_preferences LIMIT 1")
        driver = cursor.fetchone()
        if driver:
            data.update({
                "driver_name": driver["driver_name"],
                "preferred_temperature": driver["preferred_temp"],
                "seat_position": driver["seat_position"]
            })
        
        # Get maintenance info
        cursor.execute("SELECT * FROM maintenance ORDER BY date DESC LIMIT 1")
        maintenance = cursor.fetchone()
        if maintenance:
            data.update({
                "last_service_mileage": maintenance["mileage"],
                "next_service_due": maintenance["next_service_due"],
                "service_due_distance": maintenance["next_service_due"] - vehicle["mileage"]
            })
        
        return data
    
    async def publish_database_data(self, db_data):
        """Map database data to VSS signals"""
        vss_mappings = self.config.get("vss_mappings", {})
        
        try:
            for db_key, vss_path in vss_mappings.items():
                if db_key in db_data:
                    value = db_data[db_key]
                    datapoint = Datapoint(value)
                    await self.kuksa_client.set_current_values({vss_path: datapoint})
                    logging.debug(f"Published {vss_path} = {value}")
        except Exception as e:
            logging.error(f"Failed to publish database data: {e}")
    
    async def run(self):
        """Main service loop"""
        logging.info("Starting SDV Database Bridge Service")
        
        if not await self.connect_kuksa():
            return
        
        if not self.connect_database():
            return
        
        interval = self.config.get("update_interval", 10)
        
        while True:
            try:
                # Query database
                db_data = self.query_vehicle_data()
                
                # Publish to KUKSA
                await self.publish_database_data(db_data)
                
                logging.info(f"Updated {len(db_data)} database values")
                await asyncio.sleep(interval)
                
            except Exception as e:
                logging.error(f"Service error: {e}")
                await asyncio.sleep(interval)

async def main():
    try:
        with open("/app/runtime/runtimecfg.json", 'r') as f:
            config = json.load(f)
    except:
        config = {}
    
    default_config = {
        "database_path": "/app/runtime/vehicle_data.db",
        "update_interval": 10,
        "vss_mappings": {
            "vehicle_make": "Vehicle.VehicleIdentification.Brand",
            "vehicle_model": "Vehicle.VehicleIdentification.Model",
            "vehicle_year": "Vehicle.VehicleIdentification.Year",
            "vehicle_vin": "Vehicle.VehicleIdentification.VIN",
            "vehicle_mileage": "Vehicle.TraveledDistance",
            "preferred_temperature": "Vehicle.Cabin.HVAC.Station.Row1.Driver.Temperature",
            "service_due_distance": "Vehicle.Service.DistanceToService"
        }
    }
    
    for key, value in default_config.items():
        if key not in config:
            config[key] = value
    
    service = SDVDatabaseService(config)
    await service.run()

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
```

## Service Installation Configurations

### API Bridge Service Installation
```json
{
  "_id": "sdv_api_bridge_001",
  "name": "SDV API Bridge",
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"dreamkit/sdv-api-bridge:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"api_url\":\"https://your-api.com/vehicle/status\",\"update_interval\":5,\"vss_mappings\":{\"speed\":\"Vehicle.Speed\",\"engine_temp\":\"Vehicle.Powertrain.CombustionEngine.Temperature\"}}}"
}
```

### IoT Sensor Service Installation
```json
{
  "_id": "sdv_iot_sensor_001", 
  "name": "SDV IoT Sensors",
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"dreamkit/sdv-iot-sensor:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"enabled_sensors\":[\"gps\",\"environment\"],\"update_interval\":2}}"
}
```

### Database Bridge Service Installation
```json
{
  "_id": "sdv_database_001",
  "name": "SDV Database Bridge", 
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"dreamkit/sdv-database-bridge:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"database_path\":\"/app/runtime/vehicle_data.db\",\"update_interval\":10}}"
}
```

## Key SDV Benefits Demonstrated

1. **Protocol Agnostic**: Services can read from ANY data source (HTTP, databases, sensors, files, etc.)

2. **VSS Standardization**: All vehicle data is normalized to VSS standard signals

3. **KUKSA Integration**: Central data broker enables data sharing between services

4. **Flexible Configuration**: Runtime configuration allows easy customization without rebuilding

5. **Scalable Architecture**: Add new data sources by simply creating new translator services

6. **Real-time Updates**: Live data flows from sources through KUKSA to dk_ivi dashboard

This approach makes DreamKIT a true SDV platform where any vehicle system can be integrated through flexible translator services, all speaking the common VSS language through KUKSA.