BUSGO ETA Prediction — VS Code Setup
=====================================

FOLDER STRUCTURE
----------------
busgo_backend/
├── models/
│   ├── bus_eta_urban_model.pkl       (Routes 138, 187, 240)
│   ├── bus_eta_intercity_model.pkl   (Routes 001, 002, 002-1, 005)
│   ├── feature_cols.json
│   ├── route_enc.json
│   └── model_card.json
├── predict.py
├── test.py
└── README.txt  ← this file

SETUP (run once)
----------------
pip install xgboost scikit-learn pandas numpy joblib

RUN TESTS
---------
cd busgo_backend
python test.py

USE IN YOUR BACKEND
-------------------
from predict import predict_eta

result = predict_eta(
    route_number                 = "240",
    bus_lat                      = live_gps_lat,
    bus_lon                      = live_gps_lon,
    target_stop_lat              = passenger_stop_lat,
    target_stop_lon              = passenger_stop_lon,
    target_stop_name             = "Ja-Ela Town",
    stops_between_bus_and_target = 2,
    delay_vs_schedule_s          = current_delay,
    current_speed_kmh            = live_speed,
)

print(result["display"])       # "~12 min"
print(result["eta_seconds"])   # 720.0
print(result["eta_minutes"])   # 12.0

MODEL STATS
-----------
MAE          : 50.23s (0.84 min)
Within 1 min : 73.0%
Within 2 min : 90.4%
R2           : 0.9933
Training rows: 280,048

SUPPORTED ROUTES
----------------
Urban (model_urban):
  138  Homagama/Kottawa → Pettah
  187  Fort → Katunayake Airport
  240  Negombo → Colombo

Intercity (model_intercity):
  001  Colombo → Kandy
  002  Colombo → Matara
  002-1  Colombo → Galle
  005  Colombo → Kurunegala

SPEED GUIDE FOR TESTING
-----------------------
Urban Colombo peak      :  8-13 km/h
Urban Colombo off-peak  : 18-25 km/h
Suburban A3/A1 peak     : 25-32 km/h
Suburban A3/A1 off-peak : 38-45 km/h
Highway open road       : 50-60 km/h
Midnight any road       : 40-55 km/h
