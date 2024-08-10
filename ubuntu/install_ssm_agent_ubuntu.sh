#!/bin/bash

# Update the package list
echo "Updating package list..."
sudo apt-get update -y

# Install the SSM Agent
echo "Installing SSM Agent..."
sudo apt-get install -y amazon-ssm-agent

# Enable the SSM Agent to start on boot
echo "Enabling SSM Agent to start on boot..."
sudo systemctl enable amazon-ssm-agent

# Start the SSM Agent
echo "Starting SSM Agent..."
sudo systemctl start amazon-ssm-agent

# Verify the installation
echo "Verifying SSM Agent installation..."
if sudo systemctl status amazon-ssm-agent | grep "active (running)" > /dev/null; then
    echo "SSM Agent is installed and running successfully."
else
    echo "Failed to start SSM Agent."
    exit 1
fi
