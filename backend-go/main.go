package main

import (
	"fmt"
	"log"
	"net/http"

	"evat-backend/backend-go/db"
	"evat-backend/backend-go/handlers"
	"evat-backend/backend-go/repositories"
	"evat-backend/backend-go/services"
)

func main() {
	connStr := "host=localhost port=5433 user=postgres password=Bjoecr7 dbname=evat_db sslmode=disable"

	dbConn, err := db.InitDB(connStr)
	if err != nil {
		log.Fatal("database connection failed:", err)
	}

	productionRepo := repositories.NewProductionRepository(dbConn)
	productionService := services.NewProductionService(productionRepo)
	productionHandler := handlers.NewProductionHandler(productionService)
	salesRepo := repositories.NewSalesRepository(dbConn)
	salesService := services.NewSalesService(salesRepo)
	salesHandler := handlers.NewSalesHandler(salesService)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Backend is live")
	})

	http.HandleFunc("/production", productionHandler.RecordProduction)
	http.HandleFunc("/products", productionHandler.GetProducts)
	http.HandleFunc("/bulk-tanks", productionHandler.GetBulkTanks)

	http.HandleFunc("/sales", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			salesHandler.RecordSale(w, r)
			return
		}
		if r.Method == http.MethodGet {
			salesHandler.GetSales(w, r)
			return
		}
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	})

	http.HandleFunc("/vat-summary", salesHandler.GetVATSummary)

	fmt.Println("Backend running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
