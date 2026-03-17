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

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Backend is live")
	})

	http.HandleFunc("/production", productionHandler.RecordProduction)
	http.HandleFunc("/products", productionHandler.GetProducts)
	http.HandleFunc("/bulk-tanks", productionHandler.GetBulkTanks)

	fmt.Println("Backend running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
