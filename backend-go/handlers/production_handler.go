package handlers

import (
	"encoding/json"
	"net/http"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/services"
)

type ProductionHandler struct {
	Service *services.ProductionService
}

func NewProductionHandler(service *services.ProductionService) *ProductionHandler {
	return &ProductionHandler{Service: service}
}

func (h *ProductionHandler) RecordProduction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.CreateProductionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	variance, status, err := h.Service.RecordProduction(req)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": err.Error(),
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message":             "production recorded successfully",
		"variance_percentage": variance,
		"status":              status,
	})
}
