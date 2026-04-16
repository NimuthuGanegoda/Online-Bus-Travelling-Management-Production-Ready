"""
================================================
  Bus Emergency Alert Prioritization — VS Code
  Test your own alerts locally
================================================

HOW TO RUN:
    1. pip install -r requirements.txt
    2. Add your test alerts in the MY_TEST_ALERTS list below
    3. Run:  python test_alerts.py

EMERGENCY TYPES (use exactly as written):
    "Medical Emergency"
    "Criminal Activity"
    "Bus Breakdown"
    "Harassment"
    "Other"
"""

import os, re, sys, warnings
import numpy as np
import pandas as pd
import joblib
from scipy.sparse import hstack, csr_matrix
from sentence_transformers import SentenceTransformer
from tabulate import tabulate
from colorama import init, Fore, Style

warnings.filterwarnings('ignore')
init(autoreset=True)  # colorama

# ─────────────────────────────────────────────────────────────
#  ✏️  ADD YOUR OWN TEST ALERTS HERE
#  Each alert is a dict with:
#    alert_id       → any label you want
#    bus_id         → your bus number / name
#    emergency_type → must be one of the 5 types above
#    comment        → passenger's free text (can be empty "")
# ─────────────────────────────────────────────────────────────

MY_TEST_ALERTS = [

    # ── Try your own alerts below ─────────────────────────────

    {
        "alert_id": "TEST-001",
        "bus_id": "CTB-177",
        "emergency_type": "Medical Emergency",
        "comment": "Elderly man collapsed not breathing need ambulance urgently"
    },
    {
        "alert_id": "TEST-002",
        "bus_id": "CTB-204",
        "emergency_type": "Criminal Activity",
        "comment": "Man with knife threatening passengers demanding money"
    },
    {
        "alert_id": "TEST-003",
        "bus_id": "CTB-055",
        "emergency_type": "Bus Breakdown",
        "comment": "Engine fire smoke filling bus need to evacuate now"
    },
    {
        "alert_id": "TEST-004",
        "bus_id": "CTB-312",
        "emergency_type": "Harassment",
        "comment": "Man groping female passengers repeatedly please help"
    },
    {
        "alert_id": "TEST-005",
        "bus_id": "CTB-099",
        "emergency_type": "Medical Emergency",
        "comment": "sorry pressed by mistake nothing wrong"     # false alert
    },
    {
        "alert_id": "TEST-006",
        "bus_id": "CTB-411",
        "emergency_type": "Criminal Activity",
        "comment": "test 123"                                  # false alert
    },
    {
        "alert_id": "TEST-007",
        "bus_id": "CTB-208",
        "emergency_type": "Other",
        "comment": "Bus driver fell asleep at wheel swerving dangerously"
    },
    {
        "alert_id": "TEST-008",
        "bus_id": "CTB-501",
        "emergency_type": "Harassment",
        "comment": "schoolgirl being followed by man since 3 stops uncomfortable"
    },
    {
        "alert_id": "TEST-009",
        "bus_id": "CTB-033",
        "emergency_type": "Bus Breakdown",
        "comment": ""                                          # no comment
    },
    {
        "alert_id": "TEST-010",
        "bus_id": "CTB-177",
        "emergency_type": "Medical Emergency",
        "comment": "woman in labour baby coming now on bus kandy road"
    },

]

# ─────────────────────────────────────────────────────────────
#  MODEL PATHS — update if you put .pkl files elsewhere
# ─────────────────────────────────────────────────────────────

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")

MODEL_FA_PATH    = os.path.join(MODELS_DIR, "model_false_alert_xgb.pkl")
MODEL_PRIO_PATH  = os.path.join(MODELS_DIR, "model_priority_lgbm.pkl")
TFIDF_PATH       = os.path.join(MODELS_DIR, "tfidf_vectorizer.pkl")
FEATURES_PATH    = os.path.join(MODELS_DIR, "feature_list.pkl")

# ─────────────────────────────────────────────────────────────
#  FEATURE ENGINEERING  (must match what Colab used)
# ─────────────────────────────────────────────────────────────

