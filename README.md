# Setup Guide

This guide will help you set up and configure Oh My Zsh, Docker, Docker Compose, Nginx, and SSL certificates on your EC2 instance.

## Prerequisites

- Ensure you have an EC2 instance running with appropriate security groups allowing traffic on ports 80, 443, and 22.
- Ensure your domain (e.g., `easefuel.onlinedb.site`) points to your EC2 instance's public IP address via DNS settings.

## Scripts Overview

1. [install-ohmyzsh.sh](#1-install-oh-my-zsh)
2. [install-docker.sh](#2-install-docker-and-docker-compose)
3. [configure-nginx.sh](#3-configure-nginx)
4. [obtain-ssl.sh](#4-obtain-ssl-certificates)

### 1. Install Oh My Zsh

This script installs Zsh, Oh My Zsh, and the plugins for autosuggestions and syntax highlighting.

**Usage:**

```bash
chmod +x install-ohmyzsh.sh
./install-ohmyzsh.sh
```
