import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import 'result_screen.dart';
import 'history_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  // Patient data
  double age      = 55;
  int    sex      = 1;
  double trestbps = 130;
  double chol     = 220;
  double thalch   = 140;
  double oldpeak  = 1.0;
  int    cp       = 0;
  int    restecg  = 0;
  int    slope    = 1;
  int    ca       = 0;
  int    thal     = 3;
  int    exang    = 0;
  int    fbs      = 0;

  Map<String, dynamic> get _vals => {
    'age': age.round(), 'sex': sex, 'trestbps': trestbps,
    'chol': chol, 'thalch': thalch, 'oldpeak': oldpeak,
    'cp': cp, 'restecg': restecg, 'slope': slope,
    'ca': ca, 'thal': thal, 'exang': exang, 'fbs': fbs, 'dataset': 0,
  };

  Future<void> _assess() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.predict(_vals);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: result,
          patientData: {..._vals, 'patient_name': _nameCtrl.text.trim().isEmpty ? 'Patient' : _nameCtrl.text.trim()},
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red),
      );
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  children: [
                    _buildPatientName(),
                    const SizedBox(height: 14),
                    _buildSection('Demographics', Icons.person_outline_rounded, [
                      _buildSlider('Age', age, 20, 90, (v) => setState(() => age = v), unit: ' yrs', decimals: 0),
                      _buildToggle('Sex', ['Female', 'Male'], sex, (v) => setState(() => sex = v)),
                    ]),
                    const SizedBox(height: 14),
                    _buildSection('Vital Signs', Icons.monitor_heart_outlined, [
                      _buildSlider('Resting BP', trestbps, 80, 220, (v) => setState(() => trestbps = v), unit: ' mmHg', decimals: 0,
                        color: trestbps >= 140 ? AppTheme.red : trestbps >= 130 ? AppTheme.orange : AppTheme.green),
                      _buildSlider('Cholesterol', chol, 100, 600, (v) => setState(() => chol = v), unit: ' mg/dL', decimals: 0,
                        color: chol >= 240 ? AppTheme.red : chol >= 200 ? AppTheme.orange : AppTheme.green),
                      _buildSlider('Max Heart Rate', thalch, 60, 210, (v) => setState(() => thalch = v), unit: ' bpm', decimals: 0),
                      _buildSlider('ST Depression', oldpeak, 0, 6.2, (v) => setState(() => oldpeak = v), unit: '', decimals: 1),
                    ]),
                    const SizedBox(height: 14),
                    _buildSection('Clinical Data', Icons.biotech_outlined, [
                      _buildDropdown('Chest Pain Type', cp, ['Typical Angina', 'Atypical Angina', 'Non-anginal', 'Asymptomatic'], (v) => setState(() => cp = v!)),
                      _buildDropdown('Resting ECG', restecg, ['Normal', 'ST-T Abnormality', 'LV Hypertrophy'], (v) => setState(() => restecg = v!)),
                      _buildDropdown('ST Slope', slope, ['Upsloping', 'Flat', 'Downsloping'], (v) => setState(() => slope = v!)),
                      _buildDropdown('Thalassemia', thal, ['— ', 'Fixed Defect', 'Reversable Defect', 'Normal'], (v) => setState(() => thal = v!)),
                      _buildSlider('Major Vessels', ca.toDouble(), 0, 3, (v) => setState(() => ca = v.round()), unit: '', decimals: 0),
                    ]),
                    const SizedBox(height: 14),
                    _buildSection('Risk Factors', Icons.warning_amber_outlined, [
                      _buildToggle('Exercise Angina', ['No', 'Yes'], exang, (v) => setState(() => exang = v),
                        activeColor: AppTheme.red),
                      _buildToggle('Fasting Blood Sugar > 120', ['No', 'Yes'], fbs, (v) => setState(() => fbs = v),
                        activeColor: AppTheme.orange),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAssessButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
            child: const Text('🫀', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
            child: Text(
              'CardioTwin AI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const Spacer(),
          _headerBtn(
            Provider.of<ThemeProvider>(context).isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            () => Provider.of<ThemeProvider>(context, listen: false).toggle(),
          ),
          const SizedBox(width: 8),
          _headerBtn(Icons.history_rounded, () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HistoryScreen()),
          )),
          const SizedBox(width: 8),
          _headerBtn(Icons.logout_rounded, () async {
            await ApiService.logout();
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/login');
          }),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, color: AppTheme.textSecondary, size: 20),
    ),
  );

  Widget _buildPatientName() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: AppTheme.purpleLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Patient name (optional)',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 16,
            )),
          ]),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, {required String unit, required int decimals, Color? color}) {
    final displayColor = color ?? AppTheme.tealLight;
    final display = decimals == 0 ? value.round().toString() : value.toStringAsFixed(decimals);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: displayColor.withOpacity(0.3)),
                ),
                child: Text(
                  '$display$unit',
                  style: TextStyle(color: displayColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: displayColor,
              inactiveTrackColor: AppTheme.border,
              thumbColor: displayColor,
              overlayColor: displayColor.withOpacity(0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, List<String> options, int value,
      ValueChanged<int> onChanged, {Color? activeColor}) {
    final color = activeColor ?? AppTheme.purpleLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(options.length, (i) {
              final selected = value == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color.withOpacity(0.5) : AppTheme.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          color: selected ? color : AppTheme.textMuted,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, int value, List<String> options, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              underline: const SizedBox(),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
              items: List.generate(options.length, (i) => DropdownMenuItem(
                value: i,
                child: Text(options[i]),
              )),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GradientButton(
        label: 'Assess Risk',
        loading: _loading,
        icon: Icons.favorite_rounded,
        onTap: _assess,
      ),
    );
  }
}
