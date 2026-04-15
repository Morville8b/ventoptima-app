import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../anlaegs_data.dart';

class RapportDokumentation {
  static List<pw.Page> build({
    required AnlaegsData anlaeg,
    required pw.MemoryImage logo,
  }) {
    final pages = <pw.Page>[];

    if (anlaeg.dokumentation == null || anlaeg.dokumentation!.isEmpty) {
      return pages;
    }

    // Load alle billeder først
    final List<Map<String, dynamic>> billedData = [];
    for (var doc in anlaeg.dokumentation!) {
      final String? path = doc["path"];
      final String? beskrivelse = doc["beskrivelse"];

      if (path == null || path.isEmpty) continue;

      final file = File(path);
      if (!file.existsSync()) continue;

      final billedeBytes = file.readAsBytesSync();
      final billede = pw.MemoryImage(billedeBytes);

      billedData.add({
        "billede": billede,
        "beskrivelse": beskrivelse ?? "",
      });
    }

    // Generer sider med 2 billeder ad gangen
    for (int i = 0; i < billedData.length; i += 2) {
      final billede1 = billedData[i];
      final billede2 = i + 1 < billedData.length ? billedData[i + 1] : null;

      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header med anlægstype og logo
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${anlaeg.valgtAnlaegstype} - ${anlaeg.anlaegsNavn}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 13,
                          color: PdfColor.fromInt(0xFF006390),
                        ),
                      ),
                      pw.Image(logo, height: 30),
                    ],
                  ),
                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: PdfColor.fromInt(0xFF34E0A1),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Text(
                    'DOKUMENTATION',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: PdfColor.fromInt(0xFF006390),
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // Første billede - NU MED FAST HØJDE
                  _billedeKort(billede1),

                  pw.SizedBox(height: 12),

                  // Andet billede (hvis det findes) - NU MED FAST HØJDE
                  if (billede2 != null)
                    _billedeKort(billede2),
                ],
              ),
            );
          },
        ),
      );
    }

    return pages;
  }

  static pw.Widget _billedeKort(Map<String, dynamic> data) {
    final pw.MemoryImage billede = data["billede"];
    final String beskrivelse = data["beskrivelse"];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Billede - NU MED MAKSIMAL HØJDE I STEDET FOR EXPANDED
        pw.Container(
          height: 220, // Fast højde - juster denne værdi efter behov
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(billede, fit: pw.BoxFit.contain),
          ),
        ),

        pw.SizedBox(height: 6),

        // Beskrivelse
        if (beskrivelse.isNotEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              beskrivelse,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
              maxLines: 3,
              overflow: pw.TextOverflow.clip,
            ),
          ),
      ],
    );
  }
}