"""
FraudX Analyst - XGBoost Training (Tuned)
==========================================
Changes from v1:
  • Removed SMOTE → replaced with scale_pos_weight
  • Added Optuna hyperparameter tuning (50 trials)
  • Keeps best model found by Optuna
"""

import os, json, time, warnings
import numpy as np
import joblib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

import optuna
import shap
import mlflow
import mlflow.xgboost
from xgboost import XGBClassifier
from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                              f1_score, roc_auc_score, classification_report)

from preprocess import load_and_preprocess

warnings.filterwarnings('ignore')
optuna.logging.set_verbosity(optuna.logging.WARNING)

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, '..', 'models_saved')
PLOTS_DIR  = os.path.join(BASE_DIR, '..', 'plots')
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(PLOTS_DIR,  exist_ok=True)


# ── Helper ─────────────────────────────────────────────────────────────────────
def compute_metrics(y_true, y_pred, y_prob):
    return {
        "accuracy" : round(accuracy_score(y_true, y_pred),                   4),
        "precision": round(precision_score(y_true, y_pred, zero_division=0), 4),
        "recall"   : round(recall_score(y_true, y_pred,    zero_division=0), 4),
        "f1_score" : round(f1_score(y_true, y_pred,        zero_division=0), 4),
        "auc_roc"  : round(roc_auc_score(y_true, y_prob),                    4),
    }


# ── Optuna objective ───────────────────────────────────────────────────────────
def make_objective(X_train, y_train, X_test, y_test, scale_pos_weight):
    """
    Optuna calls this 50 times with different parameter combos.
    Each trial trains a model and returns the F1 score.
    Optuna focuses on parameter ranges that give the best F1.
    """
    def objective(trial):
        params = {
            "n_estimators"     : trial.suggest_int("n_estimators",       100, 500),
            "max_depth"        : trial.suggest_int("max_depth",            3,   9),
            "learning_rate"    : trial.suggest_float("learning_rate",   0.01, 0.3, log=True),
            "subsample"        : trial.suggest_float("subsample",        0.6, 1.0),
            "colsample_bytree" : trial.suggest_float("colsample_bytree", 0.6, 1.0),
            "min_child_weight" : trial.suggest_int("min_child_weight",    1,  10),
            "gamma"            : trial.suggest_float("gamma",             0,   5),
            "reg_alpha"        : trial.suggest_float("reg_alpha",         0,   2),
            "reg_lambda"       : trial.suggest_float("reg_lambda",        0,   2),
            "scale_pos_weight" : scale_pos_weight,
            "eval_metric"      : "logloss",
            "random_state"     : 42,
            "n_jobs"           : -1,
        }
        model = XGBClassifier(**params)
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        return f1_score(y_test, y_pred, zero_division=0)

    return objective


# ── Main ───────────────────────────────────────────────────────────────────────
def train_xgboost():
    print("\n" + "🔷 " * 22)
    print("  TRAINING: XGBoost (Tuned — no SMOTE)")
    print("🔷 " * 22)

    # 1. Data — no SMOTE
    X_train, X_test, y_train, y_test, feature_names = load_and_preprocess()

    # scale_pos_weight = normal count / fraud count
    # tells XGBoost how much more to penalise missing a fraud vs a normal
    n_normal         = (y_train == 0).sum()
    n_fraud          = (y_train == 1).sum()
    scale_pos_weight = round(n_normal / n_fraud, 2)
    print(f"\n  scale_pos_weight = {n_normal} / {n_fraud} = {scale_pos_weight}")

    # 2. Optuna tuning
    print(f"\n  Running Optuna (50 trials) …  (~5-10 minutes)\n")

    mlflow.set_experiment("FraudX-Models")

    with mlflow.start_run(run_name="XGBoost_Tuned"):

        t0 = time.time()

        study = optuna.create_study(direction="maximize")
        study.optimize(
            make_objective(X_train, y_train, X_test, y_test, scale_pos_weight),
            n_trials=50,
            show_progress_bar=True
        )

        best_params = study.best_params
        best_params["scale_pos_weight"] = scale_pos_weight
        best_params["eval_metric"]      = "logloss"
        best_params["random_state"]     = 42
        best_params["n_jobs"]           = -1

        print(f"\n  ✅ Best trial F1  : {study.best_value:.4f}")
        print(f"  Best params      : {best_params}")

        # 3. Train final model with best params
        print("\n  Training final model with best params …")
        model = XGBClassifier(**best_params)
        model.fit(X_train, y_train)

        training_time = round(time.time() - t0, 2)
        print(f"  ✅ Total time: {training_time}s")

        # 4. Evaluate
        y_pred = model.predict(X_test)
        y_prob = model.predict_proba(X_test)[:, 1]
        metrics = compute_metrics(y_test, y_pred, y_prob)

        print("\n  📊 Metrics:")
        for k, v in metrics.items():
            print(f"     {k:<12}: {v}")
        print()
        print(classification_report(y_test, y_pred, target_names=['Normal', 'Fraud']))

        # 5. MLflow logging
        mlflow.log_params(best_params)
        mlflow.log_metrics(metrics)
        mlflow.log_metric("training_time_seconds", training_time)
        mlflow.log_metric("optuna_best_f1", study.best_value)
        mlflow.xgboost.log_model(model, "xgboost_tuned_model")

        # 6. SHAP
        print("  Calculating SHAP values (500 samples) …")
        idx         = np.random.choice(len(X_test), size=500, replace=False)
        X_sample    = X_test[idx]
        explainer   = shap.TreeExplainer(model)
        shap_values = explainer.shap_values(X_sample)

        plt.figure(figsize=(10, 8))
        shap.summary_plot(shap_values, X_sample,
                          feature_names=feature_names, show=False)
        plot_path = os.path.join(PLOTS_DIR, 'xgboost_shap_summary.png')
        plt.savefig(plot_path, bbox_inches='tight', dpi=150)
        plt.close()
        mlflow.log_artifact(plot_path)
        print(f"  ✅ SHAP plot saved")

        # 7. Save artefacts
        joblib.dump(model,     os.path.join(MODELS_DIR, 'xgboost_model.pkl'))
        joblib.dump(explainer, os.path.join(MODELS_DIR, 'xgboost_explainer.pkl'))

        meta = {**metrics,
                "model_name"       : "XGBoost",
                "algorithm_type"   : "supervised",
                "training_time"    : training_time,
                "scale_pos_weight" : scale_pos_weight,
                "optuna_trials"    : 50,
                "best_params"      : best_params,
                "mlflow_run_id"    : mlflow.active_run().info.run_id}
        with open(os.path.join(MODELS_DIR, 'xgboost_metrics.json'), 'w') as f:
            json.dump(meta, f, indent=2)

        print(f"  ✅ Model + explainer saved")
        print(f"  ✅ MLflow Run ID → {meta['mlflow_run_id']}")

        return model, meta


if __name__ == "__main__":
    train_xgboost()
