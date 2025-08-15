#!/bin/bash

echo "🔄 Restoring Full Site Configuration"
echo "===================================="

# Check if SSL certificate exists
if [ ! -f "/etc/letsencrypt/live/yardeespaces.com/fullchain.pem" ]; then
    echo "❌ SSL certificate not found!"
    echo "Please run the SSL certificate setup first:"
    echo "Option 1: ./fix-acme-standalone.sh (recommended)"
    echo "Option 2: sudo certbot --nginx -d yardeespaces.com -d www.yardeespaces.com"
    exit 1
fi

echo "✅ SSL certificate found"

# Restore the full nginx configuration with SSL
echo "Restoring full nginx configuration with SSL..."
sudo cp nginx-yardeespaces-ssl.conf /etc/nginx/sites-available/yardeespaces

# Enable the full site configuration
sudo rm -f /etc/nginx/sites-enabled/yardeespaces-acme
sudo ln -sf /etc/nginx/sites-available/yardeespaces /etc/nginx/sites-enabled/

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl reload nginx
else
    echo "❌ Nginx configuration has errors!"
    exit 1
fi

# Start Docker containers
echo "Starting Docker containers..."
docker-compose up -d

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 10

# Test the full site
echo "Testing full site functionality..."
if curl -s -f https://yardeespaces.com > /dev/null; then
    echo "✅ HTTPS site is accessible"
else
    echo "⚠️  HTTPS site not accessible yet, checking HTTP redirect..."
    if curl -s -I http://yardeespaces.com | grep -q "301"; then
        echo "✅ HTTP to HTTPS redirect is working"
    else
        echo "❌ Site not accessible"
        exit 1
    fi
fi

# Test API endpoint
echo "Testing API endpoint..."
if curl -s -f https://yardeespaces.com/api/health/ > /dev/null; then
    echo "✅ API endpoint is accessible"
else
    echo "⚠️  API endpoint not accessible yet (containers may still be starting)"
fi

echo ""
echo "🎉 Site restoration completed!"
echo "Your site should now be accessible at: https://yardeespaces.com"
echo ""
echo "To check container status: docker-compose ps"
echo "To view logs: docker-compose logs -f"
