#!/bin/bash
echo "Starting Django backend..."
echo "Running database warmup..."
python manage.py warmup_db || echo "Warmup failed, continuing..."
echo "Starting Django server with gunicorn..."
exec gunicorn --bind 0.0.0.0:8000 --workers 2 --threads 4 --worker-class gthread --worker-tmp-dir /dev/shm --log-level info --access-logfile - --error-logfile - backend.wsgi:application
