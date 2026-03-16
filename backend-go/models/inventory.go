package models

type BulkTank struct {
	ID            int     `json:"id"`
	Name          string  `json:"name"`
	CurrentLiters float64 `json:"current_liters"`
}

type Product struct {
	ID               int     `json:"id"`
	Name             string  `json:"name"`
	BottleSizeLiters float64 `json:"bottle_size_liters"`
	StockQuantity    int     `json:"stock_quantity"`
	UnitPrice        float64 `json:"unit_price"`
}

type ProductionLog struct {
	ID                 int     `json:"id"`
	TankID             int     `json:"tank_id"`
	ProductID          int     `json:"product_id"`
	LitersUsed         float64 `json:"liters_used"`
	BottlesProduced    int     `json:"bottles_produced"`
	VariancePercentage float64 `json:"variance_percentage"`
	Status             string  `json:"status"`
}

type CreateProductionRequest struct {
	TankID          int     `json:"tank_id"`
	ProductID       int     `json:"product_id"`
	LitersUsed      float64 `json:"liters_used"`
	BottlesProduced int     `json:"bottles_produced"`
}
