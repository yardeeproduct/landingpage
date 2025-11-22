import './style.css'

// Carousel functionality for hero section
class ImageCarousel {
  constructor() {
    this.images = [
      '/assets/images/hero-image.png',
      '/assets/images/image-2.png',
      '/assets/images/image-3.png'
    ];
    this.currentIndex = 0;
    this.heroImage = null;
    this.prevBtn = null;
    this.nextBtn = null;
    
    this.init();
  }
  
  init() {
    // Wait for DOM to be ready
    document.addEventListener('DOMContentLoaded', () => {
      this.setupCarousel();
    });
    
    // If DOM is already loaded
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        this.setupCarousel();
      });
    } else {
      this.setupCarousel();
    }
  }
  
  setupCarousel() {
    // Find carousel elements
    this.heroImage = document.querySelector('.lg\\:col-span-6 img[src*="hero-image"]');
    this.prevBtn = document.getElementById('prevBtn');
    this.nextBtn = document.getElementById('nextBtn');
    
    if (!this.heroImage || !this.prevBtn || !this.nextBtn) {
      console.log('Carousel elements not found, retrying...');
      setTimeout(() => this.setupCarousel(), 100);
      return;
    }
    
    // Add event listeners
    this.prevBtn.addEventListener('click', () => this.previousImage());
    this.nextBtn.addEventListener('click', () => this.nextImage());
    
    // Auto-play carousel (optional)
    this.startAutoPlay();
    
    console.log('Carousel initialized successfully');
  }
  
  nextImage() {
    this.currentIndex = (this.currentIndex + 1) % this.images.length;
    this.updateImage();
  }
  
  previousImage() {
    this.currentIndex = this.currentIndex === 0 ? this.images.length - 1 : this.currentIndex - 1;
    this.updateImage();
  }
  
  updateImage() {
    if (this.heroImage) {
      // Add smooth fade transition
      this.heroImage.style.transition = 'opacity 0.5s ease-in-out';
      this.heroImage.style.opacity = '0';
      
      setTimeout(() => {
        this.heroImage.src = this.images[this.currentIndex];
        this.heroImage.style.opacity = '1';
      }, 250);
    }
  }
  
  startAutoPlay() {
    // Auto-advance every 7 seconds for better viewing experience
    setInterval(() => {
      this.nextImage();
    }, 5000);
  }
}

// Initialize carousel
const carousel = new ImageCarousel();

// Email submission functionality
class EmailSignup {
  constructor() {
    this.init();
  }
  
