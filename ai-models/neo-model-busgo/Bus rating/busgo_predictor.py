"""
BUSGO — Local Rating Predictor
================================
Loads the 5 model files saved from Colab and lets you rate
any bus passenger comment without re-training.

REQUIRED FILES (download from Colab Cell 18):
  bus_rating_model_v5.pkl
  vectorizer_v5.pkl
  meta_scaler_v5.pkl
  meta_feature_names_v5.pkl
  calibrator_v5.pkl          (only if USE_CALIBRATION = True in Colab)

INSTALL:
  pip install scikit-learn lightgbm pandas numpy scipy emoji langdetect deep-translator nltk openpyxl

RUN:
  python busgo_predictor.py
"""

import os
import re
import time
import joblib
import warnings
import pandas as pd
import numpy as np
import emoji
import nltk
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from deep_translator import GoogleTranslator
from langdetect import detect
from scipy.sparse import hstack, csr_matrix

warnings.filterwarnings('ignore')
nltk.download('stopwords', quiet=True)
nltk.download('wordnet', quiet=True)


# ── CONFIG ────────────────────────────────────────────────────────────────────
# Set this to the folder where your .pkl files are saved
MODEL_DIR       = "."          # same folder as this script, or full path
USE_CALIBRATION = True         # must match what you set in Colab Cell 15


# ── LOAD MODEL FILES ──────────────────────────────────────────────────────────
def load_models(model_dir=MODEL_DIR):
    required = [
        'bus_rating_model_v5.pkl',
        'vectorizer_v5.pkl',
        'meta_scaler_v5.pkl',
        'meta_feature_names_v5.pkl',
    ]
    missing = [f for f in required if not os.path.exists(os.path.join(model_dir, f))]
    if missing:
        print(f"❌ Missing model files: {missing}")
        print(f"   Download them from Colab Cell 18 and place in: {model_dir}")
        raise FileNotFoundError(f"Missing: {missing}")

    model              = joblib.load(os.path.join(model_dir, 'bus_rating_model_v5.pkl'))
    vectorizer         = joblib.load(os.path.join(model_dir, 'vectorizer_v5.pkl'))
    scaler             = joblib.load(os.path.join(model_dir, 'meta_scaler_v5.pkl'))
    meta_feature_names = joblib.load(os.path.join(model_dir, 'meta_feature_names_v5.pkl'))

    calibrator = None
    if USE_CALIBRATION:
        cal_path = os.path.join(model_dir, 'calibrator_v5.pkl')
        if os.path.exists(cal_path):
            calibrator = joblib.load(cal_path)
        else:
            print("⚠ calibrator_v5.pkl not found — running without calibration")

    print(f"✓ Model loaded from {model_dir}")
    print(f"  Vocabulary size  : {len(vectorizer.get_feature_names_out())}")
    print(f"  Meta features    : {len(meta_feature_names)}")
    print(f"  Calibration      : {'ON' if calibrator else 'OFF'}")
    return model, vectorizer, scaler, meta_feature_names, calibrator


# ── PREPROCESSING ─────────────────────────────────────────────────────────────
base_english_stopwords = set(stopwords.words('english'))
sentiment_keep = {
    'not','no','never',"don't","doesn't","didn't","won't","can't","couldn't",
    "wouldn't","shouldn't","isn't","aren't","wasn't","weren't","hasn't","haven't",
    'very','extremely','really','too','so','quite','completely','totally','utterly',
    'good','bad','well','better','worse','best','worst','more','most','less','least',
    'great','but','however','although','though','despite','even','still','only','just','yet',
}
english_stopwords = base_english_stopwords - sentiment_keep
lemmatizer        = WordNetLemmatizer()

SINHALA_INTENSITY_MAP = {
    'ගොඩක්':'extremely very','ගොඩාක්':'extremely very','හරිම':'extremely',
    'ඉතා':'very','බොහෝ':'very much','නරකම':'terrible worst',
    'හොඳම':'superb finest','අපහසු':'extremely uncomfortable',
    'කෝපෙන්':'angry aggressive rude','ලේට්':'late delayed',
    'රූඩ්':'rude impolite','නරක':'bad poor','හොඳ':'good',
    'බය':'scared frightened dangerous',
}

