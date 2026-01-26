package main

import (
	"fmt"
	"net/http"
)

func main() {

	const port = ":8080"

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Backend is LIVE - Ready for E-VAT 2026")
	})

	fmt.Printf("Server starting on http://localhost%s...\n", port)

	err := http.ListenAndServe(port, nil)
	if err != nil {
		fmt.Printf("Error starting server: %\n", err)
	}
}
