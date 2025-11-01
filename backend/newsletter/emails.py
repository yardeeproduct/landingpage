"""
Email utilities for newsletter confirmations
"""
import logging
import base64
import os
from pathlib import Path
from django.conf import settings
from django.core.mail import EmailMessage
from django.template.loader import render_to_string

logger = logging.getLogger(__name__)

def get_logo_base64():
    """
    Get the logo as base64 encoded data URI for embedding in email (PNG format for better email client support)
    """
    try:
        # Try multiple paths to find the logo PNG file
        logo_paths = [
            # Path 1: In Docker container (logo copied to /app/frontend/public/assets/images/logo-3.png)
            Path(settings.BASE_DIR) / 'frontend' / 'public' / 'assets' / 'images' / 'logo-3.png',
            # Path 2: Local development (project root)
            Path(settings.BASE_DIR).parent / 'frontend' / 'public' / 'assets' / 'images' / 'logo-3.png',
            # Path 3: From current working directory (alternative)
            Path.cwd() / 'frontend' / 'public' / 'assets' / 'images' / 'logo-3.png',
            # Path 4: Absolute path in Docker if frontend is mounted
            Path('/app') / 'frontend' / 'public' / 'assets' / 'images' / 'logo-3.png',
        ]
        
        logo_path = None
        for path in logo_paths:
            if path.exists():
                logo_path = path
                logger.debug(f"Found logo at: {logo_path}")
                break
        
        if logo_path and logo_path.exists():
            # Read PNG as binary and encode to base64
            with open(logo_path, 'rb') as f:
                logo_data = f.read()
            
            # Encode to base64
            logo_base64 = base64.b64encode(logo_data).decode('utf-8')
            logo_data_uri = f'data:image/png;base64,{logo_base64}'
            
            logger.info(f"Logo loaded successfully from {logo_path}, size: {len(logo_data)} bytes")
            return logo_data_uri
        else:
            logger.warning(f"Logo file not found. Tried paths: {logo_paths}")
            return None
    except Exception as e:
        logger.error(f"Error reading logo file: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

def get_email_context(to_email: str, company_name: str = None) -> dict:
    """
    Get the context data for email templates
    """
    if not company_name:
        company_name = getattr(settings, 'COMPANY_NAME', 'Your Company')
    
    # Get logo as base64 data URI (embedded) or URL
    logo_url = getattr(settings, 'EMAIL_LOGO_URL', None)
    logo_base64 = get_logo_base64()
    
    # Prefer base64 embedded logo if available, fallback to URL
    logo_data = logo_base64 if logo_base64 else logo_url
    
    return {
        'company_name': company_name,
        'subscriber_email': to_email,
        'support_email': getattr(settings, 'EMAIL_HOST_USER', 'support@company.com'),
        'logo_url': logo_url,  # Keep for fallback
        'logo_base64': logo_base64,  # Embedded logo
        'logo_data': logo_data,  # Use this in template (prefers base64)
        'website_url': getattr(settings, 'COMPANY_WEBSITE_URL', None),
        'company_address': getattr(settings, 'COMPANY_ADDRESS', None),
        'social_links': {
            'website': getattr(settings, 'COMPANY_WEBSITE_URL', None),
            'linkedin': getattr(settings, 'COMPANY_LINKEDIN_URL', None),
            'twitter': getattr(settings, 'COMPANY_TWITTER_URL', None),
            'instagram': getattr(settings, 'COMPANY_INSTAGRAM_URL', None),
            'facebook': getattr(settings, 'COMPANY_FACEBOOK_URL', None),
        }
    }

def send_confirmation_email(to_email: str, company_name: str = None) -> bool:
    """
    Send a confirmation email to a new subscriber.
    
    Args:
        to_email: The email address to send confirmation to
        company_name: Optional company name for personalization
    
    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    try:
        logger.debug(f"[EMAIL DEBUG] Starting email send process for: {to_email}")
        
        # Debug: Check email settings
        logger.debug(f"[EMAIL DEBUG] Email backend: {settings.EMAIL_BACKEND}")
        logger.debug(f"[EMAIL DEBUG] Email host: {settings.EMAIL_HOST}")
        logger.debug(f"[EMAIL DEBUG] Email port: {settings.EMAIL_PORT}")
        logger.debug(f"[EMAIL DEBUG] Email use TLS: {settings.EMAIL_USE_TLS}")
        logger.debug(f"[EMAIL DEBUG] Email from: {getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@company.com')}")
        
        # Get template context
        context = get_email_context(to_email, company_name)
        logger.debug(f"[EMAIL DEBUG] Template context created: {context}")
        
        # Email subject
        subject_prefix = getattr(settings, 'EMAIL_SUBJECT_PREFIX', '[Newsletter] ')
        subject = f"{subject_prefix}Welcome to our newsletter!"
        logger.debug(f"[EMAIL DEBUG] Email subject: {subject}")
        
        # Render email template
        logger.debug("[EMAIL DEBUG] Rendering email template...")
        html_body = render_to_string('newsletter/confirmation_email.html', context)
        logger.debug(f"[EMAIL DEBUG] HTML body length: {len(html_body)} characters")
        
        # Create email message
        logger.debug("[EMAIL DEBUG] Creating email message...")
        msg = EmailMessage(
            subject=subject,
            body=html_body,
            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@company.com'),
            to=[to_email],
        )
        
        # Set content type to HTML
        msg.content_subtype = 'html'
        logger.debug("[EMAIL DEBUG] HTML content type set")
        
        # Send email
        logger.debug(f"[EMAIL DEBUG] Attempting to send email to {to_email}...")
        send_result = msg.send(fail_silently=False)
        logger.debug(f"[EMAIL DEBUG] Email send result: {send_result}")
        
        logger.info(f"✅ [EMAIL SUCCESS] Confirmation email sent successfully to {to_email}")
        return True
        
    except Exception as e:
        logger.error(f"❌ [EMAIL ERROR] Failed to send confirmation email to {to_email}")
        logger.error(f"[EMAIL ERROR] Exception type: {type(e).__name__}")
        logger.error(f"[EMAIL ERROR] Exception message: {str(e)}")
        logger.exception(f"[EMAIL ERROR] Full traceback:")
        return False

def test_email_configuration() -> bool:
    """
    Test if email configuration is working by attempting to connect to the SMTP server.
    
    Returns:
        bool: True if email configuration is working, False otherwise
    """
    try:
        logger.debug("[EMAIL DEBUG] Testing email configuration...")
        from django.core.mail import get_connection
        
        # Debug: Log email settings
        logger.debug(f"[EMAIL DEBUG] Email backend: {settings.EMAIL_BACKEND}")
        logger.debug(f"[EMAIL DEBUG] Email host: {settings.EMAIL_HOST}")
        logger.debug(f"[EMAIL DEBUG] Email port: {settings.EMAIL_PORT}")
        logger.debug(f"[EMAIL DEBUG] Email host user: {getattr(settings, 'EMAIL_HOST_USER', 'Not set')}")
        logger.debug(f"[EMAIL DEBUG] Email use TLS: {settings.EMAIL_USE_TLS}")
        logger.debug(f"[EMAIL DEBUG] Email use SSL: {getattr(settings, 'EMAIL_USE_SSL', False)}")
        
        # Test connection
        logger.debug("[EMAIL DEBUG] Opening SMTP connection...")
        connection = get_connection()
        connection.open()
        logger.debug("[EMAIL DEBUG] SMTP connection opened successfully")
        
        connection.close()
        logger.debug("[EMAIL DEBUG] SMTP connection closed")
        
        logger.info("✅ [EMAIL SUCCESS] Email configuration test successful")
        return True
        
    except Exception as e:
        logger.error(f"❌ [EMAIL ERROR] Email configuration test failed")
        logger.error(f"[EMAIL ERROR] Exception type: {type(e).__name__}")
        logger.error(f"[EMAIL ERROR] Exception message: {str(e)}")
        logger.exception(f"[EMAIL ERROR] Full traceback:")
        return False