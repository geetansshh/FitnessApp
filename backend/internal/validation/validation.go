// Package validation holds every request rule in one place, so handlers stay
// thin and the same rule can't drift between two endpoints.
package validation

import (
	"errors"
	"time"

	"fitnessapp/backend/internal/calc"
	"fitnessapp/backend/internal/models"
)

// Error marks a failure caused by bad input, which the API layer maps to 400.
type Error struct{ Message string }

func (e *Error) Error() string { return e.Message }

func fail(msg string) error { return &Error{Message: msg} }

// IsInvalid reports whether err (or anything it wraps) is a validation failure.
func IsInvalid(err error) bool {
	var e *Error
	return errors.As(err, &e)
}

const dateLayout = "2006-01-02"

// Date requires a YYYY-MM-DD calendar date.
func Date(s string) error {
	if _, err := time.Parse(dateLayout, s); err != nil {
		return fail("date must be YYYY-MM-DD")
	}
	return nil
}

// OptionalDate allows an empty value, meaning "no date filter".
func OptionalDate(s string) error {
	if s == "" {
		return nil
	}
	return Date(s)
}

// ID guards the client-supplied identifier used for idempotent writes.
func ID(id string) error {
	if len(id) > 64 {
		return fail("id must be 64 characters or fewer")
	}
	return nil
}

// Body describes the shared body-stat fields of a profile and a calorie-target request.
type Body struct {
	Age           int
	Sex           string
	HeightCm      float64
	WeightKg      float64
	ActivityLevel string
	GoalType      string
}

// BodyStats validates the inputs the Mifflin-St Jeor equation needs.
func BodyStats(b Body) error {
	switch {
	case b.Age <= 0 || b.Age > 130:
		return fail("age must be between 1 and 130")
	case b.HeightCm <= 0 || b.HeightCm > 300:
		return fail("heightCm must be between 1 and 300")
	case b.WeightKg <= 0 || b.WeightKg > 700:
		return fail("weightKg must be between 1 and 700")
	case !calc.ValidSex(b.Sex):
		return fail("sex must be male or female")
	case !calc.ValidActivity(b.ActivityLevel):
		return fail("activityLevel must be sedentary, light, moderate, active, or veryActive")
	case !calc.ValidGoal(b.GoalType):
		return fail("goalType must be lose, maintain, or gain")
	}
	return nil
}

// Profile validates a full profile payload.
func Profile(p models.Profile) error {
	if err := BodyStats(Body{p.Age, p.Sex, p.HeightCm, p.WeightKg, p.ActivityLevel, p.GoalType}); err != nil {
		return err
	}
	if p.GoalWeightKg < 0 || p.GoalWeightKg > 700 {
		return fail("goalWeightKg must be between 0 and 700")
	}
	if p.WaterGoalMl < 0 || p.WaterGoalMl > 20000 {
		return fail("waterGoalMl must be between 0 and 20000")
	}
	return nil
}

// FoodEntry validates a food log entry. An empty name is allowed — the app
// treats unnamed entries as a plain "Food" row.
func FoodEntry(e models.FoodEntry) error {
	if err := Date(e.Date); err != nil {
		return err
	}
	if err := ID(e.ID); err != nil {
		return err
	}
	if e.Calories < 0 || e.Protein < 0 || e.Carbs < 0 || e.Fats < 0 {
		return fail("calories and macros must be non-negative")
	}
	return nil
}

func WaterEntry(e models.WaterEntry) error {
	if err := Date(e.Date); err != nil {
		return err
	}
	if err := ID(e.ID); err != nil {
		return err
	}
	if e.AmountMl <= 0 {
		return fail("amountMl must be positive")
	}
	return nil
}

func WeightEntry(e models.WeightEntry) error {
	if err := Date(e.Date); err != nil {
		return err
	}
	if err := ID(e.ID); err != nil {
		return err
	}
	if e.WeightKg <= 0 || e.WeightKg > 700 {
		return fail("weightKg must be between 1 and 700")
	}
	return nil
}
