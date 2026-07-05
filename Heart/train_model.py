import pandas as pd
import numpy as np
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier, VotingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import pickle
import warnings
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(BASE_DIR, 'heart_disease_uci.csv')

warnings.filterwarnings('ignore')

print("=" * 50)
print("   CardioTwin AI - Model Training")
print("=" * 50)

# ── تحميل الداتا ──
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(BASE_DIR, 'heart_disease_uci.csv')

df = pd.read_csv(file_path)
df.drop(columns=['id'], inplace=True)
df['target'] = (df['num'] > 0).astype(int)
df.drop(columns=['num'], inplace=True)

# ── تنظيف الداتا ──
encoders = {}
for col in ['sex', 'dataset', 'cp', 'restecg', 'slope', 'thal']:
    le = LabelEncoder()
    df[col] = le.fit_transform(df[col].astype(str))
    encoders[col] = le
df['exang'] = df['exang'].map({True: 1, False: 0, 'TRUE': 1, 'FALSE': 0}).fillna(0)
df['fbs']   = df['fbs'].map({True: 1, False: 0, 'TRUE': 1, 'FALSE': 0}).fillna(0)

X = df.drop(columns=['target'])
y = df['target']

# ── تجهيز الداتا ──
imputer = SimpleImputer(strategy='median')
X_imp = imputer.fit_transform(X)

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_imp)

# ── تقسيم Train/Test ──
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42, stratify=y)

# ── تدريب النماذج ──
gb = GradientBoostingClassifier(n_estimators=500, max_depth=4, learning_rate=0.05, subsample=0.8, random_state=42)
rf = RandomForestClassifier(n_estimators=300, max_depth=10, random_state=42, n_jobs=-1)
lr = LogisticRegression(max_iter=1000, C=0.5, random_state=42)

print("\nجاري تدريب النماذج...")

# Ensemble
ensemble = VotingClassifier(
    estimators=[('gb', gb), ('rf', rf), ('lr', lr)],
    voting='soft'
)
ensemble.fit(X_train, y_train)
acc = accuracy_score(y_test, ensemble.predict(X_test))
print(f"دقة Ensemble: {acc*100:.2f}%")

# ── SHAP Feature Importance (بديل بسيط لو SHAP مش متنصب) ──
gb.fit(X_train, y_train)
feature_importance = dict(zip(X.columns, gb.feature_importances_))
feature_importance = dict(sorted(feature_importance.items(), key=lambda x: x[1], reverse=True))
print(f"\nأهم الـ Features:")
for feat, imp in list(feature_importance.items())[:5]:
    print(f"  {feat}: {imp:.3f}")

# ── حفظ النموذج ──
with open('model.pkl', 'wb') as f:
    pickle.dump({
        'model': ensemble,
        'gb_model': gb,
        'imputer': imputer,
        'scaler': scaler,
        'columns': list(X.columns),
        'feature_importance': feature_importance,
        'accuracy': acc,
        'encoders': encoders
    }, f)

print(f"\n✅ تم حفظ النموذج - دقة: {acc*100:.2f}%")

# ── محاولة تنصيب SHAP ──
try:
    import shap
    print("\nجاري حساب SHAP values...")
    explainer = shap.TreeExplainer(gb)
    shap_values = explainer.shap_values(X_test[:50])
    shap_importance = dict(zip(X.columns, np.abs(shap_values).mean(0)))
    shap_importance = dict(sorted(shap_importance.items(), key=lambda x: x[1], reverse=True))
    with open('model.pkl', 'rb') as f:
        saved = pickle.load(f)
    saved['shap_importance'] = shap_importance
    with open('model.pkl', 'wb') as f:
        pickle.dump(saved, f)
    print("✅ SHAP values محفوظة!")
except ImportError:
    print("\nملاحظة: SHAP مش متنصب، شغال بـ Feature Importance عادي.")
    print("لو عايز SHAP اكتب: pip install shap")
