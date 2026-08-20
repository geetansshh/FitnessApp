package repo

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"fitnessapp/backend/internal/models"
)

// Postgres is the Repository implementation: one JSONB row per profile, one
// typed row per food/water/weight entry, all keyed by user_id.
type Postgres struct {
	pool *pgxpool.Pool
}

// NewPostgres connects via a DATABASE_URL and ensures the schema exists.
func NewPostgres(databaseURL string) (*Postgres, error) {
	pool, err := pgxpool.New(context.Background(), databaseURL)
	if err != nil {
		return nil, err
	}
	if _, err := pool.Exec(context.Background(), schema); err != nil {
		pool.Close()
		return nil, err
	}
	return &Postgres{pool: pool}, nil
}

func (p *Postgres) Close() { p.pool.Close() }

func ctx() context.Context { return context.Background() }

// deleted turns an Exec result into ErrNotFound when nothing matched.
func deleted(tag interface{ RowsAffected() int64 }, err error) error {
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// --- Profile ---

func (p *Postgres) GetProfile(user string) (models.Profile, error) {
	var data []byte
	err := p.pool.QueryRow(ctx(), `SELECT data FROM profiles WHERE user_id=$1`, user).Scan(&data)
	if errors.Is(err, pgx.ErrNoRows) {
		return models.Profile{}, ErrNotFound
	}
	if err != nil {
		return models.Profile{}, err
	}
	var out models.Profile
	if err := json.Unmarshal(data, &out); err != nil {
		return models.Profile{}, err
	}
	return out, nil
}

func (p *Postgres) PutProfile(user string, profile models.Profile) error {
	data, err := json.Marshal(profile)
	if err != nil {
		return err
	}
	_, err = p.pool.Exec(ctx(),
		`INSERT INTO profiles (user_id, data) VALUES ($1, $2)
		 ON CONFLICT (user_id) DO UPDATE SET data = EXCLUDED.data`, user, data)
	return err
}

// --- Food ---

// AddFood upserts on id so a repeated backup updates the row instead of duplicating it.
func (p *Postgres) AddFood(user string, e models.FoodEntry) error {
	_, err := p.pool.Exec(ctx(),
		`INSERT INTO food (id, user_id, date, name, calories, protein, carbs, fats, created_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		 ON CONFLICT (id) DO UPDATE SET date=EXCLUDED.date, name=EXCLUDED.name,
		   calories=EXCLUDED.calories, protein=EXCLUDED.protein,
		   carbs=EXCLUDED.carbs, fats=EXCLUDED.fats`,
		e.ID, user, e.Date, e.Name, e.Calories, e.Protein, e.Carbs, e.Fats, e.CreatedAt)
	return err
}

func (p *Postgres) ListFood(user, date string) ([]models.FoodEntry, error) {
	q := `SELECT id, date, name, calories, protein, carbs, fats, created_at FROM food WHERE user_id=$1`
	args := []any{user}
	if date != "" {
		q += ` AND date=$2`
		args = append(args, date)
	}
	q += ` ORDER BY created_at`

	rows, err := p.pool.Query(ctx(), q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.FoodEntry{}
	for rows.Next() {
		var e models.FoodEntry
		if err := rows.Scan(&e.ID, &e.Date, &e.Name, &e.Calories, &e.Protein, &e.Carbs, &e.Fats, &e.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func (p *Postgres) DeleteFood(user, id string) error {
	return deleted(p.pool.Exec(ctx(), `DELETE FROM food WHERE user_id=$1 AND id=$2`, user, id))
}

// --- Water ---

func (p *Postgres) AddWater(user string, e models.WaterEntry) error {
	_, err := p.pool.Exec(ctx(),
		`INSERT INTO water (id, user_id, date, amount_ml, created_at) VALUES ($1,$2,$3,$4,$5)
		 ON CONFLICT (id) DO UPDATE SET date=EXCLUDED.date, amount_ml=EXCLUDED.amount_ml`,
		e.ID, user, e.Date, e.AmountMl, e.CreatedAt)
	return err
}

func (p *Postgres) ListWater(user, date string) ([]models.WaterEntry, error) {
	q := `SELECT id, date, amount_ml, created_at FROM water WHERE user_id=$1`
	args := []any{user}
	if date != "" {
		q += ` AND date=$2`
		args = append(args, date)
	}
	q += ` ORDER BY created_at`

	rows, err := p.pool.Query(ctx(), q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.WaterEntry{}
	for rows.Next() {
		var e models.WaterEntry
		if err := rows.Scan(&e.ID, &e.Date, &e.AmountMl, &e.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func (p *Postgres) DeleteWater(user, id string) error {
	return deleted(p.pool.Exec(ctx(), `DELETE FROM water WHERE user_id=$1 AND id=$2`, user, id))
}

// --- Weight ---

func (p *Postgres) AddWeight(user string, e models.WeightEntry) error {
	_, err := p.pool.Exec(ctx(),
		`INSERT INTO weight (id, user_id, date, weight_kg, created_at) VALUES ($1,$2,$3,$4,$5)
		 ON CONFLICT (id) DO UPDATE SET date=EXCLUDED.date, weight_kg=EXCLUDED.weight_kg`,
		e.ID, user, e.Date, e.WeightKg, e.CreatedAt)
	return err
}

// ListWeight returns all of a user's weigh-ins sorted by date ascending.
func (p *Postgres) ListWeight(user string) ([]models.WeightEntry, error) {
	rows, err := p.pool.Query(ctx(),
		`SELECT id, date, weight_kg, created_at FROM weight WHERE user_id=$1 ORDER BY date`, user)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.WeightEntry{}
	for rows.Next() {
		var e models.WeightEntry
		if err := rows.Scan(&e.ID, &e.Date, &e.WeightKg, &e.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func (p *Postgres) DeleteWeight(user, id string) error {
	return deleted(p.pool.Exec(ctx(), `DELETE FROM weight WHERE user_id=$1 AND id=$2`, user, id))
}
