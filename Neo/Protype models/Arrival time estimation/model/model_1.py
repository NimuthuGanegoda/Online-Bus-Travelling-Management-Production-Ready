import re
import numpy as np
import requests

# ----------------------------
# 1️⃣ Meta-feature extraction
# ----------------------------
def extract_meta_features(comment_raw, hour=None, is_peak=0, is_weekend=0,
                          is_night=0, is_raining=0, driver_id=None,
                          driver_history=None):
    if not isinstance(comment_raw, str):
        comment_raw = ''
    
    raw = comment_raw.strip()
    lower = raw.lower()
    words = raw.split()
    f = {}

    # Basic text features
    f['word_count']      = len(words)
    f['char_count']      = len(raw)
    f['avg_word_length'] = np.mean([len(w) for w in words]) if words else 0
    f['exclamation_count'] = raw.count('!')
    f['question_count']    = raw.count('?')
    f['caps_word_count']   = sum(1 for w in words if w.isupper() and len(w) > 2)
    f['caps_ratio']        = f['caps_word_count'] / max(len(words), 1)

    # Emojis
    pos_emojis = {'😊','😄','😁','👍','❤️','🙏','✨','😍','🌟','👏','🎉','🥰','💯'}
    neg_emojis = {'😡','😠','👎','💔','😤','🤬','😒','😞','🤮','😢','😭','🤦'}
    f['positive_emoji_count'] = sum(raw.count(e) for e in pos_emojis)
    f['negative_emoji_count'] = sum(raw.count(e) for e in neg_emojis)

    # Negations
    f['negation_count'] = sum(lower.count(n) for n in
                              ['not', 'no', 'never', "don't", "doesn't", "didn't", "won't", "can't"])

    # Mentions of categories
    f['mentions_driver'] = int(any(w in lower for w in
        ['driver', 'rude', 'polite', 'helpful', 'friendly', 'aggressive',
         'shouted', 'yelled', 'courteous', 'impatient']))
    f['mentions_vehicle'] = int(any(w in lower for w in
        ['clean', 'dirty', 'seat', 'ac', 'air', 'smell', 'comfortable',
         'filthy', 'broken', 'damp', 'smelly', 'condition']))
    f['mentions_punctuality'] = int(any(w in lower for w in
        ['late', 'delay', 'wait', 'punctual', 'schedule', 'cancel', 'on time',
         'behind', 'overdue']))
    f['mentions_safety'] = int(any(w in lower for w in
        ['safe', 'unsafe', 'speed', 'reckless', 'dangerous', 'drunk', 'accident',
         'swerving', 'brake', 'carelessly']))
    f['mentions_fare'] = int(any(w in lower for w in
        ['fare', 'price', 'charge', 'expensive', 'overcharge', 'money', 'pay',
         'extra', 'fee', 'rupee']))

    # Numbers
    f['has_numbers'] = int(bool(re.search(r'\d', raw)))
    f['number_count'] = len(re.findall(r'\d+', raw))

    # Contextual features
    f['hour_of_day'] = int(hour) if hour is not None else 12
    f['is_peak'] = int(is_peak)
    f['is_weekend'] = int(is_weekend)
    f['is_night'] = int(is_night)
    f['is_morning_peak'] = int(hour is not None and 7 <= int(hour) <= 9 and not is_weekend)
    f['is_evening_peak'] = int(hour is not None and 17 <= int(hour) <= 19 and not is_weekend)
    f['is_raining'] = int(is_raining)

    # Interactions
    f['peak_x_lateness'] = int(is_peak and f['mentions_punctuality'])
    f['rain_x_lateness'] = int(is_raining and f['mentions_punctuality'])
    f['rain_x_cleanliness'] = int(is_raining and f['mentions_vehicle'])
    f['night_x_lateness'] = int(is_night and f['mentions_punctuality'])
    f['night_x_safety'] = int(is_night and f['mentions_safety'])

    # Specificity score (0-1)
    spec = 0.2
    if re.search(r'\d+\s*(min|hour|rs|rupee)', lower): spec += 0.25
    if re.search(r'route\s*\d+', lower): spec += 0.20
    if len(words) > 20: spec += 0.15
    f['specificity_score'] = round(min(spec, 1.0), 2)

    # Driver historical info
    if driver_history and driver_id:
        hist = driver_history.get(driver_id, {})
        f['driver_historical_avg'] = float(hist.get('avg_rating', 5.0))
        f['driver_comment_count'] = int(min(hist.get('count', 0), 100))
        f['driver_has_history'] = int(hist.get('count', 0) > 0)
    else:
        f['driver_historical_avg'] = 5.0
        f['driver_comment_count'] = 0
        f['driver_has_history'] = 0

    return f

# ----------------------------
# 2️⃣ API Ninjas sentiment
# ----------------------------
API_KEY = "QnoFVKOfdILcNMSEVisUvy3B5GwSZDjbwZULOyDk"

def get_sentiment_score(text):
    url = "https://api.api-ninjas.com/v1/sentiment"
    headers = {"X-Api-Key": API_KEY}
    params = {"text": text}

    response = requests.get(url, headers=headers, params=params)
    if response.status_code == 200:
        data = response.json()
        return data.get("score", 0)
    else:
        print("Error:", response.status_code, response.text)
        return 0

# ----------------------------
# 3️⃣ Driver rating calculation
# ----------------------------
def rate_driver(comment, hour=None, is_peak=0, is_weekend=0, is_night=0,
                is_raining=0, driver_id=None, driver_history=None):
    
    # Step 1: Extract meta-features automatically
    meta_features = extract_meta_features(
        comment_raw=comment,
        hour=hour,
        is_peak=is_peak,
        is_weekend=is_weekend,
        is_night=is_night,
        is_raining=is_raining,
        driver_id=driver_id,
        driver_history=driver_history
    )

    # Step 2: Get sentiment from API
    sentiment_score = get_sentiment_score(comment)
    sentiment_rating = ((sentiment_score + 1) * 4.5) + 1  # -1→1, +1→10

    # Step 3: Base rating from sentiment + specificity
    specificity = meta_features['specificity_score'] * 10
    rating = (0.6 * sentiment_rating) + (0.4 * specificity)

    # Step 4: Adjust rating for context factors
    if meta_features.get("mentions_punctuality") and meta_features.get("is_peak"):
        rating -= 1.0
    if meta_features.get("mentions_punctuality") and meta_features.get("is_night"):
        rating -= 0.8
    if meta_features.get("mentions_safety") and meta_features.get("is_night"):
        rating -= 1.0
    if meta_features.get("mentions_vehicle") and meta_features.get("is_raining"):
        rating -= 0.5

    # Historical driver rating
    rating = 0.7 * rating + 0.3 * meta_features.get("driver_historical_avg", 5.0) * 2

    # Cap between 1 and 10
    rating = max(1, min(rating, 10))

    return round(rating, 2)

# ----------------------------
# 4️⃣ Example usage
# ----------------------------
if __name__ == "__main__":
    comment = " I hated the driver so somuch. He kept yelling at me all the time when tried to get out. Would not recommend to anyone ."
    rating = rate_driver(
        comment,
        hour=10,
        is_peak=0,
        is_night=0,
        is_raining=1,
        driver_id="driver_0004beh",
        driver_history={"driver_0004beh": {"avg_rating": 1.2, "count": 15}}
    )
    print("Driver Rating (1-10):", rating)
