package store

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"

	"fitnessapp/backend/internal/models"
)

// Store is a Postgres-backed data store. One row per profile (JSONB); one row per
// food/water/weight entry with typed columns. Keyed by user_id (default "local").
type Store struct {
	pool *pgxpool.Pool
}

// New connects to Postgres via a DATABASE_URL and ensures the schema exists.
func New(databaseURL string) (*Store, error) {
	pool, err := pgxpool.New(context.Background(), databaseURL)
	if err != nil {
		return nil, err
	}
	s := &Store{pool: pool}
	if _, err := pool.Exec(context.Background(), schema); err != nil {
		pool.Close()
		return nil, err
	}
	return s, nil
}

func (s *Store) Close() { s.pool.Close() }

const schema = `
CREATE TABLE IF NOT EXISTS profiles (
    user_id TEXT PRIMARY KEY,
    data    JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS food (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL,
    date       TEXT NOT NULL,
    name       TEXT NOT NULL,
    calories   INTEGER NOT NULL,
    protein    DOUBLE PRECISION NOT NULL,
    carbs      DOUBLE PRECISION NOT NULL,
    fats       DOUBLE PRECISION NOT NULL,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_food_user_date ON food (user_id, date);
CREATE TABLE IF NOT EXISTS water (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL,
    date       TEXT NOT NULL,
    amount_ml  INTEGER NOT NULL,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_water_user_date ON water (user_id, date);
CREATE TABLE IF NOT EXISTS weight (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL,
    date       TEXT NOT NULL,
    weight_kg  DOUBLE PRECISION NOT NULL,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_weight_user ON weight (user_id);
`

func ctx() context.Context { return context.Background() }

// --- Profile ---

func (s *Store) GetProfile(user string) (models.Profile, bool) {
	var data []byte
	err := s.pool.QueryRow(ctx(), `SELECT data FROM profiles WHERE user_id=$1`, user).Scan(&data)
	if err != nil {
		return models.Profile{}, false
	}
	var p models.Profile
	if json.Unmarshal(data, &p) != nil {
		return models.Profile{}, false
	}
	return p, true
}

func (s *Store) PutProfile(user string, p models.Profile) error {
	data, err := json.Marshal(p)
	if err != nil {
		return err
	}
	_, err = s.pool.Exec(ctx(),
		`INSERT INTO profiles (user_id, data) VALUES ($1, $2)
		 ON CONFLICT (user_id) DO UPDATE SET data = EXCLUDED.data`, user, data)
	return err
}

// --- Food ---

func (s *Store) AddFood(user string, e models.FoodEntry) error {
	_, err := s.pool.Exec(ctx(),
		`INSERT INTO food (id, user_id, date, name, calories, protein, carbs, fats, created_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		 ON CONFLICT (id) DO UPDATE SET date=EXCLUDED.date, name=EXCLUDED.name,
		   calories=EXCLUDED.calories, protein=EXCLUDED.protein,
		   carbs=EXCLUDED.carbs, fats=EXCLUDED.fats`,
		e.ID, user, e.Date, e.Name, e.Calories, e.Protein, e.Carbs, e.Fats, e.CreatedAt)
	return err
}

func (s *Store) ListFood(user, date string) []models.FoodEntry {
	q := `SELECT id, date, name, calories, protein, carbs, fats, created_at FROM food WHERE user_id=$1`
	args := []any{user}
	if date != "" {
		q += ` AND date=$2`
		args = append(args, date)
	}
	q += ` ORDER BY created_at`
	out := []models.FoodEntry{}
	rows, err := s.pool.Query(ctx(), q, args...)
	if err != nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var e models.FoodEntry
		if rows.Scan(&e.ID, &e.Date, &e.Name, &e.Calories, &e.Protein, &e.Carbs, &e.Fats, &e.CreatedAt) == nil {
			out = append(out, e)
		}
	}
	return out
}

func (s *Store) DeleteFood(user, id string) bool {
	tag, err := s.pool.Exec(ctx(), `DELETE FROM food WHERE user_id=$1 AND id=$2`, user, id)
	return err == nil && tag.RowsAffected() > 0
}

// --- Water ---

func (s *Store) AddWater(user string, e models.WaterEntry) error {
	_, err := s.pool.Exec(ctx(),
		`INSERT INTO water (id, user_id, date, amount_ml, created_at) VALUES ($1,$2,$3,$4,$5)
		 ON CONFLICT (id) DO UPDATE SET date=EXCLUDED.date, amount_ml=EXCLUDED.amount_ml`,
		e.ID, user, e.Date, e.AmountMl, e.CreatedAt)
	return err
}

func (s *Store) ListWater(user, date string) []models.WaterEntry {
	q := `SELECT id, date, amount_ml, created_at FROM water WHERE user_id=$1`
	args := []any{user}
	if date != "" {
		q += ` AND date=$2`
		args = append(args, date)
	}
	q += ` ORDER BY created_at`
	out := []models.WaterEntry{}
	rows, err := s.pool.Query(ctx(), q, args...)
	if err != nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var e models.WaterEntry
		if rows.Scan(&e.ID, &e.Date, &e.AmountMl, &e.CreatedAt) == nil {
			out = append(out, e)
		}
	}
	return out
}

func (s *Store) DeleteWater(user, id string) bool {
	tag, err := s.pool.Exec(ctx(), `DELETE FROM water WHERE user_id=$1 AND id=$2`, user, id)
	return err == nil && tag.RowsAffected() > 0
}

// --- Weight ---

func (s *Store) AddWeight(user string, e models.WeightEntry) error {
	_, err := s.pool.Exec(ctx(),
		`INSERT INTO weight (id, user_id, date, weight_kg, created_at) VALUES ($1,$2,$3,$4,$5)
		 ON CONFLICT (id) DO UPDATE SET date=EXCLUDED.date, weight_kg=EXCLUDED.weight_kg`,
		e.ID, user, e.Date, e.WeightKg, e.CreatedAt)
	return err
}

// ListWeight returns all of a user's weight entries sorted by date ascending.
func (s *Store) ListWeight(user string) []models.WeightEntry {
	out := []models.WeightEntry{}
	rows, err := s.pool.Query(ctx(),
		`SELECT id, date, weight_kg, created_at FROM weight WHERE user_id=$1 ORDER BY date`, user)
	if err != nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var e models.WeightEntry
		if rows.Scan(&e.ID, &e.Date, &e.WeightKg, &e.CreatedAt) == nil {
			out = append(out, e)
		}
	}
	return out
}

func (s *Store) DeleteWeight(user, id string) bool {
	tag, err := s.pool.Exec(ctx(), `DELETE FROM weight WHERE user_id=$1 AND id=$2`, user, id)
	return err == nil && tag.RowsAffected() > 0
}
