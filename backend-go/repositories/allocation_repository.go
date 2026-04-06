package repositories

import (
	"database/sql"
	"fmt"

	"evat-backend/backend-go/models"
)

type AllocationRepository struct {
	DB *sql.DB
}

func NewAllocationRepository(db *sql.DB) *AllocationRepository {
	return &AllocationRepository{DB: db}
}

func (r *AllocationRepository) CreateAllocation(req models.CreateAllocationRequest) error {
	tx, err := r.DB.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	var allocationID int
	err = tx.QueryRow(`
		INSERT INTO agent_allocations (agent_name, status)
		VALUES ($1, 'active')
		RETURNING id
	`, req.AgentName).Scan(&allocationID)
	if err != nil {
		return err
	}

	for _, item := range req.Items {
		_, err := tx.Exec(`
			INSERT INTO agent_allocation_items (
				allocation_id,
				product_id,
				allocated_quantity,
				remaining_quantity
			)
			VALUES ($1, $2, $3, $3)
		`, allocationID, item.ProductID, item.AllocatedQuantity)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func (r *AllocationRepository) GetActiveAllocationByAgent(agentName string) (models.AgentAllocation, error) {
	var allocation models.AgentAllocation

	err := r.DB.QueryRow(`
		SELECT id, agent_name, status
		FROM agent_allocations
		WHERE agent_name = $1 AND status = 'active'
		ORDER BY created_at DESC
		LIMIT 1
	`, agentName).Scan(
		&allocation.ID,
		&allocation.AgentName,
		&allocation.Status,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return allocation, fmt.Errorf("no active allocation found for agent")
		}
		return allocation, err
	}

	rows, err := r.DB.Query(`
		SELECT id, product_id, allocated_quantity, remaining_quantity
		FROM agent_allocation_items
		WHERE allocation_id = $1
		ORDER BY id
	`, allocation.ID)
	if err != nil {
		return allocation, err
	}
	defer rows.Close()

	var items []models.AgentAllocationItem

	for rows.Next() {
		var item models.AgentAllocationItem
		err := rows.Scan(
			&item.ID,
			&item.ProductID,
			&item.AllocatedQuantity,
			&item.RemainingQuantity,
		)
		if err != nil {
			return allocation, err
		}
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return allocation, err
	}

	allocation.Items = items
	return allocation, nil
}
