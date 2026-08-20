package api

import (
	"encoding/json"
	"errors"
	"net/http"

	"fitnessapp/backend/internal/service"
	"fitnessapp/backend/internal/validation"
)

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

func decode(r *http.Request, v any) error {
	return json.NewDecoder(r.Body).Decode(v)
}

// userID keys every row. There is no auth beyond the optional shared secret;
// a client picks its namespace with X-User-Id.
func userID(r *http.Request) string {
	if u := r.Header.Get("X-User-Id"); u != "" {
		return u
	}
	return "local"
}

// fail is the single place service errors become HTTP status codes: bad input
// is 400, a missing row is 404, and anything else is an unexplained 500.
func fail(w http.ResponseWriter, err error, notFoundMsg string) {
	switch {
	case validation.IsInvalid(err):
		writeErr(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, service.ErrNotFound):
		writeErr(w, http.StatusNotFound, notFoundMsg)
	default:
		writeErr(w, http.StatusInternalServerError, "internal error")
	}
}
