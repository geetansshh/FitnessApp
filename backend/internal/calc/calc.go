// Package calc computes calorie and macro targets. This must match the iOS app exactly.
package calc

import "math"

var activityFactors = map[string]float64{
	"sedentary":  1.2,
	"light":      1.375,
	"moderate":   1.55,
	"active":     1.725,
	"veryActive": 1.9,
}

var goalAdjust = map[string]float64{
	"lose":     -500,
	"maintain": 0,
	"gain":     300,
}

// Result is returned by /calorie-target and used to fill Profile targets.
type Result struct {
	BMR           float64 `json:"bmr"`
	TDEE          int     `json:"tdee"`
	CalorieTarget int     `json:"calorieTarget"`
	Protein       int     `json:"protein"`
	Carbs         int     `json:"carbs"`
	Fats          int     `json:"fats"`
}

func ValidSex(s string) bool { return s == "male" || s == "female" }

func ValidActivity(a string) bool { _, ok := activityFactors[a]; return ok }

func ValidGoal(g string) bool { _, ok := goalAdjust[g]; return ok }

// Compute assumes sex, activity, and goal have already been validated.
func Compute(age int, sex string, heightCm, weightKg float64, activity, goal string) Result {
	var bmr float64
	if sex == "male" {
		bmr = 10*weightKg + 6.25*heightCm - 5*float64(age) + 5
	} else {
		bmr = 10*weightKg + 6.25*heightCm - 5*float64(age) - 161
	}

	tdee := bmr * activityFactors[activity]
	target := tdee + goalAdjust[goal]

	floor := 1500.0
	if sex == "female" {
		floor = 1200.0
	}
	if target < floor {
		target = floor
	}

	calorieTarget := int(math.Round(target))
	ct := float64(calorieTarget)

	return Result{
		BMR:           bmr,
		TDEE:          int(math.Round(tdee)),
		CalorieTarget: calorieTarget,
		Protein:       int(math.Round(ct * 0.30 / 4)),
		Carbs:         int(math.Round(ct * 0.40 / 4)),
		Fats:          int(math.Round(ct * 0.30 / 9)),
	}
}
