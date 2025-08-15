# Azure Database Setup Guide

## 1. Environment Variables Configuration

Create a `.env` file in the `backend/` directory with your Azure SQL Server credentials:

```bash
# Azure SQL Server Database Configuration
DB_NAME=your_database_name
DB_USER=your_username
DB_PASSWORD=your_password
DB_HOST=your_server.database.windows.net
DB_PORT=1433

# Django Configuration
SECRET_KEY=your-secure-secret-key-here
DEBUG=False
CORS_ALLOW_ALL_ORIGINS=False
```

## 2. Azure SQL Server Setup

### Prerequisites:
- Azure SQL Server instance
- Database created
- User with appropriate permissions

### Steps:
1. **Get your connection details** from Azure Portal:
   - Server name: `your-server.database.windows.net`
   - Database name: `your-database-name`
   - Username: `your-username`
   - Password: `your-password`

2. **Configure firewall rules** in Azure:
   - Add your application's IP address to the firewall
   - Or use Azure App Service integration

3. **Enable Azure AD authentication** (optional but recommended)

## 3. Database Migration

Run these commands to set up your database:

```bash
cd backend
python manage.py makemigrations
python manage.py migrate
```

## 4. Test the Connection

Test your database connection:

```bash
python manage.py warmup_db
```

## 5. Production Deployment

### Environment Variables for Production:
```bash
# Set these in your production environment
DB_NAME=your_production_db_name
DB_USER=your_production_username
DB_PASSWORD=your_production_password
DB_HOST=your_production_server.database.windows.net
DB_PORT=1433
SECRET_KEY=your-production-secret-key
DEBUG=False
CORS_ALLOW_ALL_ORIGINS=False
```

### Security Best Practices:
1. Use strong, unique passwords
2. Enable Azure AD authentication
3. Use connection pooling
4. Enable SSL/TLS encryption
5. Set up proper firewall rules
6. Use managed identities when possible

## 6. Troubleshooting

### Common Issues:

1. **Connection Timeout**:
   - Check firewall rules
   - Verify server name and port
   - Ensure SSL is enabled

2. **Authentication Failed**:
   - Verify username/password
   - Check if user has database access
   - Ensure user has appropriate permissions

3. **SSL Certificate Issues**:
   - The configuration already includes SSL settings
   - Ensure your Azure SQL Server has SSL enabled

### Testing the API:

```bash
# Test the health endpoint
curl http://localhost:8000/api/health/

# Test the subscribe endpoint
curl -X POST http://localhost:8000/api/subscribe/ \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

## 7. Monitoring

Monitor your database connection in the Django logs:
- Check for connection errors
- Monitor query performance
- Watch for timeout issues

The application includes built-in logging and health checks to help with monitoring.
