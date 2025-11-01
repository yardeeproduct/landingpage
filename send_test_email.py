#!/usr/bin/env python
"""
Simple script to send a test email via the API endpoint
Requires the backend to be running

Usage:
    python send_test_email.py
"""
import requests
import json

def send_test_email(email="jronith39@gmail.com"):
    """Send test email via API endpoint"""
    url = "http://localhost:8000/api/test-email/"
    
    print(f"Sending test email to {email}...")
    print(f"Using endpoint: {url}")
    print()
    
    try:
        response = requests.post(
            url,
            json={"email": email},
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Success: {data.get('message', 'Email sent')}")
            print()
            print(f"Test email sent to {email}")
            print("Please check the inbox (and spam folder) for the test email.")
            return True
        else:
            print(f"✗ Error: {response.status_code}")
            try:
                error_data = response.json()
                print(f"Message: {error_data.get('error', error_data.get('message', 'Unknown error'))}")
            except:
                print(f"Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("✗ Connection Error: Could not connect to backend")
        print("Make sure the backend is running:")
        print("  docker-compose up backend")
        print("  OR")
        print("  python manage.py runserver")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

if __name__ == '__main__':
    import sys
    email = sys.argv[1] if len(sys.argv) > 1 else "jronith39@gmail.com"
    send_test_email(email)
