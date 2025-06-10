# DreamKIT SDV Reference Examples for Creators

This document provides practical, ready-to-use SDV service examples that demonstrate real-world vehicle integration scenarios. Each example is complete and can be used as a starting point for your own services.

## Example 1: Vehicle Simulator Service
**Perfect for**: Testing, demos, development environments where no real vehicle data is available.

### Use Case
Simulate realistic vehicle behavior for testing dk_ivi dashboard without requiring actual hardware.

### Complete Service: `dreamkit-vehicle-simulator`

**Directory Structure:**
```
dreamkit-vehicle-simulator/
├── Dockerfile
├── main.py
├── vehicle_simulator.py
├── start.sh
├── requirements.txt
└── simulator_service_installcfg.json
```

**main.py:**
```python
#!/usr/bin/env python3
import json
import asyncio
import logging
from vehicle_simulator import VehicleSimulator

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def main():
    logger.info("=== DreamKIT Vehicle Simulator Starting ===")
    
    # Load configuration
    config_path = "/app/runtime/runtimecfg.json"
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        logger.info(f"Loaded config: {list(config.keys())}")
    except FileNotFoundError:
        logger.warning("No runtime config found, using defaults")
        config = {}
    except Exception as e:
        logger.error(f"Config error: {e}")
        config = {}
    
    # Default configuration
    default_config = {
        "simulation_mode": "city_drive",  # city_drive, highway, parking, racing
        "update_interval": 1.0,
        "vehicle_type": "sedan",
        "enable_faults": False,
        "kuksa_host": "127.0.0.1",
        "kuksa_port": 55555
    }
    
    # Merge configurations
    for key, value in default_config.items():
        config.setdefault(key, value)
    
    # Start simulator
    simulator = VehicleSimulator(config)
    await simulator.run()

if __name__ == "__main__":
    asyncio.run(main())
```

