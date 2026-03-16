package repositories

import (
	"database/sql"
	"fmt"
)

type ProductionRepository struct {
	DB *sql.DB
}

func NewProductionRepository(db *sql.DB) *ProductionRepository {
	return &ProductionRepository{DB: db}
}

func (r *ProductionRepository) ProcessProduction(
	tankID int,
	productID int,
	litersUsed float64,
	bottlesProduced int,
	variance float64,
	status string,
) error {
	tx, err := r.DB.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// 1. Reduce liters from bulk tank
	result, err := tx.Exec(`
		UPDATE bulk_tanks
		SET current_liters = current_liters - $1,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $2 AND current_liters >= $1
	`, litersUsed, tankID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return fmt.Errorf("tank not found or insufficient liters")
	}

	// 2. Increase finished product stock
	result, err = tx.Exec(`
		UPDATE products
		SET stock_quantity = stock_quantity + $1,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $2
	`, bottlesProduced, productID)
	if err != nil {
		return err
	}

	rowsAffected, err = result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return fmt.Errorf("product not found")
	}

	// 3. Insert production log
	_, err = tx.Exec(`
		INSERT INTO production_logs (
			tank_id,
			product_id,
			liters_used,
			bottles_produced,
			variance_percentage,
			status
		)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, tankID, productID, litersUsed, bottlesProduced, variance, status)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (r *ProductionRepository) GetProductByID(productID int) (float64, error) {
	var bottleSize float64

	err := r.DB.QueryRow(`
		SELECT bottle_size_liters
		FROM products
		WHERE id = $1
	`, productID).Scan(&bottleSize)

	if err != nil {
		if err == sql.ErrNoRows {
			return 0, fmt.Errorf("product not found")
		}
		return 0, err
	}

	return bottleSize, nil
}
