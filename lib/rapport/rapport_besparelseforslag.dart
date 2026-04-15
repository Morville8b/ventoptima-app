import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../ventilator_samlet_beregning.dart';
import '../generel_projekt_info.dart';
import '../anlaegs_data.dart';
import '../beregning_varmeforbrug.dart';

/// Tjek om et ventilatorforslag er gyldigt (har fundet en løsning)
bool erGyldigtVentilatorForslag(VentilatorOekonomiSamlet forslag) {
  final eco = forslag.oekonomi as OekonomiResultat;

  // Manuel indtastning skal altid vises
  if (forslag.fabrikant == 'Special anlæg' ||
      forslag.fabrikant == 'Nyt Ventilationsanlæg') {
    return true;
  }

  final double nytElforbrugInd = forslag.indNormal.aarsforbrugKWh;
  final double nytElforbrugUd = forslag.udNormal.aarsforbrugKWh;
  final double samletNytElforbrug = nytElforbrugInd + nytElforbrugUd;

  if (samletNytElforbrug <= 0) {
    return false;
  }

  return true;
}



class RapportBesparelsesforslag {
  static List<pw.Page> build({
    required List<VentilatorOekonomiSamlet> alleForslag,
    required GenerelProjektInfo projektInfo,
    required String anlaegsNavn,
    required double elPris,
    required double varmePris,
    required pw.MemoryImage logo,
    required Map<String, pw.MemoryImage> leverandorLogoer,
    required String anlaegsType,
    required double elforbrugInd,
    required double omkostningInd,
    required double elforbrugUd,
    required double omkostningUd,
    required double samletFoerKWh,
    required double samletFoerKr,
    required String valgtTilstand,
    VarmeforbrugResultat? varmeforbrugResultat,
  }) {
    final fmtInt = NumberFormat.decimalPattern('da_DK')..maximumFractionDigits = 0;
    final fmtDec = NumberFormat.decimalPattern('da_DK')
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;

    if (alleForslag.isEmpty) return [];

    // Sorter alle forslag
    final sorteredeForslag = [...alleForslag]
      ..sort((a, b) {
        final ecoA = a.oekonomi as OekonomiResultat;
        final ecoB = b.oekonomi as OekonomiResultat;
        return ecoA.tilbagebetalingstid.compareTo(ecoB.tilbagebetalingstid);
      });

    // 🔹 FILTRER GYLDIGE FORSLAG
    final gyldigeForslag = sorteredeForslag.where(erGyldigtVentilatorForslag).toList();
    final antalGyldige = gyldigeForslag.length;

    // 🔹 VÆLG KUN FRA GYLDIGE FORSLAG (eller fallback)
    final valgKorteste = gyldigeForslag.isNotEmpty ? gyldigeForslag.first : sorteredeForslag.first;
    final valgStoerste = gyldigeForslag.isNotEmpty
        ? ([...gyldigeForslag]
      ..sort((a, b) =>
          (b.oekonomi as OekonomiResultat).aarsbesparelse
              .compareTo((a.oekonomi as OekonomiResultat).aarsbesparelse)))
        .first
        : sorteredeForslag.first;

    final double tbtScenarie1 = (valgKorteste.oekonomi as OekonomiResultat).tilbagebetalingstid;
    final bool scenarie1KanOptimeres = tbtScenarie1 <= 5;

    final valgtAnlaeg = projektInfo.alleAnlaeg.firstWhere(
          (a) => a.anlaegsNavn == anlaegsNavn,
      orElse: () => AnlaegsData.empty(),
    );

    pw.MemoryImage? anlaegsBillede;
    if (valgtAnlaeg.dokumentation != null && valgtAnlaeg.dokumentation!.isNotEmpty) {
      final String? path = valgtAnlaeg.dokumentation!.first["path"];
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          anlaegsBillede = pw.MemoryImage(file.readAsBytesSync());
        }
      }
    }

    final pages = <pw.Page>[];

    // ═══════════════════════════════════════════════════════════════
