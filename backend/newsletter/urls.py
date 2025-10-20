from django.urls import path
from .views import subscribe_email, health_check, test_email

urlpatterns = [
    path('subscribe/', subscribe_email, name='subscribe_email'),
    path('health/', health_check, name='health_check'),
    path('test-email/', test_email, name='test_email'),
]
