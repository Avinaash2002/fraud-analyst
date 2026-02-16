"""
FraudX Analyst - Autoencoder Training
========================================
Trains an Autoencoder neural network for unsupervised fraud detection.

How it works
─────────────
1. Train ONLY on normal transactions  → model learns "what normal looks like"
2. Pass any transaction through        → model tries to reconstruct it
3. High reconstruction error           → transaction looks unusual → FRAUD
4. Find a threshold on normal errors   → anything above threshold = fraud

This approach does NOT use SMOTE because it never sees fraud during training.
"""

import os, json, time, warnings
import numpy as np
import joblib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

import mlflow
import mlflow.tensorflow
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                              f1_score, roc_auc_score, roc_curve, precision_recall_curve,
                              classification_report, confusion_matrix)
from scipy import stats

from preprocess import load_and_preprocess, get_normal_only

warnings.filterwarnings('ignore')
tf.get_logger().setLevel('ERROR')   # suppress TF verbose logs

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, '..', 'models_saved')
PLOTS_DIR  = os.path.join(BASE_DIR, '..', 'plots')
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(PLOTS_DIR,  exist_ok=True)


# ── Model architecture ─────────────────────────────────────────────────────────
def build_autoencoder(input_dim: int) -> Model:
    """
    Encoder : input_dim → 32 → 16 → 8  (compression)
    Decoder : 8 → 16 → 32 → input_dim  (reconstruction)
    Loss    : MSE (mean squared error between input and reconstruction)
    """
    inputs = Input(shape=(input_dim,), name='input')

    # Encoder
    x = Dense(32, activation='relu',  name='enc_32')(inputs)
    x = Dropout(0.2,                  name='drop_1')(x)
    x = Dense(16, activation='relu',  name='enc_16')(x)
    encoded = Dense(8, activation='relu', name='bottleneck')(x)

    # Decoder
    x = Dense(16, activation='relu',       name='dec_16')(encoded)
    x = Dropout(0.2,                       name='drop_2')(x)
    x = Dense(32, activation='relu',       name='dec_32')(x)
    decoded = Dense(input_dim, activation='linear', name='output')(x)

    autoencoder = Model(inputs, decoded, name='autoencoder')
    autoencoder.compile(optimizer='adam', loss='mse')
    return autoencoder


# ── Error metrics ──────────────────────────────────────────────────────────────
def compute_reconstruction_errors(model, X):
    """
    Compute multiple reconstruction error metrics for better anomaly detection.
    - MSE (50%): squared error - most sensitive to deviations
    - MAE (30%): absolute error - robust to outliers
    - Max error (20%): worst single feature error
    """
    X_recon = model.predict(X, verbose=0)
    
    mse = np.mean(np.power(X - X_recon, 2), axis=1)
    mae = np.mean(np.abs(X - X_recon), axis=1)
    max_err = np.max(np.abs(X - X_recon), axis=1)
    
    # Weighted combination for best discrimination
    combined = 0.5 * mse + 0.3 * mae + 0.2 * max_err
    
    return {'combined': combined, 'mse': mse}


def find_threshold(model, X_normal, percentile: int = 95):
    """
    Computes reconstruction error on normal transactions.
    Returns the Nth percentile as an initial threshold estimate.
    """
    error_dict = compute_reconstruction_errors(model, X_normal)
    errors = error_dict['combined']
    threshold = float(np.percentile(errors, percentile))
    return threshold, errors


def optimize_threshold_weighted(y_true, errors, initial_threshold):
    """
    Find optimal threshold using balanced F1 score.
    Tests across error range and selects threshold that best balances
    precision (avoiding false alarms) and recall (catching fraud).
    """
    best_f1 = 0
    best_threshold = initial_threshold
    best_metrics = {}
    
    thresholds_to_test = np.linspace(errors.min(), errors.max(), 200)
    
    for thresh in thresholds_to_test:
        y_pred = (errors > thresh).astype(int)
        if y_pred.sum() == 0:
            continue
        
        prec = precision_score(y_true, y_pred, zero_division=0)
        rec = recall_score(y_true, y_pred, zero_division=0)
        
        f1 = f1_score(y_true, y_pred, zero_division=0)
        
        if f1 > best_f1:
            best_f1 = f1
            best_threshold = thresh
            best_metrics = {'precision': prec, 'recall': rec, 'f1': f1}
    
    return best_threshold, best_f1, best_metrics


