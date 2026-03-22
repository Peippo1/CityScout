# CityScout Backend

This backend is a lightweight FastAPI service for CityScout. Its job is to sit between the iOS app and future AI itinerary generation so API keys and orchestration logic stay on the server.

For now, the itinerary endpoint returns structured mocked JSON. The project is set up so the mock service can later be replaced with a real OpenAI-backed implementation without changing the route contract.

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

Update `.env` when you are ready to add a real OpenAI integration.

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
  -H "Content-Type: application/json" \
  -d '{
    "destination": "Paris",
    "prompt": "Plan me a relaxed day with coffee and art",
    "preferences": ["Relaxed", "Cafes", "Sightseeing"],
    "saved_places": ["Louvre Museum", "Cafe de Flore"]
  }'
```
