# Online Bus Travelling Management - Monorepo

This repository contains the BusGo ecosystem: backend APIs, web admin frontend, Flutter mobile apps, ML experiments, and a payment demo.

## Repository Structure

- `BusGo Back-end/busgo-backend/`
  - Production-ready Node.js + Express backend API
- `BusGo Front-end/busgo_admin/`
  - React + TypeScript + Vite admin dashboard
- `BusGo Front-end/busgo_client/`
  - Flutter client app
- `BusGo Front-end/busgo_drive/`
  - Flutter driver app
- `BusGo Front-end/busgo_scanner/`
  - Flutter scanner app
- `NEO_MODEL_BUSGO/`
  - ML and data science experiments
- `PRE_PAYMENT_DEMO/`
  - Payee sandbox payment integration demo
- `prototype/`
  - Git submodule to the prototype repository

## Getting Started

### 1. Clone and initialize submodules

```bash
git clone <repo-url>
cd Online-Bus-Travelling-Management-Production-Ready
git submodule update --init --recursive
```

### 2. Run backend

```bash
cd "BusGo Back-end/busgo-backend"
npm install
npm run dev
```

### 3. Run admin web app

```bash
cd "BusGo Front-end/busgo_admin"
npm install
npm run dev
```

### 4. Run Flutter apps

Example for client app:

```bash
cd "BusGo Front-end/busgo_client"
flutter pub get
flutter run
```

Repeat similarly for `busgo_drive` and `busgo_scanner`.

### 5. Run payment demo

```bash
cd PRE_PAYMENT_DEMO
npm install
npm start
```

## Notes

- Each project is independently versioned and configured.
- Keep environment secrets in local `.env` files and never commit them.
- See each project's own README for project-specific setup details.