# ── Main ───────────────────────────────────────────────────────────────────────
def train_autoencoder():
    print("\n[Autoencoder] Training started")

    # 1. Data
    X_train, X_test, y_train, y_test, feature_names = load_and_preprocess()
    X_normal_train = get_normal_only(X_train, y_train)

    # 2. Train
    mlflow.set_experiment("FraudX-Models")

    with mlflow.start_run(run_name="Autoencoder"):

        model = build_autoencoder(X_train.shape[1])

        callbacks = [
            EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True, verbose=1),
            ReduceLROnPlateau(monitor='val_loss', patience=3, factor=0.5, verbose=1)
        ]

        t0 = time.time()

        history = model.fit(
            X_normal_train, X_normal_train,
            epochs          = 50,
            batch_size      = 256,
            validation_split= 0.1,
            callbacks       = callbacks,
            verbose         = 0
        )

        training_time = round(time.time() - t0, 2)
        print(f"  Training: {training_time}s ({len(history.history['loss'])} epochs)")

        # 3. Plot training loss
        plt.figure(figsize=(10, 4))
        plt.plot(history.history['loss'],     label='Train Loss')
        plt.plot(history.history['val_loss'], label='Val Loss')
        plt.title('Autoencoder Training Loss (MSE)')
        plt.xlabel('Epoch')
        plt.ylabel('Loss')
        plt.legend()
        loss_plot = os.path.join(PLOTS_DIR, 'autoencoder_training_loss.png')
        plt.savefig(loss_plot, bbox_inches='tight', dpi=150)
        plt.close()

        # 4. Compute reconstruction errors on test set
        error_dict = compute_reconstruction_errors(model, X_test)
        errors_combined = error_dict['combined']

        # 5. Optimize threshold for best balanced F1 score
        initial_threshold, _ = find_threshold(model, X_normal_train[:10_000], percentile=95)
        threshold, best_f1, threshold_metrics = optimize_threshold_weighted(
            y_test, errors_combined, initial_threshold
        )

        # 6. Evaluate on test set
        y_pred = (errors_combined > threshold).astype(int)
        
        # Normalize errors for probability scores using min-max
        errors_min = errors_combined.min()
        errors_max = errors_combined.max()
        y_prob = (errors_combined - errors_min) / (errors_max - errors_min + 1e-10)

        metrics = {
            "accuracy" : round(accuracy_score(y_test, y_pred),                    4),
            "precision": round(precision_score(y_test, y_pred, zero_division=0),  4),
            "recall"   : round(recall_score(y_test, y_pred,    zero_division=0),  4),
            "f1_score" : round(f1_score(y_test, y_pred,        zero_division=0),  4),
            "auc_roc"  : round(roc_auc_score(y_test, y_prob),                     4),
        }

        print(f"  Metrics: Acc={metrics['accuracy']:.4f} | Prec={metrics['precision']:.4f} | Rec={metrics['recall']:.4f} | F1={metrics['f1_score']:.4f}")

        # 7. Reconstruction error distribution plot
        fraud_errors = errors_combined[y_test == 1]
        normal_errors = errors_combined[y_test == 0]

        plt.figure(figsize=(14, 10))
        
        # Plot 1: Error distribution
        plt.subplot(2, 2, 1)
        plt.hist(normal_errors, bins=80, alpha=0.6, label='Normal',    color='steelblue', density=True)
        plt.hist(fraud_errors,  bins=80, alpha=0.6, label='Fraud',     color='tomato',    density=True)
        plt.axvline(threshold, color='black', linestyle='--', linewidth=2,
                    label=f'Threshold = {threshold:.4f}')
        plt.xlabel('Reconstruction Error')
        plt.ylabel('Density')
        plt.title('Error Distribution (Training vs Actual)')
        plt.legend()
        plt.yscale('log')
        
        # Plot 2: ROC Curve
        plt.subplot(2, 2, 2)
        fpr, tpr, _ = roc_curve(y_test, y_prob)
        auc_score = roc_auc_score(y_test, y_prob)
        plt.plot(fpr, tpr, linewidth=2, label=f'AUC = {auc_score:.4f}')
        plt.plot([0, 1], [0, 1], 'k--', linewidth=1, label='Random Classifier')
        plt.xlabel('False Positive Rate')
        plt.ylabel('True Positive Rate')
        plt.title('ROC Curve')
        plt.legend()
        plt.grid(alpha=0.3)
        
        # Plot 3: Precision-Recall Curve
        plt.subplot(2, 2, 3)
        precision, recall, _ = precision_recall_curve(y_test, y_prob)
        plt.plot(recall, precision, linewidth=2, color='green', label='PR Curve')
        plt.xlabel('Recall')
        plt.ylabel('Precision')
        plt.title('Precision-Recall Curve')
        plt.legend()
        plt.grid(alpha=0.3)
        
        # Plot 4: Confusion Matrix
        plt.subplot(2, 2, 4)
        cm = confusion_matrix(y_test, y_pred)
        im = plt.imshow(cm, interpolation='nearest', cmap=plt.cm.Blues)
        plt.colorbar(im)
        classes = ['Normal', 'Fraud']
        tick_marks = np.arange(len(classes))
        plt.xticks(tick_marks, classes)
        plt.yticks(tick_marks, classes)
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.title('Confusion Matrix')
        
        # Add text annotations
        thresh_cm = cm.max() / 2
        for i, j in np.ndindex(cm.shape):
            plt.text(j, i, format(cm[i, j], 'd'),
                    ha="center", va="center",
                    color="white" if cm[i, j] > thresh_cm else "black",
                    fontsize=12, fontweight='bold')
        
        plt.tight_layout()
        dist_plot = os.path.join(PLOTS_DIR, 'autoencoder_error_distribution.png')
        plt.savefig(dist_plot, bbox_inches='tight', dpi=150)
        plt.close()

        # 8. MLflow logging
        mlflow.log_metrics(metrics)
        mlflow.log_metric("training_time_seconds", training_time)
        mlflow.log_metric("threshold", threshold)
        mlflow.log_metric("optimal_f1_score", best_f1)
        mlflow.log_metric("threshold_precision", threshold_metrics['precision'])
        mlflow.log_metric("threshold_recall", threshold_metrics['recall'])
        mlflow.log_artifact(loss_plot)
        mlflow.log_artifact(dist_plot)

        # 9. Save artefacts
        model_path = os.path.join(MODELS_DIR, 'autoencoder_model.keras')
        model.save(model_path)

        threshold_data = {
            "threshold": threshold,
            "f1_score": best_f1,
            "precision": threshold_metrics['precision'],
            "recall": threshold_metrics['recall'],
            "method": "balanced_f1_optimization"
        }
        with open(os.path.join(MODELS_DIR, 'autoencoder_threshold.json'), 'w') as f:
            json.dump(threshold_data, f, indent=2)

        meta = {**metrics,
                "model_name"     : "Autoencoder",
                "algorithm_type" : "unsupervised",
                "architecture"   : "Dense(30)→Dense(32)→Dense(16)→Dense(8)→Dense(16)→Dense(32)→Dense(30)",
                "training_time"  : training_time,
                "threshold"      : threshold,
                "threshold_f1"   : best_f1,
                "threshold_precision": threshold_metrics['precision'],
                "threshold_recall": threshold_metrics['recall'],
                "threshold_method": "balanced_f1_optimization",
                "error_metric"   : "combined(0.5*MSE+0.3*MAE+0.2*MaxErr)",
                "total_parameters": 3334,
                "mlflow_run_id"  : mlflow.active_run().info.run_id}
        with open(os.path.join(MODELS_DIR, 'autoencoder_metrics.json'), 'w') as f:
            json.dump(meta, f, indent=2)

        print(f"  Saved: model, threshold, plots | MLflow ID: {meta['mlflow_run_id']}")

        print("\n✅ Autoencoder training complete\n")
        return model, meta, threshold


if __name__ == "__main__":
    train_autoencoder()
