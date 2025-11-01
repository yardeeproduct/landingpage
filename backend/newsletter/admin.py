from django.contrib import admin
from .models import Subscription

# Register your models here.
@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ('email', 'subscribed_at')
    list_filter = ('subscribed_at',)
    search_fields = ('email',)
    readonly_fields = ('subscribed_at',)
    ordering = ('-subscribed_at',)
