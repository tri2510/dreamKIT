import flask, json, time, threading, random, logging, os
from flask import Flask, jsonify, request

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/logs/vehicle-api.log")
    ]
)
logger = logging.getLogger("vehicle-api")

app = Flask(__name__)

vehicle_data = {
    "VehicleSpeed": 0,
    "EngineRPM": 0,
    "FuelLevel": 75,
    "BatteryLevel": 95,
    "InsideTemperature": 22.5,
    "OutsideTemperature": 15.0,
    "VIN": "DREAMKIT00000001",
    "ODO": 1250,
    "Lights": {"Headlights": "OFF", "HighBeam": "OFF", "Hazard": "OFF"},
    "Doors": {"DriverDoor": "CLOSED", "PassengerDoor": "CLOSED", "RearLeftDoor": "CLOSED", "RearRightDoor": "CLOSED"},
    "Windows": {"DriverWindow": "CLOSED", "PassengerWindow": "CLOSED", "RearLeftWindow": "CLOSED", "RearRightWindow": "CLOSED"}
}

@app.route("/api/v1/vehicle/info")
def vehicle_info():
    logger.info("Vehicle info API called")
    return jsonify(vehicle_data)

@app.route("/api/v1/vehicle/<path:signal>")
def get_signal(signal):
    logger.info(f"Get signal API called for {signal}")
    if signal in vehicle_data:
        return jsonify({signal: vehicle_data[signal]})
    elif signal.split(".")[0] in vehicle_data and len(signal.split(".")) > 1:
        parent, child = signal.split(".")
        if parent in vehicle_data and isinstance(vehicle_data[parent], dict) and child in vehicle_data[parent]:
            return jsonify({signal: vehicle_data[parent][child]})
    return jsonify({"error": "Signal not found"}), 404

@app.route("/api/v1/vehicle/<path:signal>", methods=["POST"])
def set_signal(signal):
    logger.info(f"Set signal API called for {signal}")
    data = request.json
    if not data or "value" not in data:
        return jsonify({"error": "Value missing"}), 400
        
    if signal in vehicle_data:
        old_value = vehicle_data[signal]
        vehicle_data[signal] = data["value"]
        logger.info(f"Signal {signal} changed from {old_value} to {data['value']}")
        return jsonify({signal: data["value"]})
    elif signal.split(".")[0] in vehicle_data and len(signal.split(".")) > 1:
        parent, child = signal.split(".")
        if parent in vehicle_data and isinstance(vehicle_data[parent], dict) and child in vehicle_data[parent]:
            old_value = vehicle_data[parent][child]
            vehicle_data[parent][child] = data["value"]
            logger.info(f"Signal {signal} changed from {old_value} to {data['value']}")
            return jsonify({signal: data["value"]})
    return jsonify({"error": "Signal not found"}), 404

def simulate_vehicle():
    while True:
        # Randomly change some values to simulate a real vehicle
        vehicle_data["VehicleSpeed"] = round(max(0, min(vehicle_data["VehicleSpeed"] + random.uniform(-5, 5), 120)), 1)
        vehicle_data["EngineRPM"] = int(max(700, min(vehicle_data["EngineRPM"] + random.uniform(-200, 200), 5000)))
        vehicle_data["OutsideTemperature"] = round(max(-10, min(vehicle_data["OutsideTemperature"] + random.uniform(-0.5, 0.5), 40)), 1)
        time.sleep(3)
        logger.info(f"Updated signals - Speed: {vehicle_data['VehicleSpeed']} km/h, RPM: {vehicle_data['EngineRPM']}")

threading.Thread(target=simulate_vehicle, daemon=True).start()

logger.info("Vehicle API starting up")
app.run(host="0.0.0.0", port=9000)
