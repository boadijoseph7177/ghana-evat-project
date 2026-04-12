package services

import (
	"database/sql"
	"fmt"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/repositories"
)

type SyncSalesService struct {
	DB             *sql.DB
	SalesRepo      *repositories.SalesRepository
	AllocationRepo *repositories.AllocationRepository
}

func NewSyncSalesService(
	db *sql.DB,
	salesRepo *repositories.SalesRepository,
	allocationRepo *repositories.AllocationRepository,
) *SyncSalesService {
	return &SyncSalesService{
		DB:             db,
		SalesRepo:      salesRepo,
		AllocationRepo: allocationRepo,
	}
}

func (s *SyncSalesService) SyncSales(req models.SyncSalesRequest) error {
	if req.AgentName == "" {
		return fmt.Errorf("agent_name is required")
	}

	if len(req.Sales) == 0 {
		return fmt.Errorf("no sales provided")
	}

	for _, sale := range req.Sales {
		err := s.syncSingleSale(req.AgentName, sale)
		if err != nil {
			return err
		}
	}

	return nil
}

func (s *SyncSalesService) syncSingleSale(agentName string, sale models.SyncSaleItemRequest) error {
	if sale.OfflineSaleID == "" {
		return fmt.Errorf("offline_sale_id is required")
	}

	if sale.Quantity <= 0 {
		return fmt.Errorf("quantity must be greater than zero")
	}

	exists, err := s.SalesRepo.OfflineSaleExists(sale.OfflineSaleID)
	if err != nil {
		return err
	}

	// If already synced before, just skip it
	if exists {
		return nil
	}

	allocationItem, err := s.AllocationRepo.GetActiveAllocationItemByAgentAndProduct(agentName, sale.ProductID)
	if err != nil {
		return err
	}

	if allocationItem.RemainingQuantity < sale.Quantity {
		return fmt.Errorf("insufficient remaining allocation for product %d", sale.ProductID)
	}

	unitPrice, _, err := s.SalesRepo.GetProductForSale(sale.ProductID)
	if err != nil {
		return err
	}

	totalAmount := float64(sale.Quantity) * unitPrice
	vatAmount := totalAmount * 0.15
	nhilAmount := totalAmount * 0.025
	getfundAmount := totalAmount * 0.025
	totalWithTax := totalAmount + vatAmount + nhilAmount + getfundAmount

	tx, err := s.DB.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

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
			customer_name,
			customer_tin,
			offline_sale_id
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
	`,
		sale.ProductID,
		sale.Quantity,
		unitPrice,
		totalAmount,
		vatAmount,
		nhilAmount,
		getfundAmount,
		totalWithTax,
		sale.CustomerName,
		sale.CustomerTIN,
		sale.OfflineSaleID,
	)
	if err != nil {
		return err
	}

	err = s.AllocationRepo.ReduceRemainingAllocationTx(
		tx,
		agentName,
		sale.ProductID,
		sale.Quantity,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
}
