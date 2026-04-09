#!/usr/bin/env bash
set -euo pipefail

# Reorganizes the repository into a clean monorepo layout.
# Run from repository root:
#   bash scripts/reorganize-repo.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d ".git" ]]; then
  echo "Error: must run inside repository root."
  exit 1
fi

mkdir -p apps/backend
mkdir -p apps/frontend
mkdir -p apps/mobile
mkdir -p ai-models
mkdir -p demos
mkdir -p docs

# Move backend
if [[ -d "BusGo Back-end/busgo-backend" && ! -d "apps/backend/busgo-backend" ]]; then
  mv "BusGo Back-end/busgo-backend" "apps/backend/busgo-backend"
fi

# Move web admin
if [[ -d "BusGo Front-end/busgo_admin" && ! -d "apps/frontend/busgo_admin" ]]; then
  mv "BusGo Front-end/busgo_admin" "apps/frontend/busgo_admin"
fi

# Move Flutter mobile apps
if [[ -d "BusGo Front-end/busgo_client" && ! -d "apps/mobile/busgo_client" ]]; then
  mv "BusGo Front-end/busgo_client" "apps/mobile/busgo_client"
fi

if [[ -d "BusGo Front-end/busgo_drive" && ! -d "apps/mobile/busgo_drive" ]]; then
  mv "BusGo Front-end/busgo_drive" "apps/mobile/busgo_drive"
fi

if [[ -d "BusGo Front-end/busgo_scanner" && ! -d "apps/mobile/busgo_scanner" ]]; then
  mv "BusGo Front-end/busgo_scanner" "apps/mobile/busgo_scanner"
fi

# Move ML and demos
if [[ -d "NEO_MODEL_BUSGO" && ! -d "ai-models/neo-model-busgo" ]]; then
  mv "NEO_MODEL_BUSGO" "ai-models/neo-model-busgo"
fi

if [[ -d "PRE_PAYMENT_DEMO" && ! -d "demos/pre-payment-demo" ]]; then
  mv "PRE_PAYMENT_DEMO" "demos/pre-payment-demo"
fi

# Clean up empty legacy containers if empty
rmdir "BusGo Back-end" 2>/dev/null || true
rmdir "BusGo Front-end" 2>/dev/null || true

cat <<'EOF'
Reorganization complete.

New layout:
- apps/backend/busgo-backend
- apps/frontend/busgo_admin
- apps/mobile/busgo_client
- apps/mobile/busgo_drive
- apps/mobile/busgo_scanner
- ai-models/neo-model-busgo
- demos/pre-payment-demo
- prototype (submodule remains at root)

Next steps:
1) Verify app run commands using new paths.
2) Update any CI/workflow path references if needed.
3) Commit the rename/move changes.
EOF
