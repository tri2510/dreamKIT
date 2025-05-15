# Start with the Python 3.12 Alpine image for a lightweight base
FROM python:3.12-alpine

# Set the working directory
WORKDIR /app/

# Install required build dependencies only for `cantools`
RUN apk add --no-cache gcc musl-dev python3-dev libffi-dev \
    && pip install --no-cache-dir PyYAML requests cantools \
    && apk del gcc musl-dev python3-dev libffi-dev  # Remove build dependencies to reduce image size

RUN apk add --no-cache docker openssh-client sshpass

# Copy only necessary scripts into the container
COPY ./scripts/main.py /app/
COPY ./scripts/start.sh /app/
COPY ./scripts/updateappmgrfile.py /app/
COPY ./scripts/updateDbcDefaultValue.py /app/

# Make the start script executable
RUN chmod +x /app/start.sh

# Set the command to execute the start script
CMD ["/app/start.sh"]
