import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class PatientProfileScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientProfileScreen({super.key, required this.patient});

  Color get riskColor {
    final r = (patient['risk'] as num).toDouble();
    return r < 30 ? AppTheme.green : r < 60 ? AppTheme.orange : AppTheme.red;
  }

  String get riskEmoji {
    final r = (patient['risk'] as num).toDouble();
    return r < 30 ? '💚' : r < 60 ? '⚠️' : '🚨';
  }

  @override
  Widget build(BuildContext context) {
    final risk = (patient['risk'] as num).toDouble();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Header
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Patient Profile', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                )),
              ]).animate().fadeIn(),

              const SizedBox(height: 24),

              // Avatar Card
              GlassCard(
                borderColor: riskColor.withOpacity(0.3),
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(riskEmoji, style: const TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 12),
                  Text(patient['name'] ?? 'Unknown',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${patient['age']} yrs  •  ${patient['sex']}',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: riskColor.withOpacity(0.4)),
                    ),
                    child: Text('${risk.round()}% — ${patient['level']}',
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(height: 8),
                  Text(patient['created_at'] ?? '',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // Stats Cards
              Text('Clinical Measurements',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                _statCard('Blood Pressure', '${patient['trestbps']}', 'mmHg',
                  (patient['trestbps'] as num) >= 140 ? AppTheme.red : (patient['trestbps'] as num) >= 130 ? AppTheme.orange : AppTheme.green,
                  Icons.favorite_rounded),
                const SizedBox(width: 10),
                _statCard('Cholesterol', '${patient['chol']}', 'mg/dL',
                  (patient['chol'] as num) >= 240 ? AppTheme.red : (patient['chol'] as num) >= 200 ? AppTheme.orange : AppTheme.green,
                  Icons.science_outlined),
              ]).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 10),

              Row(children: [
                _statCard('Max Heart Rate', '${patient['thalch']}', 'bpm', AppTheme.teal, Icons.monitor_heart_outlined),
                const SizedBox(width: 10),
                _statCard('ST Depression', '${patient['oldpeak']}', '', AppTheme.purple, Icons.show_chart_rounded),
              ]).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 16),

              // Risk Gauge Chart
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk Visualization', style: TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: PieChart(PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: risk,
                            color: riskColor,
                            title: '${risk.round()}%',
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                            radius: 70,
                          ),
                          PieChartSectionData(
                            value: 100 - risk,
                            color: AppTheme.border,
                            title: '',
                            radius: 70,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      )),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Additional Info
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clinical Details', style: TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 14),
                    _detailRow('Major Vessels', '${patient['ca']}'),
                    _detailRow('Assessment Date', patient['created_at'] ?? 'N/A'),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, String unit, Color color, IconData icon) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          if (unit.isNotEmpty) TextSpan(text: ' $unit', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    ),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}
