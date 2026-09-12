// Package service holds the business rules: validation, identity and clock
// assignment, target recomputation, and daily aggregation. It talks to a
// repo.Repository and knows nothing about HTTP.
package service

import (
	"crypto/rand"
	"encoding/hex"
	"time"

	"fitnessapp/backend/internal/calc"
	"fitnessapp/backend/internal/models"
	"fitnessapp/backend/internal/repo"
	"fitnessapp/backend/internal/validation"
)

type Service struct {
	repo repo.Repository
}

func New(r repo.Repository) *Service { return &Service{repo: r} }

// ErrNotFound is re-exported so the API layer maps 404s without importing repo.
var ErrNotFound = repo.ErrNotFound

// --- helpers ---

func newID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b) // crypto/rand.Read only fails on catastrophic OS errors
	return hex.EncodeToString(b)
}

// stampID keeps a client-supplied id — that is what makes a repeated backup
// idempotent — and generates one only when the client didn't send it.
func stampID(id string) string {
	if id != "" {
		return id
	}
	return newID()
}

func now() string { return time.Now().UTC().Format(time.RFC3339) }

// --- calorie target (pure calc, nothing persisted) ---

func (s *Service) CalorieTarget(b validation.Body) (calc.Result, error) {
	if err := validation.BodyStats(b); err != nil {
		return calc.Result{}, err
	}
	return calc.Compute(b.Age, b.Sex, b.HeightCm, b.WeightKg, b.ActivityLevel, b.GoalType), nil
}

// --- profile ---

func (s *Service) Profile(user string) (models.Profile, error) {
	return s.repo.GetProfile(user)
}

// SaveProfile recomputes the stored targets from the body stats, so a client
// that sends stale targets can't poison them.
func (s *Service) SaveProfile(user string, p models.Profile) (models.Profile, error) {
	if err := validation.Profile(p); err != nil {
		return models.Profile{}, err
	}
	r := calc.Compute(p.Age, p.Sex, p.HeightCm, p.WeightKg, p.ActivityLevel, p.GoalType)
	p.CalorieTarget = r.CalorieTarget
	p.ProteinTarget = r.Protein
	p.CarbsTarget = r.Carbs
	p.FatsTarget = r.Fats
	if err := s.repo.PutProfile(user, p); err != nil {
		return models.Profile{}, err
	}
	return p, nil
}

// --- food catalog (reference data, same for every user) ---

func (s *Service) FoodCatalog() ([]models.CatalogItem, error) { return s.repo.ListCatalog() }

// --- food ---

func (s *Service) ListFood(user, date string) ([]models.FoodEntry, error) {
	if err := validation.OptionalDate(date); err != nil {
		return nil, err
	}
	return s.repo.ListFood(user, date)
}

func (s *Service) LogFood(user string, e models.FoodEntry) (models.FoodEntry, error) {
	if err := validation.FoodEntry(e); err != nil {
		return models.FoodEntry{}, err
	}
	e.ID = stampID(e.ID)
	e.CreatedAt = now()
	if err := s.repo.AddFood(user, e); err != nil {
		return models.FoodEntry{}, err
	}
	return e, nil
}

func (s *Service) DeleteFood(user, id string) error { return s.repo.DeleteFood(user, id) }

// --- water ---

func (s *Service) ListWater(user, date string) ([]models.WaterEntry, error) {
	if err := validation.OptionalDate(date); err != nil {
		return nil, err
	}
	return s.repo.ListWater(user, date)
}

func (s *Service) LogWater(user string, e models.WaterEntry) (models.WaterEntry, error) {
	if err := validation.WaterEntry(e); err != nil {
		return models.WaterEntry{}, err
	}
	e.ID = stampID(e.ID)
	e.CreatedAt = now()
	if err := s.repo.AddWater(user, e); err != nil {
		return models.WaterEntry{}, err
	}
	return e, nil
}

func (s *Service) DeleteWater(user, id string) error { return s.repo.DeleteWater(user, id) }

// --- weight ---

func (s *Service) ListWeight(user string) ([]models.WeightEntry, error) {
	return s.repo.ListWeight(user)
}

func (s *Service) LogWeight(user string, e models.WeightEntry) (models.WeightEntry, error) {
	if err := validation.WeightEntry(e); err != nil {
		return models.WeightEntry{}, err
	}
	e.ID = stampID(e.ID)
	e.CreatedAt = now()
	if err := s.repo.AddWeight(user, e); err != nil {
		return models.WeightEntry{}, err
	}
	return e, nil
}

func (s *Service) DeleteWeight(user, id string) error { return s.repo.DeleteWeight(user, id) }

// --- summary ---

// Summary aggregates one day: intake vs target, water, and weight bookends.
// A missing profile is not an error — it just leaves the targets at zero.
func (s *Service) Summary(user, date string) (models.Summary, error) {
	if err := validation.Date(date); err != nil {
		return models.Summary{}, err
	}
	out := models.Summary{Date: date}

	p, err := s.repo.GetProfile(user)
	switch {
	case err == nil:
		out.CalorieTarget = p.CalorieTarget
		out.ProteinTarget = p.ProteinTarget
		out.CarbsTarget = p.CarbsTarget
		out.FatsTarget = p.FatsTarget
		out.WaterGoalMl = p.WaterGoalMl
		out.GoalWeightKg = p.GoalWeightKg
	case err != repo.ErrNotFound:
		return models.Summary{}, err
	}

	foods, err := s.repo.ListFood(user, date)
	if err != nil {
		return models.Summary{}, err
	}
	for _, f := range foods {
		out.CaloriesConsumed += f.Calories
		out.Protein += f.Protein
		out.Carbs += f.Carbs
		out.Fats += f.Fats
	}
	out.CaloriesRemaining = out.CalorieTarget - out.CaloriesConsumed

	waters, err := s.repo.ListWater(user, date)
	if err != nil {
		return models.Summary{}, err
	}
	for _, w := range waters {
		out.WaterMl += w.AmountMl
	}

	weights, err := s.repo.ListWeight(user)
	if err != nil {
		return models.Summary{}, err
	}
	if len(weights) > 0 {
		out.StartWeightKg = weights[0].WeightKg
		out.LatestWeightKg = weights[len(weights)-1].WeightKg
	}
	return out, nil
}
