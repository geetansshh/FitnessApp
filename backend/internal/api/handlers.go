package api

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"time"

	"fitnessapp/backend/internal/calc"
	"fitnessapp/backend/internal/models"
	"fitnessapp/backend/internal/store"
)

type Handlers struct {
	store *store.Store
}

// --- helpers ---

// keepOrNewID preserves a client-supplied id (so a re-run of the app's backup
// upserts the same row instead of duplicating it) and generates one otherwise.
func keepOrNewID(id string) string {
	if len(id) > 0 && len(id) <= 64 {
		return id
	}
	return newID()
}

func newID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b) // crypto/rand.Read only fails on catastrophic OS errors
	return hex.EncodeToString(b)
}

func nowRFC3339() string { return time.Now().UTC().Format(time.RFC3339) }

func userID(r *http.Request) string {
	if u := r.Header.Get("X-User-Id"); u != "" {
		return u
	}
	return "local"
}

func validDate(s string) bool {
	_, err := time.Parse("2006-01-02", s)
	return err == nil
}

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

// --- health ---

func (h *Handlers) healthz(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// --- calorie target (pure calc, no persist) ---

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
	if req.Age <= 0 || req.Age > 130 || req.HeightCm <= 0 || req.WeightKg <= 0 ||
		!calc.ValidSex(req.Sex) || !calc.ValidActivity(req.ActivityLevel) || !calc.ValidGoal(req.GoalType) {
		writeErr(w, http.StatusBadRequest, "invalid input: check age, sex, heightCm, weightKg, activityLevel, goalType")
		return
	}
	res := calc.Compute(req.Age, req.Sex, req.HeightCm, req.WeightKg, req.ActivityLevel, req.GoalType)
	writeJSON(w, http.StatusOK, res)
}

// --- profile ---

