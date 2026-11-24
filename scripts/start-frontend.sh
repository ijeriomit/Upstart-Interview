#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .agent
touch .agent/trace.log
exec > >(tee -a .agent/trace.log) 2>&1

echo "Starting frontend (Node + Vite)..."

if command -v nvm >/dev/null 2>&1; then
  echo "== nvm install =="
  nvm install
  echo "== nvm use =="
  nvm use
fi

echo "== node -v =="
node -v

echo "== npm -v =="
npm -v

echo "== npm ci =="
npm ci

echo "== npm start =="
echo "Frontend: http://localhost:4200"
npm start -- --host localhost
