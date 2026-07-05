# CardioTwin AI — Flutter App 🫀

## الـ Screens
- **Splash** — شاشة افتتاحية مع animation
- **Login** — تسجيل دخول
- **Assessment** — إدخال بيانات المريض بـ sliders ودروب داون
- **Result** — نتيجة الخطر مع gauge متحرك + recommendations
- **History** — سجل المرضى مع بحث وحذف
- **Dashboard** — إحصائيات مع pie chart وbar chart

---

## الإعداد

### 1. تأكد إن Flutter متثبت
```
flutter --version
```

### 2. ثبّت الـ dependencies
```
flutter pub get
```

### 3. غيّر الـ Base URL

افتح `lib/theme.dart` وغيّر:
```dart
// للـ Android Emulator (localhost)
static const String baseUrl = 'http://10.0.2.2:5000';

// للـ iOS Simulator (localhost)
static const String baseUrl = 'http://127.0.0.1:5000';

// للـ سيرفر على النت
static const String baseUrl = 'https://your-app.onrender.com';
```

### 4. شغّل الـ Flask أولاً
```
python app.py
```

### 5. شغّل الـ App
```
flutter run
```

---

## الـ Dependencies
| Package | الاستخدام |
|---------|-----------|
| `http` | API calls |
| `shared_preferences` | حفظ الـ session cookie |
| `fl_chart` | Pie chart + Bar chart |
| `google_fonts` | DM Sans font |
| `flutter_animate` | Animations |

---

## ملاحظة للـ Android
لازم تضيف في `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

وجوا `<application>`:
```xml
android:usesCleartextTraffic="true"
```
(مطلوب للـ http بدون https في التطوير)
