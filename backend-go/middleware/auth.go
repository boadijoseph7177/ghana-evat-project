package middleware

import "net/http"

const (
	RoleAdmin = "admin"
	RoleAgent = "agent"
)

func AuthMiddleware(allowedRoles []string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userRole := r.Header.Get("X-User-Role")

		for _, role := range allowedRoles {
			if userRole == role {
				next(w, r)
				return
			}
		}

		http.Error(w, "Forbidden", http.StatusForbidden)
	}
}
