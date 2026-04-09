#!/bin/bash
# Install NGINX and start service
yum update -y
yum install -y nginx
systemctl enable nginx
systemctl start nginx
echo '<h1>Welcome to the Auto-Healing Web Tier (NGINX)</h1>' > /usr/share/nginx/html/index.html
