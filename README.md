# Yardee Spaces Landing Page

Modern landing page for Yardee Spaces with newsletter subscription functionality.

## Tech Stack

- **Frontend**: Vite + Vanilla JavaScript + Tailwind CSS
- **Backend**: Django 5.2 + Python 3.12
- **Database**: Azure SQL Database
- **Email**: Outlook 365 Business (SMTP)
- **Deployment**: Docker + Docker Compose + Nginx

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Azure SQL Database credentials
- Email credentials (Outlook 365 Business)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd landingpage
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start services**
   ```bash
   docker-compose up -d
   ```

4. **Access the application**
   - Frontend: http://localhost
   - Backend API: http://localhost:8000/api/
   - Health Check: http://localhost:8000/api/health/

### Production Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed production deployment instructions.

Quick deployment:
```bash
./deploy.sh
```

## Project Structure

```
landingpage/
├── backend/                 # Django backend
│   ├── backend/            # Django project settings
│   ├── newsletter/         # Newsletter app
│   ├── manage.py
│   └── requirements.txt
├── frontend/               # Vite frontend
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── nginx.conf          # Nginx config for container
├── docker-compose.yml      # Docker Compose configuration
├── Dockerfile.backend      # Backend Docker image
├── Dockerfile.frontend     # Frontend Docker image
├── deploy.sh              # Deployment script
└── DEPLOYMENT.md          # Production deployment guide
```

## Environment Variables

Required environment variables (see `.env.production.example`):

- `SECRET_KEY` - Django secret key
- `DB_HOST` - Azure SQL server hostname
- `DB_NAME` - Database name
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password
- `EMAIL_HOST_USER` - Email username
- `EMAIL_HOST_PASSWORD` - Email password

## API Endpoints

- `GET /api/health/` - Health check endpoint
- `POST /api/subscribe/` - Subscribe to newsletter
- `POST /api/test-email/` - Test email configuration (development only)

## Development

### Backend Development

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py runserver
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

## Testing

### Test Email Configuration

```bash
docker-compose exec backend python manage.py shell
>>> from newsletter.emails import test_email_configuration
>>> test_email_configuration()
```

### Send Test Email

```bash
python send_test_email.py
```

## Troubleshooting

### Containers won't start

```bash
# Check logs
docker-compose logs

# Check environment variables
docker-compose config
```

### Database connection issues

- Verify Azure SQL firewall allows your IP
- Check database credentials in `.env`
- Ensure database exists in Azure SQL

### Email not sending

- Verify Outlook 365 app password is set correctly
- Check email credentials in `.env`
- Test email configuration using test endpoint

## Security

- Never commit `.env` file to version control
- Use strong `SECRET_KEY` in production
- Keep `DEBUG=false` in production
- Use SSL/TLS in production (see DEPLOYMENT.md)

## License

Copyright © 2025 Yardee Spaces. All rights reserved.

## Support

For issues or questions, contact the development team.

