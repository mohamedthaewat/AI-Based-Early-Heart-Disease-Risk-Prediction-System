# CardioTwin AI - Advanced Heart Disease Prediction System

## 🎯 Project Overview

CardioTwin AI is a professional-grade AI-powered cardiovascular disease prediction system built for graduation projects in AI Engineering. It combines machine learning, real-time predictions, and an intelligent chatbot to provide comprehensive CVD risk assessment.

## ✨ Key Features

### 1. **Machine Learning Model**
- **Algorithm**: Random Forest Classifier
- **Accuracy**: 84%+
- **Features**: 13 clinical parameters
- **Training Data**: 303 patient records (Cleveland dataset)

### 2. **Real-Time Predictions**
- Instant CVD risk scoring (0-100%)
- Risk levels: Low (<30%), Moderate (30-60%), High (>60%)
- Dynamic feature importance visualization
- Scenario simulation (BP reduction, cholesterol reduction, exercise impact)

### 3. **AI Chatbot Integration**
- Powered by Ollama (local, free, fast)
- Medical Q&A with patient context
- Real-time responses (no API delays)
- Contextual recommendations

### 4. **Analytics Dashboard**
- Patient statistics and risk distribution
- Top risk factors visualization
- Real-time model performance metrics
- Patient history tracking

### 5. **Advanced Reports**
- Professional PDF reports
- Personalized recommendations
- Clinical data summary
- Risk factor analysis

### 6. **API Documentation**
- RESTful API with 8+ endpoints
- Complete endpoint reference
- Request/response examples
- Authentication documentation

### 7. **Model Performance Analysis**
- Feature importance ranking
- Model accuracy metrics
- Training sample information
- Algorithm transparency

### 8. **Personalized Recommendations**
- Lifestyle modifications
- Dietary guidelines
- Medication recommendations
- Health monitoring schedule

## 📊 System Architecture

