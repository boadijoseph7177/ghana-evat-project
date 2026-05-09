package models

type AllocationItemInput struct {
	ProductID         int `json:"product_id"`
	AllocatedQuantity int `json:"allocated_quantity"`
}

type CreateAllocationRequest struct {
	AgentName string                `json:"agent_name"`
	Items     []AllocationItemInput `json:"items"`
}

type AgentAllocation struct {
	ID        int                   `json:"id"`
	AgentName string                `json:"agent_name"`
	Status    string                `json:"status"`
	Items     []AgentAllocationItem `json:"items"`
}

type AgentAllocationItem struct {
	ID                int     `json:"id"`
	ProductID         int     `json:"product_id"`
	ProductName       string  `json:"product_name"`
	BottleSizeLiters  float64 `json:"bottle_size_liters"`
	UnitPrice         float64 `json:"unit_price"`
	AllocatedQuantity int     `json:"allocated_quantity"`
	RemainingQuantity int     `json:"remaining_quantity"`
}