CRITICAL_KW = [
    'unconscious','not breathing','cardiac','heart attack','seizure','bleeding',
    'collapsed','knife','gun','weapon','armed','shooting','explosion','fire',
    'burning','dead','dying','ambulance','urgent','immediately','brake failure',
    'out of control','hijack','rape','newborn','infant','poisoning','groping',
    'sexual assault','stabbing','unresponsive','stroke','choking','electrocution'
]
HIGH_KW = [
    'assault','fight','punch','blood','injury','injured','threatening','robbery',
    'steal','theft','dangerous','highway','panic','screaming','harassment',
    'following','inappropriate','exposed','recording','overcrowding','intoxicated',
    'drunk','wrong side','fracture','overdose','hemorrhaging','maternity'
]
FALSE_KW = [
    'accident','mistake','wrong button','pocket','test','sorry','nothing','lol',
    'haha','hehe','bye','hi','ignore','false alarm','ok','cancel','resolved',
    'fine now','misunderstanding','aaa','asdf','1234','nothing happened'
]
TYPE_BASE = {
    'Medical Emergency': 4, 'Criminal Activity': 3,
    'Bus Breakdown': 2,     'Harassment': 3, 'Other': 2
}

def clean_text(text):
    if not text or str(text).strip() == '':
        return 'no comment'
    text = str(text).lower().strip()
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    return re.sub(r'\s+', ' ', text).strip()

def is_gibberish(text):
    if text == 'no comment':
        return 0
    words = text.split()
    if not words:
        return 1
    alpha_r = sum(c.isalpha() for c in text) / max(len(text), 1)
    short_r = sum(1 for w in words if len(w) <= 2) / len(words)
    return 1 if (alpha_r < 0.5 or short_r > 0.8) else 0

def count_kw(text, kw_list):
    return sum(1 for kw in kw_list if kw in text)

def engineer_features(bus_type: str, comment: str, feature_names: list) -> pd.DataFrame:
    """Build the exact same feature vector used during training."""
    cleaned = clean_text(comment)
    crit_kw = count_kw(cleaned, CRITICAL_KW)
    high_kw = count_kw(cleaned, HIGH_KW)
    fals_kw = count_kw(cleaned, FALSE_KW)
    row = {
        'base_priority':   TYPE_BASE.get(bus_type, 2),
        'comment_length':  len(str(comment)) if comment else 0,
        'word_count':      len(cleaned.split()),
        'has_comment':     int(len(str(comment)) > 3),
        'critical_kw':     crit_kw,
        'high_kw':         high_kw,
        'false_kw':        fals_kw,
        'is_gibberish':    is_gibberish(cleaned),
        'urgency_score':   crit_kw * 2 + high_kw - fals_kw * 2 - is_gibberish(cleaned) * 3,
        'type_medical':    int(bus_type == 'Medical Emergency'),
        'type_criminal':   int(bus_type == 'Criminal Activity'),
        'type_breakdown':  int(bus_type == 'Bus Breakdown'),
        'type_harassment': int(bus_type == 'Harassment'),
        'type_other':      int(bus_type == 'Other'),
    }
    return pd.DataFrame([row])[feature_names], cleaned

# ─────────────────────────────────────────────────────────────
#  DISPLAY HELPERS
# ─────────────────────────────────────────────────────────────

PRIORITY_COLOR = {
    5: Fore.RED,
    4: Fore.YELLOW,
    3: Fore.CYAN,
    2: Fore.GREEN,
    1: Fore.WHITE,
}
PRIORITY_LABEL = {
    5: '🔴 CRITICAL',
    4: '🟠 HIGH',
    3: '🟡 MEDIUM',
    2: '🟢 LOW',
    1: '⚪ FALSE',
}
RESPONSE_ACTION = {
    5: 'DISPATCH NOW — Call 119/118!',
    4: 'Urgent — Contact nearest unit',
    3: 'Moderate — Monitor & prepare',
    2: 'Low — Log & follow up',
    1: 'False Alert — No dispatch needed',
}

# ─────────────────────────────────────────────────────────────
#  MAIN PIPELINE
# ─────────────────────────────────────────────────────────────

def load_models():
    """Load all saved model artifacts."""
    missing = [p for p in [MODEL_FA_PATH, MODEL_PRIO_PATH, TFIDF_PATH, FEATURES_PATH]
               if not os.path.exists(p)]
    if missing:
        print(Fore.RED + "\n❌ Missing model files:")
        for m in missing:
            print(f"   {m}")
        print(Fore.YELLOW + "\n👉 Download these from Colab (Step 15) and place them in ./models/")
        sys.exit(1)

    print(Fore.CYAN + "⏳ Loading models...", end=" ", flush=True)
    model_fa   = joblib.load(MODEL_FA_PATH)
    model_prio = joblib.load(MODEL_PRIO_PATH)
    tfidf      = joblib.load(TFIDF_PATH)
    features   = joblib.load(FEATURES_PATH)
    print(Fore.GREEN + "✅")

    print(Fore.CYAN + "⏳ Loading Sentence-BERT...", end=" ", flush=True)
    sbert = SentenceTransformer('all-MiniLM-L6-v2')
    print(Fore.GREEN + "✅")

    return model_fa, model_prio, tfidf, features, sbert