  init() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        this.setupEmailForm();
      });
    } else {
      this.setupEmailForm();
    }
  }
  
  setupEmailForm() {
    const notifyButton = document.querySelector('button[type="submit"]');
    const emailInput = document.querySelector('input[type="email"]');
    
    if (notifyButton && emailInput) {
      notifyButton.addEventListener('click', (e) => {
        e.preventDefault();
        this.handleEmailSubmission(emailInput.value);
      });
    }
  }
  
  async handleEmailSubmission(email) {
    // Validate email format
    if (!email || email.trim() === '') {
      this.showError('Please enter an email address');
      return;
    }
    
    if (!this.isValidEmail(email.trim())) {
      this.showError('Please enter a valid email address');
      return;
    }
    
    const notifyButton = document.querySelector('button[type="submit"]');
    const emailInput = document.querySelector('input[type="email"]');
    
    // Show immediate loading state
    this.showLoadingState(notifyButton, emailInput);
    
    // Show success message immediately (user sees instant feedback)
    this.showSuccessMessage();
    
    // Continue backend submission in background (fire and forget)
    this.submitToBackend(email);
  }
  
  async submitToBackend(email) {
    // Retry logic for cold start issues
    const maxRetries = 2;
    let attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        console.log(`Email submission attempt ${attempt}/${maxRetries}`);
        
        // Determine API base URL
        // - In Docker: VITE_API_BASE_URL is set (e.g., http://backend:8000)
        // - In local dev (vite): proxy is configured for /api, so fallback '' works
        const apiBaseEnv = (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_API_BASE_URL) ? import.meta.env.VITE_API_BASE_URL : '';
        const apiBaseUrl = (apiBaseEnv || '').replace(/\/+$/, '');
        
        // Progressive timeout - longer for first attempt (cold start)
        const timeout = attempt === 1 ? 15000 : 8000; // 15s first, 8s retry
        
        // Create AbortController with appropriate timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);
        
        // Send email to Django backend with optimized headers
        const response = await fetch(`${apiBaseUrl}/api/subscribe/`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRFToken': this.getCSRFToken(),
            'Cache-Control': 'no-cache',
          },
          body: JSON.stringify({ email: email.trim() }),
          signal: controller.signal,
          // Add connection optimizations
          keepalive: true,
        });
        
        clearTimeout(timeoutId);
        
        if (!response.ok) {
          // Handle HTTP errors silently (user already sees success screen)
          console.error(`Backend submission failed: ${response.status}`);
          
          if (response.status === 400) {
            try {
              const errorData = await response.json();
              console.error('Backend error details:', errorData);
            } catch (parseError) {
              console.warn('Failed to parse error response:', parseError);
            }
          }
          
          // If this was the last attempt, log failure but don't show to user
          if (attempt >= maxRetries) {
            console.error('All backend submission attempts failed');
            return;
          }
        } else {
          // Success response
          const data = await response.json();
          console.log('Email subscription successful:', data);
          return; // Exit retry loop on success
        }
        
      } catch (error) {
        console.error(`Email submission error (attempt ${attempt}):`, error);
        
        // If this is the last attempt, log but don't show to user
        if (attempt >= maxRetries) {
          console.error('All backend submission attempts failed:', error);
          return;
        }
        
        // Wait before retry (exponential backoff)
        const waitTime = attempt === 1 ? 1000 : 2000; // 1s after first failure, 2s after second
        console.log(`Retrying in ${waitTime}ms...`);
        
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }
  
  // Get CSRF token for Django (if needed)
  getCSRFToken() {
    const csrfCookie = document.cookie
      .split('; ')
      .find(row => row.startsWith('csrftoken='));
    return csrfCookie ? csrfCookie.split('=')[1] : '';
  }
  
  showError(message) {
    const emailInput = document.querySelector('input[type="email"]');
    if (emailInput) {
      // Add red border for visual feedback
      emailInput.style.borderColor = '#ef4444';
      emailInput.style.boxShadow = '0 0 0 1px #ef4444';
      
      // Reset border after 3 seconds
      setTimeout(() => {
        emailInput.style.borderColor = '';
        emailInput.style.boxShadow = '';
      }, 3000);
    }
    
    alert(message);
  }
  
  showLoadingState(button, input) {
    if (button) {
      button.disabled = true;
      button.style.opacity = '0.8';
      button.style.cursor = 'not-allowed';
      button.innerHTML = `
        <img src="/assets/icons/Logo-icon.svg" alt="Submitting" class="logo-submitting w-6 h-6 mx-auto" />
      `;
    }
    
    if (input) {
      input.disabled = true;
      input.style.opacity = '0.7';
    }
  }
  
  resetButtonState(button, input) {
    if (button) {
      button.disabled = false;
      button.style.opacity = '1';
      button.style.cursor = 'pointer';
      button.innerHTML = 'Notify me';
    }
    
    if (input) {
      input.disabled = false;
      input.style.opacity = '1';
    }
  }
  
  showSuccessMessage() {
    const signupSection = document.getElementById('signup');
    if (signupSection) {
      // Create overlay div to prevent white flash
      const overlay = document.createElement('div');
      overlay.style.cssText = `
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: #224432;
        z-index: 10;
        opacity: 0;
        transition: opacity 0.3s ease-in-out;
      `;
      signupSection.style.position = 'relative';
      signupSection.appendChild(overlay);
      
      // Trigger overlay fade-in
      requestAnimationFrame(() => {
        overlay.style.opacity = '1';
      });
      
      setTimeout(() => {
        // Professional success message with better design
        signupSection.innerHTML = `
          <div class="max-w-4xl mx-auto text-center">
            <!-- Success Icon -->
            <div class="mb-6 sm:mb-8 flex justify-center">
              <div class="w-16 h-16 sm:w-20 sm:h-20 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
                <svg class="w-8 h-8 sm:w-10 sm:h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
              </div>
            </div>
            
            <!-- Success Message -->
            <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-semibold text-white mb-4 sm:mb-6">
              Welcome to the waitlist!
            </h2>
            
            <!-- Confirmation Text -->
            <div class="space-y-2 sm:space-y-3 mb-6 sm:mb-8">
              <p class="text-base sm:text-lg md:text-xl text-white/95 font-medium">
                You're officially on the list for early access.
              </p>
              <p class="text-sm sm:text-base md:text-lg text-white/80">
                We'll notify you as soon as Yardee Spaces launches in 2026.
              </p>
            </div>
            
            <!-- Next Steps -->
            <div class="bg-white/10 backdrop-blur-sm rounded-2xl p-4 sm:p-6 md:p-8 border border-white/20 max-w-2xl mx-auto">
              <h3 class="text-lg sm:text-xl font-semibold text-white mb-3 sm:mb-4">
                What's next?
              </h3>
              <div class="space-y-2 sm:space-y-3 text-sm sm:text-base text-white/90">
                <div class="flex items-center justify-center sm:justify-start space-x-3">
                  <div class="w-2 h-2 bg-[#88E03B] rounded-full flex-shrink-0"></div>
                  <span>Get exclusive updates on our progress</span>
                </div>
                <div class="flex items-center justify-center sm:justify-start space-x-3">
                  <div class="w-2 h-2 bg-[#88E03B] rounded-full flex-shrink-0"></div>
                  <span>Early access to beta features</span>
                </div>
                <div class="flex items-center justify-center sm:justify-start space-x-3">
                  <div class="w-2 h-2 bg-[#88E03B] rounded-full flex-shrink-0"></div>
                  <span>Priority onboarding when we launch</span>
                </div>
              </div>
            </div>
            
            <!-- Social Follow CTA -->
            <div class="mt-6 sm:mt-8">
              <p class="text-sm sm:text-base text-white/70 mb-3 sm:mb-4">
                Follow our journey on social media
              </p>
              <div class="flex justify-center space-x-4">
                <a href="https://www.facebook.com/yardeespaces#" target="_blank" rel="noopener noreferrer" 
                   class="w-10 h-10 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-all duration-300 hover:scale-110">
                  <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                  </svg>
                </a>
                <a href="https://www.linkedin.com/company/yardee-spaces" target="_blank" rel="noopener noreferrer" 
                   class="w-10 h-10 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-all duration-300 hover:scale-110">
                  <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                  </svg>
                </a>
                <a href="https://www.instagram.com/yardeespaces/" target="_blank" rel="noopener noreferrer"
                   class="w-10 h-10 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-all duration-300 hover:scale-110">
                  <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                  </svg>
                </a>
              </div>
            </div>
          </div>
        `;
        
        // Remove overlay and reset styles
        const overlay = signupSection.querySelector('div[style*="z-index: 10"]');
        if (overlay) overlay.remove();
        signupSection.style.position = '';
        
        // Add staggered animation to elements without opacity flash
        const elements = signupSection.querySelectorAll('div, h2, h3, p');
        elements.forEach((element, index) => {
          element.style.opacity = '0';
          element.style.transform = 'translateY(20px)';
          element.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
          
          setTimeout(() => {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
          }, 50 + (index * 80)); // Stagger by 80ms each for smoother effect
        });
        
      }, 300); // Reduced timeout for smoother transition
    }
  }
  
  isValidEmail(email) {
    // Comprehensive email regex pattern
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
    
    // Additional checks
    if (email.length > 254) return false; // RFC 5321 limit
    if (email.startsWith('.') || email.endsWith('.')) return false;
    if (email.includes('..')) return false; // No consecutive dots
    
    const parts = email.split('@');
    if (parts.length !== 2) return false;
    
    const [localPart, domainPart] = parts;
    if (localPart.length > 64) return false; // RFC 5321 limit for local part
    if (domainPart.length > 253) return false; // RFC 5321 limit for domain part
    
    return emailRegex.test(email);
  }
}

