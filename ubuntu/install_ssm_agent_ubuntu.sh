#!/bin/bash

# Update the package list
echo "Updating package list..."
sudo apt-get update -y

# Download the latest version of the SSM Agent
echo "Downloading SSM Agent package..."
wget https://s3.amazonaws.com/amazon-ssm-af-south-1/latest/debian_amd64/amazon-ssm-agent.deb

# Install the SSM Agent
echo "Installing SSM Agent..."
sudo dpkg -i amazon-ssm-agent.deb

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
