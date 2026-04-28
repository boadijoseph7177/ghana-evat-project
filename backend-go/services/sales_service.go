//This service layer acts like a manager, calculates the taxes, checks the math, and ensures
//the rules of the business are followed before any money changes hands

package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
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

func (s *SalesService) issueInvoiceWithMockGRA(req models.GRAIssueInvoiceRequest) (models.GRAIssueInvoiceResponse, error) {
	var graRes models.GRAIssueInvoiceResponse

	jsonData, err := json.Marshal(req)
	if err != nil {
		return graRes, err
	}

	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	resp, err := client.Post(
		"http://localhost:8081/issue-invoice",
		"application/json",
		bytes.NewBuffer(jsonData),
	)
	if err != nil {
		return graRes, fmt.Errorf("failed to call mock GRA API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return graRes, fmt.Errorf("mock GRA API returned status %d", resp.StatusCode)
	}

	err = json.NewDecoder(resp.Body).Decode(&graRes)
	if err != nil {
		return graRes, err
	}

	return graRes, nil
}

func (s *SalesService) RecordSale(req models.CreateSaleRequest) (models.SaleResponse, error) {
	if req.ProductID <= 0 {
		return models.SaleResponse{}, fmt.Errorf("invalid product_id")
	}
	if req.Quantity <= 0 {
		return models.SaleResponse{}, fmt.Errorf("quantity must be greater than 0")
	}

	unitPrice, stockQuantity, err := s.Repo.GetProductForSale(req.ProductID)
	if err != nil {
		return models.SaleResponse{}, err
	}

	if stockQuantity < req.Quantity {
		return models.SaleResponse{}, fmt.Errorf("insufficient stock")
	}

	totalAmount := float64(req.Quantity) * unitPrice

	graReq := models.GRAIssueInvoiceRequest{
		InvoiceID:   fmt.Sprintf("SALE-%d-%d", req.ProductID, time.Now().Unix()),
		BaseAmount:  totalAmount,
		CustomerTIN: req.CustomerTIN,
	}

	graRes, err := s.issueInvoiceWithMockGRA(graReq)
	if err != nil {
		return models.SaleResponse{}, err
	}

	err = s.Repo.ProcessSale(
		req.ProductID,
		req.Quantity,
		req.CustomerName,
		req.CustomerTIN,
		unitPrice,
		totalAmount,
		graRes.VATAmount,
		graRes.NHILAmount,
		graRes.GETFundAmount,
		graRes.TotalWithTax,
		graRes.SDCID,
		graRes.QRCode,
	)
	if err != nil {
		return models.SaleResponse{}, err
	}

	return models.SaleResponse{
		Message:       "sale completed successfully",
		ProductID:     req.ProductID,
		Quantity:      req.Quantity,
		UnitPrice:     unitPrice,
		TotalAmount:   totalAmount,
		VATAmount:     graRes.VATAmount,
		NHILAmount:    graRes.NHILAmount,
		GETFundAmount: graRes.GETFundAmount,
		TotalWithTax:  graRes.TotalWithTax,
		CustomerName:  req.CustomerName,
		CustomerTIN:   req.CustomerTIN,
		SDCID:         graRes.SDCID,
		QRCode:        graRes.QRCode,
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

func (s *SalesService) GetDashboardSummary() (models.DashboardSummary, error) {
	return s.Repo.GetDashboardSummary()
}
