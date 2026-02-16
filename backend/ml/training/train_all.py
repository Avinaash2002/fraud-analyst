"""
FraudX Analyst - Train All Models
====================================
Run this ONE script to train all three models in sequence:
  1. XGBoost   (supervised, ~2 min)
  2. LightGBM  (supervised, ~2 min)
  3. Autoencoder (unsupervised, ~3-5 min)

Results are saved to:  backend/ml/models_saved/
MLflow dashboard:      run  →  mlflow ui  ← in a separate terminal
"""

import os, json
from train_xgboost    import train_xgboost
from train_lightgbm   import train_lightgbm
from train_autoencoder import train_autoencoder

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, '..', 'models_saved')

if __name__ == "__main__":

    print("\n" + "=" * 60)
    print("  FraudX Analyst — Full Model Training Pipeline")
    print("=" * 60)

    all_results = {}

    # ── 1. XGBoost ─────────────────────────────────────────────────────────────
    _, xgb_meta = train_xgboost()
    all_results["XGBoost"] = xgb_meta

    # ── 2. LightGBM ────────────────────────────────────────────────────────────
    _, lgbm_meta = train_lightgbm()
    all_results["LightGBM"] = lgbm_meta

    # ── 3. Autoencoder ─────────────────────────────────────────────────────────
    _, ae_meta, _ = train_autoencoder()
    all_results["Autoencoder"] = ae_meta

    # ── Save combined summary ──────────────────────────────────────────────────
    summary_path = os.path.join(MODELS_DIR, 'all_metrics.json')
    with open(summary_path, 'w') as f:
        json.dump(all_results, f, indent=2)

    # ── Print comparison table ─────────────────────────────────────────────────
    print("\n\n" + "=" * 70)
    print("  TRAINING COMPLETE — Model Comparison")
    print("=" * 70)
    header = f"{'Model':<14} {'Accuracy':>10} {'Precision':>10} {'Recall':>10} {'F1':>10} {'AUC-ROC':>10}"
    print(header)
    print("-" * 70)
    for name, m in all_results.items():
        print(f"{name:<14} {m['accuracy']:>10} {m['precision']:>10} "
              f"{m['recall']:>10} {m['f1_score']:>10} {m['auc_roc']:>10}")

    print("\n  ✅ All models saved  →", MODELS_DIR)
    print("  ✅ Summary JSON      →", summary_path)
    print("\n  💡 To view MLflow dashboard:")
    print("     Open a NEW terminal, activate venv, then run:  mlflow ui")
    print("     Then open:  http://127.0.0.1:5000")
    print("=" * 70)
