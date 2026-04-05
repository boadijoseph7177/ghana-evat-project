package main

import (
	"fmt"
	"log"
	"net/http"

	"evat-backend/backend-go/db"
	"evat-backend/backend-go/handlers"
	"evat-backend/backend-go/middleware"
	"evat-backend/backend-go/repositories"
	"evat-backend/backend-go/services"
)

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-User-Role")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

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

	// Production routes: admin only
	http.HandleFunc(
		"/production",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin}, productionHandler.RecordProduction),
	)

	http.HandleFunc(
		"/production-logs",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin}, productionHandler.GetProductionLogs),
	)

	// Inventory read routes
	http.HandleFunc(
		"/products",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin, middleware.RoleAgent}, productionHandler.GetProducts),
	)

	http.HandleFunc(
		"/bulk-tanks",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin}, productionHandler.GetBulkTanks),
	)

	// Sales routes
	http.HandleFunc("/sales", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			middleware.AuthMiddleware(
				[]string{middleware.RoleAdmin, middleware.RoleAgent},
				salesHandler.RecordSale,
			)(w, r)
			return
		}

		if r.Method == http.MethodGet {
			middleware.AuthMiddleware(
				[]string{middleware.RoleAdmin},
				salesHandler.GetSales,
			)(w, r)
			return
		}

		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	})

	// VAT summary: admin only
	http.HandleFunc(
		"/vat-summary",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin}, salesHandler.GetVATSummary),
	)

	// Dashboard summary: admin only
	http.HandleFunc(
		"/dashboard-summary",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin}, salesHandler.GetDashboardSummary),
	)

	fmt.Println("Backend running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", withCORS(http.DefaultServeMux)))
}
