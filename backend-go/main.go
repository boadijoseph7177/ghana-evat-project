package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type Invoice struct {
	InvoiceID string  `json:"invoice_id"`
	Amount    float64 `json:"amount"`
	VATRate   float64 `json:"vat_rate"`
	Customer  string  `json:"customer"`
}

func validateInvoice(inv Invoice) error {
	if inv.InvoiceID == "" {
		return fmt.Errorf("Invoice ID is required")
	}
	if inv.Amount <= 0 {
		return fmt.Errorf("Amount must be greater than zero")
	}

	return nil
}

func main() {

	http.HandleFunc("/invoice", createInvoice)

	fmt.Println("Server running on http://localhost:8080")
	http.ListenAndServe(":8080", nil)

}

func createInvoice(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var invoice Invoice

	err := json.NewDecoder(r.Body).Decode(&invoice)
	if err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	response, _ := json.Marshal(invoice)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	w.Write(response)
}
