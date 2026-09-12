// Package repo is the persistence layer: it owns SQL and nothing else.
// The service layer depends on the Repository interface, never on Postgres.
package repo

import (
	"errors"

	"fitnessapp/backend/internal/models"
)

// ErrNotFound is returned when a delete targets a row that isn't there.
var ErrNotFound = errors.New("not found")

// Repository is every persistence operation the service layer needs.
type Repository interface {
	GetProfile(user string) (models.Profile, error)
	PutProfile(user string, p models.Profile) error

	AddFood(user string, e models.FoodEntry) error
	ListFood(user, date string) ([]models.FoodEntry, error)
	DeleteFood(user, id string) error

	ListCatalog() ([]models.CatalogItem, error)

	AddWater(user string, e models.WaterEntry) error
	ListWater(user, date string) ([]models.WaterEntry, error)
	DeleteWater(user, id string) error

	AddWeight(user string, e models.WeightEntry) error
	ListWeight(user string) ([]models.WeightEntry, error)
	DeleteWeight(user, id string) error

	Close()
}
