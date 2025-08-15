#!/bin/bash

echo "🔒 Configuring Existing SSL Certificate"
echo "======================================="

# Check if certificate exists
echo "1. Checking existing SSL certificate..."
if [ -f "/etc/letsencrypt/live/yardeespaces.com/fullchain.pem" ]; then
    echo "✅ SSL certificate found!"
    echo ""
    echo "Certificate details:"
    echo "Certificate: /etc/letsencrypt/live/yardeespaces.com/fullchain.pem"
    echo "Private key: /etc/letsencrypt/live/yardeespaces.com/privkey.pem"
    echo "Expires: $(openssl x509 -in /etc/letsencrypt/live/yardeespaces.com/fullchain.pem -noout -dates | grep notAfter | cut -d= -f2)"
    echo ""
else
    echo "❌ SSL certificate not found"
    echo "Please run: ./get-ssl-with-docker.sh"
    exit 1
fi

# Check if Docker containers are running
echo "2. Checking Docker containers..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker containers are running"
    DOCKER_RUNNING=true
else
    echo "⚠️  Docker containers are not running"
    DOCKER_RUNNING=false
fi

# Stop Docker containers to free up ports
echo ""
echo "3. Stopping Docker containers temporarily..."
docker-compose down

# Wait for ports to be free
sleep 3

# Configure nginx with SSL
echo ""
echo "4. Configuring nginx with SSL..."

# Copy SSL configuration
sudo cp nginx-yardeespaces-ssl.conf /etc/nginx/sites-available/yardeespaces

# Remove old symlink if exists
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/yardeespaces

# Create new symlink
sudo ln -sf /etc/nginx/sites-available/yardeespaces /etc/nginx/sites-enabled/

# Test nginx configuration
echo "Testing nginx SSL configuration..."
if sudo nginx -t; then
    echo "✅ Nginx SSL configuration is valid"
else
    echo "❌ Nginx SSL configuration has errors"
    exit 1
fi

# Start nginx with SSL
echo "Starting nginx with SSL..."
sudo systemctl start nginx

# Check if nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running with SSL"
else
    echo "❌ Failed to start nginx"
    sudo systemctl status nginx --no-pager -l
    exit 1
fi

# Test HTTPS access
echo ""
echo "5. Testing HTTPS access..."
sleep 3

if curl -s -k --connect-timeout 10 https://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ HTTPS is working"
    
    # Test without -k flag to check real certificate
    if curl -s --connect-timeout 10 https://yardeespaces.com > /dev/null 2>&1; then
        echo "✅ SSL certificate is valid"
    else
        echo "⚠️  SSL certificate may have issues"
    fi
    
    echo ""
    echo "🎉 HTTPS is now enabled!"
    echo ""
    echo "Your site is accessible at:"
    echo "✅ HTTP:  http://yardeespaces.com"
    echo "✅ HTTPS: https://yardeespaces.com"
    echo ""
    
    # Restart Docker if it was running before
    if [ "$DOCKER_RUNNING" = true ]; then
        echo "6. Restarting Docker containers..."
        docker-compose up -d
        
        echo ""
        echo "✅ Docker containers restarted"
        echo ""
        echo "Your full application is now running with SSL!"
        echo "✅ Frontend: https://yardeespaces.com"
        echo "✅ API: https://yardeespaces.com/api/health/"
        echo ""
        echo "Certificate will auto-renew every 60 days"
        
    else
        echo ""
        echo "To start your full application:"
        echo "docker-compose up -d"
        echo ""
        echo "Certificate will auto-renew every 60 days"
    fi
    
else
    echo "❌ HTTPS is not working"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check nginx status: sudo systemctl status nginx"
    echo "2. Check nginx logs: sudo tail -f /var/log/nginx/error.log"
    echo "3. Check if port 443 is open: sudo ufw status"
    echo "4. Test with: curl -k https://yardeespaces.com"
    
    exit 1
fi
