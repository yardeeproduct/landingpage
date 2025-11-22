import json
import logging
import threading
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import never_cache
from django.db import transaction, connection
from django.core.cache import cache
from .models import Subscription
from .emails import send_confirmation_email

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
                
                # Send confirmation email for new subscriptions (non-blocking)
                if created:
                    logger.debug(f"[EMAIL DEBUG] New subscription created, preparing to send confirmation email to {email}")
                    try:
                        # Send email in background thread to avoid blocking the response
                        def send_email():
                            try:
                                logger.debug(f"[EMAIL DEBUG] Background thread started for sending email to {email}")
                                email_status = send_confirmation_email(email)
                                if email_status:
                                    logger.info(f"✅ [EMAIL SUCCESS] Confirmation email sent successfully for {email}")
                                else:
                                    logger.error(f"❌ [EMAIL ERROR] Email send returned False for {email}")
                            except Exception as e:
                                logger.error(f"❌ [EMAIL ERROR] Exception in background thread for {email}: {str(e)}")
                                logger.exception(f"[EMAIL ERROR] Full traceback:")
                        
                        # Start background thread for email sending
                        logger.debug(f"[EMAIL DEBUG] Starting background thread for email sending to {email}")
                        email_thread = threading.Thread(target=send_email, daemon=True)
                        email_thread.start()
                        logger.debug(f"[EMAIL DEBUG] Background thread started successfully (Thread ID: {email_thread.ident})")
                        
                    except Exception as e:
                        logger.error(f"❌ [EMAIL ERROR] Failed to spawn confirmation email thread for {email}")
                        logger.error(f"[EMAIL ERROR] Exception type: {type(e).__name__}")
                        logger.error(f"[EMAIL ERROR] Exception message: {str(e)}")
                        logger.exception(f"[EMAIL ERROR] Full traceback:")
                        # Don't fail the subscription if email fails
                else:
                    logger.debug(f"[EMAIL DEBUG] Subscription already exists for {email}, skipping email send")
                
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

# Email configuration test endpoint
@csrf_exempt
def test_email(request):
    """Test endpoint to verify email configuration"""
    from .emails import test_email_configuration, send_confirmation_email
    
    def add_cors_headers(response):
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
        return response
    
    if request.method == 'OPTIONS':
        response = JsonResponse({})
        return add_cors_headers(response)
    
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            test_email_address = data.get('email', '').strip()
            
            if not test_email_address:
                response = JsonResponse({'error': 'Email address required for testing'}, status=400)
                return add_cors_headers(response)
            
            # Test email configuration
            logger.debug(f"[EMAIL DEBUG] Testing email configuration for test email to {test_email_address}")
            config_test = test_email_configuration()
            logger.debug(f"[EMAIL DEBUG] Configuration test result: {config_test}")
            
            if not config_test:
                logger.error(f"❌ [EMAIL ERROR] Email configuration test failed for {test_email_address}")
                response = JsonResponse({
                    'status': 'error',
                    'message': 'Email configuration test failed. Check your SMTP settings.'
                }, status=500)
                return add_cors_headers(response)
            
            # Send test email
            logger.debug(f"[EMAIL DEBUG] Attempting to send test email to {test_email_address}")
            email_sent = send_confirmation_email(test_email_address)
            logger.debug(f"[EMAIL DEBUG] Test email send result: {email_sent}")
            
            if email_sent:
                logger.info(f"✅ [EMAIL SUCCESS] Test email sent successfully to {test_email_address}")
                response = JsonResponse({
                    'status': 'success',
                    'message': f'Test email sent successfully to {test_email_address}'
                })
                return add_cors_headers(response)
            else:
                logger.error(f"❌ [EMAIL ERROR] Failed to send test email to {test_email_address}")
                response = JsonResponse({
                    'status': 'error',
                    'message': 'Failed to send test email. Check logs for details.'
                }, status=500)
                return add_cors_headers(response)
                
        except json.JSONDecodeError:
            response = JsonResponse({'error': 'Invalid JSON'}, status=400)
            return add_cors_headers(response)
        except Exception as e:
            logger.error(f"Email test error: {e}")
            response = JsonResponse({'error': 'Internal server error'}, status=500)
            return add_cors_headers(response)
    
    response = JsonResponse({'error': 'Invalid request method'}, status=405)
    return add_cors_headers(response)
