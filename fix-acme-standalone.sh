#!/bin/bash

echo "🔧 Fixing ACME Challenge with Standalone Mode"
echo "============================================="

# Stop Docker containers and nginx to free up port 80
echo "Stopping all services to free up port 80..."
docker-compose down
sudo systemctl stop nginx

# Wait a moment to ensure ports are free
sleep 2

# Check if port 80 is free
if sudo ss -tulpn | grep -q ":80 "; then
    echo "❌ Port 80 is still in use. Please stop any services using port 80."
    sudo ss -tulpn | grep ":80 "
    exit 1
else
    echo "✅ Port 80 is free"
fi

# Create ACME challenge directory (for future renewals)
echo "Setting up ACME challenge directory for renewals..."
sudo mkdir -p /var/www/yardeespaces/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/yardeespaces
sudo chmod -R 755 /var/www/yardeespaces

# Test external connectivity
echo "Testing external connectivity..."
if curl -s --connect-timeout 10 http://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ Domain is accessible externally"
else
    echo "⚠️  Domain may not be accessible externally"
    echo "This might be normal if nginx is stopped"
fi

echo ""
echo "🎯 Running certbot in standalone mode..."
echo "This will temporarily use port 80 for certificate verification"
echo ""

# Run certbot in standalone mode
sudo certbot certonly --standalone \
    -d yardeespaces.com \
    -d www.yardeespaces.com \
    --agree-tos \
    --email admin@yardeespaces.com \
    --non-interactive

# Check if certificate was obtained
if [ -f "/etc/letsencrypt/live/yardeespaces.com/fullchain.pem" ]; then
    echo ""
    echo "🎉 SSL certificate obtained successfully!"
    echo ""
    echo "Certificate details:"
    echo "Certificate: /etc/letsencrypt/live/yardeespaces.com/fullchain.pem"
    echo "Private key: /etc/letsencrypt/live/yardeespaces.com/privkey.pem"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./restore-site.sh"
    echo "2. Test your site at: https://yardeespaces.com"
    echo ""
    echo "Certificate will auto-renew every 60 days"
    
else
    echo ""
    echo "❌ Certificate issuance failed"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check DNS settings for yardeespaces.com"
    echo "2. Ensure port 80 is accessible from internet"
    echo "3. Check firewall settings"
    echo ""
    echo "Debug info:"
    echo "Recent certbot logs:"
    sudo tail -n 20 /var/log/letsencrypt/letsencrypt.log
    echo ""
    echo "Try manual verification:"
    echo "curl -I http://yardeespaces.com"
    exit 1
fi
