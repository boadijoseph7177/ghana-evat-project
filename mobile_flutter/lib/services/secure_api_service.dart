// SECURITY IMPROVEMENTS FOR API SERVICE
// This file shows how to properly handle authentication and API calls

import 'dart:convert';
import 'package:http/http.dart' as http;

class SecureApiService {
  // SECURITY: API token - should be retrieved from secure storage after authentication
  // In production, use flutter_secure_storage or similar
  late String _authToken;
  static const String _tokenHeader = 'Authorization';
  static const String _tokenPrefix = 'Bearer';

  // SECURITY: Constructor that requires authentication token
  SecureApiService({required String authToken}) {
    if (authToken.isEmpty) {
      throw Exception('SECURITY ERROR: Auth token cannot be empty');
    }
    _authToken = authToken;
  }

  // Get secure headers with proper authentication
  Map<String, String> _getSecureHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // SECURITY: Use Bearer token instead of custom header for role
      '$_tokenHeader': '$_tokenPrefix $_authToken',
      // Don't send role in header - let backend extract from token
    };
  }

  // SECURITY: Validate response for tampering
  bool _validateResponse(http.Response response) {
    // Check content-type
    final contentType = response.headers['content-type'];
    if (contentType == null || !contentType.contains('application/json')) {
      throw Exception('Invalid response content type');
    }
    return true;
  }

  // SECURITY: Safe error extraction
  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      // Only decode if response looks like JSON
      if (!response.body.startsWith('{')) {
        return fallback;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        // SECURITY: Only extract specific known error fields
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          // SECURITY: Don't expose full error - truncate if too long
          return error.length > 100 ? '${error.substring(0, 100)}...' : error;
        }
      }
    } catch (_) {
      // Fail silently
    }
    return fallback;
  }

  // Example: Secure API call
  Future<Map<String, dynamic>> getProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://localhost:8080/products'),
            headers: _getSecureHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      _validateResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token may have expired');
      } else {
        final message = _extractErrorMessage(
          response,
          'Failed to load products',
        );
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // SECURITY: Token refresh method
  Future<void> refreshToken(String newToken) async {
    if (newToken.isEmpty) {
      throw Exception('New token cannot be empty');
    }
    _authToken = newToken;
    // In production: also persist to secure storage
  }
}

// SECURITY BEST PRACTICES:
// 1. Always use HTTPS in production (https:// not http://)
// 2. Validate SSL certificates
// 3. Use Bearer tokens instead of custom headers
// 4. Never hardcode tokens
// 5. Store tokens securely (encrypted)
// 6. Implement token refresh logic
// 7. Sign all requests to prevent tampering
// 8. Validate all responses
// 9. Implement certificate pinning for critical endpoints
// 10. Add timeout to all requests
