package calc

import (
	"math"
	"testing"
)

func TestCompute(t *testing.T) {
	tests := []struct {
		name       string
		age        int
		sex        string
		heightCm   float64
		weightKg   float64
		activity   string
		goal       string
		wantBMR    float64
		wantTDEE   int
		wantTarget int
		wantP      int
		wantC      int
		wantF      int
	}{
		// BMR = 10*80 + 6.25*180 - 5*30 + 5 = 1780; TDEE = 1780*1.55 = 2759
		{"male moderate maintain", 30, "male", 180, 80, "moderate", "maintain", 1780, 2759, 2759, 207, 276, 92},
		// BMR = 600 + 1031.25 - 125 - 161 = 1345.25; TDEE = 1849.71875; -500 -> 1349.72 -> 1350
		{"female light lose", 25, "female", 165, 60, "light", "lose", 1345.25, 1850, 1350, 101, 135, 45},
		// BMR = 700 + 1093.75 - 110 + 5 = 1688.75; TDEE = 2913.09375; +300 -> 3213.09 -> 3213
		{"male active gain", 22, "male", 175, 70, "active", "gain", 1688.75, 2913, 3213, 241, 321, 107},
		// target 791.8 floored to female min 1200
		{"female floor applied", 20, "female", 150, 40, "sedentary", "lose", 1076.5, 1292, 1200, 90, 120, 40},
		// target 946 floored to male min 1500
		{"male floor applied", 60, "male", 160, 50, "sedentary", "lose", 1205, 1446, 1500, 113, 150, 50},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := Compute(tc.age, tc.sex, tc.heightCm, tc.weightKg, tc.activity, tc.goal)
			if math.Abs(got.BMR-tc.wantBMR) > 1e-6 {
				t.Errorf("BMR = %v, want %v", got.BMR, tc.wantBMR)
			}
			if got.TDEE != tc.wantTDEE {
				t.Errorf("TDEE = %d, want %d", got.TDEE, tc.wantTDEE)
			}
			if got.CalorieTarget != tc.wantTarget {
				t.Errorf("CalorieTarget = %d, want %d", got.CalorieTarget, tc.wantTarget)
			}
			if got.Protein != tc.wantP {
				t.Errorf("Protein = %d, want %d", got.Protein, tc.wantP)
			}
			if got.Carbs != tc.wantC {
				t.Errorf("Carbs = %d, want %d", got.Carbs, tc.wantC)
			}
			if got.Fats != tc.wantF {
				t.Errorf("Fats = %d, want %d", got.Fats, tc.wantF)
			}
		})
	}
}

func TestValidators(t *testing.T) {
	if !ValidSex("male") || !ValidSex("female") || ValidSex("other") {
		t.Error("ValidSex wrong")
	}
	if !ValidActivity("veryActive") || ValidActivity("lazy") {
		t.Error("ValidActivity wrong")
	}
	if !ValidGoal("maintain") || ValidGoal("bulk") {
		t.Error("ValidGoal wrong")
	}
}
