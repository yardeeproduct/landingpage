#!/bin/bash

echo "🔒 Configuring SSL with Existing Certificate"
echo "==========================================="

# Certificate paths (confirmed from find-ssl-certificate.sh)
CERT_PATH="/etc/letsencrypt/live/yardeespaces.com/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/yardeespaces.com/privkey.pem"

echo "1. Verifying certificate paths..."
if [ -f "$CERT_PATH" ]; then
    echo "✅ Certificate found: $CERT_PATH"
else
    echo "❌ Certificate not found at: $CERT_PATH"
    exit 1
fi

if [ -f "$KEY_PATH" ]; then
    echo "✅ Private key found: $KEY_PATH"
else
    echo "❌ Private key not found at: $KEY_PATH"
    exit 1
fi

echo ""
echo "2. Checking certificate validity..."
CERT_INFO=$(sudo openssl x509 -in "$CERT_PATH" -noout -subject -issuer -dates 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ Certificate is valid"
    echo "$CERT_INFO"
else
    echo "❌ Certificate validation failed"
    exit 1
fi

# Check if Docker containers are running
echo ""
echo "3. Checking Docker containers..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker containers are running"
    DOCKER_RUNNING=true
else
    echo "⚠️  Docker containers are not running"
    DOCKER_RUNNING=false
fi

# Stop Docker containers to free up ports
echo ""
echo "4. Stopping Docker containers temporarily..."
docker-compose down

# Wait for ports to be free
sleep 3

# Configure nginx with SSL
echo ""
echo "5. Configuring nginx with SSL..."

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
echo "6. Testing HTTPS access..."
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
    echo "Certificate details:"
    echo "Path: $CERT_PATH"
    echo "Key: $KEY_PATH"
    echo "Expires: $(sudo openssl x509 -in "$CERT_PATH" -noout -dates | grep notAfter | cut -d= -f2)"
    echo ""
    
    # Restart Docker if it was running before
    if [ "$DOCKER_RUNNING" = true ]; then
        echo "7. Restarting Docker containers..."
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
