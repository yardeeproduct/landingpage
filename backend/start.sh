#!/bin/bash
set -e

echo "Starting Django backend..."

# Wait for database to be ready
echo "Waiting for database..."
until python -c "
import os
import pyodbc
import time
max_attempts = 30
for attempt in range(max_attempts):
    try:
        conn_str = f\"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={os.environ['DB_HOST']},{os.environ['DB_PORT']};DATABASE=master;UID={os.environ['DB_USER']};PWD={os.environ['DB_PASSWORD']};TrustServerCertificate=yes\"
        conn = pyodbc.connect(conn_str, timeout=5)
        conn.close()
        print('Database is ready!')
        exit(0)
    except Exception as e:
        if attempt < max_attempts - 1:
            print(f'Database is unavailable (attempt {attempt + 1}/{max_attempts}) - {str(e)[:50]}... sleeping')
            time.sleep(2)
        else:
            print(f'Failed to connect after {max_attempts} attempts')
            exit(1)
"; do
  sleep 1
done

# Run migrations
echo "Running database migrations..."
python manage.py migrate --noinput

# Run database warmup
echo "Running database warmup..."
python manage.py warmup_db || echo "Warmup failed, continuing..."

# Start the server
echo "Starting Django server with gunicorn..."
exec gunicorn --bind 0.0.0.0:8000 --workers 2 --threads 4 --worker-class gthread --worker-tmp-dir /dev/shm --log-level info --access-logfile - --error-logfile - backend.wsgi:application