**vehicle_simulator.py:**
```python
import asyncio
import random
import math
import time
from dataclasses import dataclass
from typing import Dict, Any
import logging
from kuksa_client.grpc import VSSClient, Datapoint

logger = logging.getLogger(__name__)

@dataclass
class VehicleState:
    speed: float = 0.0
    rpm: float = 800.0
    fuel_level: float = 75.0
    engine_temp: float = 90.0
    battery_voltage: float = 12.6
    odometer: float = 45230.0
    gear: int = 0  # P=0, R=-1, N=1, D1=2, D2=3, etc.
    
    # Position
    latitude: float = 37.7749
    longitude: float = -122.4194
    altitude: float = 50.0
    
    # Environment
    ambient_temp: float = 22.0
    cabin_temp: float = 24.0
    
    # Lights and signals
    headlights: bool = False
    hazard_lights: bool = False
    turn_left: bool = False
    turn_right: bool = False
    
    # Doors and windows
    driver_door: bool = False
    passenger_door: bool = False
    driver_window: float = 0.0  # 0-100%
    
    # HVAC
    hvac_fan_speed: float = 30.0
    hvac_target_temp: float = 22.0

class VehicleSimulator:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.state = VehicleState()
        self.kuksa_client = None
        self.running = False
        self.simulation_time = 0.0
        
        # Simulation parameters
        self.mode = config.get("simulation_mode", "city_drive")
        self.update_interval = config.get("update_interval", 1.0)
        
    async def connect_kuksa(self):
        """Connect to KUKSA data broker"""
        try:
            host = self.config.get("kuksa_host", "127.0.0.1")
            port = self.config.get("kuksa_port", 55555)
            
            self.kuksa_client = VSSClient(host, port)
            await self.kuksa_client.connect()
            logger.info(f"Connected to KUKSA at {host}:{port}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to KUKSA: {e}")
            return False
    
    def simulate_city_drive(self):
        """Simulate city driving behavior"""
        # Speed varies between 0-60 km/h with traffic stops
        time_factor = self.simulation_time * 0.1
        base_speed = 30 + 25 * math.sin(time_factor * 0.5)
        
        # Add traffic stops
        if math.sin(time_factor * 2) > 0.8:
            base_speed = max(0, base_speed - 40)
        
        self.state.speed = max(0, base_speed + random.uniform(-5, 5))
        
        # RPM follows speed
        if self.state.speed > 0:
            self.state.rpm = 800 + (self.state.speed * 45)
        else:
            self.state.rpm = 800 + random.uniform(-50, 50)
        
        # Gear selection
        if self.state.speed < 5:
            self.state.gear = 2  # D1
        elif self.state.speed < 25:
            self.state.gear = 3  # D2
        else:
            self.state.gear = 4  # D3
    
    def simulate_highway_drive(self):
        """Simulate highway driving"""
        # Steady speed around 100 km/h
        self.state.speed = 95 + 10 * math.sin(self.simulation_time * 0.05) + random.uniform(-3, 3)
        self.state.rpm = 2200 + (self.state.speed - 100) * 20
        self.state.gear = 5  # High gear
    
    def simulate_parking(self):
        """Simulate parked vehicle"""
        self.state.speed = 0
        self.state.rpm = 800 + random.uniform(-20, 20)  # Idle
        self.state.gear = 0  # Park
        
        # Simulate door opening/closing
        if random.random() < 0.02:  # 2% chance per update
            self.state.driver_door = not self.state.driver_door
    
    def update_environment(self):
        """Update environmental conditions"""
        # Slow temperature changes
        if random.random() < 0.1:
            self.state.ambient_temp += random.uniform(-0.5, 0.5)
            self.state.ambient_temp = max(-20, min(45, self.state.ambient_temp))
        
        # Engine temperature based on load
        target_temp = 85 + (self.state.rpm - 800) / 100
        temp_diff = target_temp - self.state.engine_temp
        self.state.engine_temp += temp_diff * 0.1
        
        # Fuel consumption
        if self.state.speed > 0:
            consumption = (self.state.speed / 100) * 0.01  # Rough fuel consumption
            self.state.fuel_level = max(0, self.state.fuel_level - consumption)
        
        # Update odometer
        if self.state.speed > 0:
            distance_km = (self.state.speed / 3600) * self.update_interval
            self.state.odometer += distance_km
        
        # Update position (simulate movement)
        if self.state.speed > 0:
            # Simple position update (not realistic, just for demo)
            speed_ms = self.state.speed / 3.6  # Convert km/h to m/s
            distance_m = speed_ms * self.update_interval
            
            # Convert to lat/lon change (very rough approximation)
            lat_change = distance_m / 111320  # Rough meters per degree latitude
            self.state.latitude += lat_change * random.uniform(-0.5, 0.5)
            self.state.longitude += lat_change * random.uniform(-0.5, 0.5)
    
    def simulate_random_events(self):
        """Simulate random vehicle events"""
        # Turn signals
        if random.random() < 0.05:  # 5% chance
            if self.state.turn_left or self.state.turn_right:
                self.state.turn_left = False
                self.state.turn_right = False
            else:
                if random.random() < 0.5:
                    self.state.turn_left = True
                else:
                    self.state.turn_right = True
        
        # Headlights based on time or weather
        hour = time.localtime().tm_hour
        if hour < 7 or hour > 19:
            self.state.headlights = True
        else:
            self.state.headlights = False
        
        # HVAC adjustments
        if random.random() < 0.02:
            self.state.hvac_fan_speed += random.uniform(-10, 10)
            self.state.hvac_fan_speed = max(0, min(100, self.state.hvac_fan_speed))
    
    def update_simulation(self):
        """Update vehicle simulation based on mode"""
        self.simulation_time += self.update_interval
        
        if self.mode == "city_drive":
            self.simulate_city_drive()
        elif self.mode == "highway":
            self.simulate_highway_drive()
        elif self.mode == "parking":
            self.simulate_parking()
        
        self.update_environment()
        self.simulate_random_events()
    
    async def publish_to_kuksa(self):
        """Publish simulated data to KUKSA"""
        if not self.kuksa_client:
            return
        
        # Prepare VSS data points
        vss_data = {
            # Vehicle motion
            "Vehicle.Speed": self.state.speed,
            "Vehicle.Powertrain.CombustionEngine.Speed": self.state.rpm,
            "Vehicle.TraveledDistance": self.state.odometer,
            
            # Position
            "Vehicle.CurrentLocation.Latitude": self.state.latitude,
            "Vehicle.CurrentLocation.Longitude": self.state.longitude,
            "Vehicle.CurrentLocation.Altitude": self.state.altitude,
            
            # Powertrain
            "Vehicle.Powertrain.FuelSystem.Level": self.state.fuel_level,
            "Vehicle.Powertrain.CombustionEngine.Temperature": self.state.engine_temp,
            "Vehicle.Electrical.Battery.Voltage": self.state.battery_voltage,
            "Vehicle.Powertrain.Transmission.CurrentGear": self.state.gear,
            
            # Environment
            "Vehicle.Exterior.AirTemperature": self.state.ambient_temp,
            "Vehicle.Cabin.HVAC.AmbientAirTemperature": self.state.cabin_temp,
            
            # Lights
            "Vehicle.Body.Lights.Beam.Low.IsOn": self.state.headlights,
            "Vehicle.Body.Lights.Hazard.IsSignaling": self.state.hazard_lights,
            "Vehicle.Body.Lights.DirectionIndicator.Left.IsSignaling": self.state.turn_left,
            "Vehicle.Body.Lights.DirectionIndicator.Right.IsSignaling": self.state.turn_right,
            
            # Doors
            "Vehicle.Cabin.Door.Row1.DriverSide.IsOpen": self.state.driver_door,
            "Vehicle.Cabin.Door.Row1.PassengerSide.IsOpen": self.state.passenger_door,
            
            # Windows
            "Vehicle.Cabin.Door.Row1.DriverSide.Window.Position": self.state.driver_window,
            
            # HVAC
            "Vehicle.Cabin.HVAC.Station.Row1.Driver.FanSpeed": self.state.hvac_fan_speed,
            "Vehicle.Cabin.HVAC.Station.Row1.Driver.Temperature": self.state.hvac_target_temp,
        }
        
        try:
            # Publish all data points
            datapoints = {path: Datapoint(value) for path, value in vss_data.items()}
            await self.kuksa_client.set_current_values(datapoints)
            
            logger.info(f"Published {len(vss_data)} VSS signals - Speed: {self.state.speed:.1f} km/h, RPM: {self.state.rpm:.0f}")
            
        except Exception as e:
            logger.error(f"Failed to publish to KUKSA: {e}")
    
    async def run(self):
        """Main simulation loop"""
        logger.info(f"Starting vehicle simulation in '{self.mode}' mode")
        
        if not await self.connect_kuksa():
            logger.error("Cannot start without KUKSA connection")
            return
        
        self.running = True
        
        try:
            while self.running:
                # Update simulation
                self.update_simulation()
                
                # Publish to KUKSA
                await self.publish_to_kuksa()
                
                # Wait for next update
                await asyncio.sleep(self.update_interval)
                
        except KeyboardInterrupt:
            logger.info("Simulation stopped by user")
        except Exception as e:
            logger.error(f"Simulation error: {e}")
        finally:
            self.running = False
            if self.kuksa_client:
                await self.kuksa_client.disconnect()
```

