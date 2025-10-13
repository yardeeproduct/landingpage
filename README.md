# Yardee Spaces Landing Page

A modern, responsive landing page built with Django REST API backend and Vite.js frontend, fully containerized with Docker.

## 🚀 Features

- **Responsive Design**: Mobile-first approach with Tailwind CSS
- **Email Subscription**: Newsletter signup with Django backend
- **Image Carousel**: Dynamic hero section with smooth transitions
- **Docker Support**: Fully containerized for easy deployment
- **Security**: Modern security headers and CORS configured
- **Monitoring**: Health checks and logging integrated
- **2025 Ready**: Latest Python 3.12, Node.js 22 LTS, Nginx 1.27

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Vite.js)     │◄──►│   (Django)      │◄──►│  (SQL Server)   │
│   + Nginx 1.27  │    │   + Gunicorn    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Tech Stack

### Frontend
- **Vite.js** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **Vanilla JavaScript** - No framework dependencies

### Backend
- **Python 3.12** - Latest stable Python
- **Django 5.0** - Python web framework
- **Django REST Framework** - API development
- **Gunicorn** - WSGI HTTP Server
- **SQL Server 2022** - Database with ODBC driver

### Infrastructure
- **Docker & Docker Compose** - Container orchestration
- **Nginx 1.27-alpine** - Web server and reverse proxy
- **Node.js 22 LTS** - Frontend build tooling

## 📦 Project Structure

```
landingpage/
├── backend/                 # Django backend
│   ├── backend/            # Django project settings
│   ├── newsletter/         # Newsletter app
│   ├── requirements.txt    # Python dependencies
│   └── start.sh           # Startup script
├── frontend/               # Vite.js frontend
│   ├── src/               # Source files
│   ├── public/            # Static assets
│   ├── dist/              # Built files
│   ├── package.json       # Node dependencies
│   └── nginx.conf         # Nginx configuration
├── docker-compose.yml     # Docker Compose config
├── Dockerfile.backend     # Backend container
└── Dockerfile.frontend    # Frontend container
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- No other services running on ports 80, 8000, or 1433

### Start Application

```bash
# Stop any existing containers
docker compose down

# Build and start all services
docker compose build
docker compose up -d

# Check status
docker compose ps
```

The application will:
- ✅ Start SQL Server database with health checks
- ✅ Build and start Django backend
- ✅ Build and start Vite.js frontend with Nginx
- ✅ Run database migrations automatically
- ✅ Wait for all services to be healthy

### Access the Application

- **Frontend**: http://localhost
- **Backend API**: http://localhost:8000
- **API Health**: http://localhost:8000/api/health/
- **Admin Panel**: http://localhost:8000/admin/

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db
```

### Stop Application

```bash
docker compose down

# Stop and remove volumes
docker compose down -v
```

### Manual Development (Without Docker)

#### Backend Setup
```bash
cd backend
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set up database connection
export DB_HOST=localhost
export DB_NAME=yardee_dev
export DB_USER=sa
export DB_PASSWORD=YourStrong@Passw0rd

# Run migrations and start server
python manage.py migrate
python manage.py runserver
```

#### Frontend Setup
```bash
cd frontend
npm install
npm run dev  # Runs on http://localhost:5173
```

## 🌐 API Endpoints

### Newsletter Subscription
- **POST** `/api/subscribe/`
  - Subscribe to newsletter
  - Body: `{"email": "user@example.com"}`
  - Response: `{"message": "Success", "created": true}`

### Health Check
- **GET** `/api/health/`
  - Application health status
  - Response: `{"status": "ok", "message": "API is working"}`

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=1433
DB_NAME=yardee_dev
DB_USER=sa
DB_PASSWORD=YourStrong@Passw0rd

# Django Settings
DEBUG=1
SECRET_KEY=your-secret-key

# CORS Settings
CORS_ALLOW_ALL_ORIGINS=True
```

#### Frontend (Build-time)
```bash
VITE_API_BASE_URL=http://localhost:8000
VITE_APP_ENV=development
```

## 🚀 Deployment

### Docker Production Deployment

The application is fully containerized and can be deployed to any Docker-compatible platform:

#### Build Production Images
```bash
# Build images
docker compose build

# Tag for your registry
docker tag landingpage-backend:latest your-registry/backend:latest
docker tag landingpage-frontend:latest your-registry/frontend:latest

# Push to registry
docker push your-registry/backend:latest
docker push your-registry/frontend:latest
```

#### Deploy to Production
```bash
# On production server
docker compose -f docker-compose.yml up -d

