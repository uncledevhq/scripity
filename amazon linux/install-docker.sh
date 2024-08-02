#!/bin/bash

# Update and install Docker
sudo yum update -y
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

echo "Docker and Docker Compose installation complete!"
