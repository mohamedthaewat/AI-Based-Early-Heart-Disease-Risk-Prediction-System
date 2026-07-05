AI-Based Early Heart Disease Risk Prediction System (CardioTwin AI)
Overview

CardioTwin AI is an intelligent healthcare system designed to predict the risk of early heart disease using Machine Learning. The project combines a Flutter mobile application with a Flask backend and an AI-powered chatbot to provide patients with personalized cardiovascular risk assessments and recommendations.

Features
Heart disease risk prediction using Machine Learning
User authentication (Login System)
Patient profile management
AI medical chatbot powered by Groq Llama 3.1
PDF medical report generation
Risk history tracking
Interactive dashboard
REST API using Flask
Flutter mobile application
Technologies Used
Frontend
Flutter
Dart
Backend
Python
Flask
JWT Authentication
SQLite
Machine Learning
Scikit-learn
Pandas
NumPy
Joblib
AI
Groq API
Llama 3.1 8B Instant
Project Structure
AI-Based-Early-Heart-Disease-Risk-Prediction-System
│
├── Heart/
│   ├── app.py
│   ├── model.pkl
│   ├── HeartDisease_Pipeline_v3.ipynb
│   ├── train_model.py
│   ├── requirements.txt
│   └── templates/
│
├── cardiotwin_flutter/
│   ├── lib/
│   ├── pubspec.yaml
│   └── README.md
│
└── README.md
Dataset

The project uses the UCI Heart Disease Dataset.

Reference:

https://archive.ics.uci.edu/ml/datasets/heart+disease

Machine Learning

The model was trained using the UCI Heart Disease dataset after preprocessing and feature engineering. Several classification algorithms were evaluated, and the final trained model is integrated into the Flask backend to generate heart disease risk predictions.

Installation
Backend
cd Heart
pip install -r requirements.txt
python app.py
Flutter
cd cardiotwin_flutter
flutter pub get
flutter run
Authors
Mohamed Hawas
Graduation Project Team
License

This project was developed for educational and graduation project purposes.