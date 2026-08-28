#!/bin/bash

set -e

# Update package repository
sudo apt update

# Install Nginx
sudo apt install nginx -y

# Create customized web page
echo "<h1>Hello World! Welcome to John's Server</h1>" | \
sudo tee /var/www/html/index.nginx-debian.html > /dev/null

# Generate self-signed SSL/TLS certificate
sudo openssl req \
  -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=localhost"

# Configure Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    server_name _;
}
EOF

# Validate Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Display service status
sudo systemctl status nginx --no-pager
