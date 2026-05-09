// App Configuration - DO NOT commit with real credentials or sensitive data
// This file should be gitignored and configured per environment

class ApiEnvironment {
  final String baseUrl;
  final Duration timeout;
  final Duration connectivityTimeout;

  const ApiEnvironment({
    required this.baseUrl,
    required this.timeout,
    required this.connectivityTimeout,
  });
}

class ApiConfig {
  // Development environment
  static const ApiEnvironment development = ApiEnvironment(
    baseUrl: 'http://localhost:8080',
    timeout: Duration(seconds: 30),
    connectivityTimeout: Duration(seconds: 5),
  );

  // Production environment (HTTPS and secured backend)
  static const ApiEnvironment production = ApiEnvironment(
    baseUrl:
        'https://api.evat.example.com', // CHANGE THIS TO YOUR PRODUCTION URL
    timeout: Duration(seconds: 30),
    connectivityTimeout: Duration(seconds: 5),
  );

  // Staging environment
  static const ApiEnvironment staging = ApiEnvironment(
    baseUrl: 'https://staging-api.evat.example.com',
    timeout: Duration(seconds: 30),
    connectivityTimeout: Duration(seconds: 5),
  );

  // Get current environment
  // In production, this should read from build configuration
  static ApiEnvironment getCurrentEnvironment() {
    // For now, use development as default
    // In production, use flutter_dotenv or build-time configuration
    return development;
  }
}

// Security: Token management
class AuthConfig {
  static const String tokenStorageKey = 'evat_auth_token';
  static const String refreshTokenKey = 'evat_refresh_token';
  static const Duration tokenExpiration = Duration(hours: 24);

  // SECURITY: Store tokens securely using flutter_secure_storage
  // DO NOT store in SharedPreferences (unencrypted)
}

// SECURITY: HTTP Security Headers
const Map<String, String> securityHeaders = {
  'Content-Type': 'application/json',
  'X-Requested-With': 'XMLHttpRequest',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
};
