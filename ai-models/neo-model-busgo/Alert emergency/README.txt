Bus Emergency Alert Prioritization System

## Project Overview
This project develops a real-time intelligent system for prioritizing bus emergency alerts. It leverages a combination of real-world 911 call data from Montgomery County (USA) and synthetic, Sri Lanka-specific bus incident data to create a robust classification and prioritization model. The system aims to ensure that critical emergencies receive immediate attention, while false alerts are filtered out, optimizing emergency response efforts.

## Dataset Mapping Strategy
The core of the system involves mapping diverse 911 incident titles to five bus emergency categories with assigned priority scores. This mapping strategy is based on TREC-IS priority schemas and EMS dispatch protocols, ensuring a clinically and operationally relevant prioritization.

**Bus Emergency Types:**
* Medical Emergency
* Criminal Activity
* Bus Breakdown
* Harassment (synthetic, Sri Lanka-specific)
* Other

**Priority Scale:**
| Score | Label     | Action                                   |
|-------|-----------|------------------------------------------|
| 5     | 🔴 CRITICAL | Dispatch immediately — call 119/118      |
| 4     | 🟠 HIGH     | Urgent response required                 |
| 3     | 🟡 MEDIUM   | Monitor and prepare response             |
| 2     | 🟢 LOW      | Log and schedule follow-up               |
| 1     | ⚪ FALSE    | Likely false alert — flag for review     |

## Data Sources
*   **Montgomery County 911 Calls (mchirico/montcoalert):** 663,522 real records providing incident descriptions.
*   **Sri Lanka Bus Synthetic Data:** Targeted samples for the 'Harassment' category and Sri Lanka-specific contexts, generated through domain knowledge.
*   **TREC-IS Incident Streams 2018-2021:** Reference for priority label schema.
*   **CrisisBench QCRI:** Reference for text patterns.

## Model Architecture
The system employs a two-stage prediction pipeline:

1.  **False Alert Detector (XGBoost + TF-IDF):**
    *   Identifies likely false or noisy alerts (Priority Score 1).
    *   Uses TF-IDF vectorized `comment_clean` features combined with structural features.
    *   **Performance (Test Set):**
        *   Accuracy: 1.000
        *   F1 Score (weighted): 1.000

2.  **Priority Scorer (LightGBM + SBERT Embeddings):**
    *   Assigns a priority score (2-5) to real alerts (non-false).
    *   Leverages Sentence-BERT (all-MiniLM-L6-v2) for semantic understanding of comments.
    *   Combines SBERT embeddings with structural features.
    *   **Performance (Test Set):**
        *   Accuracy: 1.000
        *   F1 Score (weighted): 1.000
        *   MAE: 0.000

## Feature Engineering
Key features engineered for the models include:
*   `base_priority`: Derived from `bus_type`.
*   `comment_length`, `word_count`, `has_comment`.
*   `critical_kw`, `high_kw`, `false_kw`: Keyword counts for specific urgency levels.
*   `is_gibberish`: A quality gatekeeper to detect non-natural language inputs.
*   `urgency_score`: A composite score combining keyword presence and gibberish detection.
*   One-hot encoded `bus_type` indicators.

