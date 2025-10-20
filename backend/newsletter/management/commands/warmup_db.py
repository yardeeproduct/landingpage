from django.core.management.base import BaseCommand
from django.db import connection
from newsletter.models import Subscription
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Warm up database connections and perform initial checks'

    def handle(self, *args, **options):
        self.stdout.write('Starting database warmup...')
        
        try:
            # Test database connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Database connection test passed: {result}')
                )
            
            # Test model access
            count = Subscription.objects.count()
            self.stdout.write(
                self.style.SUCCESS(f'✓ Model access test passed: {count} subscriptions found')
            )
            
            # Perform a simple query to warm up query planner
            recent_subs = Subscription.objects.order_by('-subscribed_at')[:1]
            self.stdout.write(
                self.style.SUCCESS(f'✓ Query warmup completed: {len(list(recent_subs))} records')
            )
            
            self.stdout.write(
                self.style.SUCCESS('Database warmup completed successfully!')
            )
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Database warmup failed: {e}')
            )
            logger.error(f'Database warmup error: {e}')
            raise e
