# First stage: Build dependencies in a full Python environment
FROM ubuntu:24.04 AS app-builder

WORKDIR /app/

# Install necessary packages for building the environment
RUN apt-get update && apt install -y python3-bluez pip
RUN pip install --no-cache-dir pyinstaller kuksa-client --break-system-packages

COPY main.py /app/main.py

# Install Python dependencies into a specific directory
RUN cd /app \
    && pyinstaller --onefile main.py 

# Second stage: Create a minimal runtime environment
FROM ubuntu:24.04 AS target

# Install necessary packages for building the environment
#RUN apt-get update && apt install -y python3-bluez
RUN apt-get update && apt install -y --no-install-recommends python3-bluez
#    && apt-get autoremove -y && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /lib/python3.12/

WORKDIR /app

# Copy the Python packages from the builder stage to the Alpine image
COPY --from=app-builder /app/dist /app/dist

# Copy application files
COPY press.py /app/dist/press.py
#COPY cfg.json /app/dist/cfg.json
COPY start.sh /app/start.sh

# Set execute permission for the script
RUN chmod +x /app/start.sh

# Execute the script
CMD ["/app/start.sh"]