# Check status
docker compose ps
docker compose logs -f
```

### Supported Platforms
- **AWS ECS/Fargate** - Container orchestration
- **Azure Container Apps** - Serverless containers
- **Google Cloud Run** - Serverless deployment
- **DigitalOcean App Platform** - PaaS deployment
- **Any VPS** - With Docker installed

## 🔒 Security Features

- **Modern Security Headers (2025)**
  - X-Frame-Options, X-Content-Type-Options
  - Permissions-Policy for privacy controls
  - Content-Security-Policy with upgrade-insecure-requests
  - Strict referrer policy
- **CORS Configuration** - Proper cross-origin resource sharing
- **Input Validation** - Email format validation and sanitization
- **Database Security** - Encrypted connections and parameterized queries
- **Container Security** - Non-root users and minimal base images
- **HTTP/2 Support** - Modern protocol with server push

## 📊 Monitoring & Logging

### Health Checks
- **Backend**: `/api/health/` - Returns `{"status": "ok"}`
- **Frontend**: Root endpoint with HTTP 200
- **Database**: Automated health checks with retries
- **Container**: Docker health checks configured

### Logging
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db
```

### Monitoring Tools
- Docker health checks with automatic restart
- Structured logging with Django
- Database connection pooling
- Request/response logging

## 🧪 Testing

### Backend Tests
```bash
# Run Django tests
docker compose exec backend python manage.py test

# Or locally
cd backend
python manage.py test
```

### API Testing
```bash
# Test health endpoint
curl http://localhost:8000/api/health/

# Test newsletter subscription
curl -X POST http://localhost:8000/api/subscribe/ \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Expected response
# {"message": "Successfully subscribed!", "created": true}
```

### Frontend Testing
```bash
# Access frontend
open http://localhost

# Check Nginx config
docker compose exec frontend nginx -t
```

## 🔧 Development

### Tech Stack Versions (2025)
- **Python 3.12** - Latest stable
- **Node.js 22 LTS** - Long-term support
- **Nginx 1.27-alpine** - Latest stable
- **SQL Server 2022** - Latest version

### Code Style
- **Python**: PEP 8 compliance
- **JavaScript**: ES6+ features
- **CSS**: Tailwind utility classes

### Development Workflow
```bash
# Start in development mode
docker compose up --build

# Rebuild specific service
docker compose up -d --build backend

# Run Django commands
docker compose exec backend python manage.py makemigrations
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py createsuperuser

# Access Django shell
docker compose exec backend python manage.py shell
```

## 📈 Performance Optimization

### Frontend (Nginx 1.27)
- **Gzip Compression** - Automatic compression for text assets
- **Static Asset Caching** - 1 year cache for immutable files
- **HTTP/2** - Modern protocol with server push support
- **Proxy Buffering** - Optimized backend communication

### Backend (Python 3.12 + Django)
- **Connection Pooling** - Database connection reuse
- **Gunicorn Workers** - Multi-process request handling
- **Static Files** - Efficient serving via Nginx
- **Health Checks** - Proper startup periods configured

### Docker Optimizations
- **Multi-stage Builds** - Minimal production images
- **Layer Caching** - Fast rebuilds with optimized layers
- **No Cache Dirs** - Pip and npm without cache for smaller images
- **Health Checks** - Automatic container restart on failure

## 🐛 Troubleshooting

### Common Issues

#### Database Unhealthy Error
```bash
# The database takes ~60 seconds to fully start
# Wait for health checks to pass
docker compose ps

# If still failing, check logs
docker compose logs db

# Restart database
docker compose restart db
```

#### Port Already in Use
```bash
# Check what's using the port
lsof -i :80    # Frontend
lsof -i :8000  # Backend
lsof -i :1433  # Database

# Kill the process or change ports in docker-compose.yml
```

#### Backend Can't Connect to Database
```bash
# Ensure database is healthy first
docker compose ps db

# Check backend environment variables
docker compose exec backend env | grep DB_

# Restart backend after DB is healthy
docker compose restart backend
```

#### View All Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db

# Last 100 lines
docker compose logs --tail=100
```

#### Clean Start
```bash
# Remove everything and start fresh
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

## 📝 License

This project is proprietary software. All rights reserved.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📞 Support

For support and questions:
- Email: hello@yardeespaces.com
- Documentation: [azure-deployment.md](./azure-deployment.md)

---

**Built with ❤️ for Yardee Spaces**
