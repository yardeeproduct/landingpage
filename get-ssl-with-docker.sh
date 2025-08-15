#!/bin/bash

echo "🔒 Getting SSL Certificate with Docker Setup"
echo "============================================"

# Check if Docker containers are running
echo "1. Checking Docker containers..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker containers are running"
    DOCKER_RUNNING=true
else
    echo "⚠️  Docker containers are not running"
    DOCKER_RUNNING=false
fi

# Stop Docker containers to free up ports
echo ""
echo "2. Stopping Docker containers temporarily..."
docker-compose down

# Wait for ports to be free
sleep 3

# Check if port 80 is free
if sudo ss -tulpn | grep -q ":80 "; then
    echo "❌ Port 80 is still in use. Please stop any services using port 80."
    sudo ss -tulpn | grep ":80 "
    exit 1
else
    echo "✅ Port 80 is free"
fi

# Check if port 3000 is free
if sudo ss -tulpn | grep -q ":3000 "; then
    echo "❌ Port 3000 is still in use. Please stop any services using port 3000."
    sudo ss -tulpn | grep ":3000 "
    exit 1
else
    echo "✅ Port 3000 is free"
fi

# Start nginx for domain serving
echo ""
echo "3. Starting nginx for domain serving..."
sudo systemctl start nginx

# Check if nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Failed to start nginx"
    sudo systemctl status nginx --no-pager -l
    exit 1
fi

# Test domain accessibility
echo ""
echo "4. Testing domain accessibility..."
sleep 2

if curl -s --connect-timeout 10 http://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ Domain is accessible via HTTP"
else
    echo "❌ Domain is not accessible"
    echo "Please check nginx configuration"
    exit 1
fi

# Stop nginx for certificate issuance
echo ""
echo "5. Stopping nginx for certificate issuance..."
sudo systemctl stop nginx

# Wait for port 80 to be free
sleep 3

# Get SSL certificate using standalone mode
echo ""
echo "6. Obtaining SSL certificate..."
echo "This may take a few minutes..."

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
    echo "Expires: $(openssl x509 -in /etc/letsencrypt/live/yardeespaces.com/fullchain.pem -noout -dates | grep notAfter | cut -d= -f2)"
    
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
    exit 1
fi

# Configure nginx with SSL
echo ""
echo "7. Configuring nginx with SSL..."

# Copy SSL configuration
sudo cp nginx-yardeespaces-ssl.conf /etc/nginx/sites-available/yardeespaces

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
echo "8. Testing HTTPS access..."
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
        echo "9. Restarting Docker containers..."
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
