package api

import (
	"net/http"

	"fitnessapp/backend/internal/service"
)

// NewRouter wires the handlers onto a Go 1.22 method-pattern ServeMux, wrapped in
// CORS and (if apiKey is non-empty) a shared-secret gate.
func NewRouter(svc *service.Service, apiKey string) http.Handler {
	h := &Handlers{svc: svc}
	mux := http.NewServeMux()

	mux.HandleFunc("POST /api/v1/calorie-target", h.calorieTarget)

	mux.HandleFunc("GET /api/v1/profile", h.getProfile)
	mux.HandleFunc("PUT /api/v1/profile", h.putProfile)

	mux.HandleFunc("GET /api/v1/food", h.listFood)
	mux.HandleFunc("POST /api/v1/food", h.createFood)
	mux.HandleFunc("DELETE /api/v1/food/{id}", h.deleteFood)

	mux.HandleFunc("GET /api/v1/water", h.listWater)
	mux.HandleFunc("POST /api/v1/water", h.createWater)
	mux.HandleFunc("DELETE /api/v1/water/{id}", h.deleteWater)

	mux.HandleFunc("GET /api/v1/weight", h.listWeight)
	mux.HandleFunc("POST /api/v1/weight", h.createWeight)
	mux.HandleFunc("DELETE /api/v1/weight/{id}", h.deleteWeight)

	mux.HandleFunc("GET /api/v1/summary", h.summary)

	mux.HandleFunc("GET /healthz", h.healthz)

	return cors(requireKey(apiKey, mux))
}

// requireKey blocks requests missing X-API-Key when a key is configured.
// /healthz stays open so the host's health check keeps working.
func requireKey(key string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if key == "" || r.URL.Path == "/healthz" || r.Header.Get("X-API-Key") == key {
			next.ServeHTTP(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"error":"unauthorized"}`))
	})
}

// cors adds permissive headers and short-circuits OPTIONS preflight for every route.
func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-User-Id, X-API-Key")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
