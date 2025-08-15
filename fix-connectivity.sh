#!/bin/bash

echo "🔧 Fixing Domain Connectivity Issue"
echo "==================================="

# Get server's public IP
echo "Getting server's public IP..."
SERVER_IP=$(curl -s ifconfig.me)
echo "Server IP: $SERVER_IP"

echo ""
echo "🔍 Checking current status..."

# Check if nginx is running
echo "1. Checking nginx service..."
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
    echo "Starting nginx..."
    sudo systemctl start nginx
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx started successfully"
    else
        echo "❌ Failed to start nginx"
        sudo systemctl status nginx --no-pager -l
        exit 1
    fi
fi

# Check if port 80 is listening
echo ""
echo "2. Checking port 80..."
if sudo ss -tulpn | grep -q ":80 "; then
    echo "✅ Port 80 is listening"
    sudo ss -tulpn | grep ":80 "
else
    echo "❌ Port 80 is not listening"
    echo "This means nginx is not properly configured"
fi

# Check nginx configuration
echo ""
echo "3. Checking nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Check if nginx site is enabled
echo ""
echo "4. Checking nginx sites..."
if [ -L "/etc/nginx/sites-enabled/yardeespaces" ]; then
    echo "✅ Yardee Spaces site is enabled"
else
    echo "❌ Yardee Spaces site is not enabled"
    echo "Setting up basic nginx configuration..."
    
    # Create basic nginx config
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
    }
    
    # Everything else
    location / {
        return 200 "Yardee Spaces - Site is working!";
        add_header Content-Type text/plain;
    }
}
EOF
    
    # Enable the site
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -sf /etc/nginx/sites-available/yardeespaces /etc/nginx/sites-enabled/
    
    # Test and reload
    if sudo nginx -t; then
        echo "✅ Basic nginx configuration created"
        sudo systemctl reload nginx
    else
        echo "❌ Failed to create nginx configuration"
        exit 1
    fi
fi

# Create web root directory if it doesn't exist
echo ""
echo "5. Setting up web root directory..."
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

# Test local access
echo ""
echo "6. Testing local access..."
if curl -s http://localhost/ | grep -q "Yardee Spaces"; then
    echo "✅ Local access works"
else
    echo "❌ Local access failed"
    echo "Nginx error log:"
    sudo tail -n 5 /var/log/nginx/error.log
    exit 1
fi

# Test external access
echo ""
echo "7. Testing external access..."
sleep 2  # Give nginx time to reload

if curl -s --connect-timeout 10 http://yardeespaces.com/ | grep -q "Yardee Spaces"; then
    echo "✅ External access works"
    
    # Clean up test file
    sudo rm -f /var/www/yardeespaces/index.html
    
    echo ""
    echo "🎉 Domain connectivity is working!"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./fix-acme-standalone.sh"
    echo "2. After SSL certificate, run: ./restore-site.sh"
    
else
    echo "❌ External access failed"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo ""
    echo "1. Check firewall:"
    echo "   sudo ufw status"
    echo "   sudo ufw allow 80"
    echo ""
    echo "2. Check if port 80 is accessible from internet:"
    echo "   curl -I http://$SERVER_IP"
    echo ""
    echo "3. Check nginx logs:"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo ""
    echo "4. Test with different DNS:"
    echo "   curl -I http://yardeespaces.com --resolve yardeespaces.com:80:$SERVER_IP"
    
    exit 1
fi
