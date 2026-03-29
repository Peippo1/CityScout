# CityScout Backend

This backend is a lightweight FastAPI service for CityScout. It sits between the iOS app and OpenAI so API keys and orchestration logic stay on the server.

It includes a simple shared-secret header check and in-memory rate limiting for private testing. This is not full user authentication.

## Create a Virtual Environment

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
```

## Install Dependencies

```bash
./.venv/bin/python -m pip install -r requirements.txt
```

## Configure Environment Variables

```bash
cp .env.example .env
```

Update `.env` for local development and private testing.

Required variables:
- `APP_ENV` (development, test, staging, production)
- `OPENAI_API_KEY`
- `APP_SHARED_SECRET`

Optional variables:
- `APP_ALLOWED_ORIGIN` or `APP_ALLOWED_ORIGINS` (comma-separated) for staging/testing CORS

## Run Locally

```bash
./run_dev.sh
```

The API will start on `http://127.0.0.1:8000`.
If `8000` is already taken, the script will automatically use the next free port.

This uses the backend virtual environment directly, which avoids accidentally
starting `uvicorn` from a different global Python installation.

## Run Tests

```bash
pytest
```

## Example Requests

Health check:

```bash
curl http://127.0.0.1:8000/health
```

Plan itinerary:

```bash
curl -X POST http://127.0.0.1:8000/plan-itinerary \
  -H "X-CityScout-App-Secret: your_shared_secret" \
  -H "Content-Type: application/json" \
  -d '{
    "destination": "Paris",
    "prompt": "Plan me a relaxed day with coffee and art",
    "preferences": ["Relaxed", "Cafes", "Sightseeing"],
    "saved_places": ["Louvre Museum", "Cafe de Flore"]
  }'
```
