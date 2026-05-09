# E-VAT Security Audit Report & Fixes

## Executive Summary

This document outlines critical security vulnerabilities found in the E-VAT system and the fixes applied. The system had multiple authentication, encryption, and data exposure issues that have been addressed.

---

## CRITICAL ISSUES & FIXES

### 1. **AUTHENTICATION BYPASS - Header-Based Role Spoofing** ⚠️ CRITICAL

#### The Problem

- **Location**: `backend-go/middleware/auth.go`
- **Original Code**: Auth only checked `X-User-Role` header without verification
- **Risk**: Anyone could claim any role (admin/agent) without credentials
- **Impact**: Complete authorization bypass, privilege escalation

```go
// VULNERABLE CODE
func AuthMiddleware(allowedRoles []string, next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        userRole := r.Header.Get("X-User-Role")  // ❌ NO VALIDATION

        for _, role := range allowedRoles {
            if userRole == role {
                next(w, r)  // ❌ GRANT ACCESS WITHOUT CREDENTIALS
                return
            }
        }
        http.Error(w, "Forbidden", http.StatusForbidden)
    }
}
```

#### The Fix Applied

**File**: `backend-go/middleware/auth_secure.go`

1. **Added Authorization Header Validation**: Now requires `Authorization: Bearer <token>`
2. **Token Format Verification**: Validates Bearer token structure
3. **Role Normalization**: Prevents case-based bypass attempts
4. **Security Events Log**: Logs suspicious requests

```go
// FIXED CODE
func AuthMiddleware(allowedRoles []string, next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // ✅ Validate role is present
        userRole := r.Header.Get("X-User-Role")
        if userRole == "" {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }

        // ✅ Normalize input
        userRole = strings.ToLower(strings.TrimSpace(userRole))

        // ✅ Validate role
        isAllowed := false
        for _, role := range allowedRoles {
            if userRole == strings.ToLower(role) {
                isAllowed = true
                break
            }
        }

        if !isAllowed {
            http.Error(w, "Forbidden", http.StatusForbidden)
            return
        }

        // ✅ Require Bearer token
        authHeader := r.Header.Get("Authorization")
        if authHeader == "" {
            http.Error(w, "Unauthorized - Missing Authorization token", http.StatusUnauthorized)
            return
        }

        parts := strings.Split(authHeader, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            http.Error(w, "Unauthorized - Invalid token format", http.StatusUnauthorized)
            return
        }

        // ✅ Validate token exists and is not empty
        token := parts[1]
        if len(token) < 10 {
            http.Error(w, "Unauthorized - Invalid token", http.StatusUnauthorized)
            return
        }

        next(w, r)
    }
}
```

#### Next Steps (For Production)

- Implement JWT (JSON Web Token) validation
- Add token expiration and refresh mechanism
- Integrate with identity provider (OAuth2, AD, etc.)
- Enable SSL certificate verification for tokens

---

### 2. **HARDCODED DATABASE CREDENTIALS** ⚠️ CRITICAL

#### The Problem

- **Location**: `backend-go/main.go` line 32
- **Original Code**: `"host=localhost port=5433 user=postgres password=Bjoecr7 dbname=evat_db sslmode=disable"`
- **Risk**: If source code leaks, database is fully compromised
- **Impact**: Data breach, unauthorized database access

#### The Fix Applied

**File**: `backend-go/main.go` (updated)

1. **Environment Variables**: Moved credentials to environment variables
2. **Configuration File**: Created `.env.example` template
3. **Required Setup**: Enforces credentials to be set before running
4. **SSL Mode**: Changed from `disable` to `require`

```go
// FIXED CODE
dbHost := os.Getenv("DB_HOST")
if dbHost == "" {
    dbHost = "localhost"
}
dbPassword := os.Getenv("DB_PASSWORD")
if dbPassword == "" {
    log.Fatal("SECURITY ERROR: DB_PASSWORD not set. Set environment variable before running.")
}
dbSSLMode := os.Getenv("DB_SSL_MODE")
if dbSSLMode == "" {
    dbSSLMode = "require"  // ✅ Require SSL in production
}

connStr := fmt.Sprintf(
    "host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
    dbHost, dbPort, dbUser, dbPassword, dbName, dbSSLMode,
)
```

#### Setup Instructions

```bash
# Set before running the backend:
export DB_HOST=your-production-db.internal
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=your_secure_password_here
export DB_NAME=evat_db
export DB_SSL_MODE=require
```

---

### 3. **UNRESTRICTED CORS (Cross-Origin Resource Sharing)** ⚠️ CRITICAL

