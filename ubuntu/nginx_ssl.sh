#!/bin/bash

# Function to validate input
validate_input() {
    local input="$1"
    local error_message="$2"
    while [[ -z "$input" ]]; do
        read -p "$error_message: " input
    done
    echo "$input"
}

# Prompt for values
PORT=$(validate_input "" "Enter the port number to proxy (e.g., 9000)")
DOMAIN=$(validate_input "" "Enter the domain name (e.g., example.com)")
EMAIL=$(validate_input "" "Enter email for Let's Encrypt SSL certificate")

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y

# Install Certbot and Nginx plugin
sudo apt install certbot python3-certbot-nginx -y

# Create Nginx server block configuration
sudo tee /etc/nginx/sites-available/"$DOMAIN" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site by creating a symbolic link
sudo ln -s /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/

# Remove the default Nginx configuration if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Obtain SSL certificate using Certbot
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL"

# Display completion message
echo "Setup completed! Nginx is now configured to proxy requests to port $PORT"