# ============================================================
#  predict.py  —  BUSGO ETA Prediction Engine
#  Built from your verified Colab model files
#
#  Models loaded:
#    Urban     : Routes 138, 187, 240
#    Intercity : Routes 001, 002, 002-1, 005
#
#  Accuracy:
#    MAE          : 50.23s  (0.84 min)
#    Within 1 min : 73.0%
#    Within 2 min : 90.4%
#    R²           : 0.9933
# ============================================================

import joblib
import json
import math
import numpy as np
import pandas as pd
from datetime import datetime

# ── Load models once at startup ───────────────────────────────
_BASE = "models"

model_urban     = joblib.load(f"{_BASE}/bus_eta_urban_model.pkl")
model_intercity = joblib.load(f"{_BASE}/bus_eta_intercity_model.pkl")

with open(f"{_BASE}/feature_cols.json") as f:
    FEATURE_COLS = json.load(f)

with open(f"{_BASE}/route_enc.json") as f:
    ROUTE_ENC = json.load(f)

with open(f"{_BASE}/model_card.json") as f:
    MODEL_CARD = json.load(f)

print("=" * 50)
print("  ✅ BUSGO ETA Models loaded successfully")
print("=" * 50)
print(f"  Urban model     : {_BASE}/bus_eta_urban_model.pkl")
print(f"  Intercity model : {_BASE}/bus_eta_intercity_model.pkl")
print(f"  Features        : {len(FEATURE_COLS)}")
print(f"  Urban routes    : {MODEL_CARD['urban_routes']}")
print(f"  Intercity routes: {MODEL_CARD['intercity_routes']}")
print(f"  MAE             : {MODEL_CARD['combined_mae_s']}s ({MODEL_CARD['combined_mae_min']} min)")
print(f"  Within 1 min    : {MODEL_CARD['within_1min_%']}%")
print(f"  Within 2 min    : {MODEL_CARD['within_2min_%']}%")
print("=" * 50)

# ── Constants ─────────────────────────────────────────────────
URBAN_ROUTES  = ["138", "187", "240"]
PEAK_WINDOWS  = [(420, 570), (1020, 1170)]   # 07:00-09:30 and 17:00-19:30
SW_MONSOON    = {5, 6, 7, 8, 9}
NE_MONSOON    = {11, 12, 1}

POYA_2024 = {
    (2024,1,25),(2024,2,24),(2024,3,25),(2024,4,23),
    (2024,5,23),(2024,6,22),(2024,7,21),(2024,8,19),
    (2024,9,18),(2024,10,17),(2024,11,15),(2024,12,15),
}
NAT_HOL_2024 = {
    (2024,2,4),(2024,4,13),(2024,4,14),(2024,5,1),
    (2024,5,24),(2024,12,25),
}

# ── Speed reference guide for test inputs ─────────────────────
# Urban Colombo peak      :  8-13 km/h
# Urban Colombo off-peak  : 18-25 km/h
# Suburban A3/A1 peak     : 25-32 km/h
# Suburban A3/A1 off-peak : 38-45 km/h
# Highway open road       : 50-60 km/h
# Midnight any road       : 40-55 km/h


def _is_peak(hour, minute=0):
    t = hour * 60 + minute
    return int(any(s <= t <= e for s, e in PEAK_WINDOWS))


