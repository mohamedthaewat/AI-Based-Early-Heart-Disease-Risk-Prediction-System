import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../widgets/glass_card.dart';
import 'chat_screen.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final Map<String, dynamic> patientData;

  const ResultScreen({super.key, required this.result, required this.patientData});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _gaugeCtrl;
  late Animation<double> _gaugeAnim;
  bool _saved = false;
  bool _saving = false;
  Map<String, dynamic>? _recs;

  double get risk => (widget.result['risk'] as num).toDouble();
  String get level => widget.result['level'] ?? '';
  List get features => widget.result['features'] ?? [];

  Color get riskColor => risk < 30 ? AppTheme.green : risk < 60 ? AppTheme.orange : AppTheme.red;
  String get riskEmoji => risk < 30 ? '💚' : risk < 60 ? '⚠️' : '🚨';

  @override
  void initState() {
    super.initState();
    _gaugeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _gaugeAnim = Tween<double>(begin: 0, end: risk / 100).animate(
      CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeOutCubic),
    );
    _gaugeCtrl.forward();
    _loadRecs();
  }

  Future<void> _loadRecs() async {
    try {
      final r = await ApiService.getRecommendations(widget.patientData);
      if (mounted) setState(() => _recs = r);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.savePatient(widget.patientData);
      if (mounted) {
        if (res['success'] == true) {
          setState(() { _saved = true; _saving = false; });
        } else {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to save'), backgroundColor: AppTheme.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red),
        );
      }
    }
  }

  @override
  void dispose() { _gaugeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
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
                      color: AppTheme.surface2, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Assessment Result', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                )),
              ]).animate().fadeIn(),

              const SizedBox(height: 24),

              // Risk Hero Card
              GlassCard(
                borderColor: riskColor.withOpacity(0.3),
                child: Column(children: [
                  Text(
                    widget.patientData['patient_name'] ?? 'Patient',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Gauge
                  AnimatedBuilder(
                    animation: _gaugeAnim,
                    builder: (_, __) => CustomPaint(
                      size: const Size(220, 120),
                      painter: _GaugePainter(_gaugeAnim.value, riskColor),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Risk number
                  AnimatedBuilder(
                    animation: _gaugeAnim,
                    builder: (_, __) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${(_gaugeAnim.value * 100).round()}',
                          style: TextStyle(
                            fontSize: 52, fontWeight: FontWeight.w800,
                            color: riskColor,
                          ),
                        ),
                        TextSpan(
                          text: '%',
                          style: TextStyle(fontSize: 24, color: riskColor.withOpacity(0.7)),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: riskColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$riskEmoji  $level',
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ]),
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 16),

              // Feature Importance
              if (features.isNotEmpty)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Top Risk Factors', Icons.analytics_outlined),
                      const SizedBox(height: 16),
                      ...features.map((f) => _buildFeatureRow(f)),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Recommendations
              if (_recs != null)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Recommendations', Icons.medical_services_outlined),
                      const SizedBox(height: 16),
                      ..._buildRecItems(),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1)
              else
                GlassCard(
                  child: Row(children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        color: AppTheme.purpleLight, strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Loading recommendations...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                ),

              const SizedBox(height: 20),

              // Save Button
              GradientButton(
                label: _saved ? 'Saved to History ✓' : 'Save to History',
                loading: _saving,
                icon: _saved ? Icons.check_circle_rounded : Icons.save_outlined,
                gradient: _saved
                    ? LinearGradient(colors: [AppTheme.green, AppTheme.teal])
                    : null,
                onTap: _saved ? null : _save,
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 12),

              // PDF Button
              GestureDetector(
                onTap: () async {
                  try {
                    await PdfService.generateAndShare(
                      patientData: widget.patientData,
                      risk: risk,
                      level: level,
                      features: features,
                      recommendations: _recs,
                      context: context,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red),
                    );
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.picture_as_pdf_rounded, color: AppTheme.red, size: 20),
                    const SizedBox(width: 8),
                    Text('Download PDF Report', style: TextStyle(
                      color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 15,
                    )),
                  ]),
                ),
              ).animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 12),

              // Chat Button
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(patientData: widget.patientData),
                )),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('🤖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Ask AI Assistant', style: TextStyle(
                      color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 15,
                    )),
                  ]),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    ),
    const SizedBox(width: 10),
    Text(title, style: TextStyle(
      color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15,
    )),
  ]);

  Widget _buildFeatureRow(Map f) {
    final imp = (f['importance'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(f['name'].toString(), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text('${imp.round()}%', style: TextStyle(
              color: AppTheme.purpleLight, fontSize: 12, fontWeight: FontWeight.w700,
            )),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: imp / 100,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(AppTheme.purpleLight),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecItems() {
    final items = <Map<String, String>>[];
    if (_recs!['lifestyle'] != null)
      for (final x in _recs!['lifestyle']) items.add({'icon': '🏃', 'text': x.toString()});
    if (_recs!['diet'] != null)
      for (final x in _recs!['diet']) items.add({'icon': '🥗', 'text': x.toString()});
    if (_recs!['monitoring'] != null)
      for (final x in _recs!['monitoring']) items.add({'icon': '📊', 'text': x.toString()});

    return items.take(5).map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['icon']!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item['text']!, style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 13, height: 1.5,
            )),
          ),
        ],
      ),
    )).toList();
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final r  = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // BG arc
    final bgPaint = Paint()
      ..color = const Color(0xFF1E2D45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, bgPaint);

    // Gradient arc
    final gradPaint = Paint()
      ..shader = SweepGradient(
        startAngle: pi,
        endAngle: pi + pi * value,
        colors: [AppTheme.green, AppTheme.orange, AppTheme.red],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    if (value > 0)
      canvas.drawArc(rect, pi, pi * value, false, gradPaint);

    // Labels
    final tp = (String t, Color c) {
      final p = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      return p;
    };
    tp('Low', AppTheme.green)..paint(canvas, Offset(cx - r - 8, cy - 10));
    tp('High', AppTheme.red)..paint(canvas, Offset(cx + r - 16, cy - 10));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}
