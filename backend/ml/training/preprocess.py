"""
FraudX Analyst - Data Preprocessing
====================================
Loads and prepares the Kaggle credit card fraud dataset.
Used by all three models (XGBoost, LightGBM, Autoencoder).

Dataset: 284,807 transactions | 492 fraud (0.17%) | Features: Time, V1-V28, Amount, Class
"""

import pandas as pd
import numpy as np
import joblib
import os
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from imblearn.over_sampling import SMOTE

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
DATA_PATH   = os.path.join(BASE_DIR, '..', 'data',         'creditcard.csv')
MODELS_DIR  = os.path.join(BASE_DIR, '..', 'models_saved')
os.makedirs(MODELS_DIR, exist_ok=True)


# ── Main function ──────────────────────────────────────────────────────────────
def load_and_preprocess():
    """
    1. Load dataset
    2. Scale Amount and Time (V1-V28 are already PCA-scaled by Kaggle)
    3. Stratified 80/20 train-test split
    Returns: X_train, X_test, y_train, y_test (numpy), feature_names (list)
    """

    # ── 1. Load ────────────────────────────────────────────────────────────────
    print("=" * 55)
    print("  STEP 1: Loading Dataset")
    print("=" * 55)

    df = pd.read_csv(DATA_PATH)

    print(f"  Shape   : {df.shape[0]:,} rows × {df.shape[1]} columns")
    print(f"  Normal  : {(df['Class']==0).sum():,}  ({(df['Class']==0).mean()*100:.2f}%)")
    print(f"  Fraud   : {(df['Class']==1).sum():,}  ({(df['Class']==1).mean()*100:.2f}%)")

    # ── 2. Scale Amount and Time ───────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  STEP 2: Scaling Amount and Time")
    print("=" * 55)

    amount_scaler = StandardScaler()
    time_scaler   = StandardScaler()

    df['Amount'] = amount_scaler.fit_transform(df[['Amount']])
    df['Time']   = time_scaler.fit_transform(df[['Time']])

    # Save scalers – the backend API needs them to scale user input at prediction time
    joblib.dump(amount_scaler, os.path.join(MODELS_DIR, 'amount_scaler.pkl'))
    joblib.dump(time_scaler,   os.path.join(MODELS_DIR, 'time_scaler.pkl'))
    print("  ✅ Scalers saved to models_saved/")

    # ── 3. Features and target ─────────────────────────────────────────────────
    feature_names = [c for c in df.columns if c != 'Class']
    X = df[feature_names].values
    y = df['Class'].values

    # Save feature names for SHAP/LIME plots in the API
    joblib.dump(feature_names, os.path.join(MODELS_DIR, 'feature_names.pkl'))

    # ── 4. Train/Test split ────────────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  STEP 3: Train (80%) / Test (20%) Split")
    print("=" * 55)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y,
        test_size=0.2,
        random_state=42,
        stratify=y          # keeps fraud % the same in both splits
    )

    print(f"  Train : {X_train.shape[0]:,} samples  (fraud: {y_train.sum()})")
    print(f"  Test  : {X_test.shape[0]:,}  samples  (fraud: {y_test.sum()})")

    return X_train, X_test, y_train, y_test, feature_names


# ── SMOTE – for supervised models (XGBoost, LightGBM) ─────────────────────────
def apply_smote(X_train, y_train):
    """
    Synthetically oversamples the minority (fraud) class so the model
    sees a balanced 50/50 dataset during training.
    Only applied to TRAINING data – never to test data.
    """
    print("\n" + "=" * 55)
    print("  STEP 4: Balancing Classes with SMOTE")
    print("=" * 55)
    print(f"  Before → Fraud: {y_train.sum():,}  |  Normal: {(y_train==0).sum():,}")

    smote = SMOTE(random_state=42)
    X_bal, y_bal = smote.fit_resample(X_train, y_train)

    print(f"  After  → Fraud: {y_bal.sum():,}  |  Normal: {(y_bal==0).sum():,}")
    return X_bal, y_bal


# ── Normal-only – for Autoencoder ─────────────────────────────────────────────
def get_normal_only(X_train, y_train):
    """
    Returns only normal (non-fraud) transactions from the training set.
    The Autoencoder learns to reconstruct normal behaviour only.
    Any transaction it reconstructs poorly → likely fraud.
    """
    mask = (y_train == 0)
    X_normal = X_train[mask]
    print(f"\n  ✅ Normal-only training set: {X_normal.shape[0]:,} transactions")
    return X_normal


# ── Quick test ─────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    X_train, X_test, y_train, y_test, features = load_and_preprocess()
    print("\n  ✅ Preprocessing test passed!")
    print(f"  Feature count : {len(features)}")
    print(f"  Features      : {features}")
