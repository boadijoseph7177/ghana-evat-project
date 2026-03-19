package models

type CreateSaleRequest struct {
	ProductID    int    `json:"product_id"`
	Quantity     int    `json:"quantity"`
	CustomerName string `json:"customer_name"`
}

type SaleResponse struct {
	Message       string  `json:"message"`
	ProductID     int     `json:"product_id"`
	Quantity      int     `json:"quantity"`
	UnitPrice     float64 `json:"unit_price"`
	TotalAmount   float64 `json:"total_amount"`
	VATAmount     float64 `json:"vat_amount"`
	NHILAmount    float64 `json:"nhil_amount"`
	GETFundAmount float64 `json:"getfund_amount"`
	TotalWithTax  float64 `json:"total_with_tax"`
	CustomerName  string  `json:"customer_name"`
}