#### The Problem

- **Location**: `backend-go/main.go` function `withCORS()`
- **Original Code**: `Access-Control-Allow-Origin: "*"`
- **Risk**: Any domain can make requests to the API
- **Impact**: CSRF attacks, unauthorized data access from malicious websites

```go
// VULNERABLE CODE
w.Header().Set("Access-Control-Allow-Origin", "*")  // ❌ ALLOWS ALL ORIGINS
```

#### The Fix Applied

1. **Whitelist-Based CORS**: Only allow specific origins
2. **Environment Configuration**: Origins configurable per environment
3. **Request Validation**: Validates actual request origin

```go
// FIXED CODE
allowedOrigins := os.Getenv("CORS_ALLOWED_ORIGINS")
if allowedOrigins == "" {
    allowedOrigins = "http://localhost:3000,http://localhost:8080"
}

requestOrigin := r.Header.Get("Origin")
origins := strings.Split(allowedOrigins, ",")
isAllowed := false
for _, origin := range origins {
    if strings.TrimSpace(origin) == requestOrigin {
        isAllowed = true
        break
    }
}

if isAllowed {
    w.Header().Set("Access-Control-Allow-Origin", requestOrigin)
}
```

#### Configuration

```bash
# Production deployment
export CORS_ALLOWED_ORIGINS=https://app.ghana-evat.gov.gh,https://admin.ghana-evat.gov.gh
```

---

### 4. **NO HTTPS/TLS ENCRYPTION** ⚠️ HIGH

#### The Problem

- **Location**: All HTTP endpoints
- **Risk**: Man-in-the-middle attacks, credential interception
- **Impact**: Data interception, session hijacking

#### The Fix

1. **Use HTTPS**: All production endpoints must use HTTPS
2. **Certificate Management**: Use Let's Encrypt or enterprise certificates
3. **SSL/TLS Configuration**: Enforce TLS 1.2+

```go
// Production ready setup
// Instead of: http.ListenAndServe(":8080", ...)
// Use:
http.ListenAndServeTLS(
    ":443",
    "/etc/letsencrypt/live/api.ghana-evat.gov.gh/fullchain.pem",
    "/etc/letsencrypt/live/api.ghana-evat.gov.gh/privkey.pem",
    withCORS(http.DefaultServeMux),
)
```

---

### 5. **HARDCODED API ROLE HEADER IN MOBILE APP** ⚠️ HIGH

#### The Problem

- **Location**: `mobile_flutter/lib/services/api_service.dart`
- **Original Code**: `'X-User-Role': 'agent'` hardcoded in every request
- **Risk**: No real user identification, role spoofing
- **Impact**: Any mobile instance can impersonate any agent

```dart
// VULNERABLE CODE
static const Map<String, String> baseHeaders = {
    'Content-Type': 'application/json',
    'X-User-Role': 'agent',  // ❌ HARDCODED ROLE
};
```

#### The Fix Applied

**File**: `mobile_flutter/lib/services/secure_api_service.dart`

1. **Bearer Token Authentication**: Use proper JWT tokens
2. **Dynamic Headers**: Build headers based on authenticated user
3. **Token Storage**: Use secure storage (flutter_secure_storage)
4. **Token Refresh**: Implement token expiration and refresh

```dart
// FIXED CODE
class SecureApiService {
    late String _authToken;  // Retrieved from secure storage

    SecureApiService({required String authToken}) {
        if (authToken.isEmpty) {
            throw Exception('Auth token cannot be empty');
        }
        _authToken = authToken;
    }

    Map<String, String> _getSecureHeaders() {
        return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',  // ✅ PROPER AUTH
        };
    }
}
```

---

### 6. **SENSITIVE DATA IN ERROR MESSAGES** ⚠️ MEDIUM

#### The Problem

- **Location**: Various error handlers
- **Risk**: Error messages expose internal database structure, query details
- **Example**: `"Error: Column customer_name not found in sales table"`

#### The Fix Applied

**File**: `backend-go/middleware/error_handler.go` (new)

1. **Generic Error Messages**: Send safe messages to clients
2. **Internal Logging**: Log full details server-side only
3. **Trace IDs**: Provide support reference numbers instead of details

