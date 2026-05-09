package middleware

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

// SECURITY FIX: Implement secure error handling
// Never expose internal error details to clients in production

type ErrorResponse struct {
	Error   string `json:"error"`
	Status  int    `json:"status"`
	TraceID string `json:"trace_id,omitempty"` // Optional: for support requests
}

// WriteError sends a safe error response to client
// In production, logs full error details server-side only
func WriteError(w http.ResponseWriter, statusCode int, userMessage string, internalError error) {
	if internalError != nil {
		// SECURITY: Log full error server-side only
		traceID := fmt.Sprintf("ERR_%d", statusCode)
		log.Printf("[%s] %s: %v", traceID, userMessage, internalError)

		// SECURITY: Send generic error to client, never expose internal details
		environ := os.Getenv("ENVIRONMENT")
		response := ErrorResponse{
			Error:  userMessage,
			Status: statusCode,
		}

		// Only include trace ID in development environment
		if environ == "development" {
			response.TraceID = traceID
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(statusCode)
		json.NewEncoder(w).Encode(response)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(ErrorResponse{
		Error:  userMessage,
		Status: statusCode,
	})
}
