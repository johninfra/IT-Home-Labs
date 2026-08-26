#!/bin/bash
set -e

# Update and install Nginx
sudo apt update && sudo apt install nginx -y

# Customize page text
echo "<h1>Hello World! Welcome to my custom server</h1>" | sudo tee /var/www/html/index.nginx-debian.html > /dev/null

# Generate certificate silently
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=localhost"

# Set up configuration blocks
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

# Restart server
sudo nginx -t
sudo systemctl restart nginx