def language_detection(comment):
    cleaned     = str(comment).strip()
    has_sinhala = bool(re.search(r'[\u0D80-\u0DFF]+', cleaned))
    has_english = bool(re.search(r'[a-zA-Z]+', cleaned))
    if has_sinhala and has_english: return 'mixed'
    if has_sinhala:
        try:    return 'si' if detect(cleaned) == 'si' else 'en'
        except: return 'si'
    return 'en'

def protect_negations(text):
    pattern = (r'\b(not|no|never|dont|doesnt|didnt|wont|cant|couldnt|wouldnt|'
               r'shouldnt|isnt|arent|wasnt|werent|hasnt|havent)\b\s+(\w+)')
    return re.sub(pattern, lambda m: m.group(0).replace(' ','_'), text, flags=re.IGNORECASE)

def handle_emojis(text):
    pos = {'😊','😄','😁','👍','❤️','🙏','✨','😍','🌟','👏','🎉','😃','🥰','💯','🤩','😀','🙌','💪'}
    neg = {'😡','😠','👎','💔','😤','🤬','😒','😞','😣','🤮','😢','😭','😩','🤦','💀','😑'}
    for e in pos: text = text.replace(e,' positive_emoji ')
    for e in neg: text = text.replace(e,' negative_emoji ')
    return emoji.replace_emoji(text, replace='')

def cleaning(comment):
    comment = str(comment).lower()
    comment = handle_emojis(comment)
    comment = protect_negations(comment)
    comment = re.sub(r'[^a-z_\s]', '', comment)
    comment = re.sub(r'\s+', ' ', comment).strip()
    tokens  = [lemmatizer.lemmatize(t) for t in comment.split()
               if t not in english_stopwords]
    return ' '.join(tokens)

def process_comment(comment):
    if not isinstance(comment, str) or not comment.strip():
        return ''
    lang = language_detection(comment)
    if lang == 'si':
        for s, e in SINHALA_INTENSITY_MAP.items():
            comment = comment.replace(s, e)
        try:
            comment = GoogleTranslator(source='auto', target='en').translate(comment) or comment
        except:
            pass
        return cleaning(comment)
    elif lang == 'mixed':
        for s, e in SINHALA_INTENSITY_MAP.items():
            comment = comment.replace(s, e)
        try:
            comment = GoogleTranslator(source='auto', target='en').translate(comment) or comment
        except:
            pass
        return cleaning(comment)
    return cleaning(comment)


