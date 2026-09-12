package service

import (
	"testing"

	"fitnessapp/backend/internal/models"
	"fitnessapp/backend/internal/repo"
	"fitnessapp/backend/internal/validation"
)

// fakeRepo is an in-memory Repository, so the service layer is testable with no DB.
type fakeRepo struct {
	profile  *models.Profile
	food     []models.FoodEntry
	water    []models.WaterEntry
	weight   []models.WeightEntry
	catalog  []models.CatalogItem
	putCalls int
}

func (f *fakeRepo) GetProfile(string) (models.Profile, error) {
	if f.profile == nil {
		return models.Profile{}, repo.ErrNotFound
	}
	return *f.profile, nil
}
func (f *fakeRepo) PutProfile(_ string, p models.Profile) error {
	f.profile = &p
	f.putCalls++
	return nil
}

func (f *fakeRepo) ListCatalog() ([]models.CatalogItem, error) { return f.catalog, nil }

// AddFood mimics the real upsert-on-id behaviour.
func (f *fakeRepo) AddFood(_ string, e models.FoodEntry) error {
	for i, existing := range f.food {
		if existing.ID == e.ID {
			f.food[i] = e
			return nil
		}
	}
	f.food = append(f.food, e)
	return nil
}
func (f *fakeRepo) ListFood(string, string) ([]models.FoodEntry, error) { return f.food, nil }
func (f *fakeRepo) DeleteFood(string, string) error                     { return repo.ErrNotFound }

func (f *fakeRepo) AddWater(_ string, e models.WaterEntry) error {
	f.water = append(f.water, e)
	return nil
}
func (f *fakeRepo) ListWater(string, string) ([]models.WaterEntry, error) { return f.water, nil }
func (f *fakeRepo) DeleteWater(string, string) error                      { return repo.ErrNotFound }

func (f *fakeRepo) AddWeight(_ string, e models.WeightEntry) error {
	f.weight = append(f.weight, e)
	return nil
}
func (f *fakeRepo) ListWeight(string) ([]models.WeightEntry, error) { return f.weight, nil }
func (f *fakeRepo) DeleteWeight(string, string) error               { return repo.ErrNotFound }
func (f *fakeRepo) Close()                                          {}

func TestLogFoodStampsIDAndTimestamp(t *testing.T) {
	svc := New(&fakeRepo{})
	got, err := svc.LogFood("u", models.FoodEntry{Date: "2026-08-20", Name: "Dal", Calories: 198})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.ID == "" || got.CreatedAt == "" {
		t.Fatalf("expected id and createdAt to be filled, got %+v", got)
	}
}

// A client-supplied id must survive, or the app's repeat backup duplicates rows.
func TestLogFoodIsIdempotentOnClientID(t *testing.T) {
	r := &fakeRepo{}
	svc := New(r)
	for _, name := range []string{"Dal", "Dal (edited)"} {
		if _, err := svc.LogFood("u", models.FoodEntry{
			ID: "abc", Date: "2026-08-20", Name: name, Calories: 198,
		}); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
	}
	if len(r.food) != 1 {
		t.Fatalf("expected 1 row after re-posting the same id, got %d", len(r.food))
	}
	if r.food[0].Name != "Dal (edited)" {
		t.Fatalf("expected the row to be updated, got %q", r.food[0].Name)
	}
}

// An unnamed entry is legal — the app allows logging bare calories.
func TestLogFoodAllowsEmptyName(t *testing.T) {
	if _, err := New(&fakeRepo{}).LogFood("u", models.FoodEntry{Date: "2026-08-20", Calories: 250}); err != nil {
		t.Fatalf("empty name should be accepted, got %v", err)
	}
}

func TestLogFoodRejectsBadInput(t *testing.T) {
	svc := New(&fakeRepo{})
	cases := map[string]models.FoodEntry{
		"bad date":          {Date: "20-08-2026", Calories: 10},
		"negative calories": {Date: "2026-08-20", Calories: -1},
	}
	for name, e := range cases {
		if _, err := svc.LogFood("u", e); !validation.IsInvalid(err) {
			t.Errorf("%s: expected a validation error, got %v", name, err)
		}
	}
}

// The server recomputes targets so a client can't store numbers that disagree
// with the body stats it sent.
func TestSaveProfileRecomputesTargets(t *testing.T) {
	r := &fakeRepo{}
	got, err := New(r).SaveProfile("u", models.Profile{
		Age: 30, Sex: "male", HeightCm: 180, WeightKg: 80,
		ActivityLevel: "moderate", GoalType: "lose",
		CalorieTarget: 99999, // a lie the server must overwrite
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.CalorieTarget != 2259 {
		t.Fatalf("expected recomputed target 2259, got %d", got.CalorieTarget)
	}
}

func TestSummaryAggregatesTheDay(t *testing.T) {
	r := &fakeRepo{
		profile: &models.Profile{CalorieTarget: 2259, WaterGoalMl: 2500, GoalWeightKg: 70},
		food: []models.FoodEntry{
			{Date: "2026-08-20", Calories: 500, Protein: 30},
			{Date: "2026-08-20", Calories: 300, Protein: 20},
		},
		water:  []models.WaterEntry{{Date: "2026-08-20", AmountMl: 250}},
		weight: []models.WeightEntry{{Date: "2026-08-01", WeightKg: 82}, {Date: "2026-08-20", WeightKg: 80}},
	}
	s, err := New(r).Summary("u", "2026-08-20")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if s.CaloriesConsumed != 800 || s.CaloriesRemaining != 1459 {
		t.Errorf("calories: got consumed=%d remaining=%d", s.CaloriesConsumed, s.CaloriesRemaining)
	}
	if s.Protein != 50 || s.WaterMl != 250 {
		t.Errorf("totals: got protein=%v water=%d", s.Protein, s.WaterMl)
	}
	// Bookends, not min/max: first weigh-in vs most recent.
	if s.StartWeightKg != 82 || s.LatestWeightKg != 80 {
		t.Errorf("weights: got start=%v latest=%v", s.StartWeightKg, s.LatestWeightKg)
	}
}

// A user who has never saved a profile still gets a usable summary.
func TestSummaryWithoutProfileIsNotAnError(t *testing.T) {
	s, err := New(&fakeRepo{}).Summary("u", "2026-08-20")
	if err != nil {
		t.Fatalf("missing profile should not fail, got %v", err)
	}
	if s.CalorieTarget != 0 {
		t.Fatalf("expected zero target, got %d", s.CalorieTarget)
	}
}

func TestSummaryRejectsMissingDate(t *testing.T) {
	if _, err := New(&fakeRepo{}).Summary("u", ""); !validation.IsInvalid(err) {
		t.Fatalf("expected a validation error, got %v", err)
	}
}
