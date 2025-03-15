#!/bin/bash

# Enhanced Postgres Deployment Automation Script
# Usage: ./deploy_postgres.sh <db_name> [username] [password]

# Check if database name was provided
if [ -z "$1" ]; then
  echo "Error: Database name required"
  echo "Usage: ./deploy_postgres.sh <db_name> [username] [password]"
  exit 1
fi

DB_NAME=$1
DEFAULT_USER="uncledev"
DEFAULT_PASSWORD="Pyrexer__133"
BASE_PORT=5432
SECURITY_GROUP_ID="sg-0add8bb36a26d78c3" # Your security group ID

# Prompt for username if not provided as second argument
if [ -z "$2" ]; then
  read -p "Enter username (default: $DEFAULT_USER): " DB_USER
  DB_USER=${DB_USER:-$DEFAULT_USER}
else
  DB_USER=$2
fi

# Prompt for password if not provided as third argument
if [ -z "$3" ]; then
  read -s -p "Enter password (default: $DEFAULT_PASSWORD): " DB_PASSWORD
  echo ""
  DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_PASSWORD}
else
  DB_PASSWORD=$3
fi

# Function to check if a port is in use
port_in_use() {
  docker ps --format "{{.Ports}}" | grep -q ":$1->"
  return $?
}

# Find an available port
find_available_port() {
  local port=$BASE_PORT
  
  while port_in_use $port; do
    port=$((port + 1))
  done
  
  echo $port
}

# Create directory for the new database using the database name
DB_DIR="/home/ubuntu/$DB_NAME"
mkdir -p $DB_DIR

# Find available port
AVAILABLE_PORT=$(find_available_port)
HOST_PORT=$AVAILABLE_PORT

echo "Creating Postgres instance:"
echo "  - Database Name: $DB_NAME"
echo "  - Username: $DB_USER"
echo "  - Port: $HOST_PORT"

# Create docker-compose.yml file
cat > $DB_DIR/docker-compose.yml << EOF
services:
  db:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: $DB_USER
      POSTGRES_PASSWORD: $DB_PASSWORD
      POSTGRES_DB: $DB_NAME
    ports:
      - "${HOST_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $DB_USER"]
      interval: 10s
      timeout: 5s
volumes:
  postgres_data:
EOF

# Update AWS security group to allow inbound traffic on the new port
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port $HOST_PORT \
  --cidr 0.0.0.0/0

# Start the container
cd $DB_DIR
docker-compose up -d

echo "Postgres database '$DB_NAME' successfully deployed on port $HOST_PORT"
echo "Connection string: postgresql://$DB_USER:$DB_PASSWORD@13.246.16.165:$HOST_PORT/$DB_NAME"
echo "Container directory: $DB_DIR"
