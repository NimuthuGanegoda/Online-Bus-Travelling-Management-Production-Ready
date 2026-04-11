# 🚌 BusGo: Online Bus Travelling Management

![Project Status](https://img.shields.io/badge/Status-Production--Ready-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

Welcome to the **BusGo** ecosystem, a comprehensive suite of applications designed for modern bus management and passenger tracking in Sri Lanka.

## 👥 Project Team & Roles

| Name | Role | Responsibility |
| :--- | :--- | :--- |
| **Amiliya Fernando Pulle** | Backend Developer | System Architecture & API Development |
| **Sarasi Mahawattage** | Frontend Developer | UI/UX Design & Client-side Implementation |
| **Neo Red** | Machine Learning Engineer | Predictive Models & Intelligent Features |
| **Nimuthu Ganegoda** | Database Manager | Schema Design & Data Integrity |

---

## 🌟 Project Overview

The BusGo system provides a seamless experience for passengers, drivers, and administrators:
- **🚀 Backend Server:** High-performance Node.js and Express API.
- **📱 Mobile Apps:** Dedicated Flutter applications for tracking and trip management.
- **🌐 Admin Dashboard:** Modern React web application for system oversight.
- **🤖 AI Models:** Machine learning for ETA prediction and emergency triage.

---

## 🏗️ System Architecture

The project is organized into logical domains to ensure clarity and scalability:

### 1. Core Backend Server (`apps/backend/`)
The engine of the system, built with **Express.js** and **Supabase (PostgreSQL)**. This is the central hub for authentication, real-time tracking, and trip management.
- **Key Features:** JWT security, Role-based Access Control (RBAC), and Real-time updates.

### 2. Intelligent Layer (`ai-models/`)
The **Neo** engine provides predictive intelligence.
- **Driver Rating:** Sentiment analysis on multi-language reviews.
- **ETA Estimation:** Traffic-aware arrival predictions.
- **Emergency Triage:** Automated priority filtering for incidents.

### 3. Client Interface Applications (`apps/mobile/` & `apps/frontend/`)
A suite of **Flutter** and **React** applications tailored for each user role:
- **Passenger App:** Route finding, tracking, and seat booking.
- **Driver App:** Trip updates and passenger management.
- **Admin Dashboard:** System-wide monitoring and resource allocation.

---

## 🛠️ Technology Stack

| Domain | Technologies |
| :--- | :--- |
| **Frontend** | React, TypeScript, Vite, Tailwind CSS |
| **Mobile** | Flutter, Dart |
| **Backend** | Node.js, Express, Supabase (PostgreSQL) |
| **AI/ML** | Python, Scikit-learn, XGBoost, LightGBM |
| **Tools** | Git, Claude AI, VS Code |

---

## 🚦 Getting Started

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/NimuthuGanegoda/Online-Bus-Travelling-Management-Production-Ready.git
cd Online-Bus-Travelling-Management-Production-Ready
```

### 2️⃣ Component Setup
Navigate to each sub-directory to set up the individual services:

- **Backend Server:** `cd apps/backend/busgo-backend && npm install`
- **Admin Dashboard:** `cd apps/frontend/busgo_admin && npm install`
- **Mobile Apps:** `cd apps/mobile/busgo_client && flutter pub get`

### 3️⃣ Configuration
- Copy `.env.example` to `.env` in each respective directory.
- Ensure your **Supabase** credentials are correctly set in the backend environment file.

---

## 📁 Repository Structure

```text
Online-Bus-Travelling-Management-Production-Ready/
├── 📂 apps/
│   ├── 📂 backend/        # Core Backend Server (Express.js API)
│   ├── 📂 frontend/       # React Admin Dashboard
│   └── 📂 mobile/         # Flutter Client & Driver Apps
├── 📂 ai-models/          # Neo Engine (ML Models)
├── 📂 demos/              # Payment & Feature sandboxes
└── 📂 prototype/          # Legacy prototypes & submodules
```