# ── META-FEATURE EXTRACTION ───────────────────────────────────────────────────
def extract_meta_features(comment_raw, hour=None, is_peak=0, is_weekend=0,
                           is_night=0, is_raining=0, driver_id=None,
                           driver_history=None, specificity_score=None):
    if not isinstance(comment_raw, str): comment_raw = ''
    raw   = comment_raw.strip()
    lower = raw.lower()
    words = raw.split()
    f = {}

    f['word_count']           = len(words)
    f['char_count']           = len(raw)
    f['avg_word_length']      = np.mean([len(w) for w in words]) if words else 0
    f['exclamation_count']    = raw.count('!')
    f['question_count']       = raw.count('?')
    f['caps_word_count']      = sum(1 for w in words if w.isupper() and len(w) > 2)
    f['caps_ratio']           = f['caps_word_count'] / max(len(words), 1)

    pos_emojis = {'😊','😄','😁','👍','❤️','🙏','✨','😍','🌟','👏','🎉','🥰','💯'}
    neg_emojis = {'😡','😠','👎','💔','😤','🤬','😒','😞','🤮','😢','😭','🤦'}
    f['positive_emoji_count'] = sum(raw.count(e) for e in pos_emojis)
    f['negative_emoji_count'] = sum(raw.count(e) for e in neg_emojis)
    f['negation_count']       = sum(lower.count(n) for n in
                                    ['not','no','never',"don't","doesn't","didn't","won't","can't"])

    f['mentions_driver']      = int(any(w in lower for w in
        ['driver','rude','polite','helpful','friendly','aggressive','shouted','yelled','courteous','impatient']))
    f['mentions_vehicle']     = int(any(w in lower for w in
        ['clean','dirty','seat','ac','air','smell','comfortable','filthy','broken','damp','smelly','condition']))
    f['mentions_punctuality'] = int(any(w in lower for w in
        ['late','delay','wait','punctual','schedule','cancel','on time','behind','overdue']))
    f['mentions_safety']      = int(any(w in lower for w in
        ['safe','unsafe','speed','reckless','dangerous','drunk','accident','swerving','brake','carelessly']))
    f['mentions_fare']        = int(any(w in lower for w in
        ['fare','price','charge','expensive','overcharge','money','pay','extra','fee','rupee']))

    f['has_numbers']          = int(bool(re.search(r'\d', raw)))
    f['number_count']         = len(re.findall(r'\d+', raw))
    f['hour_of_day']          = int(hour) if hour is not None else 12
    f['is_peak']              = int(is_peak)
    f['is_weekend']           = int(is_weekend)
    f['is_night']             = int(is_night)
    f['is_morning_peak']      = int(hour is not None and 7 <= int(hour) <= 9 and not is_weekend)
    f['is_evening_peak']      = int(hour is not None and 17 <= int(hour) <= 19 and not is_weekend)
    f['is_raining']           = int(is_raining)
    f['peak_x_lateness']      = int(is_peak and f['mentions_punctuality'])
    f['rain_x_lateness']      = int(is_raining and f['mentions_punctuality'])
    f['rain_x_cleanliness']   = int(is_raining and f['mentions_vehicle'])
    f['peak_x_overcrowding']  = int(is_peak and 'crowd' in lower)
    f['offpeak_x_lateness']   = int(not is_peak and f['mentions_punctuality'])
    f['night_x_lateness']     = int(is_night and f['mentions_punctuality'])
    f['night_x_safety']       = int(is_night and f['mentions_safety'])

    if specificity_score is not None:
        f['specificity_score'] = float(specificity_score)
    else:
        spec = 0.2
        if re.search(r'\d+\s*(min|hour|rs|rupee)', lower): spec += 0.25
        if re.search(r'route\s*\d+', lower):               spec += 0.20
        if len(words) > 20:                                 spec += 0.15
        f['specificity_score'] = round(min(spec, 1.0), 2)

    if driver_history and driver_id:
        hist = driver_history.get(driver_id, {})
        f['driver_historical_avg'] = float(hist.get('avg_rating', 5.0))
        f['driver_comment_count']  = int(min(hist.get('count', 0), 100))
        f['driver_has_history']    = int(hist.get('count', 0) > 0)
    else:
        f['driver_historical_avg'] = 5.0
        f['driver_comment_count']  = 0
        f['driver_has_history']    = 0

    return f


# ── CONTEXT ADJUSTMENT ────────────────────────────────────────────────────────
LATENESS_WORDS  = ['late','delay','delayed','wait','waiting','behind schedule','not on time','slow','long time']
CLEANNESS_WORDS = ['dirty','filthy','smell','wet','muddy','damp','smelly','unclean','stinky','grimy']
RUDENESS_WORDS  = ['rude','shouted','screamed','abused','aggressive','threatening','insulted','yelled']
SAFETY_WORDS    = ['drunk','reckless','dangerous','speeding','accident','swerving','no brakes']
CROWD_WORDS     = ['overcrowd','overcrowded','packed','crush','standing room','no seats','crammed']

