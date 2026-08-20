package repo

// schema is applied on startup; every statement is IF NOT EXISTS so it is safe
// to re-run on every boot.
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
