import flask, json, time, threading, requests, logging, os
from flask import Flask, jsonify, request, render_template_string

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/logs/ivi-system.log")
    ]
)
logger = logging.getLogger("ivi-system")

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>DreamKIT IVI System</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f0f4f8; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #0066cc; }
        .panel { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .panel h2 { margin-top: 0; color: #333; font-size: 1.2em; }
        button { background: #0066cc; color: white; border: none; padding: 8px 15px; border-radius: 4px; cursor: pointer; }
        button:hover { background: #0055aa; }
        .slider { width: 100%; }
        .status { margin-top: 20px; padding: 10px; background: #e6f7ff; border-radius: 5px; }
        .logs { height: 100px; overflow-y: scroll; background: #f5f5f5; padding: 10px; font-family: monospace; border-radius: 4px; margin-top: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>DreamKIT IVI System</h1>
        
        <div class="panel">
            <h2>Vehicle Status</h2>
            <div id="vehicle-status">Loading...</div>
        </div>
        
        <div class="panel">
            <h2>HVAC Controls</h2>
            <div>
                <label for="temp">Temperature: <span id="temp-value">22</span>°C</label>
                <input type="range" id="temp" class="slider" min="16" max="30" value="22" step="0.5">
            </div>
            <div>
                <label for="fan">Fan Speed: <span id="fan-value">3</span></label>
                <input type="range" id="fan" class="slider" min="0" max="10" value="3" step="1">
            </div>
            <div>
                <button id="ac-toggle">A/C: OFF</button>
                <button id="mode-toggle">Mode: AUTO</button>
            </div>
        </div>
        
        <div class="status">
            <h2>System Status</h2>
            <div id="system-status">Connecting to services...</div>
            <div class="logs" id="logs"></div>
        </div>
    </div>
    
    <script>
        // Update vehicle status
        function updateVehicleStatus() {
            fetch('/api/vehicle-status')
                .then(response => response.json())
                .then(data => {
                    let html = `
                        <p>Speed: ${data.VehicleSpeed} km/h</p>
                        <p>RPM: ${data.EngineRPM}</p>
                        <p>Fuel: ${data.FuelLevel}%</p>
                        <p>Inside: ${data.InsideTemperature}°C</p>
                        <p>Outside: ${data.OutsideTemperature}°C</p>
                    `;
                    document.getElementById('vehicle-status').innerHTML = html;
                })
                .catch(error => console.error('Error fetching vehicle status:', error));
        }
        
        // Update HVAC status
        function updateHvacStatus() {
            fetch('/api/hvac-status')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('temp-value').textContent = data.targetTemperature;
                    document.getElementById('temp').value = data.targetTemperature;
                    document.getElementById('fan-value').textContent = data.fanSpeed;
                    document.getElementById('fan').value = data.fanSpeed;
                    document.getElementById('ac-toggle').textContent = `A/C: ${data.acEnabled ? 'ON' : 'OFF'}`;
                    document.getElementById('mode-toggle').textContent = `Mode: ${data.mode.toUpperCase()}`;
                })
                .catch(error => console.error('Error fetching HVAC status:', error));
        }
        
        // Update system status
        function updateSystemStatus() {
            fetch('/api/system-status')
                .then(response => response.json())
                .then(data => {
                    let html = `
                        <p>DM Manager: ${data.dmManager}</p>
                        <p>Vehicle API: ${data.vehicleApi}</p>
                        <p>HVAC Service: ${data.hvacService}</p>
                    `;
                    document.getElementById('system-status').innerHTML = html;
                })
                .catch(error => console.error('Error fetching system status:', error));
        }
        
        // Handle temperature changes
        document.getElementById('temp').addEventListener('input', function() {
            document.getElementById('temp-value').textContent = this.value;
        });
        
        document.getElementById('temp').addEventListener('change', function() {
            fetch('/api/set-hvac', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ targetTemperature: parseFloat(this.value) }),
            })
            .then(response => response.json())
            .then(data => {
                addLog(`Set temperature to ${data.targetTemperature}°C`);
            })
            .catch(error => console.error('Error setting temperature:', error));
        });
        
        // Handle fan speed changes
        document.getElementById('fan').addEventListener('input', function() {
            document.getElementById('fan-value').textContent = this.value;
        });
        
        document.getElementById('fan').addEventListener('change', function() {
            fetch('/api/set-hvac', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ fanSpeed: parseInt(this.value) }),
            })
            .then(response => response.json())
            .then(data => {
                addLog(`Set fan speed to ${data.fanSpeed}`);
            })
            .catch(error => console.error('Error setting fan speed:', error));
        });
        
        // Toggle A/C
        document.getElementById('ac-toggle').addEventListener('click', function() {
            const newState = this.textContent.includes('OFF');
            fetch('/api/set-hvac', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ acEnabled: newState }),
            })
            .then(response => response.json())
            .then(data => {
                this.textContent = `A/C: ${data.acEnabled ? 'ON' : 'OFF'}`;
                addLog(`Set A/C to ${data.acEnabled ? 'ON' : 'OFF'}`);
            })
            .catch(error => console.error('Error toggling A/C:', error));
        });
        
        // Toggle mode
        document.getElementById('mode-toggle').addEventListener('click', function() {
            const currentMode = this.textContent.split(': ')[1].toLowerCase();
            const modes = ['auto', 'cool', 'heat', 'fan'];
            const currentIndex = modes.indexOf(currentMode);
            const nextIndex = (currentIndex + 1) % modes.length;
            const newMode = modes[nextIndex];
            
            fetch('/api/set-hvac', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ mode: newMode }),
            })
            .then(response => response.json())
            .then(data => {
                this.textContent = `Mode: ${data.mode.toUpperCase()}`;
                addLog(`Set mode to ${data.mode.toUpperCase()}`);
            })
            .catch(error => console.error('Error toggling mode:', error));
        });
        
        // Add log entry
        function addLog(message) {
            const logElement = document.getElementById('logs');
            const now = new Date();
            const timestamp = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
            logElement.innerHTML += `${timestamp} - ${message}<br>`;
            logElement.scrollTop = logElement.scrollHeight;
        }
        
        // Initial updates
        updateVehicleStatus();
        updateHvacStatus();
        updateSystemStatus();
        
        // Set up periodic updates
        setInterval(updateVehicleStatus, 2000);
        setInterval(updateHvacStatus, 3000);
        setInterval(updateSystemStatus, 5000);
        
        addLog('IVI System initialized');
    </script>
