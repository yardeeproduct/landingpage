from django.urls import path
from .views import subscribe_email, health_check

urlpatterns = [
    path('subscribe/', subscribe_email, name='subscribe_email'),
    path('health/', health_check, name='health_check'),
]
