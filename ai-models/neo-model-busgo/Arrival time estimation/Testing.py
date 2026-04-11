import pandas as pd
import numpy as np
import joblib
import json
from datetime import datetime

# 1. LOAD MODEL AND METADATA
try:
    model = joblib.load("optimized_bus_model.pkl")
    driver_encoder = joblib.load("driver_id_encoder.pkl")
    with open("model_metadata.json", "r") as f:
        metadata = json.load(f)
    FEATURE_COLS = metadata['features']
    print("✅ Model and Metadata loaded successfully.")
except FileNotFoundError as e:
    print(f"❌ Error: Missing files. Ensure .pkl and .json files are in this folder. {e}")
    exit()

def predict_bus_eta(bus_no, dist_km, stops, speed_kmh, is_raining, hour):
    """
    Simulates the backend processing before feeding data into the ML model.
    """
    # Math conversions for time
    h_sin = np.sin(2 * np.pi * hour / 24)
    h_cos = np.cos(2 * np.pi * hour / 24)
    
    # Logic: Peak Hour (Colombo standard)
    is_peak = 1 if (7 <= hour <= 9 or 16 <= hour <= 19) else 0
    
    # Logic: Skip-Stop (If bus is fast and stops are few)
    # We assume low dwell time for this manual test
    is_full_skip = 1 if (speed_kmh > 35 and stops < 5) else 0
    
    # Try to encode the bus number; fallback to 0 if new
    try:
        driver_enc = driver_encoder.transform([bus_no])[0]
    except:
        driver_enc = 0 

    # Prepare data dictionary matching FEATURE_COLS
    input_dict = {
        "total_distance_to_target_m": dist_km * 1000,
        "stops_between_bus_and_target": stops,
        "avg_segment_distance_m": (dist_km * 1000) / (stops + 1),
        "route_encoded": 1, 
        "road_type_encoded": 1,
        "hour_sin": h_sin,
        "hour_cos": h_cos,
        "is_peak_hour": is_peak,
        "is_raining": int(is_raining),
        "is_public_holiday": 0,
        "current_speed_kmh": speed_kmh,
        "dwell_at_last_stop_s": 20,
        "driver_id_enc": driver_enc,
        "is_full_skip": is_full_skip,
        "dist_per_stop": (dist_km * 1000) / (stops + 1),
        "peak_traffic_index": is_peak * (1 / (speed_kmh + 1))
    }

    # Convert to DataFrame
    df_input = pd.DataFrame([input_dict])
    
    # Predict (Output is in log_seconds_per_km)
    log_pred = model.predict(df_input[FEATURE_COLS])[0]
    
    # Conversion: eta_seconds = exp(log_pred) * distance_km
    eta_seconds = np.expm1(log_pred) * dist_km
    return eta_seconds / 60

# ==========================================
# 2. RUN YOUR TESTS HERE
# ==========================================
print("\n--- BUS ETA VS GOOGLE MAPS COMPARISON ---")

# Example: Testing Route 177 Kaduwela to Kollupitiya
test_bus = "WP-NB-8237"
distance = 1.4    # Look this up on Google Maps (km)
num_stops = 5    # Estimated stops on this route
current_speed = 16 # Current bus speed kmh
raining = True
current_hour = datetime.now().hour

predicted_min = predict_bus_eta(test_bus, distance, num_stops, current_speed, raining, current_hour)

print(f"Bus Number    : {test_bus}")
print(f"Distance      : {distance} km")
print(f"Current Speed : {current_speed} km/h")
print(f"Rain Status   : {'Raining' if raining else 'Clear'}")
print("-" * 40)
print(f"ML ESTIMATED ETA : {predicted_min:.2f} minutes")
print("Now, check the same route on Google Maps and compare!")