</body>
</html>
"""

@app.route("/")
def index():
    logger.info("Main UI accessed")
    return render_template_string(HTML_TEMPLATE)

@app.route("/api/vehicle-status")
def vehicle_status():
    logger.info("Vehicle status API called")
    try:
        response = requests.get("http://localhost:9000/api/v1/vehicle/info", timeout=1)
        return jsonify(response.json())
    except Exception as e:
        logger.error(f"Error fetching vehicle status: {e}")
        return jsonify({
            "VehicleSpeed": 0,
            "EngineRPM": 0,
            "FuelLevel": 0,
            "InsideTemperature": 0,
            "OutsideTemperature": 0
        })

@app.route("/api/hvac-status")
def hvac_status():
    logger.info("HVAC status API called")
    try:
        response = requests.get("http://hvac-service:8080/api/v1/hvac", timeout=1)
        return jsonify(response.json())
    except Exception as e:
        logger.error(f"Error fetching HVAC status: {e}")
        return jsonify({
            "temperature": 0,
            "targetTemperature": 0,
            "fanSpeed": 0,
            "acEnabled": False,
            "mode": "unknown",
            "airDistribution": "unknown",
            "recirculation": False
        })

@app.route("/api/system-status")
def system_status():
    logger.info("System status API called")
    status = {"dmManager": "Unknown", "vehicleApi": "Unknown", "hvacService": "Unknown"}
    
    try:
        response = requests.get("http://dm-manager:5000/api/v1/status", timeout=1)
        if response.status_code == 200:
            status["dmManager"] = "Connected"
    except:
        pass
        
    try:
        response = requests.get("http://vehicle-api:9000/api/v1/vehicle/info", timeout=1)
        if response.status_code == 200:
            status["vehicleApi"] = "Connected"
    except:
        pass
        
    try:
        response = requests.get("http://hvac-service:8080/api/v1/status", timeout=1)
        if response.status_code == 200:
            status["hvacService"] = "Connected"
    except:
        pass
        
    return jsonify(status)

@app.route("/api/set-hvac", methods=["POST"])
def set_hvac():
    logger.info("Set HVAC API called")
    try:
        data = request.json
        response = requests.post("http://hvac-service:8080/api/v1/hvac", json=data, timeout=1)
        return jsonify(response.json())
    except Exception as e:
        logger.error(f"Error setting HVAC: {e}")
        return jsonify({"error": "Failed to set HVAC parameters"})

def log_activity():
    while True:
        logger.info("User interface active")
        time.sleep(30)

threading.Thread(target=log_activity, daemon=True).start()

logger.info("IVI System starting up")
app.run(host="0.0.0.0", port=8000)
