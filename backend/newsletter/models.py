from django.db import models
from django.utils import timezone

class Subscription(models.Model):
    email = models.EmailField(unique=True)  # Keep simple for now to avoid migration issues
    subscribed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-subscribed_at']  # Default ordering by newest first

    def __str__(self):
        return self.email
