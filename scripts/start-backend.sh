#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .agent
touch .agent/trace.log
exec > >(tee -a .agent/trace.log) 2>&1

echo "Starting backend (Docker + Rails)..."

echo "== Docker compose up db =="
docker compose up -d --wait db

echo "== Docker compose ps =="
docker compose ps

echo "== Docker compose db logs (tail) =="
docker compose logs --tail 30 db || true

cd backend

echo "== bundle install =="
bundle install

echo "== rails db:prepare =="
bin/rails db:prepare

echo "== rails db:seed =="
bin/rails db:seed

echo "== rails server =="
echo "Rails API: http://localhost:3000"
bin/rails server -b localhost
