package models

import "time"

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
	SDCID         string  `json:"sdc_id"`
	QRCode        string  `json:"qr_code"`
}

type SaleRecord struct {
	ID            int       `json:"id"`
	ProductID     int       `json:"product_id"`
	Quantity      int       `json:"quantity"`
	UnitPrice     float64   `json:"unit_price"`
	TotalAmount   float64   `json:"total_amount"`
	VATAmount     float64   `json:"vat_amount"`
	NHILAmount    float64   `json:"nhil_amount"`
	GETFundAmount float64   `json:"getfund_amount"`
	TotalWithTax  float64   `json:"total_with_tax"`
	CustomerName  string    `json:"customer_name"`
	CreatedAt     time.Time `json:"created_at"`
}

type VATSummary struct {
	TotalSales   float64 `json:"total_sales"`
	TotalVAT     float64 `json:"total_vat"`
	TotalNHIL    float64 `json:"total_nhil"`
	TotalGETFund float64 `json:"total_getfund"`
	TotalWithTax float64 `json:"total_with_tax"`
}