// SIDE 1: Ventilatoroptimering
// ═══════════════════════════════════════════════════════════════
    pages.add(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$anlaegsType - $anlaegsNavn',
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

                _underOverskrift('VENTILATOROPTIMERING'),
                pw.SizedBox(height: 12),

                _smallHeader('FØR situationen'),
                pw.SizedBox(height: 8),

                if (anlaegsBillede != null) ...[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: _foerSituation(
                          anlaegsType,
                          elforbrugInd,
                          omkostningInd,
                          elforbrugUd,
                          omkostningUd,
                          samletFoerKWh,
                          samletFoerKr,
                          fmtInt,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Align(
                          alignment: pw.Alignment.topCenter,
                          child: pw.Container(
                            height: 140,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 8,
                              verticalRadius: 8,
                              child: pw.Image(anlaegsBillede, fit: pw.BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _foerSituation(
                    anlaegsType,
                    elforbrugInd,
                    omkostningInd,
                    elforbrugUd,
                    omkostningUd,
                    samletFoerKWh,
                    samletFoerKr,
                    fmtInt,
                  ),
                ],

                pw.SizedBox(height: 16),

                _smallHeader('EFTER situationen'),
                pw.SizedBox(height: 8),

                if (gyldigeForslag.length == 1 &&
                    (gyldigeForslag.first.fabrikant.contains('Nyt Ventilationsanlæg') ||
                        gyldigeForslag.first.fabrikant.contains('Special anlæg'))) ...[
                  pw.Center(
                    child: pw.Text(
                      gyldigeForslag.first.fabrikant.contains('Nyt Ventilationsanlæg')
                          ? 'Komplet nyt ventilationsanlæg'
                          : 'Forslag til energieffektiv ventilatorløsning med beregnet besparelse',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColor.fromInt(0xFF006390),  // ✅ BLÅ FARVE
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],

                // 🔹 Brug allerede filtrerede forslag fra toppen
                ...(() {
                  // Find manglende fabrikanter
                  final alleFabrikanter = ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
                  final gyldigeFabrikanter =
                  gyldigeForslag.map((f) => f.fabrikant).toSet();
                  final manglenedFabrikanter = alleFabrikanter
                      .where((f) => !gyldigeFabrikanter.contains(f))
                      .toList();

                  // ✅ HVIS 0 MATCHES - VIS SPECIALANLÆG
                  if (antalGyldige == 0) {
                    return [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFFFF3E0),
                          border: pw.Border.all(color: PdfColors.orange, width: 2),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('⚠',
                                    style: pw.TextStyle(
                                        fontSize: 20, color: PdfColors.orange)),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  'SPECIALANLÆG',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    color: PdfColors.orange,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Dette anlæg ligger uden for standardløsningerne fra vores leverandører.',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text('Årsag:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            _bulletPoint(
                                'Luftmængde og tryk ligger uden for standardområdet'),
                            _bulletPoint('Kombination kræver specialdesign'),
                            pw.SizedBox(height: 8),
                            pw.Text('NÆSTE SKRIDT:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text(
                              'Bravida kan tilbyde en skræddersyet løsning baseret på:\n'
                                  '- Nøjagtige målinger af anlægget\n'
                                  '- Tilbud fra flere leverandører\n'
                                  '- Teknisk rådgivning om optimal løsning',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Kontakt din serviceleder for videre assistance.',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontStyle: pw.FontStyle.italic,
                                  color: PdfColors.grey),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }

                  // ✅ HVIS 1–3 MATCHES - VIS SCENARIEKORT + dynamisk tekst
                  return [
                    // ✅ Tjek om det er manuel data (nyt ventilationsanlæg)
                  if (gyldigeForslag.length == 1 &&
                      (gyldigeForslag.first.fabrikant.contains('Nyt Ventilationsanlæg') ||
                          gyldigeForslag.first.fabrikant.contains('Special anlæg')))
                    // VIS KUN ÉN CENTRERET BOKS
                    pw.Center(
                      child: pw.Container(
                        constraints: const pw.BoxConstraints(maxWidth: 270),
                        child: _scenarieKort(
                          'Besparelsesforslag',
                          valgKorteste,
                          samletFoerKWh,
                          samletFoerKr,
                          elPris,
                          scenarie1KanOptimeres,
                          fmtInt,
                          fmtDec,
                          leverandorLogoer,
                          varmeforbrugResultat,
                          anlaegsType,
                        ),
                      ),
                    )
                  else
                    // VIS TO SCENARIER VED SIDEN AF HINANDEN
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: _scenarieKort(
                            'Scenarie 1 Korteste tilbagebetalingstid',
                            valgKorteste,
                            samletFoerKWh,
                            samletFoerKr,
                            elPris,
                            scenarie1KanOptimeres,
                            fmtInt,
                            fmtDec,
                            leverandorLogoer,
                            varmeforbrugResultat,
                            anlaegsType,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: _scenarieKort(
                            'Scenarie 2 Største besparelse\nover 10 år',
                            valgStoerste,
                            samletFoerKWh,
                            samletFoerKr,
                            elPris,
                            scenarie1KanOptimeres,
                            fmtInt,
                            fmtDec,
                            leverandorLogoer,
                            varmeforbrugResultat,
                            anlaegsType,
                          ),
                        ),
                      ],
                    ),

// ✅ KUN VIS TEKSTEN HVIS DER IKKE ER MANUEL DATA
                  if (!gyldigeForslag.any((f) =>
                  f.fabrikant.contains('Nyt Ventilationsanlæg') ||
                  f.fabrikant.contains('Special anlæg'))) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                  'Besparelsesforslaget er udarbejdet på baggrund af beregninger fra tre ventilatorproducenter. '
                  'De viste forslag repræsenterer hhv. den korteste tilbagebetalingstid og den største økonomiske besparelse.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                  ),
                  ),
                  ]
                  ];

                })(),
              ],
            ),
          );
        },
      ),
    );

    // ═══════════════════════════════════════════════════════════════
    // SIDE 2: Varmeoptimering og samlet resultat
    // ═══════════════════════════════════════════════════════════════
    pages.add(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$anlaegsType - $anlaegsNavn',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromInt(0xFF006390))),
                    pw.Image(logo, height: 30),
                  ],
                ),
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: PdfColor.fromInt(0xFF34E0A1),
                ),
                pw.SizedBox(height: 6),

                if (varmeforbrugResultat != null && (
                    anlaegsType == 'Ventilationsanlæg' ||
                        (varmeforbrugResultat.varmeforbrugKWh ?? 0) > 0
                )) ...[
                  _underOverskrift('VARMEOPTIMERING'),
                  pw.SizedBox(height: 12),
                  _varmeSektion(
                    varmeforbrugResultat,
                    varmePris,
                    anlaegsType,
                    fmtInt,
                  ),
                  pw.SizedBox(height: 20),
                ],

                _underOverskrift('SAMLET RESULTAT OG TILSTANDSVURDERING'),
                pw.SizedBox(height: 12),

                _samletResultat(
                  valgStoerste.oekonomi as OekonomiResultat,
                  varmeforbrugResultat,
                  elPris,
                  valgtTilstand,
                  fmtInt,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pages;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METODER
  // ═══════════════════════════════════════════════════════════════

  static pw.Widget _underOverskrift(String tekst) {
    return pw.Text(
      tekst,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        color: PdfColor.fromInt(0xFF006390),
      ),
    );
  }

  static pw.Widget _smallHeader(String tekst) {
    return pw.Text(
      tekst,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromInt(0xFF006390),
      ),
    );
  }

  static pw.Widget _foerSituation(
      String anlaegsType,
      double elforbrugInd,
      double omkostningInd,
      double elforbrugUd,
      double omkostningUd,
      double samletFoerKWh,
      double samletFoerKr,
      NumberFormat fmtInt,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if ((anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
            elforbrugInd > 0) ...[
          pw.Text('Indblæsningsventilator',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 2),
          _bulletPoint('Elforbrug: ${fmtInt.format(elforbrugInd)} kWh'),
          _bulletPoint('Omkostning: ${fmtInt.format(omkostningInd)} kr'),
          pw.SizedBox(height: 8),
        ],
        if ((anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
            elforbrugUd > 0) ...[
          pw.Text('Udsugningsventilator',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 2),
          _bulletPoint('Elforbrug: ${fmtInt.format(elforbrugUd)} kWh'),
          _bulletPoint('Omkostning: ${fmtInt.format(omkostningUd)} kr'),
          pw.SizedBox(height: 8),
        ],
        if (elforbrugInd > 0 || elforbrugUd > 0) ...[
          pw.Text('Samlet energiforbrug og driftsomkostning',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 2),
          _bulletPoint('Samlet elforbrug: ${fmtInt.format(samletFoerKWh)} kWh/år'),
          _bulletPoint('Samlet omkostning: ${fmtInt.format(samletFoerKr)} kr/år'),
        ],
      ],
    );
  }

  static pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '-',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _scenarieKort(
      String overskrift,
      VentilatorOekonomiSamlet forslag,
      double samletFoerKWh,
      double samletFoerKr,
      double elPris,
      bool scenarie1KanOptimeres,
      NumberFormat fmtInt,
      NumberFormat fmtDec,
      Map<String, pw.MemoryImage> leverandorLogoer,
      VarmeforbrugResultat? varmeforbrugResultat,
      String anlaegsType,
      ) {
    final eco = forslag.oekonomi as OekonomiResultat;
    final aarligKr = eco.aarsbesparelse;
    final double elbesparelseKWh = elPris > 0 ? aarligKr / elPris : 0;
    final double co2Besparelse = elbesparelseKWh * 0.34;
    final double nytElforbrugKWh = samletFoerKWh - elbesparelseKWh;
    final double nyOmkostningKr = samletFoerKr - aarligKr;

    // ✅ BEREGN OM DET ER NYT VENTILATIONSANLÆG
    final bool erNytVentilationsanlaeg = forslag.fabrikant.contains('Nyt Ventilationsanlæg') &&
        anlaegsType == 'Ventilationsanlæg';

    // ✅ BEREGN VARMEBESPARELSE HVIS RELEVANT
    final bool harVarmeOptimering = varmeforbrugResultat?.optimering?.kanOptimeres ?? false;

    final double varmeBesparelseKWh = (erNytVentilationsanlaeg && harVarmeOptimering)
        ? ((varmeforbrugResultat?.varmeforbrugKWh?.toDouble() ?? 0) -
        (varmeforbrugResultat?.optimering?.nytVarmeforbrugKWh?.toDouble() ?? 0))
        : 0;

    final double varmeBesparelseKr = (erNytVentilationsanlaeg && harVarmeOptimering)
        ? ((varmeforbrugResultat?.varmeOmkostning?.toDouble() ?? 0) -
        (varmeforbrugResultat?.optimering?.nytVarmeforbrugKr?.toDouble() ?? 0))
        : 0;

    final double varmeCo2 = varmeBesparelseKWh * 0.10;

    // ✅ SAMLET besparelse
    final double samletBesparelseKWh = elbesparelseKWh + varmeBesparelseKWh;
    final double samletBesparelseKr = aarligKr + varmeBesparelseKr;
    final double samletCo2 = co2Besparelse + varmeCo2;

    // ✅ 10-ÅRS BESPARELSE LOGIK
    final double tiAarsBesparelse = erNytVentilationsanlaeg
        ? samletBesparelseKr * 10
        : aarligKr * 10;

    // 🔹 Bruges KUN til note — skjuler IKKE længere data
    final bool kanOptimeres = scenarie1KanOptimeres;

    return pw.Container(
      height: erNytVentilationsanlaeg && harVarmeOptimering
          ? 340  // ✅ Højere for nye anlæg med varme
          : (!kanOptimeres ? 310 : 280),  // ✅ Lidt højere når note vises
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFF34E0A1), width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Logo øverst (kun hvis ikke nyt anlæg)
          if (!forslag.fabrikant.contains('Nyt Ventilationsanlæg') &&
              forslag.logoPath.isNotEmpty &&
              leverandorLogoer.containsKey(forslag.logoPath))
            pw.Padding(
              padding: pw.EdgeInsets.only(
                top: forslag.fabrikant == 'Ebmpapst' ? 24 : 4,
                bottom: forslag.fabrikant == 'Ebmpapst' ? 32 : 10,
              ),
              child: pw.Container(
                alignment: pw.Alignment.center,
                height: forslag.fabrikant == 'Ebmpapst' ? 25
                    : forslag.fabrikant == 'Novenco' ? 70
                    : 70,
                child: pw.Image(
                  leverandorLogoer[forslag.logoPath]!,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),

          if (!forslag.fabrikant.contains('Nyt Ventilationsanlæg'))
            pw.SizedBox(height: 8),

          pw.Text(
            overskrift,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColor.fromInt(0xFF006390),
            ),
          ),
          pw.SizedBox(height: 8),


          pw.SizedBox(height: 8),

          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ✅ RETTET: Besparelsesdata vises ALTID (ingen if scenarie1KanOptimeres wrapper)

                // ✅ NYT VENTILATIONSANLÆG - OPDELT VISNING
                if (erNytVentilationsanlaeg) ...[
                  // VENTILATORBESPARELSE
                  pw.Text(
                    'VENTILATORBESPARELSE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF006390),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  _bulletPoint('El-besparelse: ${fmtInt.format(elbesparelseKWh)} kWh/år'),
                  _bulletPoint('Økonomisk: ${fmtInt.format(aarligKr)} kr/år'),
                  _bulletPoint('Nyt elforbrug: ${fmtInt.format(nytElforbrugKWh)} kWh/år'),
                  _bulletPoint('Ny elomkostning: ${fmtInt.format(nyOmkostningKr)} kr/år'),

                  // VARMEBESPARELSE (hvis relevant)
                  if (harVarmeOptimering) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'VARMEBESPARELSE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF006390),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    _bulletPoint('Energibesparelse: ${fmtInt.format(varmeBesparelseKWh)} kWh/år'),
                    _bulletPoint('Økonomisk: ${fmtInt.format(varmeBesparelseKr)} kr/år'),
                    _bulletPoint('Nyt varmeforbrug: ${fmtInt.format(varmeforbrugResultat?.optimering?.nytVarmeforbrugKWh ?? 0)} kWh/år'),
                    _bulletPoint('Ny varmeomkostning: ${fmtInt.format(varmeforbrugResultat?.optimering?.nytVarmeforbrugKr ?? 0)} kr/år'),
                  ],

                  // SAMLET BESPARELSE
                  pw.SizedBox(height: 6),
                  pw.Container(
                    height: 1,
                    color: PdfColor.fromInt(0xFF34E0A1),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'SAMLET BESPARELSE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF006390),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  _bulletPoint('Samlet energi: ${fmtInt.format(samletBesparelseKWh)} kWh/år'),
                  _bulletPoint('Samlet økonomi: ${fmtInt.format(samletBesparelseKr)} kr/år'),
                  _bulletPoint('CO2: ${fmtInt.format(samletCo2)} kg/år'),

                  pw.SizedBox(height: 6),
                  pw.Container(
                    height: 1,
                    color: PdfColor.fromInt(0xFF34E0A1),
                  ),
                  pw.SizedBox(height: 4),
                ] else ...[
                  // STANDARD LØSNINGER - SIMPEL VISNING
                  _bulletPoint('El-besparelse: ${fmtInt.format(elbesparelseKWh)} kWh/år'),
                  _bulletPoint('Økonomisk besparelse: ${fmtInt.format(aarligKr)} kr/år'),
                  _bulletPoint('CO2-besparelse: ${fmtInt.format(co2Besparelse)} kg/år'),
                  pw.SizedBox(height: 4),
                ],

                // RESTEN (for alle typer)
                _bulletPoint('Investering: ${fmtInt.format(eco.pris)} kr'),
                _bulletPoint('Tilbagebetalingstid: ${fmtDec.format(eco.tilbagebetalingstid)} år'),
                pw.SizedBox(height: 4),

                // Kun vis for STANDARD løsninger (ikke nye ventilationsanlæg)
                if (!erNytVentilationsanlaeg) ...[
                  _bulletPoint('Nyt elforbrug: ${fmtInt.format(nytElforbrugKWh)} kWh/år'),
                  _bulletPoint('Ny elomkostning: ${fmtInt.format(nyOmkostningKr)} kr/år'),
                  pw.SizedBox(height: 4),
                ],

                _bulletPoint('10 års besparelse: ${fmtInt.format(tiAarsBesparelse)} kr'),

                // ✅ RETTET: Note vises som info NÅR TBT > 5 år (data skjules IKKE)
                if (!kanOptimeres) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFF3E0),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.orange200),
                    ),
                    child: pw.Text(
                      'Tilbagebetalingstiden er over 5 år. Optimering kan stadig være relevant afhængigt af anlæggets tilstand og forventede restlevetid.',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _varmeSektion(
      VarmeforbrugResultat? varmeforbrugResultat,
      double varmePris,
      String anlaegsType,
      NumberFormat fmtInt,
      ) {
    if (varmeforbrugResultat == null) {
      return pw.Text('Ingen varmeberegning tilgængelig',
          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey));
    }

    final num nuvEnergiKWh = varmeforbrugResultat.varmeforbrugKWh ?? 0;
    final num nuvEnergiKr = varmeforbrugResultat.varmeOmkostning ?? (nuvEnergiKWh * varmePris);

    // ✅ Brug kanOptimeres direkte fra optimering-objektet
    final bool kanOptimeres = varmeforbrugResultat.optimering?.kanOptimeres ?? false;

    // ✅ VIGTIG FIX: Hvis kanOptimeres = false, skal efter-værdier være SAMME som før-værdier
    // Dette sikrer at besparelsen bliver 0 for anlæg uden varmegenvinding
    final num efterEnergiKWh = kanOptimeres
        ? (varmeforbrugResultat.optimering?.nytVarmeforbrugKWh ?? nuvEnergiKWh)
        : nuvEnergiKWh;
    final num efterEnergiKr = kanOptimeres
        ? (varmeforbrugResultat.optimering?.nytVarmeforbrugKr ?? nuvEnergiKr)
        : nuvEnergiKr;
    final num nyVirkningsgrad = varmeforbrugResultat.optimering?.nyVirkningsgrad ?? 0;

    final num besparelseKWh = nuvEnergiKWh - efterEnergiKWh;
    final num besparelseKr = nuvEnergiKr - efterEnergiKr;
    final num co2Besparelse = varmeforbrugResultat.optimering?.co2Besparelse ?? 0;

    final String? kommentar = varmeforbrugResultat.optimering?.kommentar;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 🔹 Før optimering (hvis der er beregning)
        if (varmeforbrugResultat.harBeregning) ...[
          pw.Text('Før optimering',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 2),
          _bulletPoint('Årsforbrug: ${fmtInt.format(nuvEnergiKWh)} kWh/år'),
          _bulletPoint('Årlig omkostning: ${fmtInt.format(nuvEnergiKr)} kr/år'),

          // ✅ KORRIGERET VERSION
          _bulletPoint(
              'Virkningsgrad før: ${((varmeforbrugResultat.optimering?.virkningsgradFoer ?? 0)).toStringAsFixed(1)} %'
          ),

          pw.SizedBox(height: 8),
        ],

        // 🔹 Efter optimering (hvis kanOptimeres)
        if (kanOptimeres) ...[
          pw.Text('Efter optimering',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 2),
          _bulletPoint('Nyt varmeforbrug: ${fmtInt.format(efterEnergiKWh)} kWh/år'),
          _bulletPoint('Ny omkostning: ${fmtInt.format(efterEnergiKr)} kr/år'),
          _bulletPoint('Ny virkningsgrad: ${nyVirkningsgrad.toStringAsFixed(1)} %'),
          pw.SizedBox(height: 8),

          pw.Text('Besparelse',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 2),
          _bulletPoint('Energibesparelse: ${fmtInt.format(besparelseKWh)} kWh/år'),
          _bulletPoint('Økonomisk besparelse: ${fmtInt.format(besparelseKr)} kr/år'),
          if (co2Besparelse > 0)
            _bulletPoint('CO2 besparelse: ${fmtInt.format(co2Besparelse)} kg/år'),
          pw.SizedBox(height: 8),
        ],

        // 🔹 Kommentar fra optimering (hvis den findes)
        if (kommentar != null && kommentar.isNotEmpty) ...[
          pw.Text(kommentar,
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
        ],
      ],
    );
  }

  static pw.Widget _samletResultat(
      OekonomiResultat eco,
      VarmeforbrugResultat? varme,
      double elPris,
      String valgtTilstand,
      NumberFormat fmtInt,
      ) {
    final double elBesparelseVent = eco.aarsbesparelse > 0 && elPris > 0
        ? eco.aarsbesparelse / elPris
        : 0;
    final double krBesparelseVent = eco.aarsbesparelse;
    final double co2BesparelseVent = elBesparelseVent * 0.34;

    final bool harVarmeData = varme != null &&
        varme.harBeregning &&
        (varme.optimering?.kanOptimeres ?? false);

    final double nuvEnergiKWh = harVarmeData ? (varme.varmeforbrugKWh?.toDouble() ?? 0) : 0;
    final double efterEnergiKWh = harVarmeData ? (varme.optimering?.nytVarmeforbrugKWh?.toDouble() ?? 0) : 0;
    final double nuvEnergiKr = harVarmeData ? (varme.varmeOmkostning?.toDouble() ?? 0) : 0;
    final double efterEnergiKr = harVarmeData ? (varme.optimering?.nytVarmeforbrugKr?.toDouble() ?? 0) : 0;

    final double varmeBesparelseKWh = harVarmeData ? (nuvEnergiKWh - efterEnergiKWh) : 0;
    final double varmeBesparelseKr = harVarmeData ? (nuvEnergiKr - efterEnergiKr) : 0;
    final double varmeBesparelseCo2 = (varmeBesparelseKWh > 0) ? varmeBesparelseKWh * 0.10 : 0;

    final double totalKWh = elBesparelseVent + varmeBesparelseKWh;
    final double totalKr = krBesparelseVent + varmeBesparelseKr;
    final double totalCo2 = co2BesparelseVent + varmeBesparelseCo2;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Største besparelsespotentiale og tilstandsvurdering',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          harVarmeData
              ? '(Beregnet inkl. både ventilator- og varmeoptimering)'
              : '(Beregnet kun for ventilatoroptimering)',
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),

        pw.Text('Opsummering',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        _bulletPoint('Energibesparelse: ${fmtInt.format(totalKWh)} kWh/år'),
        _bulletPoint('Økonomisk besparelse: ${fmtInt.format(totalKr)} kr/år'),
        _bulletPoint('CO2 besparelse: ${fmtInt.format(totalCo2)} kg/år'),
        pw.SizedBox(height: 13),

        pw.Center(
          child: pw.Text(
            'Samlet årlig besparelse: ${fmtInt.format(totalKr)} kr/år',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColor.fromInt(0xFF006390),
            ),
          ),
        ),

        pw.SizedBox(height: 12),

        pw.Text('Tilstandsvurdering',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Anlægget er ${_tekstForTilstand(valgtTilstand)}',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _getTilstandsfarve(valgtTilstand),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _tilstandsKommentar(valgtTilstand),
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static String _tekstForTilstand(String valgtTilstand) {
    switch (valgtTilstand) {
      case '1':
        return 'i god stand';
      case '2':
        return 'rimelig stand';
      case '3':
        return 'slidt kræver opmærksomhed';
      case '4':
        return 'kritisk bør optimeres';
      case '5':
        return 'meget kritisk akut behov';
      case '6':
        return 'ude af drift';
      default:
        return 'uden vurdering';
    }
  }

  static PdfColor _getTilstandsfarve(String valgtTilstand) {
    switch (valgtTilstand) {
      case '1':
        return PdfColors.green;
      case '2':
        return PdfColors.lightGreen;
      case '3':
        return PdfColors.orange;
      case '4':
        return PdfColors.deepOrange;
      case '5':
        return PdfColors.red;
      case '6':
        return PdfColors.black;
      default:
        return PdfColors.grey;
    }
  }

  static String _tilstandsKommentar(String valgtTilstand) {
    switch (valgtTilstand) {
      case '1':
        return 'Da anlægget er i god stand, er det oplagt at gennemføre en energioptimering, '
            'da investeringen kan udnyttes fuldt ud og skabe størst mulig værdi.';
      case '2':
        return 'Anlægget er i rimelig stand med mindre slitage registreret. Det kan fortsat fungere '
            'uden større problemer, men en energioptimering kan være fordelagtig for at reducere '
            'driftsomkostninger og forlænge levetiden.';
      case '3':
        return 'Anlægget er slidt og har en restlevetid på 1 til 3 år. Det bør vurderes, om en renovering '
            'kan forlænge levetiden, eller om en udskiftning er mere hensigtsmæssig. '
            'Ved begge løsninger bør energioptimering indgå som en naturlig del af indsatsen.';
      case '4':
        return 'Anlægget er i kritisk stand og bør udskiftes eller gennemgå en større renovering '
            'inden for det næste år. Det anbefales at planlægge indsatsen i god tid og samtidig '
            'inddrage energioptimering som en central del af løsningen.';
      case '5':
        return 'Anlægget er i meget kritisk stand og kræver en større indsats. '
            'Der bør planlægges omfattende renovering eller udskiftning, '
            'hvor energioptimering indgå som en del af løsningen.';
      case '6':
        return 'Anlægget er ikke længere funktionsdygtigt og skal udskiftes. '
            'I forbindelse med udskiftningen anbefales det at vælge en løsning med fokus på energioptimering.';
      default:
        return '';
    }
  }
}