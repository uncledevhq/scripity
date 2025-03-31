#!/bin/bash

# Jenkins Setup Script for Ubuntu/Debian
# This script installs Jenkins and configures it with basic settings

# Exit immediately if a command exits with a non-zero status
set -e

# Print commands and their arguments as they are executed
set -x

echo "Starting Jenkins installation..."

# Update package lists
sudo apt-get update

# Install Java (Jenkins dependency)
echo "Installing Java..."
sudo apt-get install -y openjdk-11-jdk

# Add Jenkins repository key
echo "Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists again
sudo apt-get update

# Install Jenkins
echo "Installing Jenkins..."
sudo apt-get install -y jenkins

# Start Jenkins service
echo "Starting Jenkins service..."
sudo systemctl start jenkins

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Install some useful tools
echo "Installing additional tools..."
sudo apt-get install -y git curl nodejs npm

# Wait for Jenkins to start up
echo "Waiting for Jenkins to start..."
sleep 30

# Get the initial admin password
JENKINS_INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Install Jenkins CLI
echo "Setting up Jenkins CLI..."
JENKINS_URL="http://localhost:8080"
curl -L -o jenkins-cli.jar $JENKINS_URL/jnlpJars/jenkins-cli.jar

# Print information
echo "================================================"
echo "Jenkins installation complete!"
echo "================================================"
echo "Jenkins URL: http://localhost:8080"
echo "Initial Admin Password: $JENKINS_INITIAL_PASSWORD"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:8080 in your browser"
echo "2. Enter the initial admin password shown above"
echo "3. Install suggested plugins"
echo "4. Create an admin user"
echo "5. Start configuring your CI/CD pipelines"
echo "================================================"

# Note: For security in production environments, you should:
# - Set up HTTPS
# - Configure proper authentication
# - Set up firewall rules