def apply_context_adjustments(raw_comment, base_prediction, timestamp=None,
                               is_raining=False, is_peak=None, is_weekend=None, is_night=None):
    if not isinstance(raw_comment, str):
        return base_prediction, 'no adjustment', 1.0

    lower = raw_comment.lower(); adj = float(base_prediction); reasons = []; conf = 1.0
    peak_f = wkend_f = night_f = False

    if timestamp:
        try:
            dt = pd.to_datetime(timestamp); h, wd = dt.hour, dt.weekday()
            peak_f = (7 <= h <= 9 or 17 <= h <= 19) and wd < 5
            wkend_f = wd >= 5; night_f = h >= 22 or h <= 5
        except: pass

    if is_peak    is not None: peak_f  = bool(is_peak)
    if is_weekend is not None: wkend_f = bool(is_weekend)
    if is_night   is not None: night_f = bool(is_night)

    is_rude = any(w in lower for w in RUDENESS_WORDS)
    is_safe = any(w in lower for w in SAFETY_WORDS)
    is_late = any(w in lower for w in LATENESS_WORDS)

    if is_late and not is_rude and not is_safe:
        if peak_f:
            adj += 1.0; reasons.append('peak_lateness_tolerance +1.0'); conf *= 0.95
        elif night_f:
            adj -= 0.4; reasons.append('night_lateness -0.4')
        elif wkend_f:
            adj -= 0.2; reasons.append('weekend_lateness -0.2')
        else:
            adj -= 0.3; reasons.append('offpeak_lateness -0.3')
        if is_raining:
            adj += 0.6; reasons.append('rain_lateness_tolerance +0.6')

    if any(w in lower for w in CLEANNESS_WORDS) and is_raining and not is_safe:
        adj += 0.5; reasons.append('rain_cleanliness_tolerance +0.5'); conf *= 0.95

    if any(w in lower for w in CROWD_WORDS) and peak_f and not is_safe and not is_rude:
        adj += 0.6; reasons.append('peak_crowd_tolerance +0.6'); conf *= 0.95

    adj = float(np.clip(adj, 1.0, 10.0)); conf = float(np.clip(conf, 0.1, 1.0))
    return round(adj, 1), ' | '.join(reasons) if reasons else 'no adjustment', round(conf, 2)