**Dockerfile:**
```dockerfile
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY main.py .
COPY vehicle_simulator.py .
COPY start.sh .

# Make start script executable
RUN chmod +x start.sh

# Run as non-root user
RUN useradd -m -u 1000 simulator
USER simulator

CMD ["./start.sh"]
```

**requirements.txt:**
```
kuksa-client>=0.4.0
asyncio-mqtt
```

**start.sh:**
```bash
#!/bin/bash
echo "=== DreamKIT Vehicle Simulator ==="
echo "Starting simulation service..."
python3 main.py
```

**simulator_service_installcfg.json:**
```json
{
  "_id": "dreamkit_simulator_001",
  "name": "DreamKIT Vehicle Simulator",
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"dreamkit/vehicle-simulator:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"simulation_mode\":\"city_drive\",\"update_interval\":1.0,\"vehicle_type\":\"sedan\",\"enable_faults\":false}}"
}
```

## Example 2: Weather Integration Service
**Perfect for**: Demonstrating external API integration with vehicle systems.

### Complete Service: `dreamkit-weather-service`

**main.py:**
```python
#!/usr/bin/env python3
import json
import asyncio
import aiohttp
import logging
from datetime import datetime
from kuksa_client.grpc import VSSClient, Datapoint

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class WeatherService:
    def __init__(self, config):
        self.config = config
        self.kuksa_client = None
        self.session = None
        
    async def connect_kuksa(self):
        try:
            self.kuksa_client = VSSClient("127.0.0.1", 55555)
            await self.kuksa_client.connect()
            logger.info("Connected to KUKSA data broker")
            return True
        except Exception as e:
            logger.error(f"KUKSA connection failed: {e}")
            return False
    
    async def get_weather_data(self, lat=None, lon=None):
        """Fetch weather data from OpenWeatherMap API"""
        api_key = self.config.get("api_key")
        if not api_key:
            logger.warning("No API key provided, using mock data")
            return self.get_mock_weather()
        
        # Use provided coordinates or default location
        latitude = lat or self.config.get("default_lat", 37.7749)
        longitude = lon or self.config.get("default_lon", -122.4194)
        
        url = f"http://api.openweathermap.org/data/2.5/weather"
        params = {
            "lat": latitude,
            "lon": longitude,
            "appid": api_key,
            "units": "metric"
        }
        
        try:
            if not self.session:
                self.session = aiohttp.ClientSession()
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return self.parse_weather_data(data)
                else:
                    logger.error(f"Weather API error: {response.status}")
                    return self.get_mock_weather()
                    
        except Exception as e:
            logger.error(f"Weather fetch error: {e}")
            return self.get_mock_weather()
    
    def get_mock_weather(self):
        """Generate mock weather data for testing"""
        import random
        
        conditions = ["clear", "cloudy", "rainy", "snowy", "foggy"]
        return {
            "temperature": round(random.uniform(15, 30), 1),
            "humidity": random.randint(30, 80),
            "pressure": round(random.uniform(990, 1020), 1),
            "visibility": random.randint(5, 20),
            "wind_speed": round(random.uniform(0, 15), 1),
            "wind_direction": random.randint(0, 360),
            "condition": random.choice(conditions),
            "uv_index": random.randint(1, 10),
            "timestamp": datetime.now().isoformat()
        }
    
    def parse_weather_data(self, api_data):
        """Parse OpenWeatherMap API response"""
        try:
            return {
                "temperature": api_data["main"]["temp"],
                "humidity": api_data["main"]["humidity"],
                "pressure": api_data["main"]["pressure"],
                "visibility": api_data.get("visibility", 10000) / 1000,  # Convert to km
                "wind_speed": api_data.get("wind", {}).get("speed", 0) * 3.6,  # Convert to km/h
                "wind_direction": api_data.get("wind", {}).get("deg", 0),
                "condition": api_data["weather"][0]["main"].lower(),
                "uv_index": 5,  # Not available in free API
                "timestamp": datetime.now().isoformat()
            }
        except KeyError as e:
            logger.error(f"Weather data parsing error: {e}")
            return self.get_mock_weather()
    
    def calculate_driving_recommendations(self, weather):
        """Generate driving recommendations based on weather"""
        recommendations = {
            "suggested_speed_limit": 100,  # km/h
            "headlights_recommended": False,
            "wipers_recommended": False,
            "ac_recommended": False,
            "heating_recommended": False,
            "tire_pressure_check": False
        }
        
        # Temperature-based recommendations
        if weather["temperature"] < 5:
            recommendations["heating_recommended"] = True
            recommendations["tire_pressure_check"] = True
            recommendations["suggested_speed_limit"] = 80
        elif weather["temperature"] > 25:
            recommendations["ac_recommended"] = True
        
        # Weather condition recommendations
        condition = weather["condition"]
        if condition in ["rain", "drizzle", "thunderstorm"]:
            recommendations["suggested_speed_limit"] = 70
            recommendations["headlights_recommended"] = True
            recommendations["wipers_recommended"] = True
        elif condition in ["snow", "sleet"]:
            recommendations["suggested_speed_limit"] = 50
            recommendations["headlights_recommended"] = True
            recommendations["tire_pressure_check"] = True
        elif condition in ["fog", "mist", "haze"]:
            recommendations["suggested_speed_limit"] = 60
            recommendations["headlights_recommended"] = True
        
        # Visibility-based recommendations
        if weather["visibility"] < 1:  # Less than 1km
            recommendations["suggested_speed_limit"] = 30
            recommendations["headlights_recommended"] = True
        
        # Wind-based recommendations
        if weather["wind_speed"] > 50:  # Strong wind
            recommendations["suggested_speed_limit"] = 80
        
        return recommendations
    
    async def publish_weather_data(self, weather, recommendations):
        """Publish weather data to KUKSA VSS signals"""
        try:
            # Weather data
            vss_data = {
                "Vehicle.Exterior.AirTemperature": weather["temperature"],
                "Vehicle.Exterior.Humidity": weather["humidity"],
                "Vehicle.Exterior.AirPressure": weather["pressure"],
                "Vehicle.Exterior.LightIntensity": 100 - weather["humidity"],  # Rough approximation
                
                # Wind data
                "Vehicle.Exterior.WindSpeed": weather["wind_speed"],
                
                # Driving recommendations (custom signals)
                "Vehicle.ADAS.SuggestedSpeedLimit": recommendations["suggested_speed_limit"],
                
                # Equipment recommendations
                "Vehicle.Body.Lights.Beam.Low.IsOn": recommendations["headlights_recommended"],
                "Vehicle.Body.Windshield.Front.Wiping.System.IsWiping": recommendations["wipers_recommended"],
            }
            
            # Publish to KUKSA
            datapoints = {path: Datapoint(value) for path, value in vss_data.items()}
            await self.kuksa_client.set_current_values(datapoints)
            
            logger.info(f"Weather update: {weather['temperature']}°C, {weather['condition']}, "
                       f"Speed limit: {recommendations['suggested_speed_limit']} km/h")
            
        except Exception as e:
            logger.error(f"Failed to publish weather data: {e}")
    
    async def run(self):
        """Main service loop"""
        logger.info("Starting DreamKIT Weather Service")
        
        if not await self.connect_kuksa():
            return
        
        update_interval = self.config.get("update_interval", 300)  # 5 minutes default
        
        try:
            while True:
                # Get current weather
                weather = await self.get_weather_data()
                
                # Calculate recommendations
                recommendations = self.calculate_driving_recommendations(weather)
                
                # Publish to KUKSA
                await self.publish_weather_data(weather, recommendations)
                
                # Wait for next update
                await asyncio.sleep(update_interval)
                
        except KeyboardInterrupt:
            logger.info("Weather service stopped")
        finally:
            if self.session:
                await self.session.close()
            if self.kuksa_client:
                await self.kuksa_client.disconnect()

async def main():
    # Load configuration
    try:
        with open("/app/runtime/runtimecfg.json", 'r') as f:
            config = json.load(f)
    except:
        config = {}
    
    # Default configuration
    default_config = {
        "api_key": "",  # OpenWeatherMap API key
        "default_lat": 37.7749,  # San Francisco
        "default_lon": -122.4194,
        "update_interval": 300,  # 5 minutes
        "use_vehicle_location": True
    }
    
    for key, value in default_config.items():
        config.setdefault(key, value)
    
    service = WeatherService(config)
    await service.run()

if __name__ == "__main__":
    asyncio.run(main())
```

