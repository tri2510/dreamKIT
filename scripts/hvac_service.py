import flask, json, time, threading, requests, logging, os
from flask import Flask, jsonify, request

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/logs/hvac-service.log")
    ]
)
logger = logging.getLogger("hvac-service")

app = Flask(__name__)

hvac_state = {
    "temperature": 22,
    "targetTemperature": 22,
    "fanSpeed": 3,
    "acEnabled": False,
    "mode": "auto",
    "airDistribution": "normal",
    "recirculation": False
}

@app.route("/api/v1/status")
def status():
    logger.info("Status API called")
    return jsonify({
        "status": "running",
        "service": "hvac-service",
        "version": "1.0.0"
    })

@app.route("/api/v1/hvac")
def get_hvac():
    logger.info("Get HVAC state API called")
    return jsonify(hvac_state)

@app.route("/api/v1/hvac", methods=["POST"])
def set_hvac():
    logger.info("Set HVAC state API called")
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
        
    # Update state with provided values
    for key in data:
        if key in hvac_state:
            old_value = hvac_state[key]
            hvac_state[key] = data[key]
            logger.info(f"Setting {key} from {old_value} to {data[key]}")
            
            # If target temperature changed, notify vehicle API
            if key == "targetTemperature":
                try:
                    requests.post("http://vehicle-api:9000/api/v1/vehicle/InsideTemperature", 
                                 json={"value": data[key]}, timeout=1)
                except Exception as e:
                    logger.error(f"Failed to notify vehicle API: {e}")
    
    return jsonify(hvac_state)

def update_hvac_state():
    while True:
        # Gradually move current temperature toward target
        if hvac_state["temperature"] != hvac_state["targetTemperature"]:
            direction = 1 if hvac_state["temperature"] < hvac_state["targetTemperature"] else -1
            hvac_state["temperature"] += direction * 0.5
            hvac_state["temperature"] = round(hvac_state["temperature"], 1)
            logger.info(f"Adjusting temperature to {hvac_state['temperature']}°C (Target: {hvac_state['targetTemperature']}°C)")
        time.sleep(5)

threading.Thread(target=update_hvac_state, daemon=True).start()

logger.info("HVAC Service starting up")
app.run(host="0.0.0.0", port=8080)
