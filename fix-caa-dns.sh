#!/bin/bash

echo "🔧 Fixing CAA Records for Let's Encrypt"
echo "======================================="

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

# Check CAA records
echo ""
echo "CAA records:"
CAA_RECORDS=$(dig +short CAA yardeespaces.com 2>/dev/null)
if [ -n "$CAA_RECORDS" ]; then
    echo "Found CAA records:"
    echo "$CAA_RECORDS"
    echo ""
    echo "🔍 Analyzing CAA records..."
    
    # Check if Let's Encrypt is allowed
    if echo "$CAA_RECORDS" | grep -q "letsencrypt.org"; then
        echo "✅ Let's Encrypt is allowed in CAA records"
    else
        echo "❌ Let's Encrypt is NOT allowed in CAA records"
        echo "   This is likely blocking certificate issuance"
    fi
    
    # Check for conflicting CAA records
    if echo "$CAA_RECORDS" | grep -q "issue"; then
        echo "✅ Issue CAA records found"
    fi
    
    if echo "$CAA_RECORDS" | grep -q "issuewild"; then
        echo "✅ Issuewild CAA records found"
    fi
    
else
    echo "✅ No CAA records found (good for Let's Encrypt)"
fi

# Test connectivity
echo ""
echo "Testing connectivity..."
if curl -s --connect-timeout 5 http://yardeespaces.com > /dev/null 2>&1; then
    echo "✅ Domain is accessible"
else
    echo "❌ Domain is not accessible"
fi

echo ""
echo "🔧 CAA Record Issues and Solutions:"
echo ""

# Check if Let's Encrypt is blocked
if [ -n "$CAA_RECORDS" ] && ! echo "$CAA_RECORDS" | grep -q "letsencrypt.org"; then
    echo "❌ PROBLEM: CAA records exist but don't allow Let's Encrypt"
    echo ""
    echo "SOLUTION: Update your CAA records to include Let's Encrypt"
    echo ""
    echo "Required CAA records for Let's Encrypt:"
    echo "Type | Name | Value"
    echo "-----|------|------"
    echo "CAA  | @    | 0 issue \"letsencrypt.org\""
    echo ""
    echo "Optional (if you want to allow other CAs too):"
    echo "CAA  | @    | 0 issue \"digicert.com\""
    echo "CAA  | @    | 0 issue \"sectigo.com\""
    echo ""
    echo "⚠️  IMPORTANT: Remove or update conflicting CAA records"
    echo "   that don't include \"letsencrypt.org\""
    
elif [ -n "$CAA_RECORDS" ] && echo "$CAA_RECORDS" | grep -q "letsencrypt.org"; then
    echo "✅ CAA records allow Let's Encrypt"
    echo ""
    echo "The issue might be elsewhere. Let's try the certificate again:"
    echo ""
    echo "1. Run: ./fix-acme-standalone.sh"
    echo "2. If it fails, check the detailed logs"
    
else
    echo "✅ No CAA records found - Let's Encrypt should work"
    echo ""
    echo "Let's try the certificate again:"
    echo ""
    echo "1. Run: ./fix-acme-standalone.sh"
fi

echo ""
echo "📋 Quick CAA Check Commands:"
echo "dig CAA yardeespaces.com"
echo "nslookup -type=CAA yardeespaces.com"
echo ""
echo "🔧 If you need to update CAA records:"
echo "1. Go to your DNS provider"
echo "2. Find CAA records for @ (root domain)"
echo "3. Ensure one record allows Let's Encrypt:"
echo "   CAA | @ | 0 issue \"letsencrypt.org\""
echo "4. Remove any CAA records that don't include Let's Encrypt"
echo "5. Wait 5-10 minutes for propagation"
echo "6. Run: ./fix-acme-standalone.sh"