# ── MAIN PREDICTOR CLASS ──────────────────────────────────────────────────────
class BUSGOPredictor:
    def __init__(self, model_dir=MODEL_DIR):
        self.model, self.vectorizer, self.scaler, \
        self.meta_feature_names, self.calibrator = load_models(model_dir)

    def predict(self, comment, timestamp=None, is_raining=False,
                is_peak=None, is_weekend=None, is_night=None,
                driver_id=None, driver_history=None, specificity_score=None):
        """
        Rate a single bus passenger comment.

        Parameters
        ----------
        comment        : str   — the passenger review text
        timestamp      : str   — e.g. "2026-04-07 08:30:00" (optional)
        is_raining     : bool  — was it raining? (optional)
        is_peak        : bool  — peak hour? overrides timestamp if set
        is_weekend     : bool  — weekend? overrides timestamp if set
        is_night       : bool  — night time? overrides timestamp if set
        driver_id      : str   — driver ID for history lookup (optional)
        driver_history : dict  — {driver_id: {'avg_rating': x, 'count': n}}
        specificity_score : float — 0-1, how specific the review is

        Returns
        -------
        dict with keys: rating, confidence, base_pred, adjustment, context, cleaned
        """
        if not isinstance(comment, str) or not comment.strip():
            return None

        cleaned = process_comment(comment)
        if not cleaned.strip():
            return None

        hour_v = 12; peak_v = wkend_v = night_v = 0
        if timestamp:
            try:
                dt = pd.to_datetime(timestamp)
                hour_v  = dt.hour
                peak_v  = int((7 <= dt.hour <= 9 or 17 <= dt.hour <= 19) and dt.weekday() < 5)
                wkend_v = int(dt.weekday() >= 5)
                night_v = int(dt.hour >= 22 or dt.hour <= 5)
            except: pass

        if is_peak    is not None: peak_v  = int(is_peak)
        if is_weekend is not None: wkend_v = int(is_weekend)
        if is_night   is not None: night_v = int(is_night)

        text_vec = self.vectorizer.transform([cleaned])
        meta_raw = extract_meta_features(
            comment, hour=hour_v, is_peak=peak_v, is_weekend=wkend_v,
            is_night=night_v, is_raining=int(is_raining),
            driver_id=driver_id, driver_history=driver_history,
            specificity_score=specificity_score
        )
        meta_row = pd.DataFrame([meta_raw])[self.meta_feature_names]
        meta_vec = csr_matrix(self.scaler.transform(meta_row))
        combined = hstack([text_vec, meta_vec])

        raw_pred = self.model.predict(combined.toarray())[0]
        if USE_CALIBRATION and self.calibrator:
            base_pred = float(np.clip(self.calibrator.predict([raw_pred])[0], 1, 10))
        else:
            base_pred = float(np.clip(raw_pred, 1, 10))

        adjusted, reason, confidence = apply_context_adjustments(
            comment, base_pred, timestamp=timestamp, is_raining=is_raining,
            is_peak=peak_v if is_peak is None else is_peak,
            is_weekend=wkend_v if is_weekend is None else is_weekend,
            is_night=night_v if is_night is None else is_night
        )

        ctx = []
        if peak_v:     ctx.append('PEAK')
        if wkend_v:    ctx.append('WEEKEND')
        if night_v:    ctx.append('NIGHT')
        if is_raining: ctx.append('RAIN')

        return {
            'rating':     adjusted,
            'confidence': confidence,
            'base_pred':  round(base_pred, 1),
            'adjustment': reason,
            'context':    '+'.join(ctx) if ctx else 'NORMAL',
            'cleaned':    cleaned,
        }

    def predict_batch(self, comments_list):
        """
        Rate a list of dicts. Each dict must have 'comment' key.
        Optional keys: timestamp, is_raining, is_peak, is_weekend,
                       is_night, driver_id, specificity_score.
        Returns a DataFrame.
        """
        rows = []
        for item in comments_list:
            comment = item.get('comment', '')
            result  = self.predict(
                comment,
                timestamp         = item.get('timestamp', None),
                is_raining        = item.get('is_raining', False),
                is_peak           = item.get('is_peak', None),
                is_weekend        = item.get('is_weekend', None),
                is_night          = item.get('is_night', None),
                driver_id         = item.get('driver_id', None),
                specificity_score = item.get('specificity_score', None),
            )
            if result:
                rows.append({'comment': comment, **result})
            else:
                rows.append({'comment': comment, 'rating': None,
                             'confidence': None, 'base_pred': None,
                             'adjustment': 'error', 'context': '', 'cleaned': ''})
        return pd.DataFrame(rows)

    def predict_from_excel(self, filepath, output_filepath=None):
        """
        Read an Excel file with a 'comment' column and rate every row.
        Saves results to output_filepath (or adds _rated suffix).
        """
        df = pd.read_excel(filepath)
        df.columns = df.columns.str.strip().str.lower()
        print(f"Loaded {len(df)} rows from {filepath}")

        records = df.to_dict('records')
        results = self.predict_batch(records)

        if output_filepath is None:
            base, ext = os.path.splitext(filepath)
            output_filepath = base + '_rated' + ext

        with pd.ExcelWriter(output_filepath, engine='openpyxl') as writer:
            results.to_excel(writer, sheet_name='Ratings', index=False)

        print(f"✓ Saved rated results to: {output_filepath}")
        return results

    def print_result(self, comment, result):
        if not result:
            print(f"  ✗ Could not process: {comment[:60]}")
            return
        stars = '★' * round(result['rating']) + '☆' * (10 - round(result['rating']))
        print(f"\n  Comment   : {comment[:80]}")
        print(f"  Rating    : {result['rating']:.1f}/10  {stars}")
        print(f"  Confidence: {result['confidence']:.2f}")
        print(f"  Base pred : {result['base_pred']:.1f}  →  Adjusted: {result['rating']:.1f}")
        print(f"  Adjustment: {result['adjustment']}")
        print(f"  Context   : {result['context']}")


