#!/bin/bash

echo "🔧 Fixing ACME Challenge for SSL Certificate"
echo "============================================="

# Stop Docker containers to free up port 80
echo "Stopping Docker containers temporarily..."
docker-compose down

# Create ACME challenge directory with proper permissions
echo "Setting up ACME challenge directory..."
sudo mkdir -p /var/www/yardeespaces/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/yardeespaces
sudo chmod -R 755 /var/www/yardeespaces

# Create a test file to verify ACME challenge works
echo "Creating test file for ACME challenge verification..."
sudo tee /var/www/yardeespaces/.well-known/acme-challenge/test > /dev/null << 'EOF'
test-acme-challenge-working
EOF

# Create a minimal nginx config that ONLY serves ACME challenges
echo "Creating minimal nginx config for ACME challenges..."
sudo tee /etc/nginx/sites-available/yardeespaces-acme > /dev/null << 'EOF'
server {
    listen 80;
    server_name yardeespaces.com www.yardeespaces.com;
    
    # Root directory for ACME challenges
    root /var/www/yardeespaces;
    
    # ACME challenge location - HIGHEST PRIORITY
    location /.well-known/acme-challenge/ {
        root /var/www/yardeespaces;
        try_files $uri =404;
        allow all;
        access_log /var/log/nginx/acme.log;
    }
    
    # Everything else gets a simple response
    location / {
        return 200 "ACME Challenge Mode - Site temporarily unavailable";
        add_header Content-Type text/plain;
    }
}
EOF

# Remove any existing site and enable the ACME-only config
echo "Enabling ACME-only nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/yardeespaces
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/yardeespaces-acme /etc/nginx/sites-enabled/

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    
    # Start nginx service if not running
    echo "Starting nginx service..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Check nginx status
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx service is running"
        sudo systemctl reload nginx
    else
        echo "❌ Failed to start nginx service"
        sudo systemctl status nginx
        exit 1
    fi
else
    echo "❌ Nginx configuration has errors!"
    exit 1
fi

# Test ACME challenge directory access
echo "Testing ACME challenge access..."
sleep 3  # Give nginx time to start and reload

# Test locally first
echo "Testing local access..."
if curl -s http://localhost/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ Local ACME challenge access works"
else
    echo "❌ Local ACME challenge access failed"
    echo "Nginx may not be listening on port 80"
    sudo ss -tulpn | grep :80
    exit 1
fi

# Test external access
echo "Testing external access..."
if curl -s http://yardeespaces.com/.well-known/acme-challenge/test | grep -q "test-acme-challenge-working"; then
    echo "✅ ACME challenge directory is accessible"
    
    # Clean up test file
    sudo rm -f /var/www/yardeespaces/.well-known/acme-challenge/test
    
    echo ""
    echo "🎉 Ready for SSL certificate setup!"
    echo "Run: sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com"
    echo ""
    echo "After SSL setup completes, run: ./restore-site.sh"
    
else
    echo "❌ ACME challenge directory is not accessible externally"
    echo "Please check:"
    echo "1. DNS settings for yardeespaces.com"
    echo "2. Firewall settings (port 80 should be open)"
    echo "3. Nginx is running: sudo systemctl status nginx"
    echo ""
    echo "Debugging info:"
    echo "Nginx status:"
    sudo systemctl status nginx --no-pager -l
    echo ""
    echo "Port 80 listening:"
    sudo ss -tulpn | grep :80
    echo ""
    echo "Nginx error log:"
    sudo tail -n 10 /var/log/nginx/error.log
    exit 1
fi
