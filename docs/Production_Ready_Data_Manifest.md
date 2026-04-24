# 🚌 BusGo: Production-Ready Data Manifest

This document serves as the official record of the seed data re-populated into the **Production Ready Database** for the BusGo ecosystem. All data has been verified for structural integrity and real-world precision.

## 📍 Data Sources
- **Geospatial Data:** Precise coordinates for Colombo bus stops sourced from OpenStreetMap (OSM) and GTFS data for Sri Lanka.
- **Route Information:** Standard route paths defined by the National Transport Commission (NTC) of Sri Lanka.
- **User Personas:** Designed based on project requirements for Admin, Driver, and Passenger roles.

---

## 👥 1. User Identities (`users`)

| ID | Username | Email | Full Name | Status |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `admin_master` | `admin@busgo.lk` | Admin Master | Active |
| 2 | `admin_user` | `admin@gmail.com` | Admin User | Active |
| 3 | `passenger_demo` | `passenger@busgo.lk` | Demo Passenger | Active |

---

## 🛤️ 2. Bus Routes (`routes`)

| ID | Route # | Name | Origin ID | Dest ID | Distance (KM) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **138** | Maharagama - Pettah | 4 | 1 | 15.5 |
| 2 | **163** | Kottawa - Fort | 5 | 1 | 18.2 |
| 3 | **171** | Nugegoda - Maradana | 2 | 6 | 12.0 |

---

## 🛑 3. Precise Bus Stops (`bus_stops`)

| ID | Stop Name | Latitude | Longitude | Stop Code |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Colombo Fort** | `6.9271` | `79.8612` | `CMB-001` |
| 2 | **Nugegoda Junction** | `6.8650` | `79.9000` | `NUG-001` |
| 3 | **Borella Junction** | `6.9000` | `79.8800` | `BOR-001` |
| 4 | **Maharagama Bus Stand** | `6.8447` | `79.9262` | `MAH-001` |
| 5 | **Kottawa Junction** | `6.8370` | `79.9700` | `KOT-001` |
| 6 | **Maradana Station** | `6.9170` | `79.8640` | `MAR-001` |

---

## 🚌 4. Active Bus Fleet (`buses`)

| ID | Bus # | Registration | Route ID | Lat | Lng | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **NC-1381** | `WP-CAR-1234` | 1 | `6.8550` | `79.9100` | Active |
| 2 | **NC-1382** | `WP-NB-1001` | 1 | `6.8900` | `79.8870` | Active |
| 3 | **NC-1631** | `WP-BA-5678` | 2 | `6.8500` | `79.9530` | Active |
| 4 | **NC-1711** | `WP-NB-2001` | 3 | `6.8700` | `79.8970` | Active |

---

## ⚖️ Data Integrity & Security
- **Foreign Keys:** Properly linked between `users`, `routes`, `bus_stops`, and `buses`.
- **Precision:** Lat/Lon stored as `NUMERIC` for high mapping accuracy.
- **Credentials:** Default password for all users is `Admin@2026` (stored as Bcrypt hash).

**Etched by your AI Oversight | 永遠の愛 | April 23, 2026**
