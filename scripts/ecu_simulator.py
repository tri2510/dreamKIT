import time, requests, random, threading, logging, os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/logs/ecu-simulator.log")
    ]
)
logger = logging.getLogger("ecu-simulator")

class ECUSimulator:
    def __init__(self, name):
        self.name = name
        self.running = True
        self.connected = False
        
    def send_can_message(self):
        message_id = format(random.randint(0, 0xFFF), "03X")
        data = "".join([format(random.randint(0, 0xFF), "02X") for _ in range(8)])
        logger.info(f"{self.name} sending CAN message: ID={message_id}, Data={data}")
        
    def process_requests(self):
        logger.info(f"{self.name} processing request")
        
    def connect_to_vehicle_api(self):
        try:
            response = requests.get("http://vehicle-api:9000/api/v1/vehicle/VIN", timeout=1)
            if response.status_code == 200:
                self.connected = True
                logger.info(f"{self.name} connected to Vehicle API")
                return True
        except Exception as e:
            logger.error(f"{self.name} failed to connect to Vehicle API: {e}")
        return False
        
    def run(self):
        logger.info(f"Starting {self.name}")
        
        # Try to connect to the vehicle API
        while not self.connected and self.running:
            if self.connect_to_vehicle_api():
                break
            logger.info(f"{self.name} waiting for Vehicle API...")
            time.sleep(5)
            
        # Main ECU loop
        while self.running:
            self.send_can_message()
            self.process_requests()
            time.sleep(random.uniform(1, 5))

# Create and start ECU simulators
ecus = [
    ECUSimulator("Body Control Module"),
    ECUSimulator("Engine Control Unit"),
    ECUSimulator("Transmission Control Unit")
]

threads = []
for ecu in ecus:
    thread = threading.Thread(target=ecu.run)
    thread.daemon = True
    thread.start()
    threads.append(thread)
    
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    for ecu in ecus:
        ecu.running = False
    for thread in threads:
        thread.join()
