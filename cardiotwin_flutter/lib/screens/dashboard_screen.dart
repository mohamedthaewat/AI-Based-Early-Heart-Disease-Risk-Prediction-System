import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ApiService.getDashboard();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: AppTheme.purpleLight))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.purpleLight,
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
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.textSecondary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Dashboard', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                        )),
                      ]).animate().fadeIn(),

                      const SizedBox(height: 24),

                      // Stats Cards
                      Row(children: [
                        _statCard('Total Patients', '${_data!['total']}', Icons.people_outline_rounded, AppTheme.purple),
                        const SizedBox(width: 12),
                        _statCard('Avg Risk', '${(_data!['avg_risk'] as num).toStringAsFixed(1)}%', Icons.favorite_outline_rounded, AppTheme.teal),
                      ]).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 12),

                      Row(children: [
                        _statCard('High Risk', '${_data!['high']}', Icons.warning_outlined, AppTheme.red),
                        const SizedBox(width: 12),
                        _statCard('Low Risk', '${_data!['low']}', Icons.check_circle_outline_rounded, AppTheme.green),
                      ]).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 20),

                      // Pie Chart
                      if ((_data!['total'] as int) > 0)
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(Icons.pie_chart_outline_rounded, color: Colors.white, size: 17),
                                ),
                                const SizedBox(width: 10),
                                Text('Risk Distribution', style: TextStyle(
                                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15,
                                )),
                              ]),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: PieChart(PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: (_data!['low'] as int).toDouble(),
                                      color: AppTheme.green,
                                      title: 'Low\n${_data!['low']}',
                                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                      radius: 75,
                                    ),
                                    PieChartSectionData(
                                      value: (_data!['moderate'] as int).toDouble(),
                                      color: AppTheme.orange,
                                      title: 'Mod\n${_data!['moderate']}',
                                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                      radius: 75,
                                    ),
                                    PieChartSectionData(
                                      value: (_data!['high'] as int).toDouble(),
                                      color: AppTheme.red,
                                      title: 'High\n${_data!['high']}',
                                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                      radius: 75,
                                    ),
                                  ],
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 40,
                                )),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _legend('Low Risk', AppTheme.green),
                                  _legend('Moderate', AppTheme.orange),
                                  _legend('High Risk', AppTheme.red),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 16),

                      // Recent Risk Bar Chart
                      if ((_data!['recent_risks'] as List?)?.isNotEmpty == true)
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(Icons.bar_chart_rounded, color: Colors.white, size: 17),
                                ),
                                const SizedBox(width: 10),
                                Text('Recent Assessments', style: TextStyle(
                                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15,
                                )),
                              ]),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 160,
                                child: BarChart(BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(show: false),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: AppTheme.border, strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: (_data!['recent_risks'] as List).asMap().entries.map((e) {
                                    final risk = (e.value as num).toDouble();
                                    final color = risk < 30 ? AppTheme.green : risk < 60 ? AppTheme.orange : AppTheme.red;
                                    return BarChartGroupData(x: e.key, barRods: [
                                      BarChartRodData(
                                        toY: risk, color: color,
                                        width: 14,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true, toY: 100, color: AppTheme.border,
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                )),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withOpacity(0.2),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(
            color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ]),
      ]),
    ),
  );

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
  ]);
}
