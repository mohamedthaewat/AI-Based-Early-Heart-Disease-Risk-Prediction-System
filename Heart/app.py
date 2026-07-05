from flask import Flask, render_template, request, jsonify, send_file, redirect, url_for, session
from flask_cors import CORS
import pickle, numpy as np, io, sqlite3, os, requests, hashlib, secrets
from datetime import datetime
from functools import wraps

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", secrets.token_hex(32))
CORS(app, supports_credentials=True)

DB_PATH = 'patients.db'
# ── DB ──────────────────────────────────────────────────────
def init_db():
    admin_pw_plain = os.environ.get("ADMIN_PASSWORD", "admin123")
    admin_pw = hashlib.sha256(admin_pw_plain.encode()).hexdigest()
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''CREATE TABLE IF NOT EXISTS patients (
            id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER, sex TEXT,
            risk REAL, level TEXT, trestbps REAL, chol REAL, thalch REAL, oldpeak REAL,
            ca INTEGER, cp INTEGER, thal INTEGER, exang INTEGER, fbs INTEGER,
            created_at TEXT, user_id INTEGER DEFAULT 1)''')
        conn.execute('''CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL, full_name TEXT, role TEXT DEFAULT 'doctor', created_at TEXT)''')
        conn.execute('INSERT OR IGNORE INTO users (username,password,full_name,role,created_at) VALUES (?,?,?,?,?)',
            ('admin', admin_pw, 'Administrator', 'admin', datetime.now().strftime("%Y-%m-%d")))
        conn.commit()

init_db()

# ── Model ───────────────────────────────────────────────────
import os
MODEL_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "model.pkl"
)
with open(MODEL_PATH, "rb") as f:
    _d = pickle.load(f)
    model = _d['model']
    imputer = _d['imputer']
    scaler = _d['scaler']
    columns = _d['columns']
    accuracy = _d.get('accuracy', 0)
    feature_importance = _d.get('shap_importance') or _d.get('feature_importance', {})

# ── MAPPINGS (Web App → Model) ───────────────────────────────
# LabelEncoder mappings من الداتا الأصلية:
# sex:     Female=0, Male=1  ✅ نفس الـ Web App
# dataset: Cleveland=0  → نحط 0 دايماً
# cp:      asymptomatic=0, atypical angina=1, non-anginal=2, typical angina=3
#          Web App:      0=Typical,           1=Atypical,     2=Non-anginal, 3=Asymptomatic
CP_MAP = {0: 3, 1: 1, 2: 2, 3: 0}

# restecg: lv hypertrophy=0, normal=1, st-t abnormality=2
#          Web App: 1=normal → correct already, just map
RESTECG_MAP = {0: 1, 1: 2, 2: 0}  # Web App: 0=Normal,1=ST-T,2=LVH → Model: normal=1,st-t abnormality=2,lv hypertrophy=0

# slope:   downsloping=0, flat=1, upsloping=2
#          Web App: 0=upsloping, 1=flat, 2=downsloping → Model: upsloping=2,flat=1,downsloping=0
SLOPE_MAP = {0: 2, 1: 1, 2: 0}

# thal:    fixed defect=0, normal=1, reversable defect=2
#          Web App: 1=Fixed, 2=Reversable, 3=Normal → Model: fixed=0,reversable=2,normal=1
THAL_MAP = {1: 0, 2: 2, 3: 1}

def map_input(v):
    """تحويل قيم الـ Web App للقيم الصح للنموذج"""
    d = dict(v)
    d['cp']      = CP_MAP.get(int(d.get('cp', 0)), 0)
    d['thal']    = THAL_MAP.get(int(d.get('thal', 3)), 1)
    d['slope']   = SLOPE_MAP.get(int(d.get('slope', 2)), 1)
    d['restecg'] = RESTECG_MAP.get(int(d.get('restecg', 1)), 1)
    d['dataset'] = 0  # Cleveland
    return d

def predict_risk(v):
    d   = map_input(v)
    arr = np.array([[d.get(c, 0) for c in columns]])
    return round(model.predict_proba(scaler.transform(imputer.transform(arr)))[0][1]*100, 1)

def get_features(v, top=5):
    items = list(feature_importance.items())[:top]
    mx    = max(x for _, x in items) if items else 1
    return [{'name': f, 'importance': round(i/mx*100,1), 'value': round(float(v.get(f,0)),2)} for f,i in items]

def login_required(f):
    @wraps(f)
    def dec(*a, **k):
        if 'user_id' not in session: return redirect(url_for('login'))
        return f(*a, **k)
    return dec

# ── Token Store (in-memory for simplicity) ──────────────────
_tokens = {}

# ── Auth ────────────────────────────────────────────────────
@app.route('/api/login', methods=['POST'])
def api_login():
    d  = request.json
    pw = hashlib.sha256(d.get('password','').encode()).hexdigest()
    with sqlite3.connect(DB_PATH) as conn:
        u = conn.execute('SELECT * FROM users WHERE username=? AND password=?',
                         (d.get('username','').strip(), pw)).fetchone()
    if u:
        token = secrets.token_hex(32)
        _tokens[token] = {'user_id': u[0], 'username': u[1], 'full_name': u[3], 'role': u[4]}
        return jsonify({'success': True, 'token': token, 'username': u[1], 'full_name': u[3], 'role': u[4]})
    return jsonify({'success': False, 'message': 'Invalid username or password'})

@app.route('/api/logout', methods=['POST'])
def api_logout():
    token = request.headers.get('X-Auth-Token','')
    _tokens.pop(token, None)
    return jsonify({'success': True})

def token_required(f):
    @wraps(f)
    def dec(*a, **k):
        token = request.headers.get('X-Auth-Token','')
        if not token:
            token = request.args.get('_token', '')
        if not token and request.is_json:
            token = (request.get_json(silent=True) or {}).get('_token', '')
        user = _tokens.get(token)
        if not user:
            return jsonify({'error': 'Unauthorized'}), 401
        request.user = user
        return f(*a, **k)
    return dec

@app.route('/api/predict', methods=['POST'])
@token_required
def api_predict():
    v = request.json
    r = predict_risk(v)
    feats = get_features(v)
    lv = 'Low Risk' if r < 30 else 'Moderate Risk' if r < 60 else 'High Risk'
    return jsonify({'risk': r, 'level': lv, 'features': feats})

@app.route('/api/save_patient', methods=['POST'])
@token_required
def api_save_patient():
    v  = request.json
    r  = predict_risk(v)
    lv = 'Low Risk' if r < 30 else 'Moderate Risk' if r < 60 else 'High Risk'
    uid = request.user['user_id']
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''INSERT INTO patients
            (name,age,sex,risk,level,trestbps,chol,thalch,oldpeak,ca,cp,thal,exang,fbs,created_at,user_id)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
            (v.get('patient_name','Unknown'), int(v.get('age',0)),
             'Male' if int(v.get('sex',1))==1 else 'Female', r, lv,
             v.get('trestbps',0), v.get('chol',0), v.get('thalch',0), v.get('oldpeak',0),
             int(v.get('ca',0)), int(v.get('cp',0)), int(v.get('thal',3)),
             int(v.get('exang',0)), int(v.get('fbs',0)),
             datetime.now().strftime("%Y-%m-%d %H:%M"), uid))
        conn.commit()
    return jsonify({'success': True})

@app.route('/api/patients', methods=['GET'])
@token_required
def api_patients():
    s    = request.args.get('search','')
    uid  = request.user['user_id']
    role = request.user['role']
    with sqlite3.connect(DB_PATH) as conn:
        if role == 'admin':
            rows = conn.execute(
                "SELECT * FROM patients WHERE name LIKE ? ORDER BY id DESC" if s
                else "SELECT * FROM patients ORDER BY id DESC",
                (f'%{s}%',) if s else ()).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM patients WHERE user_id=? AND name LIKE ? ORDER BY id DESC" if s
                else "SELECT * FROM patients WHERE user_id=? ORDER BY id DESC",
                (uid, f'%{s}%') if s else (uid,)).fetchall()
    return jsonify([{'id':r[0],'name':r[1],'age':r[2],'sex':r[3],'risk':r[4],'level':r[5],
        'trestbps':r[6],'chol':r[7],'thalch':r[8],'oldpeak':r[9],'ca':r[10],'created_at':r[15]} for r in rows])

@app.route('/api/patients/<int:pid>', methods=['DELETE'])
@token_required
def api_delete_patient(pid):
    uid  = request.user['user_id']
    role = request.user['role']
    with sqlite3.connect(DB_PATH) as conn:
        if role == 'admin':
            conn.execute("DELETE FROM patients WHERE id=?", (pid,))
        else:
            conn.execute("DELETE FROM patients WHERE id=? AND user_id=?", (pid, uid))
        conn.commit()
    return jsonify({'success': True})

@app.route('/api/dashboard_data', methods=['GET'])
@token_required
def api_dashboard_data():
    uid  = request.user['user_id']
    role = request.user['role']
    with sqlite3.connect(DB_PATH) as conn:
        if role == 'admin':
            rows = conn.execute("SELECT risk FROM patients").fetchall()
        else:
            rows = conn.execute("SELECT risk FROM patients WHERE user_id=?", (uid,)).fetchall()
    risks  = [r[0] for r in rows]
    total  = len(risks)
    low    = sum(1 for r in risks if r < 30)
    mod    = sum(1 for r in risks if 30 <= r < 60)
    high   = sum(1 for r in risks if r >= 60)
    avg    = sum(risks)/total if total else 0
    recent = risks[-10:]
    return jsonify({'total':total,'low':low,'moderate':mod,'high':high,'avg_risk':round(avg,1),'recent_risks':recent})

@app.route('/login', methods=['GET','POST'])
def login():
    if request.method == 'GET':
        return redirect(url_for('welcome')) if 'user_id' in session else render_template('login.html')
    d  = request.json
    pw = hashlib.sha256(d.get('password','').encode()).hexdigest()
    with sqlite3.connect(DB_PATH) as conn:
        u = conn.execute('SELECT * FROM users WHERE username=? AND password=?',
                         (d.get('username','').strip(), pw)).fetchone()
    if u:
        session.update({'user_id': u[0], 'username': u[1], 'full_name': u[3], 'role': u[4]})
        return jsonify({'success': True, 'redirect': '/'})
    return jsonify({'success': False, 'message': 'Invalid username or password'})

@app.route('/logout')
def logout():
    session.clear(); return redirect(url_for('login'))

@app.route('/register', methods=['POST'])
def register():
    d        = request.json
    username = d.get('username','').strip()
    pw       = d.get('password','')
    if not username or not pw:
        return jsonify({'success': False, 'message': 'Username and password required'})
    if len(pw) < 6:
        return jsonify({'success': False, 'message': 'Password must be at least 6 characters'})
    try:
        with sqlite3.connect(DB_PATH) as conn:
            conn.execute('INSERT INTO users (username,password,full_name,role,created_at) VALUES (?,?,?,?,?)',
                (username, hashlib.sha256(pw.encode()).hexdigest(),
                 d.get('full_name','').strip(), 'doctor', datetime.now().strftime("%Y-%m-%d")))
            conn.commit()
        return jsonify({'success': True, 'message': 'Account created!'})
    except sqlite3.IntegrityError:
        return jsonify({'success': False, 'message': 'Username already exists'})

@app.route('/me')
@login_required
def me():
    return jsonify({'username': session['username'], 'full_name': session['full_name'], 'role': session['role']})

# ── Pages ───────────────────────────────────────────────────
@app.route('/')
@login_required
def welcome(): return render_template('welcome.html')

@app.route('/assessment')
@login_required
def index(): 
    return render_template('index.html', accuracy=round(accuracy*100, 2))

@app.route('/performance')
@login_required
def performance_page():
    return render_template('performance.html')

@app.route('/recommendations')
@login_required
def recommendations_page():
    return render_template('recommendations.html')

@app.route('/api')
def api_docs():
    return render_template('api.html')

@app.route('/history')
@login_required
def history(): return render_template('history.html')

@app.route('/chat')
@login_required
def chat_page(): return render_template('chat.html')

# ── ML ──────────────────────────────────────────────────────
@app.route('/predict', methods=['POST'])
@login_required
def predict():
    v = request.json
    r = predict_risk(v)
    if r < 30:   lv, co = 'Low Risk',     'green'
    elif r < 60: lv, co = 'Moderate Risk', 'orange'
    else:        lv, co = 'High Risk',     'red'
    return jsonify({'risk': r, 'level': lv, 'color': co, 'features': get_features(v)})

@app.route('/simulate', methods=['POST'])
@login_required
def simulate():
    v  = request.json
    sc = v.pop('scenario', None)
    bf = predict_risk(v)
    mv = v.copy()
    if sc == 'bp':
        mv['trestbps'] = max(90,  float(v.get('trestbps', 130)) - 20); msg = 'BP reduced by 20 mmHg'
    elif sc == 'chol':
        mv['chol']     = max(120, float(v.get('chol', 223))     - 30); msg = 'Cholesterol reduced by 30 mg/dL'
    elif sc == 'active':
        mv['thalch']   = min(200, float(v.get('thalch', 140))   + 15); msg = 'Max HR improved +15 bpm'
    elif sc == 'oldpeak':
        mv['oldpeak']  = max(0,   float(v.get('oldpeak', 0.5))  - 0.5); msg = 'ST depression reduced by 0.5'
    else:
        msg = 'No change'
    af = predict_risk(mv)
    return jsonify({'before': bf, 'after': af, 'diff': round(bf-af, 1), 'message': msg})

@app.route('/save_patient', methods=['POST'])
@login_required
def save_patient():
    v  = request.json
    r  = predict_risk(v)
    lv = 'Low Risk' if r < 30 else 'Moderate Risk' if r < 60 else 'High Risk'
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''INSERT INTO patients
            (name,age,sex,risk,level,trestbps,chol,thalch,oldpeak,ca,cp,thal,exang,fbs,created_at,user_id)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
            (v.get('patient_name','Unknown'), int(v.get('age',0)),
             'Male' if int(v.get('sex',1))==1 else 'Female', r, lv,
             v.get('trestbps',0), v.get('chol',0), v.get('thalch',0), v.get('oldpeak',0),
             int(v.get('ca',0)), int(v.get('cp',0)), int(v.get('thal',3)),
             int(v.get('exang',0)), int(v.get('fbs',0)),
             datetime.now().strftime("%Y-%m-%d %H:%M"), session.get('user_id',1)))
        conn.commit()
    return jsonify({'success': True, 'message': f'Patient saved! Risk: {r}%'})

@app.route('/get_patients')
@login_required
def get_patients():
    s    = request.args.get('search','')
    uid  = session.get('user_id',1)
    role = session.get('role','doctor')
    with sqlite3.connect(DB_PATH) as conn:
        if role == 'admin':
            rows = conn.execute(
                "SELECT * FROM patients WHERE name LIKE ? ORDER BY id DESC" if s
                else "SELECT * FROM patients ORDER BY id DESC",
                (f'%{s}%',) if s else ()).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM patients WHERE user_id=? AND name LIKE ? ORDER BY id DESC" if s
                else "SELECT * FROM patients WHERE user_id=? ORDER BY id DESC",
                (uid, f'%{s}%') if s else (uid,)).fetchall()
    return jsonify([{'id':r[0],'name':r[1],'age':r[2],'sex':r[3],'risk':r[4],'level':r[5],
        'trestbps':r[6],'chol':r[7],'thalch':r[8],'oldpeak':r[9],'ca':r[10],'created_at':r[15]} for r in rows])

@app.route('/delete_patient/<int:pid>', methods=['DELETE'])
@login_required
def delete_patient(pid):
    uid  = session.get('user_id', 1)
    role = session.get('role', 'doctor')
    with sqlite3.connect(DB_PATH) as conn:
        if role == 'admin':
            conn.execute("DELETE FROM patients WHERE id=?", (pid,))
        else:
            conn.execute("DELETE FROM patients WHERE id=? AND user_id=?", (pid, uid))
        conn.commit()
    return jsonify({'success': True})

# ── Chatbot ─────────────────────────────────────────────────
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "YOUR_GROQ_API_KEY")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.1-8b-instant"

@app.route('/chatbot', methods=['POST'])
@token_required
def chatbot():
    d   = request.json
    msg = d.get('message','')
    pt  = d.get('patient',{})
    r   = predict_risk(pt) if pt else 0
    lv  = 'Low Risk' if r < 30 else 'Moderate Risk' if r < 60 else 'High Risk'
    system_prompt = f"""You are CardioTwin AI, a professional medical assistant specialized in cardiovascular health.

Patient Data:
- Age: {pt.get('age')} years
- Sex: {'Male' if pt.get('sex',1)==1 else 'Female'}
- Blood Pressure: {pt.get('trestbps')} mmHg
- Cholesterol: {pt.get('chol')} mg/dL
- Max Heart Rate: {pt.get('thalch')} bpm
- ST Depression: {pt.get('oldpeak')}
- CVD Risk: {r}% ({lv})

Give professional, specific medical advice based on the patient data above.
Keep responses concise (3-4 sentences). Always recommend consulting a doctor for final decisions."""

    try:
        resp = requests.post(
            GROQ_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": GROQ_MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": msg}
                ],
                "max_tokens": 300,
                "temperature": 0.7
            },
            timeout=30
        )
        if resp.status_code == 200:
            reply = resp.json()['choices'][0]['message']['content'].strip()
            return jsonify({'reply': reply})
        else:
            raise Exception(f"Groq error: {resp.status_code}")
    except Exception as e:
        reply = f"""Based on your CVD risk of {r}% ({lv}):
- {'Seek immediate medical consultation given your high risk.' if r >= 60 else 'Maintain healthy lifestyle to prevent cardiovascular disease.'}
- Monitor blood pressure and cholesterol regularly.
- Always follow your doctor's advice for medical decisions."""
        return jsonify({'reply': reply})

# ── PDF Report ───────────────────────────────────────────────
@app.route('/report', methods=['POST'])
@login_required
def generate_report():
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.lib.styles import ParagraphStyle
        from reportlab.lib.units import cm
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
        from reportlab.lib.enums import TA_CENTER
    except ImportError:
        return jsonify({'error': 'reportlab not installed'}), 500

    v       = request.json
    r       = predict_risk(v)
    feats   = get_features(v)
    patient = v.get('patient_name','Unknown')
    now     = datetime.now().strftime("%Y-%m-%d %H:%M")
    doctor  = session.get('full_name', session.get('username','CardioTwin'))

    if r < 30:   lv, rc = 'Low Risk',     colors.HexColor('#2ecc71')
    elif r < 60: lv, rc = 'Moderate Risk', colors.HexColor('#f39c12')
    else:        lv, rc = 'High Risk',     colors.HexColor('#e74c3c')

    recs = (["Maintain healthy lifestyle","Annual check-ups","Continue activity","Monitor BP"] if r < 30 else
            ["See cardiologist soon","Reduce salt & fats","30 min exercise daily","Monitor BP weekly"] if r < 60 else
            ["Immediate medical consult","Full cardiac evaluation","Strict medication",
             "Avoid strenuous activity","Daily BP monitoring"])

    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, rightMargin=2*cm, leftMargin=2*cm, topMargin=2*cm, bottomMargin=2*cm)
    st  = []
    C   = lambda s, **k: ParagraphStyle(s, **k)

    h1  = C('h1',  fontSize=22, fontName='Helvetica-Bold', textColor=colors.HexColor('#021B4E'), alignment=TA_CENTER)
    h2  = C('h2',  fontSize=11, fontName='Helvetica',      textColor=colors.HexColor('#065A82'), alignment=TA_CENTER)
    h3  = C('h3',  fontSize=13, fontName='Helvetica-Bold', textColor=colors.HexColor('#021B4E'))
    rk  = C('rk',  fontSize=36, fontName='Helvetica-Bold', textColor=rc, alignment=TA_CENTER)
    rl  = C('rl',  fontSize=11, fontName='Helvetica',      textColor=rc, alignment=TA_CENTER)
    rc2 = C('rc2', fontSize=10, fontName='Helvetica',      leftIndent=15, spaceAfter=5)
    ds  = C('ds',  fontSize=8,  fontName='Helvetica',      textColor=colors.HexColor('#64748B'), alignment=TA_CENTER)

    st += [Paragraph("CardioTwin AI", h1), Spacer(1,.3*cm),
           Paragraph("Heart Disease Risk Assessment Report", h2),
           Spacer(1,.2*cm), HRFlowable(width="100%",thickness=2,color=colors.HexColor('#e63946')), Spacer(1,.5*cm)]

    info = Table([['Patient',patient,'Date',now],['Doctor',doctor,'Accuracy',f"{round(accuracy*100,2)}%"]],
                 colWidths=[2.5*cm,7.5*cm,2.5*cm,4.5*cm])
    info.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(0,-1),colors.HexColor('#EAF4FB')),
        ('BACKGROUND',(2,0),(2,-1),colors.HexColor('#EAF4FB')),
        ('FONTNAME',(0,0),(0,-1),'Helvetica-Bold'),('FONTNAME',(2,0),(2,-1),'Helvetica-Bold'),
        ('FONTNAME',(1,0),(-1,-1),'Helvetica'),('FONTSIZE',(0,0),(-1,-1),9),
        ('GRID',(0,0),(-1,-1),.5,colors.HexColor('#CBD5E1')),('PADDING',(0,0),(-1,-1),6)]))

    st += [info, Spacer(1,.7*cm),
           Paragraph(f"CVD Risk Score: {r}%", rk), Spacer(1,.2*cm), Paragraph(lv, rl),
           Spacer(1,.3*cm), HRFlowable(width="100%",thickness=1,color=colors.HexColor('#CBD5E1')), Spacer(1,.5*cm)]

    sm = {0:'Female',1:'Male'}
    cp_names = {0:'Typical Angina',1:'Atypical Angina',2:'Non-anginal',3:'Asymptomatic'}
    th_names = {1:'Fixed Defect',2:'Reversable Defect',3:'Normal'}

    pt2 = Table([['Parameter','Value','Parameter','Value'],
        ['Age',f"{int(v.get('age',0))} yrs",'Sex',sm.get(int(v.get('sex',1)),'Male')],
        ['Resting BP',f"{int(v.get('trestbps',0))} mmHg",'Cholesterol',f"{int(v.get('chol',0))} mg/dL"],
        ['Max HR',f"{int(v.get('thalch',0))} bpm",'ST Depression',str(v.get('oldpeak',0))],
        ['Vessels',str(int(v.get('ca',0))),'Chest Pain',cp_names.get(int(v.get('cp',0)),'N/A')],
        ['Thalassemia',th_names.get(int(v.get('thal',3)),'Normal'),'Exercise Angina','Yes' if v.get('exang',0) else 'No']],
        colWidths=[4.5*cm,4*cm,4.5*cm,4*cm])
    pt2.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#021B4E')),('TEXTCOLOR',(0,0),(-1,0),colors.white),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTNAME',(0,1),(0,-1),'Helvetica-Bold'),
        ('FONTNAME',(2,1),(2,-1),'Helvetica-Bold'),('FONTNAME',(1,1),(-1,-1),'Helvetica'),
        ('FONTSIZE',(0,0),(-1,-1),9),('GRID',(0,0),(-1,-1),.5,colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F8FAFC')]),('PADDING',(0,0),(-1,-1),7)]))

    ft = Table([['Feature','Value','Importance']]+
               [[x['name'],str(x['value']),f"{x['importance']}%"] for x in feats],
               colWidths=[6*cm,5*cm,6*cm])
    ft.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#065A82')),('TEXTCOLOR',(0,0),(-1,0),colors.white),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTNAME',(0,1),(-1,-1),'Helvetica'),
        ('FONTSIZE',(0,0),(-1,-1),9),('GRID',(0,0),(-1,-1),.5,colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F8FAFC')]),('PADDING',(0,0),(-1,-1),7)]))

    st += [Paragraph("Clinical Data",h3), Spacer(1,.3*cm), pt2, Spacer(1,.7*cm),
           Paragraph("Top Risk Factors",h3), Spacer(1,.3*cm), ft, Spacer(1,.7*cm),
           Paragraph("Recommendations",h3), Spacer(1,.3*cm)]
    for x in recs: st.append(Paragraph(f"• {x}", rc2))
    st += [Spacer(1,.7*cm), HRFlowable(width="100%",thickness=1,color=colors.HexColor('#CBD5E1')), Spacer(1,.3*cm),
           Paragraph("For educational purposes only. Always consult a qualified healthcare provider.", ds)]

    doc.build(st)
    buf.seek(0)
    return send_file(buf, as_attachment=True,
                     download_name=f"CardioTwin_{patient.replace(' ','_')}.pdf",
                     mimetype='application/pdf')

# ── Dashboard & Analytics ───────────────────────────────────
@app.route('/dashboard')
@login_required
def dashboard_page():
    return render_template('dashboard.html')

@app.route('/api/dashboard')
@login_required
def api_dashboard():
    uid = session.get('user_id',1)
    role = session.get('role','doctor')
    with sqlite3.connect(DB_PATH) as conn:
        if role == 'admin':
            rows = conn.execute("SELECT risk FROM patients").fetchall()
        else:
            rows = conn.execute("SELECT risk FROM patients WHERE user_id=?", (uid,)).fetchall()
    
    risks = [r[0] for r in rows]
    total = len(risks)
    low = sum(1 for r in risks if r < 30)
    moderate = sum(1 for r in risks if 30 <= r < 60)
    high = sum(1 for r in risks if r >= 60)
    avg_risk = sum(risks)/total if total > 0 else 0
    
    return jsonify({
        'total_patients': total,
        'low_risk_count': low,
        'moderate_risk_count': moderate,
        'high_risk_count': high,
        'avg_risk_score': avg_risk,
        'model_accuracy': round(accuracy*100, 2),
        'top_factors': [{'name': name, 'importance': round(imp, 1)} for name, imp in list(feature_importance.items())[:5]]
    })

# ── Model Performance ───────────────────────────────────────
@app.route('/api/model-performance')
@login_required
def model_performance():
    return jsonify({
        'model_type': 'Random Forest Classifier',
        'accuracy': round(accuracy*100, 2),
        'total_features': len(columns),
        'training_samples': 303,  # Cleveland dataset size
        'feature_importance': dict(list(feature_importance.items())[:10])
    })

# ── Recommendations ────────────────────────────────────────
@app.route('/api/recommendations', methods=['POST'])
@token_required
def get_recommendations():
    v = request.json
    r = predict_risk(v)
    
    if r < 30:
        recs = {
            'level': 'Low Risk',
            'color': 'green',
            'lifestyle': ['Maintain current healthy lifestyle', 'Continue regular exercise', 'Annual check-ups'],
            'diet': ['Balanced diet with whole grains', 'Moderate salt intake', 'Low saturated fats'],
            'medication': ['As prescribed by doctor'],
            'monitoring': ['Annual BP and cholesterol checks']
        }
    elif r < 60:
        recs = {
            'level': 'Moderate Risk',
            'color': 'orange',
            'lifestyle': ['Increase physical activity to 30 min/day', 'Reduce stress', 'Schedule cardiologist visit'],
            'diet': ['Low sodium diet (<2300mg/day)', 'Reduce saturated fat to <7% of calories', 'Increase fiber'],
            'medication': ['Discuss with cardiologist about preventive medications'],
            'monitoring': ['BP and cholesterol every 3-6 months', 'Stress test if recommended']
        }
    else:
        recs = {
            'level': 'High Risk',
            'color': 'red',
            'lifestyle': ['Seek immediate medical consultation', 'Avoid strenuous activities', 'Daily BP monitoring'],
            'diet': ['Strict low sodium diet', 'Heart-healthy Mediterranean diet', 'Limit alcohol'],
            'medication': ['Urgent: Schedule full cardiac evaluation', 'Follow medication strictly'],
            'monitoring': ['Weekly BP and HR monitoring', 'Consider continuous ECG monitoring']
        }
    
    return jsonify(recs)

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=os.environ.get('FLASK_DEBUG', 'False') == 'True')