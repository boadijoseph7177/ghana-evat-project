package services

import (
	"fmt"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/repositories"
)

type AllocationService struct {
	Repo *repositories.AllocationRepository
}

func NewAllocationService(repo *repositories.AllocationRepository) *AllocationService {
	return &AllocationService{Repo: repo}
}

func (s *AllocationService) CreateAllocation(req models.CreateAllocationRequest) error {
	if req.AgentName == "" {
		return fmt.Errorf("agent_name is required")
	}

	if len(req.Items) == 0 {
		return fmt.Errorf("at least one allocation item is required")
	}

	for _, item := range req.Items {
		if item.ProductID <= 0 {
			return fmt.Errorf("invalid product_id")
		}
		if item.AllocatedQuantity <= 0 {
			return fmt.Errorf("allocated_quantity must be greater than 0")
		}
	}

	return s.Repo.CreateAllocation(req)
}

func (s *AllocationService) GetActiveAllocation(agentName string) (models.AgentAllocation, error) {
	if agentName == "" {
		return models.AgentAllocation{}, fmt.Errorf("agent_name is required")
	}

	return s.Repo.GetActiveAllocationByAgent(agentName)
}
