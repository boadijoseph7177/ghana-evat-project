package models

// Product represents 1L or 5L bottles
type Product struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`  // e.g., "Edible Gold 1L"
	Stock     int     `json:"stock"` // Current units on hand
	UnitPrice float64 `json:"unit_price"`
}

// BulkTank represents the raw oil before bottling
type BulkTank struct {
	ID            string  `json:"id"`
	CurrentLiters float64 `json:"current_liters"`
}
