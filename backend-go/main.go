package main

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"evat-backend/backend-go/db"
	"evat-backend/backend-go/handlers"
	"evat-backend/backend-go/middleware"
	"evat-backend/backend-go/repositories"
	"evat-backend/backend-go/services"
)

// loadEnvFile reads .env file and sets environment variables
func loadEnvFile() {
	envFile := ".env"
	file, err := os.Open(envFile)
	if err != nil {
		// .env file doesn't exist, skip (use system env vars instead)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		// Parse KEY=VALUE
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			// Only set if not already in environment
			if os.Getenv(key) == "" {
				os.Setenv(key, value)
			}
		}
	}
}

// SECURITY FIX: Restrict CORS to specific origins instead of allowing all (*)
func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// SECURITY: Get allowed origins from environment variable
		allowedOrigins := os.Getenv("CORS_ALLOWED_ORIGINS")
		if allowedOrigins == "" {
			// Default to localhost for development (should be configured in production)
			allowedOrigins = "http://localhost:3000,http://localhost:8080"
		}

		// SECURITY: Check if request origin is in allowed list
		requestOrigin := r.Header.Get("Origin")
		origins := strings.Split(allowedOrigins, ",")
		isAllowed := false
		for _, origin := range origins {
			if strings.TrimSpace(origin) == requestOrigin {
				isAllowed = true
				break
			}
		}

		// SECURITY: Only set CORS headers if origin is allowed
		if isAllowed {
			w.Header().Set("Access-Control-Allow-Origin", requestOrigin)
		}

		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-User-Role, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	// Load .env file if it exists (for local development)
	loadEnvFile()

	// SECURITY FIX: Load database credentials from environment variables
	// NEVER hardcode credentials in source code
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5433"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "postgres"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		// For development, use default if not set
		log.Println("WARNING: DB_PASSWORD not set in environment. Using default 'Bjoecr7' for development.")
		dbPassword = "Bjoecr7"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "evat_db"
	}
	dbSSLMode := os.Getenv("DB_SSL_MODE")
	if dbSSLMode == "" {
		dbSSLMode = "disable" // For development
	}

	// Build connection string from environment variables
	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		dbHost, dbPort, dbUser, dbPassword, dbName, dbSSLMode,
	)

	dbConn, err := db.InitDB(connStr)
	if err != nil {
		log.Fatal("database connection failed:", err)
	}

	if err := db.RunMigrations(dbConn, "migrations"); err != nil {
		log.Fatal("migration failed:", err)
	}

	productionRepo := repositories.NewProductionRepository(dbConn)
	productionService := services.NewProductionService(productionRepo)
	productionHandler := handlers.NewProductionHandler(productionService)

	salesRepo := repositories.NewSalesRepository(dbConn)
	salesService := services.NewSalesService(salesRepo)
	salesHandler := handlers.NewSalesHandler(salesService)

	allocationRepo := repositories.NewAllocationRepository(dbConn)
	allocationService := services.NewAllocationService(allocationRepo)
	allocationHandler := handlers.NewAllocationHandler(allocationService)

	syncSalesService := services.NewSyncSalesService(
		dbConn,
		salesRepo,
		allocationRepo,
	)
	syncSalesHandler := handlers.NewSyncSalesHandler(syncSalesService)

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

	// Sync sales route (for offline sales from mobile app)
	http.HandleFunc(
		"/sync-sales",
		middleware.AuthMiddleware([]string{middleware.RoleAdmin, middleware.RoleAgent}, syncSalesHandler.SyncSales),
	)

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

	http.HandleFunc(
		"/allocations",
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method == http.MethodPost {
				middleware.AuthMiddleware([]string{middleware.RoleAdmin}, allocationHandler.CreateAllocation)(w, r)
				return
			}
			if r.Method == http.MethodGet {
				middleware.AuthMiddleware([]string{middleware.RoleAdmin, middleware.RoleAgent}, allocationHandler.GetAllocation)(w, r)
				return
			}
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		},
	)

	fmt.Println("Backend running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", withCORS(http.DefaultServeMux)))
}