def _haversine_m(lat1, lon1, lat2, lon2):
    R  = 6371000
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    a  = (math.sin(math.radians(lat2 - lat1) / 2) ** 2
          + math.cos(p1) * math.cos(p2)
          * math.sin(math.radians(lon2 - lon1) / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def predict_eta(
    route_number,
    bus_lat,
    bus_lon,
    target_stop_lat,
    target_stop_lon,
    target_stop_name,
    stops_between_bus_and_target,
    delay_vs_schedule_s,
    current_speed_kmh    = None,
    dwell_at_last_stop_s = 40,
    is_raining           = 0,
    timestamp            = None,
):
    """
    Predict full ETA from bus current position to passenger stop.
    One call returns the complete answer — no segment adding needed.

    Parameters
    ----------
    route_number                 : "138","187","240","001","002","002-1","005"
    bus_lat / bus_lon            : live GPS from driver app
    target_stop_lat / lon        : passenger chosen stop GPS
    target_stop_name             : for display only
    stops_between_bus_and_target : number of intermediate stops
    delay_vs_schedule_s          : seconds late (positive = late)
    current_speed_kmh            : live GPS speed (auto-inferred if None)
    dwell_at_last_stop_s         : seconds bus paused at last stop
    is_raining                   : 1 or 0
    timestamp                    : datetime (defaults to now)

    Returns dict with:
      eta_seconds, eta_minutes, display, distance_km,
      speed_kmh, spk, model_used, is_peak, confidence
    """

    if timestamp is None:
        timestamp = datetime.now()

    h   = timestamp.hour
    mi  = timestamp.minute
    dow = timestamp.weekday()
    mon = timestamp.month
    day = timestamp.day
    yr  = timestamp.year

    # Road distance via Haversine × 1.13 road factor
    straight_m = _haversine_m(bus_lat, bus_lon, target_stop_lat, target_stop_lon)
    dist_m     = straight_m * 1.13
    dist_km    = dist_m / 1000

    # Already at the stop
    if dist_km < 0.1:
        return {
            "route_number": route_number,
            "target_stop":  target_stop_name,
            "eta_seconds":  15.0,
            "eta_minutes":  0.25,
            "display":      "🚌 Arriving now",
            "distance_km":  round(dist_km, 3),
            "speed_kmh":    0.0,
            "spk":          0.0,
            "is_peak":      bool(_is_peak(h, mi)),
            "model_used":   "urban" if route_number in URBAN_ROUTES else "intercity",
            "model_calls":  1,
            "confidence":   "High",
            "timestamp":    str(timestamp),
        }

    # Auto-infer speed from conditions if not supplied
    if current_speed_kmh is None:
        current_speed_kmh = 13.0 if _is_peak(h, mi) else 28.0
        if is_raining:
            current_speed_kmh *= 0.83

    pk_f      = _is_peak(h, mi)
    avg_seg_m = dist_m / max(stops_between_bus_and_target + 1, 1)
    frac      = max(0.0, min(1 - dist_km / 100, 0.98))
    log_d     = math.log1p(dist_m)
    rt_enc    = ROUTE_ENC.get(route_number, 1)
    rd_enc    = 0 if route_number == "138" else 1

    hs = round(math.sin(2 * math.pi * h   / 24), 6)
    hc = round(math.cos(2 * math.pi * h   / 24), 6)
    ms = round(math.sin(2 * math.pi * mon / 12), 6)
    mc = round(math.cos(2 * math.pi * mon / 12), 6)

    is_py  = int((yr, mon, day) in POYA_2024)
    is_hol = int((yr, mon, day) in NAT_HOL_2024) or is_py
    is_sc  = int(dow < 5 and mon in {1,2,3,4,5,9,10,11,12})
    is_mo  = int(mon in SW_MONSOON or mon in NE_MONSOON)

    peak_speed_int = pk_f * current_speed_kmh
    dist_per_stop  = dist_m / max(stops_between_bus_and_target + 1, 1)
    delay_ratio    = (
        min(max(delay_vs_schedule_s, -300), 1500) /
        max(dist_km * 120, 60)
    )

    features = pd.DataFrame([{
        "total_distance_to_target_m":   dist_m,
        "stops_between_bus_and_target": stops_between_bus_and_target,
        "avg_segment_distance_m":       avg_seg_m,
        "fraction_trip_completed":      frac,
        "log_distance":                 log_d,
        "route_encoded":                rt_enc,
        "road_type_encoded":            rd_enc,
        "hour_sin":                     hs,
        "hour_cos":                     hc,
        "month_sin":                    ms,
        "month_cos":                    mc,
        "observation_hour":             h,
        "day_of_week":                  dow,
        "is_peak_hour":                 pk_f,
        "is_weekend":                   int(dow >= 5),
        "is_public_holiday":            is_hol,
        "is_poya_day":                  is_py,
        "is_school_day":                is_sc,
        "is_monsoon_season":            is_mo,
        "is_raining":                   is_raining,
        "current_speed_kmh":            current_speed_kmh,
        "delay_vs_schedule_s":          delay_vs_schedule_s,
        "dwell_at_last_stop_s":         dwell_at_last_stop_s,
        "peak_speed_interaction":       peak_speed_int,
        "dist_per_stop":                dist_per_stop,
        "delay_ratio":                  delay_ratio,
    }])

    selected = (
        model_urban if route_number in URBAN_ROUTES
        else model_intercity
    )

    log_spk = float(selected.predict(features[FEATURE_COLS])[0])
    spk     = max(60, min(600, np.expm1(log_spk)))
    eta_s   = max(10.0, spk * dist_km)
    eta_min = eta_s / 60

    if   eta_s < 45:  display = "🚌 Arriving now"
    elif eta_s < 90:  display = "🚌 ~1 min"
    else:             display = f"🚌 ~{int(round(eta_min))} min"

    if   dist_m < 8000:  confidence = "High"
    elif dist_m < 25000: confidence = "Medium"
    else:                confidence = "Low"

    return {
        "route_number": route_number,
        "target_stop":  target_stop_name,
        "eta_seconds":  round(eta_s, 1),
        "eta_minutes":  round(eta_min, 2),
        "display":      display,
        "distance_km":  round(dist_km, 2),
        "speed_kmh":    round(current_speed_kmh, 1),
        "spk":          round(spk, 1),
        "is_peak":      bool(pk_f),
        "model_used":   "urban" if route_number in URBAN_ROUTES else "intercity",
        "model_calls":  1,
        "confidence":   confidence,
        "timestamp":    str(timestamp),
    }
