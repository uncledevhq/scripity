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
echo "Configuring AWS CLI..."
echo "Note: You are setting up AWS CLI for an AWS IAM user. Ensure you have the correct permissions."
read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY
read -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY

# Set default values if not provided
read -p "Enter AWS Region [default: af-south-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-af-south-1}
read -p "Enter Output Format [default: json]: " AWS_OUTPUT_FORMAT
AWS_OUTPUT_FORMAT=${AWS_OUTPUT_FORMAT:-json}

aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"
aws configure set output "$AWS_OUTPUT_FORMAT"

echo "AWS CLI setup complete."