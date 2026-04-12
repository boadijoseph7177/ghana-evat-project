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

type AllocationItemRecord struct {
	ID                int
	AllocationID      int
	ProductID         int
	AllocatedQuantity int
	RemainingQuantity int
}

func (r *AllocationRepository) GetActiveAllocationItemByAgentAndProduct(agentName string, productID int) (*AllocationItemRecord, error) {
	query := `
		SELECT aai.id, aai.allocation_id, aai.product_id, aai.allocated_quantity, aai.remaining_quantity
		FROM agent_allocation_items aai
		INNER JOIN agent_allocations aa ON aa.id = aai.allocation_id
		WHERE aa.agent_name = $1
		  AND aa.status = 'active'
		  AND aai.product_id = $2
		ORDER BY aa.created_at DESC, aai.id DESC
		LIMIT 1
	`

	var item AllocationItemRecord
	err := r.DB.QueryRow(query, agentName, productID).Scan(
		&item.ID,
		&item.AllocationID,
		&item.ProductID,
		&item.AllocatedQuantity,
		&item.RemainingQuantity,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("active allocation item not found for agent %s and product %d", agentName, productID)
		}
		return nil, err
	}

	return &item, nil
}

func (r *AllocationRepository) ReduceRemainingAllocationTx(tx *sql.Tx, agentName string, productID int, quantity int) error {
	result, err := tx.Exec(`
		UPDATE agent_allocation_items
		SET remaining_quantity = remaining_quantity - $1
		WHERE id = (
			SELECT aai.id
			FROM agent_allocation_items aai
			INNER JOIN agent_allocations aa ON aa.id = aai.allocation_id
			WHERE aa.agent_name = $2
			  AND aa.status = 'active'
			  AND aai.product_id = $3
			  AND aai.remaining_quantity >= $1
			ORDER BY aa.created_at DESC, aai.id DESC
			LIMIT 1
		)
	`, quantity, agentName, productID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("insufficient remaining allocation or allocation not found")
	}

	return nil
}
