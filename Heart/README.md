# CardioTwin AI 🫀
## Heart Disease Digital Twin — Web App

### طريقة التشغيل

#### الخطوة 1 - تنصيب المكتبات
```
py -m pip install flask scikit-learn pandas numpy shap
```

#### الخطوة 2 - حط الداتا
حط ملف `heart_disease_uci.csv` في نفس مجلد المشروع

#### الخطوة 3 - تدريب النموذج
```
py train_model.py
```

#### الخطوة 4 - تشغيل الـ Web App
```
py app.py
```

#### الخطوة 5 - افتح المتصفح
```
http://127.0.0.1:5000
```

### مميزات المشروع
- Ensemble Model (GB + RF + LR) بدقة 85%+
- Animated Risk Counter
- Gauge Chart تفاعلي
- AI Explainability (SHAP / Feature Importance)
- Digital Twin Simulation
- UI احترافي داكن
