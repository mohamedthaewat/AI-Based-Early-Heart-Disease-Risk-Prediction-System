import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import 'patient_profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String search = ''}) async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPatients(search: search);
      if (mounted) setState(() { _patients = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Patient', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Are you sure?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deletePatient(id);
      _load();
    }
  }

  Color _riskColor(double risk) =>
      risk < 30 ? AppTheme.green : risk < 60 ? AppTheme.orange : AppTheme.red;

  String _riskEmoji(double risk) =>
      risk < 30 ? '💚' : risk < 60 ? '⚠️' : '🚨';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
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
                  Text('Patient History', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                  )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_patients.length} records',
                      style: TextStyle(color: AppTheme.purpleLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]).animate().fadeIn(),
              ),

              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(children: [
                    Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search patients...',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) => _load(search: v),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () { _searchCtrl.clear(); _load(); },
                        child: Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                      ),
                  ]),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _statCard('Low Risk', _patients.where((p) => (p['risk'] as num) < 30).length, AppTheme.green),
                  const SizedBox(width: 10),
                  _statCard('Moderate', _patients.where((p) {
                    final r = (p['risk'] as num).toDouble();
                    return r >= 30 && r < 60;
                  }).length, AppTheme.orange),
                  const SizedBox(width: 10),
                  _statCard('High Risk', _patients.where((p) => (p['risk'] as num) >= 60).length, AppTheme.red),
                ]),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: AppTheme.purpleLight))
                    : _patients.isEmpty
                        ? Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('📋', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('No patients found', style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                            ],
                          ))
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppTheme.purpleLight,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _patients.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _buildCard(_patients[i], i),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderColor: color.withOpacity(0.2),
      child: Column(children: [
        Text('$count', style: TextStyle(
          color: color, fontSize: 22, fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _buildCard(Map p, int i) {
    final risk = (p['risk'] as num).toDouble();
    final color = _riskColor(risk);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withOpacity(0.2),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PatientProfileScreen(patient: Map<String, dynamic>.from(p)),
        )),
        child: Row(children: [
        // Avatar
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(_riskEmoji(risk), style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p['name'] ?? 'Unknown',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.cake_outlined, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('${p['age']} yrs', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(width: 10),
              Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(p['sex'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Text(p['created_at'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        )),

        // Risk + Actions
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${risk.round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              GestureDetector(
                onTap: () async {
                  final text = 'Patient: ${p['name']}\nRisk: ${risk.round()}% — ${p['level']}\nBP: ${p['trestbps']} mmHg | Chol: ${p['chol']} mg/dL\nDate: ${p['created_at']}';
                  await Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied to clipboard ✅'), backgroundColor: AppTheme.green, duration: Duration(seconds: 2)),
                  );
                },
                child: Icon(Icons.share_outlined, color: AppTheme.textMuted, size: 18),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _delete(p['id']),
                child: Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted, size: 20),
              ),
            ]),
          ],
        ),
      ]),
      ),
    ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05);
  }
}
