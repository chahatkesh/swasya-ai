// Environment configuration utility
// Provides centralized access to environment variables

class EnvironmentConfig {
  constructor() {
    // Validate required environment variables
    this.validateEnvironment();
  }

  // API Configuration
  get apiBaseUrl() {
    return import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';
  }

  get nodeEnv() {
    return import.meta.env.VITE_NODE_ENV || 'development';
  }

  // Environment checks
  get isDevelopment() {
    return this.nodeEnv === 'development';
  }

  get isProduction() {
    return this.nodeEnv === 'production';
  }

  // Validation
  validateEnvironment() {
    const requiredVars = ['VITE_API_BASE_URL'];
    const missing = requiredVars.filter(varName => !import.meta.env[varName]);
    
    if (missing.length > 0) {
      console.warn('Missing environment variables:', missing);
      console.warn('Using default values. Check your .env file.');
    }
  }

  // Debug info (only in development)
  getDebugInfo() {
    if (this.isDevelopment) {
      return {
        apiBaseUrl: this.apiBaseUrl,
        nodeEnv: this.nodeEnv,
        allEnvVars: import.meta.env
      };
    }
    return null;
  }
}

// Export singleton instance
export const env = new EnvironmentConfig();

// Export individual values for convenience
export const {
  apiBaseUrl,
  nodeEnv,
  isDevelopment,
  isProduction
} = env;

export default env;