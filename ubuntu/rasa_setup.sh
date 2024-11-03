#!/bin/bash

# Update package lists and install prerequisites
echo "Updating packages and installing dependencies..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y python3.8 python3.8-venv python3-pip build-essential

# Create a project directory and navigate into it
echo "Creating Rasa project directory..."
mkdir -p ~/rasa_project
cd ~/rasa_project

# Set up Python virtual environment
echo "Creating a virtual environment with Python 3.8..."
python3.8 -m venv rasa_env

# Activate the virtual environment
echo "Activating virtual environment..."
source rasa_env/bin/activate

# Update pip, setuptools, and wheel
echo "Upgrading pip, setuptools, and wheel..."
pip install --upgrade pip setuptools wheel

# Install Rasa with use-pep517 flag to resolve any dependency issues
echo "Installing Rasa..."
pip install rasa --use-pep517

# Verify Rasa installation
echo "Rasa installation completed. Verifying installation..."
rasa --version

# Prompt to initialize a new Rasa project
echo "Do you want to initialize a new Rasa project in ~/rasa_project? (y/n)"
read initialize_project

if [ "$initialize_project" = "y" ]; then
    echo "Initializing new Rasa project..."
    rasa init --no-prompt
    echo "New Rasa project initialized in ~/rasa_project."
else
    echo "Skipping project initialization. Run 'rasa init' manually if needed."
fi

echo "Rasa setup completed successfully!"
