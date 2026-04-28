package repositories

import (
	"database/sql"
	"fmt"

	"evat-backend/backend-go/models"
)

type SalesRepository struct {
	DB *sql.DB
}

func NewSalesRepository(db *sql.DB) *SalesRepository {
	return &SalesRepository{DB: db}
}

func (r *SalesRepository) OfflineSaleExists(offlineSaleID string) (bool, error) {
	var exists bool

	query := `
		SELECT EXISTS(
			SELECT 1 FROM sales WHERE offline_sale_id = $1
		)
	`

	err := r.DB.QueryRow(query, offlineSaleID).Scan(&exists)
	if err != nil {
		return false, err
	}

	return exists, nil
}

func (r *SalesRepository) GetProductForSale(productID int) (float64, int, error) {
	var unitPrice float64
	var stockQuantity int

	err := r.DB.QueryRow(`
		SELECT unit_price, stock_quantity
		FROM products
		WHERE id = $1
	`, productID).Scan(&unitPrice, &stockQuantity)

	if err != nil {
		if err == sql.ErrNoRows {
			return 0, 0, fmt.Errorf("product not found")
		}
		return 0, 0, err
	}

	return unitPrice, stockQuantity, nil
}

func (r *SalesRepository) ProcessSale(
	productID int,
	quantity int,
	customerName string,
	unitPrice float64,
	totalAmount float64,
	vatAmount float64,
	nhilAmount float64,
	getfundAmount float64,
	totalWithTax float64,
) error {
	tx, err := r.DB.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	result, err := tx.Exec(`
		UPDATE products
		SET stock_quantity = stock_quantity - $1,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $2 AND stock_quantity >= $1
	`, quantity, productID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return fmt.Errorf("product not found or insufficient stock")
	}

	_, err = tx.Exec(`
		INSERT INTO sales (
			product_id,
			quantity,
			unit_price,
			total_amount,
			vat_amount,
			nhil_amount,
			getfund_amount,
			total_with_tax,
			customer_name
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`,
		productID,
		quantity,
		unitPrice,
		totalAmount,
		vatAmount,
		nhilAmount,
		getfundAmount,
		totalWithTax,
		customerName,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (r *SalesRepository) GetAllSales() ([]models.SaleRecord, error) {
	rows, err := r.DB.Query(`
		SELECT 
			s.id,
			s.product_id,
			p.name,
			s.quantity,
			s.unit_price,
			s.total_amount,
			s.vat_amount,
			s.nhil_amount,
			s.getfund_amount,
			s.total_with_tax,
			s.customer_name,
			s.created_at,
			s.sdc_id,
			s.qr_code
		FROM sales s
		INNER JOIN products p ON s.product_id = p.id
		ORDER BY s.created_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sales []models.SaleRecord

	for rows.Next() {
		var s models.SaleRecord
		err := rows.Scan(
			&s.ID,
			&s.ProductID,
			&s.ProductName,
			&s.Quantity,
			&s.UnitPrice,
			&s.TotalAmount,
			&s.VATAmount,
			&s.NHILAmount,
			&s.GETFundAmount,
			&s.TotalWithTax,
			&s.CustomerName,
			&s.CreatedAt,
			&s.SDCID,
			&s.QRCode,
		)
		if err != nil {
			return nil, err
		}
		sales = append(sales, s)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return sales, nil
}
func (r *SalesRepository) GetVATSummary() (models.VATSummary, error) {
	var summary models.VATSummary

	err := r.DB.QueryRow(`
		SELECT
			COALESCE(SUM(total_amount), 0),
			COALESCE(SUM(vat_amount), 0),
			COALESCE(SUM(nhil_amount), 0),
			COALESCE(SUM(getfund_amount), 0),
			COALESCE(SUM(total_with_tax), 0)
		FROM sales
	`).Scan(
		&summary.TotalSales,
		&summary.TotalVAT,
		&summary.TotalNHIL,
		&summary.TotalGETFund,
		&summary.TotalWithTax,
	)
	if err != nil {
		return summary, err
	}

	return summary, nil
}

func (r *SalesRepository) GetDashboardSummary() (models.DashboardSummary, error) {
	var summary models.DashboardSummary

	err := r.DB.QueryRow(`
		SELECT
			(SELECT COUNT(*) FROM products),
			(SELECT COALESCE(SUM(stock_quantity), 0) FROM products),
			(SELECT COUNT(*) FROM sales),
			(SELECT COALESCE(SUM(total_amount), 0) FROM sales),
			(SELECT COALESCE(SUM(vat_amount), 0) FROM sales),
			(SELECT COUNT(*) FROM production_logs WHERE status = 'warning')
	`).Scan(
		&summary.TotalProducts,
		&summary.TotalStockUnits,
		&summary.TotalSalesCount,
		&summary.TotalSalesAmount,
		&summary.TotalVAT,
		&summary.ProductionWarningsCount,
	)

	if err != nil {
		return summary, err
	}

	return summary, nil
}
