#!/bin/bash

echo "🔧 Fixing IPv6 ACME Challenge Issue"
echo "==================================="

# Stop Docker containers
echo "Stopping Docker containers..."
docker-compose down

# Create ACME challenge directory
echo "Setting up ACME challenge directory..."
sudo mkdir -p /var/www/yardeespaces/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/yardeespaces
sudo chmod -R 755 /var/www/yardeespaces

# Create test file
echo "Creating test file..."
sudo tee /var/www/yardeespaces/.well-known/acme-challenge/test > /dev/null << 'EOF'
test-acme-challenge-working
EOF

# Create nginx config with IPv6 support
echo "Creating nginx config with IPv6 support..."
sudo tee /etc/nginx/sites-available/yardeespaces-acme > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    root /var/www/yardeespaces;
    
    # ACME challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/yardeespaces;
        try_files $uri =404;
        allow all;
        access_log /var/log/nginx/acme.log;
    }
    
    # Everything else
    location / {
        return 200 "ACME Challenge Mode - Site temporarily unavailable";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable the config
echo "Enabling nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/yardeespaces
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/yardeespaces-acme /etc/nginx/sites-enabled/

# Test and start nginx
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl start nginx
    sudo systemctl reload nginx
else
    echo "❌ Nginx configuration has errors!"
    exit 1
fi

# Test access
echo "Testing ACME challenge access..."
sleep 2

# Test IPv4
if curl -s http://localhost/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ IPv4 ACME challenge works"
else
    echo "❌ IPv4 ACME challenge failed"
    exit 1
fi

# Test IPv6 locally
if curl -s -6 http://[::1]/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ IPv6 ACME challenge works locally"
else
    echo "⚠️  IPv6 ACME challenge doesn't work locally (this might be normal)"
fi

# Test external access
if curl -s http://yardeespaces.com/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ External ACME challenge works"
    
    # Clean up
    sudo rm -f /var/www/yardeespaces/.well-known/acme-challenge/test
    
    echo ""
    echo "🎉 Ready for SSL certificate!"
    echo "Run: sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com"
    echo ""
    echo "If you still get IPv6 errors, try:"
    echo "sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com --preferred-challenges http"
    
else
    echo "❌ External ACME challenge failed"
    echo "Checking if IPv6 is the issue..."
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me)
    echo "Server IP: $SERVER_IP"
    
    # Test with IP directly
    if curl -s http://$SERVER_IP/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
        echo "✅ ACME challenge works with IP address"
        echo "This suggests a DNS issue with IPv6"
        echo ""
        echo "Try using HTTP challenge instead:"
        echo "sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com --preferred-challenges http"
    else
        echo "❌ ACME challenge doesn't work with IP address"
        echo "This suggests a firewall or nginx issue"
    fi
fi
