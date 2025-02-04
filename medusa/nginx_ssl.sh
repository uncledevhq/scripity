#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y

# Install Certbot and Nginx plugin
sudo apt install certbot python3-certbot-nginx -y

# Create Nginx server block configuration
sudo tee /etc/nginx/sites-available/marketplace.syaonlinetrading.com << EOF
server {
    listen 80;
    listen [::]:80;
    server_name marketplace.syaonlinetrading.com;

    location / {
        proxy_pass http://localhost:9000;
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
sudo ln -s /etc/nginx/sites-available/marketplace.syaonlinetrading.com /etc/nginx/sites-enabled/

# Remove the default Nginx configuration if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Obtain SSL certificate using Certbot
sudo certbot --nginx -d marketplace.syaonlinetrading.com --non-interactive --agree-tos --email your-email@example.com

# Display completion message
echo "Setup completed! Nginx is now configured to proxy requests to port 9000"