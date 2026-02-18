package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"sync"
	"time"
)

// The "Contract" sent by Main Backend
type InvoiceRequest struct {
	InvoiceID   string  `json:"invoice_id"`
	BaseAmount  float64 `json:"base_amount"`
	CustomerTIN string  `json:"customer_tin"`
}

// The "Official" response from the Mock GRA
type InvoiceResponse struct {
	InvoiceID     string  `json:"invoice_id"`
	VATAmount     float64 `json:"vat_amount"`     // 15%
	NHILAmount    float64 `json:"nhil_amount"`    // 2.5%
	GETFundAmount float64 `json:"getfund_amount"` // 2.5%
	TotalWithTax  float64 `json:"total_with_tax"`
	SDCID         string  `json:"sdc_id"`
	QRCode        string  `json:"qr_code"`
}

var (
	issuedInvoices = make(map[string]InvoiceResponse)
	mu             sync.Mutex
)

func main() {

	time.Now().UnixNano()

	http.HandleFunc("/issue-invoice", createInvoice)

	fmt.Println("GRA Mock Service active on http://localhost:8081")
	http.ListenAndServe(":8081", nil)
}

func validateGRAInvoice(req InvoiceRequest) error {
	// 1. Basic empty checks
	if req.InvoiceID == "" {
		return fmt.Errorf("missing local invoice reference")
	}

	// 2. Business Logic: Amount check
	if req.BaseAmount <= 0 {
		return fmt.Errorf("invalid base amount: must be greater than 0")
	}

	// 3. Ghanaian Compliance: TIN format check
	// Simple mock check: Ghana TINs are usually 11-13 characters
	if len(req.CustomerTIN) < 11 && req.CustomerTIN != "" {
		return fmt.Errorf("invalid Customer TIN format")
	}

	return nil
}

func createInvoice(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	var req InvoiceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid Payload", http.StatusBadRequest)
		return
	}

	if err := validateGRAInvoice(req); err != nil {
		w.WriteHeader(http.StatusUnprocessableEntity)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	mu.Lock()
	// UNLOCK happens when the function finishes
	defer mu.Unlock()

	// IDENTITY CHECK (thread-safe)
	if existing, found := issuedInvoices[req.InvoiceID]; found {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(existing)
		return
	}

	// Tax Logic
	vat := req.BaseAmount * 0.15
	nhil := req.BaseAmount * 0.025
	getfund := req.BaseAmount * 0.025
	total := req.BaseAmount + vat + nhil + getfund

	sdc := generateSDCID()

	res := InvoiceResponse{
		InvoiceID:     req.InvoiceID,
		VATAmount:     vat,
		NHILAmount:    nhil,
		GETFundAmount: getfund,
		TotalWithTax:  total,
		SDCID:         sdc,
		QRCode:        fmt.Sprintf("https://gra.gov.gh/verify/%s", sdc),
	}

	// store invoice
	issuedInvoices[req.InvoiceID] = res

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(res)
}

func generateSDCID() string {
	// 16-digit style signature

	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	result := make([]byte, 16)
	for i := range result {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}
