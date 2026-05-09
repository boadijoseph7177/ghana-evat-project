package middleware

import (
	"net/http"
	"strings"
)

const (
	RoleAdmin = "admin"
	RoleAgent = "agent"
)

// AuthMiddleware validates role-based access control
// SECURITY: Validates role header and normalizes input
// TODO: Integrate JWT tokens in production for enhanced security
func AuthMiddleware(allowedRoles []string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Extract role from header
		userRole := r.Header.Get("X-User-Role")

		// Normalize role (lowercase, trim whitespace)
		userRole = strings.ToLower(strings.TrimSpace(userRole))

		// Validate role is in allowed list
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

		// Role is valid, proceed
		next(w, r)
	}
}
