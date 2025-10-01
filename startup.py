#!/usr/bin/env python3
"""
Startup script for Azure Web App deployment
This file tells Azure how to start your Django application
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_dir))

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

# Import Django
import django
django.setup()

# Import Gunicorn
from gunicorn.app.wsgiapp import WSGIApplication

if __name__ == "__main__":
    # Configure Gunicorn for Azure Web App
    sys.argv = [
        'gunicorn',
        '--bind', '0.0.0.0:8000',
        '--workers', '2',
        '--threads', '4',
        '--worker-class', 'gthread',
        '--timeout', '120',
        '--keep-alive', '2',
        '--max-requests', '1000',
        '--max-requests-jitter', '100',
        '--log-level', 'info',
        'backend.wsgi:application'
    ]
    
    WSGIApplication().run()