**weather_service_installcfg.json:**
```json
{
  "_id": "dreamkit_weather_001",
  "name": "DreamKIT Weather Service",
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"dreamkit/weather-service:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"api_key\":\"\",\"update_interval\":300,\"use_vehicle_location\":true}}"
}
```

## Example 3: Simple Hello World Service
**Perfect for**: Learning the basics, testing installation, first service development.

### Complete Service: `dreamkit-hello-world`

**main.py:**
```python
#!/usr/bin/env python3
import json
import asyncio
import logging
from datetime import datetime
from kuksa_client.grpc import VSSClient, Datapoint

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HelloWorldService:
    def __init__(self, config):
        self.config = config
        self.kuksa_client = None
        self.counter = 0
        
    async def connect_kuksa(self):
        try:
            self.kuksa_client = VSSClient("127.0.0.1", 55555)
            await self.kuksa_client.connect()
            logger.info("Connected to KUKSA data broker")
            return True
        except Exception as e:
            logger.error(f"KUKSA connection failed: {e}")
            return False
    
    async def publish_hello_data(self):
        """Publish hello world data to KUKSA"""
        if not self.kuksa_client:
            return
        
        try:
            self.counter += 1
            message = self.config.get("message", "Hello from DreamKIT!")
            
            # Use custom VSS signals for demonstration
            vss_data = {
                "Vehicle.Service.HelloWorld.Message": f"{message} (#{self.counter})",
                "Vehicle.Service.HelloWorld.Timestamp": datetime.now().isoformat(),
                "Vehicle.Service.HelloWorld.Counter": self.counter,
                "Vehicle.Service.HelloWorld.IsActive": True
            }
            
            datapoints = {path: Datapoint(value) for path, value in vss_data.items()}
            await self.kuksa_client.set_current_values(datapoints)
            
            logger.info(f"Published: {message} (#{self.counter})")
            
        except Exception as e:
            logger.error(f"Failed to publish hello data: {e}")
    
    async def run(self):
        """Main service loop"""
        logger.info("Starting DreamKIT Hello World Service")
        
        if not await self.connect_kuksa():
            logger.warning("Running without KUKSA connection")
        
        interval = self.config.get("interval", 10)
        message = self.config.get("message", "Hello from DreamKIT!")
        
        logger.info(f"Service will send '{message}' every {interval} seconds")
        
        try:
            while True:
                await self.publish_hello_data()
                await asyncio.sleep(interval)
                
        except KeyboardInterrupt:
            logger.info("Hello World service stopped")
        finally:
            if self.kuksa_client:
                await self.kuksa_client.disconnect()

async def main():
    try:
        with open("/app/runtime/runtimecfg.json", 'r') as f:
            config = json.load(f)
        logger.info(f"Loaded config: {config}")
    except:
        logger.info("No config file found, using defaults")
        config = {}
    
    # Default configuration
    config.setdefault("message", "Hello from DreamKIT!")
    config.setdefault("interval", 10)
    
    service = HelloWorldService(config)
    await service.run()

if __name__ == "__main__":
    asyncio.run(main())
```

**hello_world_installcfg.json:**
```json
{
  "_id": "dreamkit_hello_001",
  "name": "Hello World Service",
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"dreamkit/hello-world:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"message\":\"Hello from DreamKIT!\",\"interval\":5}}"
}
```

## Why These Examples Are Great References:

### 1. **Progressive Complexity**
- **Hello World**: Basic structure, simple KUKSA integration
- **Weather Service**: External API integration, real-world logic
- **Vehicle Simulator**: Complex state management, comprehensive VSS usage

### 2. **Real SDV Value**
- **Demonstrates VSS standardization**
- **Shows KUKSA data broker integration**
- **Provides configurable, flexible services**

### 3. **Production-Ready Patterns**
- Proper error handling and logging
- Configuration management
- Graceful shutdown
- Docker best practices

### 4. **Educational Value**
- Complete, working examples
- Well-commented code
- Clear documentation
- Copy-paste ready

### 5. **Practical Use Cases**
- **Simulator**: Perfect for testing and demos
- **Weather**: Shows external API integration
- **Hello World**: Learning and validation

Each example can be built and deployed immediately, giving creators working references they can modify for their specific needs while demonstrating the full power of the DreamKIT SDV platform.