func (h *Handlers) getProfile(w http.ResponseWriter, r *http.Request) {
	p, ok := h.store.GetProfile(userID(r))
	if !ok {
		writeErr(w, http.StatusNotFound, "no profile set")
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
	if p.Age <= 0 || p.Age > 130 || p.HeightCm <= 0 || p.WeightKg <= 0 ||
		!calc.ValidSex(p.Sex) || !calc.ValidActivity(p.ActivityLevel) || !calc.ValidGoal(p.GoalType) {
		writeErr(w, http.StatusBadRequest, "invalid input: check age, sex, heightCm, weightKg, activityLevel, goalType")
		return
	}
	// Recompute targets server-side so the stored values can't drift.
	res := calc.Compute(p.Age, p.Sex, p.HeightCm, p.WeightKg, p.ActivityLevel, p.GoalType)
	p.CalorieTarget = res.CalorieTarget
	p.ProteinTarget = res.Protein
	p.CarbsTarget = res.Carbs
	p.FatsTarget = res.Fats
	if err := h.store.PutProfile(userID(r), p); err != nil {
		writeErr(w, http.StatusInternalServerError, "could not save profile")
		return
	}
	writeJSON(w, http.StatusOK, p)
}

// --- food ---

func (h *Handlers) listFood(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date != "" && !validDate(date) {
		writeErr(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	writeJSON(w, http.StatusOK, h.store.ListFood(userID(r), date))
}

func (h *Handlers) createFood(w http.ResponseWriter, r *http.Request) {
	var e models.FoodEntry
	if err := decode(r, &e); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	if !validDate(e.Date) || e.Calories < 0 || e.Protein < 0 || e.Carbs < 0 || e.Fats < 0 {
		writeErr(w, http.StatusBadRequest, "invalid input: check date (YYYY-MM-DD) and non-negative macros")
		return
	}
	e.ID = keepOrNewID(e.ID)
	e.CreatedAt = nowRFC3339()
	if err := h.store.AddFood(userID(r), e); err != nil {
		writeErr(w, http.StatusInternalServerError, "could not save food entry")
		return
	}
	writeJSON(w, http.StatusCreated, e)
}

func (h *Handlers) deleteFood(w http.ResponseWriter, r *http.Request) {
	if !h.store.DeleteFood(userID(r), r.PathValue("id")) {
		writeErr(w, http.StatusNotFound, "food entry not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- water ---

func (h *Handlers) listWater(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date != "" && !validDate(date) {
		writeErr(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	writeJSON(w, http.StatusOK, h.store.ListWater(userID(r), date))
}

func (h *Handlers) createWater(w http.ResponseWriter, r *http.Request) {
	var e models.WaterEntry
	if err := decode(r, &e); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	if !validDate(e.Date) || e.AmountMl <= 0 {
		writeErr(w, http.StatusBadRequest, "invalid input: check date (YYYY-MM-DD) and positive amountMl")
		return
	}
	e.ID = keepOrNewID(e.ID)
	e.CreatedAt = nowRFC3339()
	if err := h.store.AddWater(userID(r), e); err != nil {
		writeErr(w, http.StatusInternalServerError, "could not save water entry")
		return
	}
	writeJSON(w, http.StatusCreated, e)
}

func (h *Handlers) deleteWater(w http.ResponseWriter, r *http.Request) {
	if !h.store.DeleteWater(userID(r), r.PathValue("id")) {
		writeErr(w, http.StatusNotFound, "water entry not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- weight ---

func (h *Handlers) listWeight(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.ListWeight(userID(r)))
}

func (h *Handlers) createWeight(w http.ResponseWriter, r *http.Request) {
	var e models.WeightEntry
	if err := decode(r, &e); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid json body")
		return
	}
	if !validDate(e.Date) || e.WeightKg <= 0 {
		writeErr(w, http.StatusBadRequest, "invalid input: check date (YYYY-MM-DD) and positive weightKg")
		return
	}
	e.ID = keepOrNewID(e.ID)
	e.CreatedAt = nowRFC3339()
	if err := h.store.AddWeight(userID(r), e); err != nil {
		writeErr(w, http.StatusInternalServerError, "could not save weight entry")
		return
	}
	writeJSON(w, http.StatusCreated, e)
}

func (h *Handlers) deleteWeight(w http.ResponseWriter, r *http.Request) {
	if !h.store.DeleteWeight(userID(r), r.PathValue("id")) {
		writeErr(w, http.StatusNotFound, "weight entry not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- summary ---

type summaryResp struct {
	Date              string  `json:"date"`
	CalorieTarget     int     `json:"calorieTarget"`
	CaloriesConsumed  int     `json:"caloriesConsumed"`
	CaloriesRemaining int     `json:"caloriesRemaining"`
	Protein           float64 `json:"protein"`
	Carbs             float64 `json:"carbs"`
	Fats              float64 `json:"fats"`
	ProteinTarget     int     `json:"proteinTarget"`
	CarbsTarget       int     `json:"carbsTarget"`
	FatsTarget        int     `json:"fatsTarget"`
	WaterMl           int     `json:"waterMl"`
	WaterGoalMl       int     `json:"waterGoalMl"`
	LatestWeightKg    float64 `json:"latestWeightKg"`
	GoalWeightKg      float64 `json:"goalWeightKg"`
	StartWeightKg     float64 `json:"startWeightKg"`
}

func (h *Handlers) summary(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if !validDate(date) {
		writeErr(w, http.StatusBadRequest, "date query param required, YYYY-MM-DD")
		return
	}
	user := userID(r)

	resp := summaryResp{Date: date}

	if p, ok := h.store.GetProfile(user); ok {
		resp.CalorieTarget = p.CalorieTarget
		resp.ProteinTarget = p.ProteinTarget
		resp.CarbsTarget = p.CarbsTarget
		resp.FatsTarget = p.FatsTarget
		resp.WaterGoalMl = p.WaterGoalMl
		resp.GoalWeightKg = p.GoalWeightKg
	}

	for _, f := range h.store.ListFood(user, date) {
		resp.CaloriesConsumed += f.Calories
		resp.Protein += f.Protein
		resp.Carbs += f.Carbs
		resp.Fats += f.Fats
	}
	resp.CaloriesRemaining = resp.CalorieTarget - resp.CaloriesConsumed

	for _, wt := range h.store.ListWater(user, date) {
		resp.WaterMl += wt.AmountMl
	}

	if weights := h.store.ListWeight(user); len(weights) > 0 {
		resp.StartWeightKg = weights[0].WeightKg
		resp.LatestWeightKg = weights[len(weights)-1].WeightKg
	}

	writeJSON(w, http.StatusOK, resp)
}
