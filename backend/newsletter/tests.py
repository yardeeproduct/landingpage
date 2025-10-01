from django.test import TestCase, Client
from django.urls import reverse
import json

class NewsletterTests(TestCase):
    def setUp(self):
        self.client = Client()
    
    def test_health_check_endpoint(self):
        """Test the health check endpoint returns 200"""
        response = self.client.get('/api/health/')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.content)
        self.assertEqual(data['status'], 'ok')
        self.assertIn('message', data)
    
    def test_subscribe_valid_email(self):
        """Test subscribing with a valid email"""
        email_data = {'email': 'test@example.com'}
        response = self.client.post(
            '/api/subscribe/',
            data=json.dumps(email_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.content)
        self.assertEqual(data['message'], 'Success')
        self.assertTrue(data['created'])
    
    def test_subscribe_invalid_email(self):
        """Test subscribing with an invalid email"""
        email_data = {'email': 'invalid-email'}
        response = self.client.post(
            '/api/subscribe/',
            data=json.dumps(email_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 400)
        
        data = json.loads(response.content)
        self.assertIn('error', data)
    
    def test_subscribe_duplicate_email(self):
        """Test subscribing with the same email twice"""
        email_data = {'email': 'duplicate@example.com'}
        
        # First subscription
        response1 = self.client.post(
            '/api/subscribe/',
            data=json.dumps(email_data),
            content_type='application/json'
        )
        self.assertEqual(response1.status_code, 200)
        
        # Second subscription
        response2 = self.client.post(
            '/api/subscribe/',
            data=json.dumps(email_data),
            content_type='application/json'
        )
        self.assertEqual(response2.status_code, 200)
        
        data = json.loads(response2.content)
        self.assertEqual(data['message'], 'Success')
        self.assertFalse(data['created'])
    
    def test_subscribe_empty_email(self):
        """Test subscribing with empty email"""
        email_data = {'email': ''}
        response = self.client.post(
            '/api/subscribe/',
            data=json.dumps(email_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 400)
        
        data = json.loads(response.content)
        self.assertIn('error', data)
    
    def test_subscribe_no_email_field(self):
        """Test subscribing without email field"""
        response = self.client.post(
            '/api/subscribe/',
            data=json.dumps({}),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 400)
        
        data = json.loads(response.content)
        self.assertIn('error', data)
    
    def test_cors_headers(self):
        """Test CORS headers are present"""
        response = self.client.get('/api/health/')
        self.assertIn('Access-Control-Allow-Origin', response)
        self.assertEqual(response['Access-Control-Allow-Origin'], '*')