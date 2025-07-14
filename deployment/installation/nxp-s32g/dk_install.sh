#!/bin/bash

# Enable the Service to Start at Boot
cp scripts/dreamos-setup.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable dreamos-setup.service
systemctl start dreamos-setup.service
systemctl status dreamos-setup.service

# Setup on client machines
cp /scripts/daemon.json /etc/docker/daemon.json
# Restart docker daemon
systemctl restart docker

# Can ultilities
chmod +x tools/.
cp -r tools/* /usr/local/bin
