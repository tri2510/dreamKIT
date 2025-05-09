import flask, json, time, threading, logging, os
from flask import Flask, jsonify

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/logs/dm-manager.log")
    ]
)
logger = logging.getLogger("dm-manager")

app = Flask(__name__)

@app.route("/api/v1/status")
def status():
    logger.info("Status API called")
    return jsonify({
        "status": "running",
        "version": "1.0.0",
        "components": {
            "dreamos-core": "connected",
            "vehicle-api": "connected"
        }
    })

@app.route("/api/v1/services")
def services():
    logger.info("Services API called")
    return jsonify({
        "services": [
            {"name": "hvac-service", "status": "running", "url": "http://hvac-service:8080"},
            {"name": "vehicle-api", "status": "running", "url": "http://vehicle-api:9000"}
        ]
    })

def log_activity():
    while True:
        logger.info("Monitoring system components")
        time.sleep(15)

threading.Thread(target=log_activity, daemon=True).start()

logger.info("DM Manager starting up")
app.run(host="0.0.0.0", port=5000)
