import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import 'assessment_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.login(_userCtrl.text.trim(), _passCtrl.text);
      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AssessmentScreen()),
        );
      } else {
        setState(() => _error = res['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.purple.withOpacity(0.5),
                        blurRadius: 30, offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🫀', style: TextStyle(fontSize: 42)),
                  ),
                )
                .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.7, 0.7)),

                const SizedBox(height: 28),

                Text(
                  'CardioTwin AI',
                  style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800,
                    foreground: Paint()..shader = AppTheme.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 250, 40),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.3),

                const SizedBox(height: 6),

                Text(
                  'Heart Disease Risk Assessment',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 50),

                // Login Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to your account',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 28),

                      // Username
                      _buildLabel('Username'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _userCtrl,
                        hint: 'Enter username',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 18),

                      // Password
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passCtrl,
                        hint: 'Enter password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted, size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        onSubmit: (_) => _login(),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppTheme.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: AppTheme.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      GradientButton(
                        label: 'Sign In',
                        loading: _loading,
                        icon: Icons.login_rounded,
                        onTap: _login,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 32),

                // Footer
                Text(
                  'For medical professionals only',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 13, fontWeight: FontWeight.w500,
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onSubmitted: onSubmit,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
