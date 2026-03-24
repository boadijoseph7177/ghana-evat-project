package services

import (
	"fmt"

	"evat-backend/backend-go/models"
	"evat-backend/backend-go/repositories"
)

type ProductionService struct {
	Repo *repositories.ProductionRepository
}

func NewProductionService(repo *repositories.ProductionRepository) *ProductionService {
	return &ProductionService{Repo: repo}
}

func (s *ProductionService) RecordProduction(req models.CreateProductionRequest) (float64, string, error) {
	if req.TankID <= 0 {
		return 0, "", fmt.Errorf("invalid tank_id")
	}
	if req.ProductID <= 0 {
		return 0, "", fmt.Errorf("invalid product_id")
	}
	if req.LitersUsed <= 0 {
		return 0, "", fmt.Errorf("liters_used must be greater than 0")
	}
	if req.BottlesProduced <= 0 {
		return 0, "", fmt.Errorf("bottles_produced must be greater than 0")
	}

	bottleSizeLiters, err := s.Repo.GetProductByID(req.ProductID)
	if err != nil {
		return 0, "", err
	}

	expectedLiters := float64(req.BottlesProduced) * bottleSizeLiters
	variance := ((req.LitersUsed - expectedLiters) / req.LitersUsed) * 100

	status := "within_threshold"
	if variance > 0.5 || variance < -0.5 {
		status = "warning"
	}

	err = s.Repo.ProcessProduction(
		req.TankID,
		req.ProductID,
		req.LitersUsed,
		req.BottlesProduced,
		variance,
		status,
	)
	if err != nil {
		return 0, "", err
	}

	return variance, status, nil
}

func (s *ProductionService) GetProducts() ([]models.Product, error) {
	return s.Repo.GetAllProducts()
}

func (s *ProductionService) GetBulkTanks() ([]models.BulkTank, error) {
	return s.Repo.GetAllBulkTanks()
}

func (s *ProductionService) GetProductionLogs() ([]models.ProductionLog, error) {
	return s.Repo.GetAllProductionLogs()
}
