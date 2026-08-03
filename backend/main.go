package main

import (
	"log"
	"net/http"
	"os"

	"fitnessapp/backend/internal/api"
	"fitnessapp/backend/internal/store"
)

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is required (Postgres connection string)")
	}

	s, err := store.New(dbURL)
	if err != nil {
		log.Fatalf("connect/migrate database: %v", err)
	}
	defer s.Close()

	// Optional shared-secret gate. If API_KEY is set, requests must send X-API-Key.
	apiKey := os.Getenv("API_KEY")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	addr := ":" + port

	log.Printf("fitness backend listening on %s (auth=%v)", addr, apiKey != "")
	if err := http.ListenAndServe(addr, api.NewRouter(s, apiKey)); err != nil {
		log.Fatal(err)
	}
}
