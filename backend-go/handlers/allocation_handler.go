package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/services"
)

type AllocationHandler struct {
	Service *services.AllocationService
}

func NewAllocationHandler(service *services.AllocationService) *AllocationHandler {
	return &AllocationHandler{Service: service}
}

func (h *AllocationHandler) CreateAllocation(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.CreateAllocationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	if err := h.Service.CreateAllocation(req); err != nil {
		http.Error(w, fmt.Sprintf("failed to create allocation: %v", err), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]string{"status": "allocation created"})
}

func (h *AllocationHandler) GetAllocation(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	agentName := r.URL.Query().Get("agent_name")
	allocation, err := h.Service.GetActiveAllocation(agentName)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to get allocation: %v", err), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(allocation); err != nil {
		http.Error(w, "failed to encode response", http.StatusInternalServerError)
	}
}
