#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Update system packages
sudo apt update -y

# Install Snap if not installed
if ! command_exists snap; then
    echo "Snap is not installed. Installing Snap..."
    sudo apt install snapd -y
    echo "Snap installed successfully."
fi

# Ensure Snap daemon is running
sudo systemctl enable --now snapd

# Verify Snap installation
snap version

# Install AWS CLI using Snap
if ! command_exists aws; then
    echo "Installing AWS CLI via Snap..."
    sudo snap install aws-cli --classic
    echo "AWS CLI installed successfully."
else
    echo "AWS CLI is already installed. Skipping installation."
fi

# Verify AWS CLI installation
aws --version

# AWS CLI Configuration
read -p "Do you want to configure AWS CLI now? (y/n): " CONFIGURE_AWS
if [[ "$CONFIGURE_AWS" == "y" ]]; then
    aws configure
fi

echo "AWS CLI setup complete."
