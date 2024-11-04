#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install curl if it's not already installed
echo "Installing curl..."
sudo apt install curl -y

# Install NVM
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# Load NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify NVM installation
if command -v nvm &> /dev/null
then
    echo "NVM installed successfully."
else
    echo "NVM installation failed."
    exit 1
fi

# Install the latest LTS version of Node.js
echo "Installing latest LTS version of Node.js..."
nvm install --lts

# Set default Node.js version
echo "Setting default Node.js version to the latest LTS..."
nvm alias default 'lts/*'

# Verify Node.js and npm installation
echo "Verifying Node.js and npm installation..."
node_version=$(node -v)
npm_version=$(npm -v)
echo "Node.js version: $node_version"
echo "npm version: $npm_version"

echo "NVM and Node.js setup complete!"
