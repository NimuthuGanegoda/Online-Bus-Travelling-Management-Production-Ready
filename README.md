# Online Bus Travelling Management - Monorepo

This repository contains the **BusGo** ecosystem: a comprehensive suite of applications designed for modern bus management and passenger tracking.

## Project Overview

The BusGo system was built to provide a seamless experience for passengers, drivers, and administrators. It consists of:
- **Backend API:** A robust Node.js and Express server managing data flow and business logic.
- **Mobile Applications:** Dedicated Flutter apps for passengers (to track and book) and drivers (to manage trips).
- **Admin Dashboard:** A React-based web application for system-wide oversight and management.
- **AI Models:** Machine learning models for ETA prediction and intelligent emergency triage.

## Development & Technology Stack

This project was built using a modern, efficient workflow:
- **Design:** The frontend interfaces were meticulously designed using **Figma** to ensure a user-friendly and consistent aesthetic.
- **Frontend & Mobile:** 
  - **Flutter** was used for both the passenger and driver mobile applications to provide a high-performance cross-platform experience.
  - **React (TypeScript)** was employed for the Admin Web application, utilizing Vite for a modern development experience.
- **Backend:** 
  - Developed using **Node.js** and **Express.js**, with the assistance of **Claude AI** for optimized logic and **Visual Studio Code** as the primary IDE.
- **Database:** **Supabase (PostgreSQL)** handles all data storage, authentication, and real-time location broadcasting.
- **AI/ML:** Developed with Python using **Scikit-learn** and **Pandas**.

## Organized Structure

- `apps/backend/busgo-backend/`
  - Production-ready Node.js + Express backend API.
- `apps/frontend/busgo_admin/`
  - React + TypeScript + Vite admin dashboard.
- `apps/mobile/busgo_client/`
  - Flutter client app for passengers.
- `apps/mobile/busgo_drive/`
  - Flutter driver app for trip management.
- `apps/mobile/busgo_scanner/`
  - Flutter scanner app for ticket validation.
- `ai-models/neo-model-busgo/`
  - ML and data science experiments for ETA and triage.
- `demos/pre-payment-demo/`
  - Payee sandbox payment integration demo.
- `prototype/`
  - Git submodule to the initial project prototypes.

## Getting Started

### 1. Environment Setup
Each project requires its own configuration. See the `.env.example` files within each app directory. You will need a **Supabase** project for the backend to function.

### 2. Run the Backend
```bash
cd apps/backend/busgo-backend
npm install
npm run dev
```

### 3. Run the Admin Dashboard
```bash
cd apps/frontend/busgo_admin
npm install
npm run dev
```

### 4. Run Mobile Apps (Flutter)
Ensure you have the Flutter SDK installed.
```bash
cd apps/mobile/busgo_client
flutter pub get
flutter run
```

## Academic Supervision

This project was guided and supervised by **Ann Roshani Appuhamy**. This project is a part of an undergraduate coursework.