// Initialize email signup
const emailSignup = new EmailSignup();

// Terms and Privacy Policy links functionality
class LegalLinksHandler {
  constructor() {
    // Google Docs links
    this.termsUrl = 'https://docs.google.com/document/d/1n4tNZlwd4pCVvcF244N_5EuhKAgKusWk-yKyefdoSyY/preview';
    this.privacyUrl = 'https://docs.google.com/document/d/1DXZhPpswqPezkHC73PEe7-4gvnqwsXqFcCwLFmkQXyg/preview';
    
    this.init();
  }
  
  init() {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        this.setupLegalLinks();
      });
    } else {
      this.setupLegalLinks();
    }
  }
  
  setupLegalLinks() {
    // Find all legal links in the footer
    const footerLinks = document.querySelectorAll('footer a');
    
    footerLinks.forEach(link => {
      const linkText = link.textContent.trim().toLowerCase();
      const href = link.getAttribute('href') || '';
      
      if (linkText.includes('terms') || linkText.includes('conditions')) {
        link.addEventListener('click', (e) => {
          e.preventDefault();
          this.openTerms();
        });
      } else if (linkText.includes('privacy')) {
        link.addEventListener('click', (e) => {
          e.preventDefault();
          this.openPrivacy();
        });
      } else if (href.includes('mailto:') || linkText.includes('@') || linkText.includes('hello')) {
        // Handle email contact link
        link.addEventListener('click', (e) => {
          e.preventDefault();
          this.openEmail();
        });
      }
    });
  }
  
  openTerms() {
    // Open Terms & Conditions in new tab
    window.open(this.termsUrl, '_blank', 'noopener,noreferrer');
  }
  
  openPrivacy() {
    // Open Privacy Policy in new tab
    window.open(this.privacyUrl, '_blank', 'noopener,noreferrer');
  }
  
  openEmail() {
    // Open default mail app with pre-filled email
    const subject = 'Inquiry from Yardee Spaces Website';
    const mailtoUrl = `mailto:hello@yardeespaces.com?subject=${encodeURIComponent(subject)}`;
    
    window.location.href = mailtoUrl;
  }
  
  // Method to update URLs if needed
  updateUrls(termsUrl, privacyUrl) {
    this.termsUrl = termsUrl;
    this.privacyUrl = privacyUrl;
  }
}

// Initialize legal links handler
const legalLinks = new LegalLinksHandler();

// Smooth scroll functionality (if not already in HTML)
window.scrollToSignup = function() {
  const signupSection = document.getElementById('signup');
  if (signupSection) {
    signupSection.scrollIntoView({ 
      behavior: 'smooth',
      block: 'start'
    });
    
    // Focus and select the email input after scrolling
    setTimeout(() => {
      const emailInput = signupSection.querySelector('input[type="email"]');
      if (emailInput) {
        emailInput.focus();
        emailInput.select();
      }
    }, 800);
  }
}
