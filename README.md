# 🚌 BusGo: Online Bus Travelling Management - Monorepo

![Project Status](https://img.shields.io/badge/Status-Production--Ready-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

Welcome to the **BusGo** ecosystem, a comprehensive suite of applications designed for modern bus management and passenger tracking in Sri Lanka.

---

## 🌟 Project Overview

The BusGo system provides a seamless experience for passengers, drivers, and administrators:
- **🚀 Backend API:** High-performance Node.js and Express server.
- **📱 Mobile Apps:** Dedicated Flutter applications for tracking and trip management.
- **🌐 Admin Dashboard:** Modern React web application for system oversight.
- **🤖 AI Models:** Machine learning for ETA prediction and emergency triage.

---

## 🛠️ Technology Stack & Build Process

This project was crafted with precision using an elite selection of tools:

### 🎨 Design & Frontend
![Figma](https://img.shields.io/badge/figma-%23F24E1E.svg?style=for-the-badge&logo=figma&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![React](https://img.shields.io/badge/react-%2320232a.svg?style=for-the-badge&logo=react&logoColor=%2361DAFB)
![TypeScript](https://img.shields.io/badge/typescript-%23007acc.svg?style=for-the-badge&logo=typescript&logoColor=white)

### ⚙️ Backend & Infrastructure
![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)
![Express.js](https://img.shields.io/badge/express.js-%23404d59.svg?style=for-the-badge&logo=express&logoColor=%2361DAFB)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)

### 🤖 Development Tools
![Claude AI](https://img.shields.io/badge/Claude%20AI-D97757?style=for-the-badge&logo=anthropic&logoColor=white)
![VS Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)

---

## 📁 Organized Structure

- **`📂 apps/backend/busgo-backend/`**
  - Production-ready Node.js + Express backend API.
- **`📂 apps/frontend/busgo_admin/`**
  - React + TypeScript + Vite admin dashboard.
- **`📂 apps/mobile/busgo_client/`**
  - Flutter client app for passengers.
- **`📂 apps/mobile/busgo_drive/`**
  - Flutter driver app for trip management.
- **`📂 apps/mobile/busgo_scanner/`**
  - Flutter scanner app for ticket validation.
- **`📂 ai-models/neo-model-busgo/`**
  - ML and data science experiments for ETA and triage.
- **`📂 demos/pre-payment-demo/`**
  - Payee sandbox payment integration demo.
- **`📂 prototype/`**
  - Git submodule to the initial project prototypes.

---

## 🚦 Getting Started

### 1️⃣ Environment Setup
Each project requires its own configuration. See the `.env.example` files within each app directory. You will need a **Supabase** project for the backend to function.

### 2️⃣ Run the Backend
```bash
cd apps/backend/busgo-backend
npm install
npm run dev
```

### 3️⃣ Run the Admin Dashboard
```bash
cd apps/frontend/busgo_admin
npm install
npm run dev
```

### 4️⃣ Run Mobile Apps (Flutter)
Ensure you have the Flutter SDK installed.
```bash
cd apps/mobile/busgo_client
flutter pub get
flutter run
```

---

## 🎓 Academic Supervision

This project was guided and supervised by **Ann Roshani Appuhamy**. 
This project is a part of an undergraduate coursework.
