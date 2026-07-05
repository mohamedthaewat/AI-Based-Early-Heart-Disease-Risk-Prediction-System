import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/assessment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await ApiService.loadSavedToken();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const CardioTwinApp(),
    ),
  );
}

class CardioTwinApp extends StatelessWidget {
  const CardioTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'CardioTwin AI',
      theme: themeProvider.isDark ? AppTheme.theme : AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home':  (_) => const AssessmentScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    // Try to verify cookie still valid
    try {
      await ApiService.getDashboard();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AssessmentScreen()),
      );
    } catch (_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.purple.withOpacity(0.6),
                      blurRadius: 40, offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🫀', style: TextStyle(fontSize: 52)),
                ),
              )
              .animate()
              .fadeIn(duration: 700.ms)
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: Text(
                  'CardioTwin AI',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.5,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: 8),

              Text(
                'Heart Disease Risk Assessment',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 60),

              SizedBox(
                width: 36, height: 36,
                child: CircularProgressIndicator(
                  color: AppTheme.purpleLight,
                  strokeWidth: 2.5,
                ),
              ).animate().fadeIn(delay: 900.ms),

              const SizedBox(height: 16),

              Text(
                'Powered by Ensemble AI',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ).animate().fadeIn(delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }
}
