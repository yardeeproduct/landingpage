#!/bin/bash

echo "🔍 DNS Configuration Check"
echo "=========================="

# Get server's public IP
echo "Getting server's public IP..."
SERVER_IP=$(curl -s ifconfig.me)
echo "Server IP: $SERVER_IP"

echo ""
echo "Checking DNS records..."

# Check A record
echo "A record (IPv4):"
A_RECORD=$(nslookup yardeespaces.com 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
if [ -n "$A_RECORD" ]; then
    echo "✅ A record found: $A_RECORD"
    if [ "$A_RECORD" = "$SERVER_IP" ]; then
        echo "✅ A record matches server IP"
    else
        echo "❌ A record ($A_RECORD) does not match server IP ($SERVER_IP)"
    fi
else
    echo "❌ No A record found"
fi

# Check AAAA record
echo ""
echo "AAAA record (IPv6):"
AAAA_RECORD=$(nslookup -type=AAAA yardeespaces.com 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
if [ -n "$AAAA_RECORD" ]; then
    echo "⚠️  AAAA record still exists: $AAAA_RECORD"
else
    echo "✅ No AAAA record found (good)"
fi

# Check www subdomain
echo ""
echo "www.yardeespaces.com A record:"
WWW_RECORD=$(nslookup www.yardeespaces.com 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
if [ -n "$WWW_RECORD" ]; then
    echo "✅ www A record found: $WWW_RECORD"
    if [ "$WWW_RECORD" = "$SERVER_IP" ]; then
        echo "✅ www A record matches server IP"
    else
        echo "❌ www A record ($WWW_RECORD) does not match server IP ($SERVER_IP)"
    fi
else
    echo "❌ No www A record found"
fi

# Test connectivity
echo ""
echo "Testing connectivity..."

# Test server IP directly
echo "Testing server IP directly:"
if curl -s --connect-timeout 5 http://$SERVER_IP > /dev/null 2>&1; then
    echo "✅ Server IP is accessible"
else
    echo "❌ Server IP is not accessible"
fi

# Test domain
echo ""
echo "Testing domain:"
if curl -s --connect-timeout 5 http://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ Domain is accessible"
else
    echo "❌ Domain is not accessible"
fi

# Test www subdomain
echo ""
echo "Testing www subdomain:"
if curl -s --connect-timeout 5 http://www.yardeespaces.com > /dev/null 2>&1; then
    echo "✅ www subdomain is accessible"
else
    echo "❌ www subdomain is not accessible"
fi

echo ""
echo "🔧 DNS Configuration Issues Found:"
echo ""

if [ -z "$A_RECORD" ]; then
    echo "❌ PROBLEM: No A record for yardeespaces.com"
    echo "   SOLUTION: Add A record pointing to $SERVER_IP"
fi

if [ -n "$AAAA_RECORD" ]; then
    echo "❌ PROBLEM: AAAA record still exists"
    echo "   SOLUTION: Remove AAAA record completely"
fi

if [ "$A_RECORD" != "$SERVER_IP" ] && [ -n "$A_RECORD" ]; then
    echo "❌ PROBLEM: A record points to wrong IP"
    echo "   SOLUTION: Update A record to point to $SERVER_IP"
fi

if [ -z "$WWW_RECORD" ]; then
    echo "❌ PROBLEM: No A record for www.yardeespaces.com"
    echo "   SOLUTION: Add A record for www pointing to $SERVER_IP"
fi

if [ "$WWW_RECORD" != "$SERVER_IP" ] && [ -n "$WWW_RECORD" ]; then
    echo "❌ PROBLEM: www A record points to wrong IP"
    echo "   SOLUTION: Update www A record to point to $SERVER_IP"
fi

echo ""
echo "📋 Required DNS Configuration:"
echo "Type  | Name                    | Value"
echo "------|-------------------------|----------------"
echo "A     | yardeespaces.com        | $SERVER_IP"
echo "A     | www.yardeespaces.com    | $SERVER_IP"
echo ""
echo "❌ Remove these if they exist:"
echo "AAAA | yardeespaces.com        | (any IPv6 address)"
echo "AAAA | www.yardeespaces.com    | (any IPv6 address)"
echo ""
echo "⏰ After updating DNS, wait 5-10 minutes for propagation"
echo "Then run: ./fix-acme-standalone.sh"
