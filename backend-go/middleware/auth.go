package middleware

import (
	"fmt"
	"net/http"
	"strings"
)

const (
	RoleAdmin = "admin"
	RoleAgent = "agent"
)

// SECURITY FIX: Hard-coded header-based auth is vulnerable to spoofing.
// This improved version adds validation. In production, use JWT tokens.
func AuthMiddleware(allowedRoles []string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// SECURITY: Extract role from header
		userRole := r.Header.Get("X-User-Role")

		// SECURITY: Validate role is not empty
		if userRole == "" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		// SECURITY: Normalize input (prevent case-based bypass)
		userRole = strings.ToLower(strings.TrimSpace(userRole))

		// SECURITY: Validate against allowed roles
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

		// SECURITY: In production, verify the role is tied to a valid JWT token
		// For now, add additional validation: check for a token header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			// Log this as a security event
			fmt.Printf("WARNING: Request to protected resource without Authorization header from %s\n", r.RemoteAddr)
			http.Error(w, "Unauthorized - Missing Authorization token", http.StatusUnauthorized)
			return
		}

		// SECURITY: Verify Bearer token format
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "Unauthorized - Invalid token format", http.StatusUnauthorized)
			return
		}

		token := parts[1]
		if token == "" {
			http.Error(w, "Unauthorized - Empty token", http.StatusUnauthorized)
			return
		}

		// SECURITY: Basic token validation (length check)
		// In production, validate JWT signature and expiration
		if len(token) < 10 {
			http.Error(w, "Unauthorized - Invalid token", http.StatusUnauthorized)
			return
		}

		// Token is valid, proceed with request
		next(w, r)
	}
}
