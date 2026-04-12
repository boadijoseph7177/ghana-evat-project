package models

import "time"

type CreateSaleRequest struct {
	ProductID    int    `json:"product_id"`
	Quantity     int    `json:"quantity"`
	CustomerName string `json:"customer_name"`
	CustomerTIN  string `json:"customer_tin"`
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
	CustomerTIN   string  `json:"customer_tin"`
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

type GRAIssueInvoiceRequest struct {
	InvoiceID   string  `json:"invoice_id"`
	BaseAmount  float64 `json:"base_amount"`
	CustomerTIN string  `json:"customer_tin"`
}

type GRAIssueInvoiceResponse struct {
	InvoiceID     string  `json:"invoice_id"`
	VATAmount     float64 `json:"vat_amount"`
	NHILAmount    float64 `json:"nhil_amount"`
	GETFundAmount float64 `json:"getfund_amount"`
	TotalWithTax  float64 `json:"total_with_tax"`
	SDCID         string  `json:"sdc_id"`
	QRCode        string  `json:"qr_code"`
}

type DashboardSummary struct {
	TotalProducts           int     `json:"total_products"`
	TotalStockUnits         int     `json:"total_stock_units"`
	TotalSalesCount         int     `json:"total_sales_count"`
	TotalSalesAmount        float64 `json:"total_sales_amount"`
	TotalVAT                float64 `json:"total_vat"`
	ProductionWarningsCount int     `json:"production_warnings_count"`
}

type SyncSaleItemRequest struct {
	OfflineSaleID string `json:"offline_sale_id"`
	ProductID     int    `json:"product_id"`
	Quantity      int    `json:"quantity"`
	CustomerName  string `json:"customer_name"`
	CustomerTIN   string `json:"customer_tin"`
}

type SyncSalesRequest struct {
	AgentName string                `json:"agent_name"`
	Sales     []SyncSaleItemRequest `json:"sales"`
}

type SyncSalesResponse struct {
	Message string `json:"message"`
}