```
Frontend (HTML/CSS/JS)
├── Assessment Page (Risk Prediction)
├── Dashboard (Analytics)
├── Model Performance
├── Recommendations
├── Chat Interface
├── Patient History
├── API Documentation
└── Welcome Page

Backend (Flask + Python)
├── ML Model (Scikit-learn)
├── Database (SQLite)
├── Ollama Integration
├── PDF Generation
├── Analytics Engine
└── API Endpoints
```

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- Ollama (https://ollama.ai)
- pip packages (see requirements.txt)

### Installation

1. **Clone/Setup Project**
```bash
cd heart_app_v6
pip install -r requirements.txt
```

2. **Start Ollama**
```bash
ollama run neural-chat
```
(First run may take 5-10 minutes to download the model)

3. **Run Application**
```bash
python app.py
```

4. **Access Application**
- Open http://localhost:5000
- Login with: admin / admin123

## 🎮 Usage

### Assessment Page
1. Adjust patient parameters using sliders
2. View real-time CVD risk score
3. See top risk factors
4. Simulate lifestyle changes
5. Generate PDF report

### Dashboard
- View aggregate patient statistics
- Analyze risk distribution
- Track top risk factors
- Monitor model performance

### Chatbot
- Ask medical questions
- Get responses based on patient context
- Receive personalized advice
- All powered by local Ollama

### Recommendations
- View personalized health recommendations
- See lifestyle, diet, and medication guidance
- Download recommendations as PDF
- Share with healthcare provider

## 📁 Project Structure

```
heart_app_v6/
├── app.py                          # Flask backend
├── model.pkl                       # Trained ML model
├── train_model.py                  # Model training script
├── requirements.txt                # Python dependencies
├── heart_disease_uci.csv          # Training dataset
├── patients.db                     # SQLite database
├── static/                         # CSS, JS, images
└── templates/
    ├── index.html                 # Assessment page
    ├── chat.html                  # Chatbot interface
    ├── history.html               # Patient history
    ├── dashboard.html             # Analytics dashboard
    ├── performance.html           # Model performance
    ├── recommendations.html       # Health recommendations
    ├── api.html                   # API documentation
    ├── login.html                 # Login page
    ├── welcome.html               # Welcome page
    └── ...
```

## 🔌 API Endpoints

### Predictions
- `POST /predict` - Get CVD risk score
- `POST /simulate` - Simulate lifestyle changes

### Chat
- `POST /chatbot` - Chat with AI assistant

### Analytics
- `GET /api/dashboard` - Dashboard statistics
- `GET /api/model-performance` - Model metrics
- `POST /api/recommendations` - Health recommendations

### Patient Management
- `GET /get_patients` - List patients
- `POST /save_patient` - Save patient record
- `DELETE /delete_patient/<id>` - Delete patient

### Pages
- `GET /assessment` - Risk prediction page
- `GET /dashboard` - Analytics dashboard
- `GET /performance` - Model performance
- `GET /recommendations` - Recommendations page
- `GET /chat` - Chatbot interface
- `GET /history` - Patient history
- `GET /api` - API documentation

## 🤖 Chatbot Configuration

**Current Setup**: Ollama (local, free, fast)
- Model: neural-chat
- No API keys needed
- Runs on localhost:11434
- Instant responses

**Alternative Options**:
- Gemini API (requires key, free tier limited)
- Claude API (requires key, paid)
- Local LLaMA models (custom setup)

## 🔐 Security

- Session-based authentication
- Password hashing (SHA-256)
- Role-based access control (Doctor/Admin)
- SQL injection protection
- CORS security headers

## 🎓 Educational Value

This project demonstrates:
- ✅ Machine Learning (Classification, Feature Engineering)
- ✅ Full-stack Web Development (Flask, HTML/CSS/JS)
- ✅ Database Design (SQLite)
- ✅ API Design & Documentation
- ✅ Data Visualization (Chart.js)
- ✅ AI Integration (Ollama, LLMs)
- ✅ Professional UI/UX
- ✅ Healthcare Domain Knowledge

## 📈 Performance Metrics

| Metric | Value |
|--------|-------|
| Model Accuracy | 84%+ |
| Training Samples | 303 |
| Features Used | 13 |
| Risk Categories | 3 |
| Response Time | <200ms |
| Chatbot Response | 2-5 seconds |

## 🛠️ Technologies Used

### Frontend
- HTML5
- CSS3 (Custom Design)
- JavaScript (Vanilla)
- Chart.js (Visualizations)

### Backend
- Flask (Web Framework)
- Scikit-learn (ML)
- Pandas (Data Processing)
- SQLite (Database)
- ReportLab (PDF Generation)

### AI/ML
- Random Forest Classifier
- Feature Importance Analysis
- Ollama (Local LLM)
- SHAP (Explainability)

## 📝 Sample Data

Admin Account:
- Username: `admin`
- Password: `admin123`
- Role: Administrator

## 🐛 Troubleshooting

### Ollama Not Responding
```bash
# Restart Ollama
ollama serve
# Or in new terminal
ollama run neural-chat
```

### Database Issues
```bash
# Reset database
rm patients.db
python app.py  # Will recreate database
```

### Model Not Found
```bash
# Ensure model.pkl exists in project root
# If missing, run train_model.py to regenerate
python train_model.py
```

## 🎯 Future Enhancements

- [ ] Multi-model comparison (XGBoost, SVM)
- [ ] Advanced SHAP visualizations
- [ ] Mobile app (React Native)
- [ ] Real-time data streaming
- [ ] Integration with EHR systems
- [ ] Deployment to cloud (AWS/GCP)
- [ ] Advanced analytics (Time series, Trends)
- [ ] Multi-language support
- [ ] Voice interface
- [ ] Wearable device integration

## 📄 License

This project is for educational purposes.

## 👨‍💻 Author

AI Engineering Graduation Project - 2026

## 📞 Support

For issues or questions, refer to the API documentation at `/api` endpoint.

---

**Made with ❤️ for Cardiovascular Health**
