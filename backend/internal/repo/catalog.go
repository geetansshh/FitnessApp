package repo

import (
	_ "embed"
	"encoding/json"

	"fitnessapp/backend/internal/models"
)

// catalogSeed is the starter food table shipped with the server. It is inserted
// on startup with ON CONFLICT DO NOTHING, so rows edited or added in the
// database survive every restart — this file is a seed, not the source of truth.
//
//go:embed food_catalog.json
var catalogSeed []byte

func catalogSeedItems() ([]models.CatalogItem, error) {
	var items []models.CatalogItem
	if err := json.Unmarshal(catalogSeed, &items); err != nil {
		return nil, err
	}
	return items, nil
}
