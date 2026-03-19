//This service layer acts like a manager, calculates the taxes, checks the math, and ensures
//the rules of the business are followed before any money changes hands

package services

import (
	"fmt"
	"math/rand"
	"time"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/repositories"
)

// defines what SalesService is and what it has
type SalesService struct {
	Repo *repositories.SalesRepository
}

func NewSalesService(repo *repositories.SalesRepository) *SalesService {
	return &SalesService{Repo: repo}
}

func (s *SalesService) RecordSale(req models.CreateSaleRequest) (models.SaleResponse, error) {
	if req.ProductID <= 0 {
		return models.SaleResponse{}, fmt.Errorf("invalid product_id")
	}
	if req.Quantity <= 0 {
		return models.SaleResponse{}, fmt.Errorf("quantity must be greater than 0")
	}

	//pre-sale inventory check...price and stock
	unitPrice, stockQuantity, err := s.Repo.GetProductForSale(req.ProductID)
	if err != nil {
		return models.SaleResponse{}, err
	}

	if stockQuantity < req.Quantity {
		return models.SaleResponse{}, fmt.Errorf("insufficient stock")
	}

	//E-VAT math
	totalAmount := float64(req.Quantity) * unitPrice
	vatAmount := totalAmount * 0.15
	nhilAmount := totalAmount * 0.025
	getfundAmount := totalAmount * 0.025
	totalWithTax := totalAmount + vatAmount + nhilAmount + getfundAmount

	err = s.Repo.ProcessSale(
		req.ProductID,
		req.Quantity,
		req.CustomerName,
		unitPrice,
		totalAmount,
		vatAmount,
		nhilAmount,
		getfundAmount,
		totalWithTax,
	)
	if err != nil {
		return models.SaleResponse{}, err
	}

	time.Now().UnixNano()

	sdcID := generateSDCID()

	return models.SaleResponse{
		Message:       "sale completed successfully",
		ProductID:     req.ProductID,
		Quantity:      req.Quantity,
		UnitPrice:     unitPrice,
		TotalAmount:   totalAmount,
		VATAmount:     vatAmount,
		NHILAmount:    nhilAmount,
		GETFundAmount: getfundAmount,
		TotalWithTax:  totalWithTax,
		CustomerName:  req.CustomerName,
		SDCID:         sdcID,
		QRCode:        fmt.Sprintf("https://gra.gov.gh/verify/%s", sdcID),
	}, nil
}

func (s *SalesService) GetSales() ([]models.SaleRecord, error) {
	return s.Repo.GetAllSales()
}

func generateSDCID() string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	result := make([]byte, 16)
	for i := range result {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}

func (s *SalesService) GetVATSummary() (models.VATSummary, error) {
	return s.Repo.GetVATSummary()
}
