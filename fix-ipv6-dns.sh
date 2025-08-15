#!/bin/bash

echo "🔧 Fixing IPv6 DNS Issue for SSL Certificate"
echo "============================================="

# Get server's public IP
echo "Getting server's public IP..."
SERVER_IP=$(curl -s ifconfig.me)
echo "Server IP: $SERVER_IP"

# Check DNS records
echo ""
echo "Checking DNS records..."
echo "A record (IPv4):"
nslookup yardeespaces.com 2>/dev/null | grep "Address:" | tail -1
echo ""
echo "AAAA record (IPv6):"
nslookup -type=AAAA yardeespaces.com 2>/dev/null | grep "Address:" | tail -1

echo ""
echo "🔍 The issue is that your domain has an AAAA (IPv6) record"
echo "that points to: 2a02:4780:2b:1816:0:33c0:5abd:2"
echo "But your server's IPv6 is not properly configured for ACME challenges."
echo ""

# Option 1: Try with HTTP challenge and force IPv4
echo "🎯 Option 1: Try HTTP challenge with IPv4 forcing..."
echo ""

# Stop all services
docker-compose down
sudo systemctl stop nginx

# Wait for port 80 to be free
sleep 3

# Try certbot with HTTP challenge and IPv4 preference
echo "Running certbot with HTTP challenge..."
sudo certbot certonly --standalone \
    -d yardeespaces.com \
    -d www.yardeespaces.com \
    --agree-tos \
    --email admin@yardeespaces.com \
    --preferred-challenges http \
    --non-interactive

# Check if it worked
if [ -f "/etc/letsencrypt/live/yardeespaces.com/fullchain.pem" ]; then
    echo ""
    echo "🎉 SSL certificate obtained successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./restore-site.sh"
    echo "2. Test your site at: https://yardeespaces.com"
    exit 0
fi

echo ""
echo "❌ HTTP challenge failed. Trying alternative approach..."
echo ""

# Option 2: Try with DNS challenge (if you have API access)
echo "🎯 Option 2: Manual DNS verification..."
echo ""
echo "Since automatic verification is failing due to IPv6,"
echo "you have these options:"
echo ""
echo "1. TEMPORARY FIX: Remove AAAA record from DNS"
echo "   - Go to your DNS provider (Cloudflare, etc.)"
echo "   - Remove the AAAA record for yardeespaces.com"
echo "   - Keep only the A record pointing to: $SERVER_IP"
echo "   - Wait 5-10 minutes for DNS propagation"
echo "   - Then run: ./fix-acme-standalone.sh"
echo ""
echo "2. ALTERNATIVE: Use a different domain or subdomain"
echo "   - Try with a subdomain that doesn't have IPv6 issues"
echo "   - Example: api.yardeespaces.com"
echo ""
echo "3. MANUAL: Create certificate manually"
echo "   - Use a different CA or manual verification"
echo ""
echo "4. CLOUDFLARE: If using Cloudflare, set DNS to 'DNS only'"
echo "   - Change from 'Proxied' (orange cloud) to 'DNS only' (grey cloud)"
echo "   - This bypasses Cloudflare's proxy for ACME challenges"
echo ""

# Test current connectivity
echo "Testing current connectivity..."
echo "IPv4 test:"
curl -s -I http://$SERVER_IP 2>/dev/null | head -1 || echo "IPv4 not accessible"

echo ""
echo "Domain test:"
curl -s -I http://yardeespaces.com 2>/dev/null | head -1 || echo "Domain not accessible"

echo ""
echo "🔧 Recommended immediate action:"
echo "1. Remove AAAA record from DNS"
echo "2. Wait 5-10 minutes"
echo "3. Run: ./fix-acme-standalone.sh"
