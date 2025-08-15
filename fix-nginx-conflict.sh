#!/bin/bash

echo "🔧 Fixing Nginx Configuration Conflicts"
echo "======================================="

# Stop nginx first
echo "Stopping nginx..."
sudo systemctl stop nginx

# Remove all existing site configurations
echo "Cleaning up existing nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/*
sudo rm -f /etc/nginx/sites-available/yardeespaces*
sudo rm -f /etc/nginx/sites-available/default

# Create a clean nginx configuration
echo "Creating clean nginx configuration..."
sudo tee /etc/nginx/sites-available/yardeespaces > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    root /var/www/yardeespaces;
    index index.html;
    
    # ACME challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/yardeespaces;
        try_files $uri =404;
        allow all;
        access_log /var/log/nginx/acme.log;
    }
    
    # Everything else
    location / {
        return 200 "Yardee Spaces - Site is working!";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable the site
echo "Enabling the site..."
sudo ln -sf /etc/nginx/sites-available/yardeespaces /etc/nginx/sites-enabled/

# Create web root directory
echo "Setting up web root directory..."
sudo mkdir -p /var/www/yardeespaces
sudo chown -R www-data:www-data /var/www/yardeespaces
sudo chmod -R 755 /var/www/yardeespaces

# Create a test file
echo "Creating test file..."
sudo tee /var/www/yardeespaces/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Yardee Spaces</title>
</head>
<body>
    <h1>Yardee Spaces - Site is working!</h1>
    <p>If you can see this, nginx is properly configured.</p>
</body>
</html>
EOF

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Start nginx
echo "Starting nginx..."
sudo systemctl start nginx

# Check if nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Failed to start nginx"
    sudo systemctl status nginx --no-pager -l
    exit 1
fi

# Wait a moment for nginx to fully start
sleep 2

# Test local access
echo "Testing local access..."
if curl -s http://localhost/ | grep -q "Yardee Spaces"; then
    echo "✅ Local access works"
else
    echo "❌ Local access failed"
    echo "Nginx error log:"
    sudo tail -n 10 /var/log/nginx/error.log
    exit 1
fi

# Test external access
echo "Testing external access..."
if curl -s --connect-timeout 10 http://yardeespaces.com/ | grep -q "Yardee Spaces"; then
    echo "✅ External access works"
    
    # Clean up test file
    sudo rm -f /var/www/yardeespaces/index.html
    
    echo ""
    echo "🎉 Nginx configuration conflicts resolved!"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./fix-acme-standalone.sh"
    echo "2. After SSL certificate, run: ./restore-site.sh"
    
else
    echo "❌ External access failed"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo ""
    echo "1. Check nginx status:"
    echo "   sudo systemctl status nginx"
    echo ""
    echo "2. Check nginx logs:"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo ""
    echo "3. Check if port 80 is accessible:"
    echo "   curl -I http://20.151.76.30"
    echo ""
    echo "4. Check firewall:"
    echo "   sudo ufw status"
    
    exit 1
fi
