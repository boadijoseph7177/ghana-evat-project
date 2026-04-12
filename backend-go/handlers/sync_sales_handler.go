package handlers

import (
	"encoding/json"
	"net/http"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/services"
)

type SyncSalesHandler struct {
	Service *services.SyncSalesService
}

func NewSyncSalesHandler(service *services.SyncSalesService) *SyncSalesHandler {
	return &SyncSalesHandler{Service: service}
}

func (h *SyncSalesHandler) SyncSales(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.SyncSalesRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	err = h.Service.SyncSales(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	response := models.SyncSalesResponse{
		Message: "pending sales synced successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
