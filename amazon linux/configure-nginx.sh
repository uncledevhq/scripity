#!/bin/bash

# Create necessary directories and files for Nginx
mkdir -p ~/nginx
cat <<EOF > ~/nginx/nginx.conf
server {
    listen 80;
    server_name easefuel.onlinedb.site;

    location / {
        proxy_pass http://db:5432;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl;
    server_name easefuel.onlinedb.site;

    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    location / {
        proxy_pass http://db:5432;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Create Docker Compose file for PostgreSQL and Nginx
cat <<EOF > docker-compose.yml
version: '3.1'

services:
  db:
    image: postgres:latest
    container_name: postgres
    environment:
      POSTGRES_USER: uncledev
      POSTGRES_PASSWORD: Pyrexer__133
      POSTGRES_DB: fuel-app
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  reverse-proxy:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ~/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ~/certs:/etc/nginx/certs:ro
    depends_on:
      - db

volumes:
  postgres_data:
EOF

echo "Nginx configuration complete!"
