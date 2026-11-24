#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .agent
touch .agent/trace.log
exec > >(tee -a .agent/trace.log) 2>&1

echo "Starting Accounts Dashboard stack..."

./scripts/start-backend.sh &
BACKEND_PID=$!

./scripts/start-frontend.sh &
FRONTEND_PID=$!

cleanup() {
  echo "Shutting down..."
  kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
  docker compose stop db || true
}
trap cleanup INT TERM EXIT

echo "Frontend: http://localhost:4200"
echo "Rails API: http://localhost:3000"
echo "DB: localhost:5433"
wait
