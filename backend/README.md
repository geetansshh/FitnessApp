# FitnessApp backend

A small single-user REST API for a MyFitnessPal-lite iOS app. Go + **Postgres**
(via `github.com/jackc/pgx/v5`). No CGO — builds a static binary.

## Run locally

Needs a Postgres connection string in `DATABASE_URL` (a free Neon DB works):

```sh
cd backend
export DATABASE_URL='postgres://user:pass@host/db?sslmode=require'
go run .
```

Tables are created automatically on startup (`CREATE TABLE IF NOT EXISTS`).

Tests (calc only, no DB needed):

```sh
go test ./internal/calc/...
```

## Environment

| Var            | Required | Meaning                                             |
| -------------- | -------- | --------------------------------------------------- |
| `DATABASE_URL` | yes      | Postgres connection string                          |
| `PORT`         | no       | Listen port (host sets this; defaults `8080`)       |
| `API_KEY`      | no       | If set, every request must send `X-API-Key: <key>`  |

## Deploy (Render + Neon, both free)

1. **Neon** ([neon.tech](https://neon.tech)) → create a project → copy the
   connection string (looks like `postgres://...@...neon.tech/neondb?sslmode=require`).
2. **Render** ([render.com](https://render.com)) → New → **Web Service** →
   point at this repo, **Root Directory = `backend`** (it auto-detects the
   `Dockerfile`) → add env var `DATABASE_URL` = the Neon string → Deploy.
3. Render gives an HTTPS URL like `https://fitnessapp-xxx.onrender.com`. Put
   that in the iOS app: **Settings → server URL → Back up now**.

`Dockerfile` builds a tiny static image; `go.sum` is committed so the build is
reproducible.

## Storage & users

Postgres: `profiles` (JSONB, one row per user), `food` / `water` / `weight`
(typed columns, indexed by `user_id`+`date`). No auth by default; data is keyed
by an optional `X-User-Id` header (default `local`). Set `API_KEY` to gate the
public URL with a shared secret.

## Endpoints (all under `/api/v1` except `/healthz`)

### POST /api/v1/calorie-target (pure calc, does not persist)

```sh
curl -s localhost:8080/api/v1/calorie-target \
  -H 'Content-Type: application/json' \
  -d '{"age":30,"sex":"male","heightCm":180,"weightKg":80,"activityLevel":"moderate","goalType":"maintain"}'
# {"bmr":1780,"tdee":2759,"calorieTarget":2759,"protein":207,"carbs":276,"fats":92}
```

### GET / PUT /api/v1/profile

PUT recomputes `calorieTarget` and macro targets server-side from the body
stats so they cannot drift. GET returns 404 if no profile set.

```sh
curl -s -X PUT localhost:8080/api/v1/profile \
  -H 'Content-Type: application/json' \
  -d '{"name":"Avi","age":30,"sex":"male","heightCm":180,"weightKg":80,
       "goalWeightKg":75,"activityLevel":"moderate","goalType":"lose",
       "waterGoalMl":2500}'

curl -s localhost:8080/api/v1/profile
```

### Food

```sh
curl -s -X POST localhost:8080/api/v1/food \
  -H 'Content-Type: application/json' \
  -d '{"date":"2026-07-26","name":"Oatmeal","calories":300,"protein":10,"carbs":54,"fats":6}'

curl -s 'localhost:8080/api/v1/food?date=2026-07-26'
curl -s -X DELETE localhost:8080/api/v1/food/<id>   # 204
```

### Water

```sh
curl -s -X POST localhost:8080/api/v1/water \
  -H 'Content-Type: application/json' \
  -d '{"date":"2026-07-26","amountMl":500}'

curl -s 'localhost:8080/api/v1/water?date=2026-07-26'
curl -s -X DELETE localhost:8080/api/v1/water/<id>  # 204
```

### Weight (GET returns all, sorted by date ascending)

```sh
curl -s -X POST localhost:8080/api/v1/weight \
  -H 'Content-Type: application/json' \
  -d '{"date":"2026-07-26","weightKg":79.5}'

curl -s localhost:8080/api/v1/weight
curl -s -X DELETE localhost:8080/api/v1/weight/<id> # 204
```

### Summary

```sh
curl -s 'localhost:8080/api/v1/summary?date=2026-07-26'
```

### Health

```sh
curl -s localhost:8080/healthz   # {"status":"ok"}
```

## Multi-user example

Pass `-H 'X-User-Id: alice'` on any request to isolate that user's data.

## Calorie math (matches the iOS app)

Mifflin-St Jeor BMR, activity factor -> TDEE, goal adjustment
(lose -500 / maintain 0 / gain +300), floored (female 1200, male 1500) and
rounded. Macros from the calorie target: protein 30% and carbs 40% at 4
kcal/g, fats 30% at 9 kcal/g. See `internal/calc`.
