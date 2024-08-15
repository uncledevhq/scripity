#!/bin/bash

# This script installs Ansible on an Ubuntu server

# Update the package list and upgrade the installed packages
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install required dependencies
echo "Installing required dependencies..."
sudo apt-get install software-properties-common -y

# Add the Ansible PPA (Personal Package Archive)
echo "Adding Ansible PPA..."
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install Ansible
echo "Installing Ansible..."
sudo apt-get install ansible -y

# Verify the installation
echo "Verifying Ansible installation..."
ansible --version

# Installation complete
echo "Ansible installation is complete!"
