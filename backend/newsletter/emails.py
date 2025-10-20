"""
Email utilities for newsletter confirmations
"""
import logging
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string

logger = logging.getLogger(__name__)

def get_email_context(to_email: str, company_name: str = None) -> dict:
    """
    Get the context data for email templates
    """
    if not company_name:
        company_name = getattr(settings, 'COMPANY_NAME', 'Your Company')
    
    return {
        'company_name': company_name,
        'subscriber_email': to_email,
        'support_email': getattr(settings, 'EMAIL_HOST_USER', 'support@company.com'),
        'logo_url': getattr(settings, 'EMAIL_LOGO_URL', None),
        'website_url': getattr(settings, 'COMPANY_WEBSITE_URL', None),
        'company_address': getattr(settings, 'COMPANY_ADDRESS', None),
        'social_links': {
            'website': getattr(settings, 'COMPANY_WEBSITE_URL', None),
            'linkedin': getattr(settings, 'COMPANY_LINKEDIN_URL', None),
            'twitter': getattr(settings, 'COMPANY_TWITTER_URL', None),
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
        
        # Render email templates
        logger.debug("[EMAIL DEBUG] Rendering email templates...")
        text_body = render_to_string('newsletter/confirmation_email.txt', context)
        logger.debug(f"[EMAIL DEBUG] Text body length: {len(text_body)} characters")
        
        html_body = render_to_string('newsletter/confirmation_email.html', context)
        logger.debug(f"[EMAIL DEBUG] HTML body length: {len(html_body)} characters")
        
        # Create email message
        logger.debug("[EMAIL DEBUG] Creating email message...")
        msg = EmailMultiAlternatives(
            subject=subject,
            body=text_body,
            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@company.com'),
            to=[to_email],
        )
        
        # Attach HTML version
        msg.attach_alternative(html_body, "text/html")
        logger.debug("[EMAIL DEBUG] HTML alternative attached")
        
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