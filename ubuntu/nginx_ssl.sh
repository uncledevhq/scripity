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
echo "Is this a root domain or subdomain?"
DOMAIN_TYPE=$(validate_input "" "Enter 'root' or 'subdomain'" "root")

PORT=$(validate_input "" "Enter the local port to proxy (e.g. 3000)")

ROOT_DOMAIN=$(validate_input "" "Enter the domain (e.g. panukaagribizhub.com)")
if [[ "$DOMAIN_TYPE" == "subdomain" ]]; then
    SUBDOMAIN=$(validate_input "" "Enter the subdomain (e.g. training)")
    FULL_DOMAIN="$SUBDOMAIN.$ROOT_DOMAIN"
else
    FULL_DOMAIN="$ROOT_DOMAIN"
fi

EMAIL=$(validate_input "" "Enter email for Let's Encrypt (expiry notices)" "uncledevhq@gmail.com")

echo ""
echo "======================================"
echo "Nginx Reverse Proxy + SSL Configuration"
echo "--------------------------------------"
echo "Domain      : $FULL_DOMAIN"
echo "Proxy port  : localhost:$PORT"
echo "Certbot email: $EMAIL"
echo "======================================"
echo ""

# -----------------------------
# System update & install
# -----------------------------
sudo apt update
sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx

# -----------------------------
# Create Nginx server block
# -----------------------------
NGINX_CONF="/etc/nginx/sites-available/$FULL_DOMAIN"

if [[ -f "$NGINX_CONF" ]]; then
    echo "⚠️ Nginx config for $FULL_DOMAIN already exists. Skipping creation."
else
    sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $FULL_DOMAIN;

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
    sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
fi

# -----------------------------
# Test & reload Nginx
# -----------------------------
sudo nginx -t
sudo systemctl reload nginx

# -----------------------------
# Obtain SSL certificate
# -----------------------------
sudo certbot --nginx \
    -d "$FULL_DOMAIN" \
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
echo "  https://$FULL_DOMAIN"
echo ""
echo "Proxying traffic to localhost:$PORT"