def predict_single(alert: dict, model_fa, model_prio, tfidf, features, sbert) -> dict:
    """Run the two-stage prediction pipeline on one alert."""
    etype   = alert.get('emergency_type', 'Other')
    comment = alert.get('comment', '')

    # Build features
    X_struct, cleaned = engineer_features(etype, comment, features)

    # Stage 1 — False Alert Detection
    X_tfidf    = tfidf.transform([cleaned])
    X_combined = hstack([csr_matrix(X_struct.values), X_tfidf])
    false_prob = float(model_fa.predict_proba(X_combined)[0][1])
    is_false   = false_prob > 0.50

    # Stage 2 — Priority Scoring
    embedding = sbert.encode([cleaned])
    X_prio    = np.hstack([X_struct.values, embedding])

    if is_false:
        priority = 1
        conf     = false_prob
    else:
        priority = int(model_prio.predict(X_prio)[0])
        conf     = float(max(model_prio.predict_proba(X_prio)[0]))

    return {
        'alert_id':     alert.get('alert_id', '???'),
        'bus_id':       alert.get('bus_id', 'N/A'),
        'type':         etype,
        'comment':      comment[:50] + '...' if len(comment) > 50 else comment,
        'priority':     priority,
        'label':        PRIORITY_LABEL[priority],
        'is_false':     is_false,
        'false_prob':   false_prob,
        'confidence':   conf,
        'action':       RESPONSE_ACTION[priority],
    }


def run_test(alerts: list):
    """Run all alerts through the pipeline and print ranked results."""
    print(Style.BRIGHT + "\n" + "="*72)
    print("  🚨  BUS EMERGENCY ALERT PRIORITIZATION SYSTEM")
    print("  Sri Lanka Public Transport — VS Code Test Mode")
    print("="*72)

    model_fa, model_prio, tfidf, features, sbert = load_models()

    print(f"\n🔄 Processing {len(alerts)} alert(s)...\n")

    results = []
    for alert in alerts:
        r = predict_single(alert, model_fa, model_prio, tfidf, features, sbert)
        results.append(r)

    # Sort: most critical first, false alerts last
    results.sort(key=lambda x: x['priority'], reverse=True)

    # ── Print ranked table ──────────────────────────────────────
    print(Style.BRIGHT + "="*72)
    print("  RANKED QUEUE  (Most Critical → Least Critical)")
    print("="*72 + "\n")

    for rank, r in enumerate(results, 1):
        p     = r['priority']
        color = PRIORITY_COLOR.get(p, Fore.WHITE)

        false_tag = (Fore.RED + " ⚠ FALSE ALERT") if r['is_false'] else ""
        conf_str  = f"{r['confidence']*100:.0f}%"

        print(color + Style.BRIGHT + f"  #{rank}  {r['label']}  {false_tag}")
        print(Style.RESET_ALL + f"      Alert ID : {r['alert_id']}   |   Bus: {r['bus_id']}")
        print(f"      Type     : {r['type']}")
        print(f"      Comment  : \"{r['comment']}\"")
        print(f"      Action   : {color}{r['action']}{Style.RESET_ALL}")
        print(f"      Conf     : {conf_str}  |  False prob: {r['false_prob']*100:.1f}%")
        print()

    # ── Summary table ───────────────────────────────────────────
    headers = ["Rank","Alert ID","Bus","Priority","False?","Action"]
    table   = [
        [
            f"#{i+1}",
            r['alert_id'],
            r['bus_id'],
            r['label'],
            "YES ⚠" if r['is_false'] else "No",
            r['action'][:35]
        ]
        for i, r in enumerate(results)
    ]
    print(Style.BRIGHT + "\n  SUMMARY TABLE\n")
    print(tabulate(table, headers=headers, tablefmt="rounded_outline"))

    # ── Stats ───────────────────────────────────────────────────
    total    = len(results)
    critical = sum(1 for r in results if r['priority'] == 5)
    high     = sum(1 for r in results if r['priority'] == 4)
    false_n  = sum(1 for r in results if r['is_false'])

    print(f"\n  📊 Stats: {total} alerts  |  "
          f"{Fore.RED}{critical} CRITICAL{Style.RESET_ALL}  |  "
          f"{Fore.YELLOW}{high} HIGH{Style.RESET_ALL}  |  "
          f"{Fore.WHITE}{false_n} FALSE{Style.RESET_ALL}")
    print("="*72 + "\n")


# ─────────────────────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    run_test(MY_TEST_ALERTS)