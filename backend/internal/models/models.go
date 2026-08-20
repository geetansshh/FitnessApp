package models

// JSON keys are the exact camelCase keys the Swift client depends on.

type Profile struct {
	Name          string  `json:"name"`
	Age           int     `json:"age"`
	Sex           string  `json:"sex"`
	HeightCm      float64 `json:"heightCm"`
	WeightKg      float64 `json:"weightKg"`
	GoalWeightKg  float64 `json:"goalWeightKg"`
	ActivityLevel string  `json:"activityLevel"`
	GoalType      string  `json:"goalType"`
	CalorieTarget int     `json:"calorieTarget"`
	ProteinTarget int     `json:"proteinTarget"`
	CarbsTarget   int     `json:"carbsTarget"`
	FatsTarget    int     `json:"fatsTarget"`
	WaterGoalMl   int     `json:"waterGoalMl"`
}

type FoodEntry struct {
	ID        string  `json:"id"`
	Date      string  `json:"date"`
	Name      string  `json:"name"`
	Calories  int     `json:"calories"`
	Protein   float64 `json:"protein"`
	Carbs     float64 `json:"carbs"`
	Fats      float64 `json:"fats"`
	CreatedAt string  `json:"createdAt"`
}

type WaterEntry struct {
	ID        string `json:"id"`
	Date      string `json:"date"`
	AmountMl  int    `json:"amountMl"`
	CreatedAt string `json:"createdAt"`
}

type WeightEntry struct {
	ID        string  `json:"id"`
	Date      string  `json:"date"`
	WeightKg  float64 `json:"weightKg"`
	CreatedAt string  `json:"createdAt"`
}

// Summary is the aggregated view of one day, assembled by the service layer.
type Summary struct {
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
