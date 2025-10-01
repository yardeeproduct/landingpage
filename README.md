# Yardee Spaces Landing Page

A modern, responsive landing page built with Django REST API backend and Vite.js frontend, designed for Azure App Service deployment.

## 🚀 Features

- **Responsive Design**: Mobile-first approach with Tailwind CSS
- **Email Subscription**: Newsletter signup with Django backend
- **Image Carousel**: Dynamic hero section with smooth transitions
- **Production Ready**: Optimized for Azure App Service deployment
- **Docker Support**: Containerized for easy deployment
- **Security**: HTTPS, CORS, and security headers configured
- **Monitoring**: Health checks and logging integrated

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Vite.js)     │◄──►│   (Django)      │◄──►│   (Azure SQL)   │
│   + Nginx       │    │   + Gunicorn    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Tech Stack

### Frontend
- **Vite.js** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **Vanilla JavaScript** - No framework dependencies

### Backend
- **Django 5.0** - Python web framework
- **Django REST Framework** - API development
- **Gunicorn** - WSGI HTTP Server
- **SQL Server** - Database (Azure SQL compatible)

### Infrastructure
- **Docker** - Containerization
- **Azure App Service** - Cloud hosting
- **Azure SQL Database** - Managed database
- **Azure Container Registry** - Container storage

## 📦 Project Structure

```
yardee-spaces/
├── backend/                 # Django backend
│   ├── backend/            # Django project settings
│   ├── newsletter/         # Newsletter app
│   ├── requirements.txt    # Python dependencies
│   └── start.sh           # Startup script
├── frontend/               # Vite.js frontend
│   ├── src/               # Source files
│   ├── public/            # Static assets
│   ├── package.json       # Node dependencies
│   └── nginx.conf         # Nginx configuration
├── .github/               # GitHub Actions workflows
├── docker-compose.yml     # Local development
├── docker-compose.azure.yml # Azure deployment
├── Dockerfile.backend     # Backend container
├── Dockerfile.frontend    # Frontend container
└── azure-deployment.md    # Deployment guide
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local frontend development)
- Python 3.11+ (for local backend development)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd yardee-spaces
   ```

2. **Set up environment variables**
   ```bash
   cp backend/env.example backend/.env
   # Edit backend/.env with your settings
   ```

3. **Start with Docker Compose**
   ```bash
   docker-compose up --build
   ```

4. **Access the application**
   - Frontend: http://localhost:80
   - Backend API: http://localhost:8000
   - Health Check: http://localhost:8000/api/health/

### Manual Development Setup

#### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

#### Frontend Setup
```bash
cd frontend
npm install
npm run dev
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

### Azure App Service

See [azure-deployment.md](./azure-deployment.md) for detailed deployment instructions.

### Quick Azure Deployment

1. **Set up Azure resources**
   ```bash
   # Create resource group
   az group create --name yardee-spaces-rg --location eastus
   
   # Create SQL Database
   az sql server create --name yardee-sql --resource-group yardee-spaces-rg --location eastus --admin-user admin --admin-password "Password123!"
   az sql db create --resource-group yardee-spaces-rg --server yardee-sql --name yardee-db --service-objective Basic
   
   # Create Container Registry
   az acr create --resource-group yardee-spaces-rg --name yardeeacr --sku Basic --admin-enabled true
   ```

2. **Build and push images**
   ```bash
   az acr login --name yardeeacr
   docker build -f Dockerfile.backend -t yardeeacr.azurecr.io/backend:latest .
   docker build -f Dockerfile.frontend -t yardeeacr.azurecr.io/frontend:latest .
   docker push yardeeacr.azurecr.io/backend:latest
   docker push yardeeacr.azurecr.io/frontend:latest
   ```

3. **Deploy to App Service**
   ```bash
   az appservice plan create --name yardee-plan --resource-group yardee-spaces-rg --location eastus --sku P1V2 --is-linux
   az webapp create --resource-group yardee-spaces-rg --plan yardee-plan --name yardee-app --multicontainer-config-type compose --multicontainer-config-file docker-compose.azure.yml
   ```

## 🔒 Security Features

- **HTTPS Enforcement** - Automatic SSL redirect in production
- **CORS Configuration** - Proper cross-origin resource sharing
- **Security Headers** - XSS protection, content type sniffing prevention
- **Input Validation** - Email format validation and sanitization
- **Database Security** - Encrypted connections and parameterized queries
- **Container Security** - Non-root users and minimal base images

## 📊 Monitoring & Logging

### Health Checks
- Backend: `/api/health/`
- Frontend: Root endpoint with HTTP 200
- Container health checks configured

### Logging
- Structured logging with Django
- Application Insights integration (Azure)
- Container logs accessible via Azure portal

### Performance Monitoring
- Response time tracking
- Error rate monitoring
- Database connection monitoring
- Auto-scaling based on metrics

## 🧪 Testing

### Backend Tests
```bash
cd backend
python manage.py test
```

### Frontend Tests
```bash
cd frontend
npm test
```

### Integration Tests
```bash
# Test email subscription
curl -X POST http://localhost:8000/api/subscribe/ \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Test health check
curl http://localhost:8000/api/health/
```

## 🔧 Development

### Code Style
- **Python**: PEP 8 compliance
- **JavaScript**: ES6+ features
- **CSS**: Tailwind utility classes

### Git Workflow
- Feature branches from `main`
- Pull requests for code review
- Automated testing on PR
- Deployment on merge to `main`

### Docker Development
```bash
# Development with hot reload
docker-compose -f docker-compose.yml up --build

# Production build test
docker-compose -f docker-compose.azure.yml up --build
```

## 📈 Performance Optimization

### Frontend
- **Code Splitting** - Dynamic imports for better loading
- **Image Optimization** - WebP format support
- **Caching** - Browser cache headers
- **Compression** - Gzip compression enabled

### Backend
- **Connection Pooling** - Database connection reuse
- **Caching** - In-memory caching for frequent queries
- **Static Files** - Optimized serving with nginx
- **Health Checks** - Fast startup detection

### Infrastructure
- **CDN** - Azure CDN for static assets
- **Auto-scaling** - Based on CPU and memory usage
- **Load Balancing** - Built into Azure App Service
- **Database Optimization** - Indexed queries and connection pooling

## 🐛 Troubleshooting

### Common Issues

1. **Container startup failures**
   ```bash
   # Check logs
   docker-compose logs backend
   docker-compose logs frontend
   ```

2. **Database connection issues**
   ```bash
   # Test connection
   python manage.py dbshell
   ```

3. **CORS errors**
   - Verify `CORS_ALLOWED_ORIGINS` setting
   - Check `FRONTEND_URL` environment variable

### Debug Mode
```bash
# Enable debug logging
export DEBUG=1
export LOG_LEVEL=DEBUG
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
