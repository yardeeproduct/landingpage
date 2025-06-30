import json
import logging
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import never_cache
from django.db import transaction, connection
from django.core.cache import cache
from .models import Subscription

# Configure logging
logger = logging.getLogger(__name__)

def warmup_database():
    """Warm up database connection to avoid cold start delays"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        logger.info("Database connection warmed up successfully")
        return True
    except Exception as e:
        logger.warning(f"Database warmup failed: {e}")
        return False

@csrf_exempt
@never_cache
def subscribe_email(request):
    # Always add CORS headers
    def add_cors_headers(response):
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
        response['Access-Control-Max-Age'] = '86400'
        return response
    
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        response = JsonResponse({})
        return add_cors_headers(response)
    
    # Handle POST request
    if request.method == 'POST':
        try:
            logger.info(f"Received POST request from {request.META.get('HTTP_ORIGIN', 'unknown origin')}")
            
            # Warm up database connection on first request
            if not hasattr(subscribe_email, '_db_warmed'):
                logger.info("Warming up database connection...")
                warmup_database()
                subscribe_email._db_warmed = True
                
            data = json.loads(request.body)
            email = data.get('email', '').strip().lower()  # Normalize email
            logger.info(f"Processing email: {email}")

            if not email:
                logger.warning("No email provided in request")
                response = JsonResponse({'error': 'Email not provided'}, status=400)
                return add_cors_headers(response)
            
            # Basic email validation
            if '@' not in email or '.' not in email.split('@')[1]:
                logger.warning(f"Invalid email format: {email}")
                response = JsonResponse({'error': 'Invalid email format'}, status=400)
                return add_cors_headers(response)
            
            # Use atomic transaction for database operations
            with transaction.atomic():
                # Check cache first to avoid database hit for recent duplicates
                cache_key = f"email_sub_{email}"
                if cache.get(cache_key):
                    logger.info(f"Email {email} found in cache, returning existing subscription")
                    response = JsonResponse({'message': 'Success', 'created': False}, status=200)
                    return add_cors_headers(response)
                
                # Use get_or_create with select_for_update to prevent race conditions
                subscription, created = Subscription.objects.select_for_update().get_or_create(
                    email=email
                )
                
                # Cache the result for 1 hour to prevent duplicate processing
                cache.set(cache_key, True, 3600)
                
                message = 'New subscription created' if created else 'Email already subscribed'
                logger.info(f"Subscription result for {email}: {message}")
                
                response = JsonResponse({'message': 'Success', 'created': created}, status=200)
                return add_cors_headers(response)
                
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            response = JsonResponse({'error': 'Invalid JSON'}, status=400)
            return add_cors_headers(response)
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            response = JsonResponse({'error': 'Internal server error'}, status=500)
            return add_cors_headers(response)

    # Handle other methods
    logger.warning(f"Invalid method: {request.method}")
    response = JsonResponse({'error': 'Invalid request method'}, status=405)
    return add_cors_headers(response)

# Simple health check endpoint
@csrf_exempt
def health_check(request):
    response = JsonResponse({'status': 'ok', 'message': 'API is working'})
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    return response
