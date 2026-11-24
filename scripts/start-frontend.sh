#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .agent
touch .agent/trace.log
exec > >(tee -a .agent/trace.log) 2>&1

echo "Starting frontend (Node + Vite)..."

nvm_script="${NVM_DIR:-$HOME/.nvm}/nvm.sh"
if ! command -v nvm >/dev/null 2>&1 && [[ -s "$nvm_script" ]]; then
  source "$nvm_script" --no-use
fi

if command -v nvm >/dev/null 2>&1; then
  echo "== nvm use =="
  nvm use || nvm install
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
