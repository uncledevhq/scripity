#!/bin/bash

set -e

# -----------------------------
# Helper: validate input
# -----------------------------
validate_input() {
    local input="$1"
    local prompt="$2"
    local default="$3"

    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " input
        input="${input:-$default}"
    else
        while [[ -z "$input" ]]; do
            read -p "$prompt: " input
        done
    fi

    echo "$input"
}

# -----------------------------
# User inputs
# -----------------------------
PORT=$(validate_input "" "Enter the local port to proxy (e.g. 3000)")
ROOT_DOMAIN=$(validate_input "" "Enter the root domain (e.g. panukaagribizhub.com)")
EMAIL=$(validate_input "" "Enter email for Let's Encrypt (expiry notices)" "uncledevhq@gmail.com")

WWW_DOMAIN="www.$ROOT_DOMAIN"

echo ""
echo "======================================"
echo "Nginx Reverse Proxy + SSL Configuration"
echo "--------------------------------------"
echo "Root domain : $ROOT_DOMAIN"
echo "WWW domain  : $WWW_DOMAIN"
echo "Proxy port  : localhost:$PORT"
echo "Certbot email: $EMAIL"
echo "======================================"
echo ""

# -----------------------------
# System update
# -----------------------------
sudo apt update
sudo apt upgrade -y

# -----------------------------
# Install required packages
# -----------------------------
sudo apt install -y nginx certbot python3-certbot-nginx

# -----------------------------
# Nginx server block (HTTP)
# -----------------------------
sudo tee /etc/nginx/sites-available/"$ROOT_DOMAIN" > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $ROOT_DOMAIN $WWW_DOMAIN;

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

# -----------------------------
# Enable site
# -----------------------------
sudo ln -sf /etc/nginx/sites-available/"$ROOT_DOMAIN" /etc/nginx/sites-enabled/"$ROOT_DOMAIN"

# Remove default site if exists
sudo rm -f /etc/nginx/sites-enabled/default

# -----------------------------
# Test & reload Nginx
# -----------------------------
sudo nginx -t
sudo systemctl reload nginx

# -----------------------------
# Obtain SSL certificate (root + www)
# -----------------------------
sudo certbot --nginx \
    -d "$ROOT_DOMAIN" \
    -d "$WWW_DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL"

# -----------------------------
# Done
# -----------------------------
echo ""
echo "✅ Setup complete!"
echo ""
echo "Your application is now live at:"
echo "  https://$ROOT_DOMAIN"
echo "  https://$WWW_DOMAIN"
echo ""
echo "Proxying traffic to localhost:$PORT"
