package middleware

import "net/http"

const (
	RoleAdmin = "admin"
	RoleAgent = "agent"
)

func AuthMiddleware(requiredRole string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userRole := r.Header.Get("X-User_Role")

		// Admins can do everything: agents are restricted
		if userRole != requiredRole && userRole != RoleAdmin {
			http.Error(w, "Forbidden: You do not have permission to perform this action", http.StatusForbidden)
			return
		}
		next(w, r)
	}
}
