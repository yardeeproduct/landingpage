from django.core.management.base import BaseCommand
from newsletter.emails import send_confirmation_email, test_email_configuration
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Send a test confirmation email to verify email configuration'

    def add_arguments(self, parser):
        parser.add_argument(
            'email',
            type=str,
            help='Email address to send test email to'
        )

    def handle(self, *args, **options):
        email = options['email']
        
        self.stdout.write(f'Sending test email to {email}...')
        self.stdout.write('')
        
        # First test the email configuration
        self.stdout.write('Step 1: Testing email configuration...')
        try:
            config_test = test_email_configuration()
            if config_test:
                self.stdout.write(self.style.SUCCESS('✓ Email configuration test passed'))
            else:
                self.stdout.write(self.style.ERROR('✗ Email configuration test failed'))
                self.stdout.write('Please check your email settings in .env file')
                return
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Email configuration test error: {e}'))
            return
        
        self.stdout.write('')
        self.stdout.write('Step 2: Sending test email...')
        
        # Send the test email
        try:
            email_sent = send_confirmation_email(email)
            
            if email_sent:
                self.stdout.write(self.style.SUCCESS(f'✓ Test email sent successfully to {email}'))
                self.stdout.write('')
                self.stdout.write('Please check the inbox (and spam folder) for the test email.')
            else:
                self.stdout.write(self.style.ERROR(f'✗ Failed to send test email to {email}'))
                self.stdout.write('Check the logs above for error details.')
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error sending test email: {e}'))
            logger.exception('Test email error:')