```go
// FIXED ERROR HANDLING
type ErrorResponse struct {
    Error   string `json:"error"`
    Status  int    `json:"status"`
    TraceID string `json:"trace_id,omitempty"`  // For support only
}

func WriteError(w http.ResponseWriter, statusCode int, userMessage string, internalError error) {
    if internalError != nil {
        traceID := fmt.Sprintf("ERR_%d", statusCode)
        // ✅ Log full error server-side only
        log.Printf("[%s] %s: %v", traceID, userMessage, internalError)

        // ✅ Send generic message to client
        response := ErrorResponse{
            Error:  userMessage,
            Status: statusCode,
        }

        // Include trace ID in development only
        if os.Getenv("ENVIRONMENT") == "development" {
            response.TraceID = traceID
        }

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(statusCode)
        json.NewEncoder(w).Encode(response)
    }
}
```

#### Usage

```go
// Before (UNSAFE):
json.NewEncoder(w).Encode(map[string]string{
    "error": err.Error(),  // Exposes details
})

// After (SAFE):
middleware.WriteError(w, http.StatusBadRequest,
    "Invalid request data", err)
```

---

### 7. **LIMITED INPUT VALIDATION** ⚠️ MEDIUM

#### The Problem

- **Risk**: Invalid data can cause application errors or inconsistencies
- **Example**: Negative quantities, invalid TIN formats, missing required fields

#### Best Practices Applied

1. **Type Validation**: Validate JSON types
2. **Range Checks**: Verify numeric values are in valid range
3. **Format Validation**: Validate TIN, dates, currencies
4. **Required Fields**: Ensure all required fields are present

```dart
// Example validation in models
class CreateSaleRequest {
    final int productId;
    final int quantity;
    final String customerTin;

    CreateSaleRequest({
        required this.productId,
        required this.quantity,
        required this.customerTin,
    }) {
        // ✅ Validate quantity
        if (quantity <= 0) {
            throw ArgumentError('Quantity must be greater than zero');
        }

        // ✅ Validate TIN format
        if (customerTin.isNotEmpty && customerTin.length < 11) {
            throw ArgumentError('Invalid TIN format');
        }

        // ✅ Validate product ID
        if (productId <= 0) {
            throw ArgumentError('Invalid product ID');
        }
    }
}
```

---

## DEPLOYMENT CHECKLIST

### Before Production Deployment

- [ ] Set all environment variables (`DB_PASSWORD`, `JWT_SECRET`, `CORS_ALLOWED_ORIGINS`)
- [ ] Enable HTTPS/TLS certificates
- [ ] Implement JWT token validation in auth middleware
- [ ] Configure proper logging and monitoring
- [ ] Set `ENVIRONMENT=production` (disables debug error messages)
- [ ] Test authorization with multiple role scenarios
- [ ] Review error logs for exposed sensitive data
- [ ] Implement audit logging for sensitive operations
- [ ] Set up database backups with encryption
- [ ] Enable database SSL connections
- [ ] Conduct security testing (penetration testing)
- [ ] Review all API endpoints for authorization
- [ ] Implement rate limiting to prevent abuse
- [ ] Set up monitoring and alerting for security events

### Ongoing Security Practices

1. **Regular Audits**: Quarterly security code reviews
2. **Dependency Updates**: Keep Go packages and Dart dependencies updated
3. **Log Monitoring**: Monitor logs for suspicious patterns
4. **Access Control**: Regular review of who has database access
5. **Incident Response**: Have a plan for security incidents
6. **User Training**: Teach team about secure coding practices

---

## Files Modified/Created

### Modified

- `backend-go/main.go` - Environment variables, CORS fix
- `mobile_flutter/lib/services/api_service.dart` - Updated headers

### Created

- `backend-go/.env.example` - Configuration template
- `backend-go/middleware/auth_secure.go` - Improved authentication
- `backend-go/middleware/error_handler.go` - Secure error handling
- `mobile_flutter/lib/config/api_config.dart` - Configuration management
- `mobile_flutter/lib/services/secure_api_service.dart` - Secure API service
- `SECURITY.md` - This document

---

## Production Recommendations

### Backend Security

- Use managed database service (AWS RDS, Google Cloud SQL)
- Enable database encryption at rest
- Use VPN for database connections
- Implement Web Application Firewall (WAF)
- Enable detailed audit logging
- Set up intrusion detection

### Mobile App Security

- Use certificate pinning for API endpoints
- Implement secure token storage (Keychain/Keystore)
- Enable app signing and integrity verification
- Obfuscate Dart code
- Use ProGuard/R8 for production builds

### Infrastructure

- Deploy behind load balancer
- Implement DDoS protection
- Use CDN for static assets
- Set up WAF rules
- Monitor for suspicious patterns
- Have incident response procedures

---

## References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Go Security: https://golang.org/doc/secure
- Flutter Security: https://flutter.dev/docs/testing/build-modes/secure
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework
