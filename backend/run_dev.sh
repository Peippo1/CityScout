#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PYTHON="$ROOT_DIR/.venv/bin/python"
DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT="8000"

if [[ ! -x "$VENV_PYTHON" ]]; then
  echo "Missing backend virtual environment at $VENV_PYTHON" >&2
  echo "Create it with: cd backend && python3 -m venv .venv" >&2
  echo "Then install deps with: ./.venv/bin/python -m pip install -r requirements.txt" >&2
  exit 1
fi

has_explicit_port=false
args=("$@")

for ((i = 0; i < ${#args[@]}; i++)); do
  if [[ "${args[$i]}" == "--port" ]]; then
    has_explicit_port=true
    break
  fi
done

if [[ "$has_explicit_port" == false ]]; then
  selected_port="$("$VENV_PYTHON" - <<'PY'
import socket

host = "127.0.0.1"
for port in range(8000, 8011):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if sock.connect_ex((host, port)) != 0:
            print(port)
            break
else:
    raise SystemExit("No free port found between 8000 and 8010.")
PY
)"

  if [[ "$selected_port" != "$DEFAULT_PORT" ]]; then
    echo "Port $DEFAULT_PORT is already in use. Starting backend on http://$DEFAULT_HOST:$selected_port instead."
  fi

  args+=(--port "$selected_port")
fi

cd "$ROOT_DIR"
exec "$VENV_PYTHON" -m uvicorn app.main:app --reload "${args[@]}"
