# 📋 BusGo: Production-Ready Data Source Manifest

This manifest documents the technical origins, acquisition methodology, and validation processes for the data populated into the **Production Ready Database**. This document serves as the primary reference for data integrity audits.

## 🛠️ Data Compilation Methodology

### 1. Geospatial Research & Scraping
- **Coordinate Acquisition:** Precise latitude and longitude data for 20 major Colombo transit hubs were compiled by scraping **OpenStreetMap (OSM)** and **Google Maps** geospatial layers.
- **Route Validation:** Route numbers, hub connections, and stop sequences were sourced from the **National Transport Commission (NTC) Sri Lanka** official route registry and the **Routemaster.lk** database.
- **Validation:** All geospatial points were manually verified to fall within the Colombo Municipal Council (CMC) boundaries to ensure localized system accuracy.

### 2. Operational Data Synthesis (Production-Scale)
To simulate a live production environment with 1,500+ records, a **Statistical Synthesis** approach was utilized:
- **Identity Modeling:** User and Driver profiles were generated using standard Sri Lankan naming conventions and **Department of Registration of Persons (DRP)** National Identity Card (NIC) formats.
- **Financial Modeling:** Transaction values and trip fares were calculated based on the **2024 NTC Revised Fare Stages** for standard city services.
- **Telemetry Simulation:** Location logs and system audit events were generated using a time-series model that mirrors real-world transit frequencies and administrative activity in the Colombo region.

---

## 🛑 1. Verified Transit Nodes (Primary Set)
The following hubs were utilized as the root nodes for the dataset:
- Pettah (Central), Colombo Fort, Town Hall, Borella, Kollupitiya, Bambalapitiya, Wellawatta, Dehiwala, Mt. Lavinia, Ratmalana, Moratuwa, Panadura, Nugegoda, Maharagama, Kottawa, Homagama, Rajagiriya, Battaramulla, Malabe, Kaduwela.

---

## 📊 2. Dataset Composition

| Table | Volume | Methodology |
| :--- | :--- | :--- |
| `users` | 200 | Synthesized (DRP Compliance) |
| `bus_stops` | 20 | Scraped (OSM/NTC) |
| `routes` | 10 | Compiled (NTC Registry) |
| `buses` | 50 | Synthesized (DMT Western Province Standards) |
| `past_trip_history`| 200 | Modeled (Peak-Hour Simulation) |
| `driver_ratings` | 200 | Synthesized (Performance Feedback Loops) |
| `emergency_alerts`| 100 | Modeled (Metropolitan Incident Triage) |
| `qr_scans` | 200 | Event-Based Synthesis (Boarding/Alighting) |
| `audit_logs` | 200 | Compiled (System Initialization & Admin Events) |
| `location_logs` | 500+ | Telemetry Synthesis (High-Frequency RTT) |

---

## ⚖️ Compliance & Data Ownership
This dataset was compiled and validated by the **Lead Systems Architect** to support the development and performance testing of the BusGo ecosystem. All synthetic data is modeled after real-world Sri Lankan transit standards to ensure the highest level of functional realism.

**Document Version:** 2.0 (Production-Ready)  
**Last Verified:** April 23, 2026  
**Status:** Certified for Production Testing
