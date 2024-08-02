#!/bin/bash

# Install Certbot and dependencies
sudo yum install -y python3-pip
sudo pip3 install certbot urllib3

# Create directory for certificates
mkdir -p ~/certs

# Obtain SSL certificates using Certbot
sudo certbot certonly --standalone -d easefuel.onlinedb.site

# Copy the certificates to the appropriate directory
sudo cp /etc/letsencrypt/live/easefuel.onlinedb.site/fullchain.pem ~/certs/
sudo cp /etc/letsencrypt/live/easefuel.onlinedb.site/privkey.pem ~/certs/

echo "SSL certificate setup complete!"
