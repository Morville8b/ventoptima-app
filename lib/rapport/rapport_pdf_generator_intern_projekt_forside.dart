import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Formatér tal med punktum som tusindtalsseparator
String formatDK(double value, {int decimals = 0}) {
  if (value.isNaN || value.isInfinite) return 'Ikke beregnet';
  final parts = value.toStringAsFixed(decimals).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
  );
  if (decimals > 0 && parts.length > 1) {
    return '$intPart,${parts[1]}';
  }
  return intPart;
}

/// Generér samlet forside for projekt med summering af alle anlæg
Future<Uint8List> generateInternProjektForside({
  required String projektNavn,
  required int antalAnlaeg,
  required double samletInvestering,
  required double samletBesparelse,
  required double samletTBT,
  double samletVarmebesparelse = 0.0,  // ✅ NY PARAMETER
}) async {
  final pdf = pw.Document();

  const PdfColor matchingGreen = PdfColor.fromInt(0xFF34E0A1);
  const PdfColor matchingBlue = PdfColor.fromInt(0xFF006390);

  // Layoutkonstanter
  const double titleFontSize = 28.0;
  const double subtitleFontSize = 22.0;
  const double headerFontSize = 18.0;
  const double bodyFontSize = 13.0;
  const double pageMargin = 32.0;

  // ✅ BEREGN DEN RIGTIGE SAMLEDE BESPARELSE
  final double ventilatorBesparelse = samletBesparelse;
  final double faktiskSamletBesparelse = ventilatorBesparelse + samletVarmebesparelse;

  // ✅ BEREGN KORREKT TILBAGEBETALINGSTID
  final double korrektTBT = faktiskSamletBesparelse > 0
      ? samletInvestering / faktiskSamletBesparelse
      : samletTBT;

  // ✅ TJEK OM DER ER VARMEBESPARELSE
  final bool harVarmebesparelse = samletVarmebesparelse > 0;

  // Byg PDF-side
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(pageMargin),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          // Titel
          pw.Text(
            'Intern teknisk rapport',
            style: pw.TextStyle(
              fontSize: titleFontSize,
              fontWeight: pw.FontWeight.bold,
              color: matchingBlue,
            ),
          ),
          pw.SizedBox(height: 20),

          // Projekt navn
          pw.Text(
            projektNavn,
            style: pw.TextStyle(
              fontSize: subtitleFontSize,
              fontWeight: pw.FontWeight.bold,
              color: matchingBlue,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),

          // Dato
          pw.Text(
            DateFormat('dd. MMMM yyyy', 'da_DK').format(DateTime.now()),
            style: pw.TextStyle(
              fontSize: headerFontSize,
              color: matchingBlue,
            ),
          ),

          pw.SizedBox(height: 40),

          // Antal anlæg
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Antal analyserede anlæg: $antalAnlaeg',
              style: pw.TextStyle(
                fontSize: bodyFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 45),

          // Grøn projektøkonomi-boks
          pw.Container(
            width: PdfPageFormat.a4.availableWidth - (2 * pageMargin),
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: matchingGreen,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  harVarmebesparelse
                      ? 'SAMLET PROJEKT-ØKONOMI'  // ✅ UDEN "(VENTILATOR)" NÅR DER ER VARME
                      : 'SAMLET PROJEKT-ØKONOMI (VENTILATOR)',
                  style: pw.TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: matchingBlue,
                  ),
                ),
                pw.SizedBox(height: 20),

                _buildDataRow(
                  'Samlet investering:',
                  '${formatDK(samletInvestering)} kr.',
                  bodyFontSize,
                  bold: true,
                ),
                pw.SizedBox(height: 12),

                // ✅ VIS OPDELING HVIS DER ER VARMEBESPARELSE
                if (harVarmebesparelse) ...[
                  _buildDataRow(
                    'Ventilatorbesparelse:',
                    '${formatDK(ventilatorBesparelse)} kr./år',
                    bodyFontSize,
                    bold: false,
                  ),
                  pw.SizedBox(height: 8),
                  _buildDataRow(
                    'Varmebesparelse:',
                    '${formatDK(samletVarmebesparelse)} kr./år',
                    bodyFontSize,
                    bold: false,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1.2, color: matchingBlue),
                  pw.SizedBox(height: 10),
                ],

                _buildDataRow(
                  'Samlet årlig besparelse:',
                  '${formatDK(faktiskSamletBesparelse)} kr./år',
                  bodyFontSize,
                  bold: true,
                ),
                pw.SizedBox(height: 10),

                pw.Divider(thickness: 1.2, color: matchingBlue),
                pw.SizedBox(height: 10),

                _buildDataRow(
                  'Samlet tilbagebetalingstid:',
                  '${formatDK(korrektTBT, decimals: 1)} år',
                  bodyFontSize,
                  bold: true,
                ),
              ],
            ),
          ),

          pw.Spacer(),

          // Note nederst
          pw.Text(
            'Detaljeret analyse for hvert anlæg følger på næste side',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}

/// Hjælpefunktion til layout af data-rækker
pw.Widget _buildDataRow(String label, String value, double fontSize, {bool bold = false}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 3,
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColor.fromInt(0xFF006390),
          ),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Expanded(
        flex: 2,
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}