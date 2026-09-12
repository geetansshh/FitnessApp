package api

import (
	"net/http"

	"fitnessapp/backend/internal/models"
	"fitnessapp/backend/internal/service"
	"fitnessapp/backend/internal/validation"
)

// Handlers translate HTTP to service calls and back. No business rules live here.
type Handlers struct {
	svc *service.Service
}

// --- health ---

func (h *Handlers) healthz(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// --- calorie target ---

func (h *Handlers) calorieTarget(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Age           int     `json:"age"`
		Sex           string  `json:"sex"`
		HeightCm      float64 `json:"heightCm"`
		WeightKg      float64 `json:"weightKg"`
		ActivityLevel string  `json:"activityLevel"`
		GoalType      string  `json:"goalType"`
	}
	if err := decode(r, &req); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	res, err := h.svc.CalorieTarget(validation.Body{
		Age: req.Age, Sex: req.Sex, HeightCm: req.HeightCm,
		WeightKg: req.WeightKg, ActivityLevel: req.ActivityLevel, GoalType: req.GoalType,
	})
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, res)
}

// --- food catalog ---

func (h *Handlers) foodCatalog(w http.ResponseWriter, r *http.Request) {
	items, err := h.svc.FoodCatalog()
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

// --- profile ---

func (h *Handlers) getProfile(w http.ResponseWriter, r *http.Request) {
	p, err := h.svc.Profile(userID(r))
	if err != nil {
		fail(w, err, "no profile set")
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func (h *Handlers) putProfile(w http.ResponseWriter, r *http.Request) {
	var p models.Profile
	if err := decode(r, &p); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	saved, err := h.svc.SaveProfile(userID(r), p)
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, saved)
}

// --- food ---

func (h *Handlers) listFood(w http.ResponseWriter, r *http.Request) {
	out, err := h.svc.ListFood(userID(r), r.URL.Query().Get("date"))
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (h *Handlers) createFood(w http.ResponseWriter, r *http.Request) {
	var e models.FoodEntry
	if err := decode(r, &e); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	saved, err := h.svc.LogFood(userID(r), e)
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusCreated, saved)
}

func (h *Handlers) deleteFood(w http.ResponseWriter, r *http.Request) {
	if err := h.svc.DeleteFood(userID(r), r.PathValue("id")); err != nil {
		fail(w, err, "food entry not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- water ---

func (h *Handlers) listWater(w http.ResponseWriter, r *http.Request) {
	out, err := h.svc.ListWater(userID(r), r.URL.Query().Get("date"))
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (h *Handlers) createWater(w http.ResponseWriter, r *http.Request) {
	var e models.WaterEntry
	if err := decode(r, &e); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	saved, err := h.svc.LogWater(userID(r), e)
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusCreated, saved)
}

func (h *Handlers) deleteWater(w http.ResponseWriter, r *http.Request) {
	if err := h.svc.DeleteWater(userID(r), r.PathValue("id")); err != nil {
		fail(w, err, "water entry not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- weight ---

func (h *Handlers) listWeight(w http.ResponseWriter, r *http.Request) {
	out, err := h.svc.ListWeight(userID(r))
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, out)
}

func (h *Handlers) createWeight(w http.ResponseWriter, r *http.Request) {
	var e models.WeightEntry
	if err := decode(r, &e); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	saved, err := h.svc.LogWeight(userID(r), e)
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusCreated, saved)
}

func (h *Handlers) deleteWeight(w http.ResponseWriter, r *http.Request) {
	if err := h.svc.DeleteWeight(userID(r), r.PathValue("id")); err != nil {
		fail(w, err, "weight entry not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- summary ---

func (h *Handlers) summary(w http.ResponseWriter, r *http.Request) {
	out, err := h.svc.Summary(userID(r), r.URL.Query().Get("date"))
	if err != nil {
		fail(w, err, "")
		return
	}
	writeJSON(w, http.StatusOK, out)
}
