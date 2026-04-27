# 🚌 BusGo: Online Bus Travelling Management

![Project Status](https://img.shields.io/badge/Status-Production--Ready-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

A comprehensive ecosystem for modern bus management and passenger tracking in Sri Lanka — passenger app, driver app, QR scanner, admin web dashboard and a production-grade REST backend.

---

## 👥 Project Team & Roles

| Name | Role | Responsibility |
| :--- | :--- | :--- |
| **Amiliya Fernando Pulle** | Backend Developer | System Architecture & API Development |
| **Sarasi Mahawattage** | Frontend Developer | UI/UX Design & Client-side Implementation |
| **Neo Red** | Machine Learning Engineer | Predictive Models & Intelligent Features |
| **Nimuthu Ganegoda** | Database Manager | Schema Design & Data Integrity |

---

## 🌟 Project Overview

| Component | Tech | Purpose |
|---|---|---|
| 🚀 **Backend** | Node.js + Express + Supabase (PostgreSQL) | REST API, JWT auth, real-time bus tracking, trip lifecycle |
| 📱 **Passenger App** (`busgo_client`) | Flutter | Search bus, live map, board/exit via QR, rate driver, ride history |
| 🚌 **Driver App** (`busgo_drive`) | Flutter | Live map for assigned route, passenger gauge, emergency alerts |
| 📷 **Scanner App** (`busgo_scanner`) | Flutter | QR scanner UI for boarding/offboarding (driver/conductor side) |
| 🌐 **Admin Dashboard** (`busgo_admin`) | React + TypeScript + Vite | Fleet management, emergency triage, audit logs, CSV exports |

---

## 🚦 Quick Start

### 1️⃣ Prerequisites

- **Node.js** ≥ 18 ([download](https://nodejs.org))
- **Flutter SDK** ≥ 3.8 ([install guide](https://docs.flutter.dev/get-started/install))
- A free **Supabase** project ([sign up](https://supabase.com))
- **Git**

### 2️⃣ Clone the Repository

```bash
git clone https://github.com/NimuthuGanegoda/Online-Bus-Travelling-Management-Production-Ready.git
cd Online-Bus-Travelling-Management-Production-Ready
```

### 3️⃣ Install all dependencies

```bash
npm run install:all
```

This installs deps for backend, admin, passenger app, driver app, and scanner app.

### 4️⃣ Configure the backend

```bash
cd apps/backend/busgo-backend
cp .env.example .env
# Edit .env — fill in your Supabase URL + keys (see backend README for details)
cd ../../..
```

### 5️⃣ Set up the database

In your Supabase dashboard → **SQL Editor** → run **in order**:

1. `apps/backend/busgo-backend/src/db/full_setup.sql` — base schema, admin schema, seed data
2. `apps/backend/busgo-backend/src/db/driver_migration.sql` — driver app additions
3. `apps/backend/busgo-backend/src/db/payments_migration.sql` — payments module

Then create a Storage bucket named `avatars` (public).

### 6️⃣ Run the apps

Open **5 separate terminals** at the project root:

```bash
# Terminal 1 — Backend (Express API)
npm run dev:backend          # → http://localhost:5000

# Terminal 2 — Admin Dashboard
npm run dev:frontend         # → http://localhost:5173

# Terminal 3 — Passenger App (Chrome)
npm run dev:mobile           # → opens new Chrome tab

# Terminal 4 — Driver App (Chrome)
npm run dev:driver           # → opens new Chrome tab

# Terminal 5 — Scanner App (Chrome)
npm run dev:scanner          # → opens new Chrome tab
```

---

## 🔑 Demo Credentials

The seed scripts create a few demo accounts so you can try every flow immediately.

### Passenger App (`busgo_client`)

| Email | Password |
|---|---|
| `admin@gmail.com` | `12345678` |

### Driver App (`busgo_drive`)

Driver default password = their driver code (until they change it).

| Email / Code | Password | Status |
|---|---|---|
| `kamal@busgo.lk` / `DRV-001` | `DRV-001` | ✅ active |
| `saman@busgo.lk` / `DRV-002` | `DRV-002` | ✅ active |
| `amara@busgo.lk` / `DRV-005` | `DRV-005` | ✅ active |
| `nimal@busgo.lk` / `DRV-003` | `DRV-003` | ❌ inactive |
| `ruwan@busgo.lk` / `DRV-004` | `DRV-004` | ⚠️ pending approval |

### Admin Dashboard (`busgo_admin`)

| Email | Password | Role |
|---|---|---|
| `admin@busgo.lk` | `Admin@2026` | super_admin |
| `kasun@busgo.lk` | `Admin@2026` | admin |
| `dilani@busgo.lk` | `Admin@2026` | admin |

---

## 📁 Repository Structure

```text
Online-Bus-Travelling-Management-Production-Ready/
├── 📂 apps/
│   ├── 📂 backend/busgo-backend/       # Express.js + Supabase REST API
│   ├── 📂 frontend/busgo_admin/        # React admin dashboard
│   └── 📂 mobile/
│       ├── 📂 busgo_client/            # Flutter passenger app
│       ├── 📂 busgo_drive/             # Flutter driver app
│       └── 📂 busgo_scanner/           # Flutter QR scanner app
├── 📂 docs/                            # Compliance reports, viva script
├── 📂 scripts/                         # DB population helpers
├── package.json                        # Monorepo run scripts
└── README.md
```

---

## 📚 Useful npm Scripts

| Command | What it does |
|---|---|
| `npm run install:all` | Install dependencies for backend + admin + all 3 mobile apps |
| `npm run install:backend` / `:frontend` / `:mobile` / `:driver` / `:scanner` | Install one component's deps |
| `npm run dev:backend` | Run Express API in watch mode |
| `npm run dev:frontend` | Run admin dashboard (Vite) |
| `npm run dev:mobile` | Run passenger app in Chrome |
| `npm run dev:driver` | Run driver app in Chrome |
| `npm run dev:scanner` | Run scanner app in Chrome |
| `npm run start:backend` | Run backend without nodemon (production-style) |
| `npm run build:frontend` | Build admin dashboard for production |
| `npm run lint:backend` / `:frontend` | Run linters |

---

## 🎓 Academic Supervision

This project was guided and supervised by **Ann Roshanie Appuhamy**.
Submitted as part of undergraduate unit coursework — **CSG3101 Applied Project**.
