# Online Bus Travelling Management - Monorepo

This repository contains the BusGo ecosystem: backend APIs, web admin frontend, Flutter mobile apps, ML experiments, and a payment demo.

## Organized Structure

- `apps/backend/busgo-backend/`
  - Production-ready Node.js + Express backend API
- `apps/frontend/busgo_admin/`
  - React + TypeScript + Vite admin dashboard
- `apps/mobile/busgo_client/`
  - Flutter client app
- `apps/mobile/busgo_drive/`
  - Flutter driver app
- `apps/mobile/busgo_scanner/`
  - Flutter scanner app
- `ai-models/neo-model-busgo/`
  - ML and data science experiments
- `demos/pre-payment-demo/`
  - Payee sandbox payment integration demo
- `prototype/`
  - Git submodule to the prototype repository

## Reorganize Existing Folder Names

If your checkout still has old folder names (for example with spaces and inconsistent casing), run:

```bash
bash scripts/reorganize-repo.sh
```

## Getting Started

### 1. Clone and initialize submodules

```bash
git clone <repo-url>
cd Online-Bus-Travelling-Management-Production-Ready
git submodule update --init --recursive
```

### 2. Run backend

```bash
cd apps/backend/busgo-backend
npm install
npm run dev
```

### 3. Run admin web app

```bash
cd apps/frontend/busgo_admin
npm install
npm run dev
```

### 4. Run Flutter apps

Example for client app:

```bash
cd apps/mobile/busgo_client
flutter pub get
flutter run
```

Repeat similarly for `apps/mobile/busgo_drive` and `apps/mobile/busgo_scanner`.

### 5. Run payment demo

```bash
cd demos/pre-payment-demo
npm install
npm start
```

## Notes

- Each project is independently versioned and configured.
- Keep environment secrets in local `.env` files and never commit them.
- See each project's own README for project-specific setup details.

## Academic Supervision

This project was guided and supervised by **Ann Roshani Appuhamy**. This project is a part of an undergraduate coursework.
