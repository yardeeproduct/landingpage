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
          // Handle HTTP errors
          let errorMessage = 'Failed to submit email. Please try again.';
          
          if (response.status === 400) {
            try {
              const errorData = await response.json();
              if (errorData.email && Array.isArray(errorData.email)) {
                errorMessage = errorData.email[0];
              } else if (errorData.message) {
                errorMessage = errorData.message;
              } else if (errorData.detail) {
                errorMessage = errorData.detail;
              }
            } catch (parseError) {
              console.warn('Failed to parse error response:', parseError);
            }
          } else if (response.status === 429) {
            errorMessage = 'Too many requests. Please try again later.';
          } else if (response.status >= 500) {
            errorMessage = 'Server error. Please try again later.';
          }
          
          this.resetButtonState(notifyButton, emailInput);
          this.showError(errorMessage);
          return;
        }
        
        // Success response
        const data = await response.json();
        console.log('Email subscription successful:', data);
        this.showSuccessMessage();
        return; // Exit retry loop on success
        
      } catch (error) {
        console.error(`Email submission error (attempt ${attempt}):`, error);
        
        // If this is the last attempt, show error
        if (attempt >= maxRetries) {
          this.resetButtonState(notifyButton, emailInput);
          
          if (error.name === 'AbortError') {
            this.showError('The server is starting up. Please try again in a moment.');
          } else if (error instanceof TypeError && error.message.includes('fetch')) {
            this.showError('Network error. Please check your connection and try again.');
          } else {
            this.showError('An unexpected error occurred. Please try again.');
          }
          return;
        }
        
        // Wait before retry (exponential backoff)
        const waitTime = attempt === 1 ? 1000 : 2000; // 1s after first failure, 2s after second
        console.log(`Retrying in ${waitTime}ms...`);
        
        // Update button to show retry status
        if (notifyButton) {
          notifyButton.innerHTML = `
            <img src="/assets/icons/Logo-icon.svg" alt="Retrying" class="logo-submitting w-6 h-6 mx-auto" />
          `;
        }
        
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
      // Transform the entire signup section content
      signupSection.innerHTML = `
        <div class="max-w-4xl mx-auto text-center">
          <h2 class="text-xl sm:text-2xl md:text-3xl lg:text-4xl xl:text-5xl font-medium text-white mb-4 sm:mb-6 md:mb-8 lg:mb-10">
            You're in! 🎉
          </h2>
          <p class="text-sm sm:text-base md:text-lg lg:text-xl text-white/90 mb-2 sm:mb-3 md:mb-4">
            We've added you to the waitlist.
          </p>
          <p class="text-sm sm:text-base md:text-lg lg:text-xl text-white/90">
            Stay tuned for updates!
          </p>
        </div>
      `;
      
      // Add a subtle animation
      signupSection.style.transition = 'all 0.5s ease-in-out';
      signupSection.style.transform = 'scale(1.02)';
      
      setTimeout(() => {
        signupSection.style.transform = 'scale(1)';
      }, 500);
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
    // Replace these URLs with your actual Google Drive links
    this.termsUrl = 'https://yardeespaces.sharepoint.com/:b:/s/YardeeSpaces/Ed99FtOLatVAgtRxSJkxsRsBPCZuIwnCP1OCPGJDbqoMGg?e=ZTbpGZ';
    this.privacyUrl = 'https://yardeespaces.sharepoint.com/:b:/s/YardeeSpaces/ERja7G50Z51CkgA7bWXhRgABc3tT5tefPqYnB_JFi9PaEg?e=hZsvNc';
    
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