# ── INTERACTIVE TEST CASES ────────────────────────────────────────────────────
if __name__ == '__main__':

    print("\n" + "="*60)
    print("  BUSGO RATING PREDICTOR — Local Mode")
    print("="*60)

    # Load models
    predictor = BUSGOPredictor(model_dir=MODEL_DIR)

    # ── SECTION 1: Individual test comments ──────────────────────────────────
    # Edit these comments to test your own inputs
    print("\n" + "─"*60)
    print("  SECTION 1: Individual test predictions")
    print("─"*60)

    test_cases = [
        {
            "comment"   : "The driver was extremely rude and shouted at passengers. The bus smelled terrible.",
            "is_peak"   : False,
            "is_raining": False,
        },
        {
            "comment"   : "Bus was late but I understand it was rush hour and raining heavily.",
            "is_peak"   : True,
            "is_raining": True,
        },
        {
            "comment"   : "Very clean bus, driver was polite and helpful. Arrived on time. Great experience!",
            "is_peak"   : False,
            "is_raining": False,
        },
        {
            "comment"   : "Bus was overcrowded during morning peak. Could not get a seat but the driver was okay.",
            "timestamp" : "2026-04-07 08:15:00",  # auto-detects peak + morning
        },
        {
            "comment"   : "Driver was drunk and driving recklessly. Nearly caused an accident.",
            "is_night"  : True,
        },
        {
            "comment"   : "Ordinary journey. Bus came on time. Nothing special.",
            "is_peak"   : False,
        },
        {
            "comment"   : "කොන්දොස්තර ගොඩක් රළු. බස් ලේට් ආවා.",  # Sinhala input
        },
    ]

    for i, tc in enumerate(test_cases, 1):
        comment = tc.pop('comment')
        result  = predictor.predict(comment, **tc)
        print(f"\nTest {i}:")
        predictor.print_result(comment, result)

    # ── SECTION 2: Batch prediction from a list ───────────────────────────────
    print("\n" + "─"*60)
    print("  SECTION 2: Batch prediction")
    print("─"*60)

    batch = [
        {"comment": "Excellent service, very professional driver.", "is_peak": False},
        {"comment": "The bus floor was dirty and seats were broken.", "is_raining": False},
        {"comment": "Late by 30 minutes with no explanation given.", "is_peak": False},
        {"comment": "Driver greeted passengers and helped elderly passengers.", "is_peak": True},
        {"comment": "Bus was packed during evening rush, couldn't breathe properly.", "timestamp": "2026-04-07 17:45:00"},
    ]

    df_batch = predictor.predict_batch(batch)
    print(df_batch[['comment', 'rating', 'confidence', 'context', 'adjustment']].to_string(index=False))

    # ── SECTION 3: Rate from Excel file ──────────────────────────────────────
    print("\n" + "─"*60)
    print("  SECTION 3: Rate from Excel file")
    print("─"*60)
    print("  To rate an Excel file, call:")
    print('  results = predictor.predict_from_excel("your_file.xlsx")')
    print()
    print("  The Excel file needs at minimum a 'comment' column.")
    print("  Optional columns: timestamp, is_raining, is_peak,")
    print("                    is_weekend, is_night, driver_id")
    print()
    print("  Example:")
    print('  results = predictor.predict_from_excel("drivers_to_rate.xlsx")')
    print('  # Saves → drivers_to_rate_rated.xlsx automatically')

    # ── SECTION 4: Interactive single input ───────────────────────────────────
    print("\n" + "─"*60)
    print("  SECTION 4: Interactive — type your own comment")
    print("  (press Ctrl+C to exit)")
    print("─"*60)

    while True:
        try:
            print()
            comment = input("Enter comment (or 'q' to quit): ").strip()
            if comment.lower() in ('q', 'quit', 'exit', ''):
                break

            peak_in    = input("Peak hour? (y/n, enter to skip): ").strip().lower()
            rain_in    = input("Raining?   (y/n, enter to skip): ").strip().lower()
            night_in   = input("Night time? (y/n, enter to skip): ").strip().lower()

            is_peak    = True if peak_in == 'y' else (False if peak_in == 'n' else None)
            is_raining = rain_in == 'y'
            is_night   = True if night_in == 'y' else (False if night_in == 'n' else None)

            result = predictor.predict(
                comment,
                is_peak    = is_peak,
                is_raining = is_raining,
                is_night   = is_night,
            )
            predictor.print_result(comment, result)

        except KeyboardInterrupt:
            print("\n\nExiting.")
            break