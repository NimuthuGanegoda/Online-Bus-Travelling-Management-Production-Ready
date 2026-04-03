# Smart City Management System: Public Transport and Emergency Response (Production-Ready)

This repository contains the formal implementation of the **Smart City Management System**, a project developed for the ECU Applied Project module (2026). It is designed to modernize public transportation and optimize emergency response through real-time tracking, machine learning predictions, and intelligent triage systems.

## Project Overview

The system is divided into two primary ecosystems:
- **Sarasi:** The frontend suite, providing intuitive mobile and web interfaces for passengers, drivers, and administrators.
- **Neo:** The backend and intelligence engine, housing the core logic, databases, and machine learning models that power the system's smart features.

## Key Features

### 🚌 Public Transport Management (Sarasi)
- **Passenger Application:**
  - **Real-time Tracking:** Live GPS monitoring of bus locations.
  - **ETA Predictions:** AI-powered estimated arrival times.
  - **Emergency Alerts:** One-touch SOS reporting for passengers.
  - **Rating & Feedback:** Direct reporting system for service quality.
- **Driver Application:**
  - **Trip Management:** Automated logging for starting and ending routes.
  - **Crowd Monitoring:** Real-time reporting of passenger density.
  - **Authentication:** NFC-based driver verification.

### 🧠 Intelligence & Backend (Neo)
- **Bus Arrival Estimation:** A machine learning model (`bus_arrival_model.joblib`) predicting ETAs based on historical traffic and trip data.
- **Intelligent Emergency Triage:** A sophisticated ranking system that prioritizes emergency reports based on severity, victim count, and incident type.
- **Driver Rating Analysis:** Automated classification of feedback to identify service improvements.

## Technology Stack
- **Mobile Frontend:** Flutter & Dart
- **Web Frontend:** React.js
- **Backend Services:** Node.js & Express
- **Machine Learning:** Python (Scikit-learn, Pandas, Joblib)
- **Database:** Supabase / SQLite

## Project Structure
```text
.
├── prototype/          # Git Submodule: Original research and initial prototypes
├── Neo/                # (Planned) Production Backend & ML Services
└── Sarasi/             # (Planned) Production Mobile & Web Applications
```

## Getting Started

### Prerequisites
- Git
- Flutter SDK (for mobile apps)
- Node.js (for backend services)
- Python 3.x (for ML models)

### Installation
To clone this repository along with its submodules:
```bash
git clone --recursive https://github.com/NimuthuGanegoda/Online-Bus-Travelling-Management-Production-Ready.git
```

If you have already cloned the repository, you can initialize the submodules with:
```bash
git submodule update --init --recursive
```

---
*Developed as part of the ECU Applied Project Module - 2026.*
