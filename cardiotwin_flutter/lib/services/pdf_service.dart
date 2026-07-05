import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  static Future<void> generateAndShare({
    required Map<String, dynamic> patientData,
    required double risk,
    required String level,
    required List features,
    required Map<String, dynamic>? recommendations,
    required BuildContext context,
  }) async {
    final pdf = pw.Document();
    final riskColor = risk < 30
        ? PdfColors.green700
        : risk < 60
            ? PdfColors.orange700
            : PdfColors.red700;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo900,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('CardioTwin AI', style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Heart Disease Risk Assessment', style: pw.TextStyle(color: PdfColors.indigo200, fontSize: 12)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Assessment Report', style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                  pw.Text(DateTime.now().toString().substring(0, 10), style: pw.TextStyle(color: PdfColors.indigo200, fontSize: 11)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Patient Info
          pw.Text('Patient Information', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                _infoRow('Name', patientData['patient_name'] ?? 'Unknown'),
                _infoRow('Age', '${patientData['age']} years'),
                _infoRow('Sex', patientData['sex'] == 1 ? 'Male' : 'Female'),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                _infoRow('Blood Pressure', '${patientData['trestbps']} mmHg'),
                _infoRow('Cholesterol', '${patientData['chol']} mg/dL'),
                _infoRow('Max Heart Rate', '${patientData['thalch']} bpm'),
              ])),
            ]),
          ),
          pw.SizedBox(height: 20),

          // Risk Result
          pw.Text('Risk Assessment Result', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: riskColor),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(child: pw.Column(children: [
              pw.Text('${risk.round()}%', style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: riskColor)),
              pw.Text(level, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: riskColor)),
              pw.Text('CVD Risk Score', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ])),
          ),
          pw.SizedBox(height: 20),

          // Top Risk Factors
          if (features.isNotEmpty) ...[
            pw.Text('Top Risk Factors', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...features.take(5).map((f) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text(f['name'].toString(), style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('${(f['importance'] as num).round()}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                ]),
                pw.SizedBox(height: 3),
                pw.LinearProgressIndicator(value: (f['importance'] as num).toDouble() / 100, backgroundColor: PdfColors.grey200, valueColor: PdfColors.indigo700),
              ]),
            )),
            pw.SizedBox(height: 20),
          ],

          // Recommendations
          if (recommendations != null) ...[
            pw.Text('Recommendations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (recommendations['lifestyle'] != null) _recSection('Lifestyle', recommendations['lifestyle'], PdfColors.green700),
            if (recommendations['diet'] != null) _recSection('Diet', recommendations['diet'], PdfColors.orange700),
            if (recommendations['monitoring'] != null) _recSection('Monitoring', recommendations['monitoring'], PdfColors.blue700),
          ],

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'This report is generated by CardioTwin AI for educational purposes only. Always consult a qualified healthcare professional.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final name = (patientData['patient_name'] ?? 'Report').toString().replaceAll(' ', '_');
    final file = File('${output.path}/CardioTwin_$name.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open file
    await OpenFile.open(file.path);
  }

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(children: [
      pw.Text('$label: ', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
      pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    ]),
  );

  static pw.Widget _recSection(String title, List items, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      pw.SizedBox(height: 4),
      ...items.take(3).map((item) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
        child: pw.Text('• $item', style: const pw.TextStyle(fontSize: 11)),
      )),
    ]),
  );
}
