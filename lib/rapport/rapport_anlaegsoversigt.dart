import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../ventilator_samlet_beregning.dart';
import '../generel_projekt_info.dart';
import '../anlaegs_data.dart';

/// Tjek om et ventilatorforslag er gyldigt (har fundet en løsning)
bool erGyldigtVentilatorForslag(VentilatorOekonomiSamlet forslag) {
  final double nytElforbrugInd = forslag.indNormal.aarsforbrugKWh;
  final double nytElforbrugUd = forslag.udNormal.aarsforbrugKWh;
  final double samletNytElforbrug = nytElforbrugInd + nytElforbrugUd;

  if (samletNytElforbrug <= 0) {
    return false;
  }

  return true;
}

class RapportAnlaegsOversigt {
  static List<pw.Page> build(
      List<VentilatorOekonomiSamlet> alleForslag,
      GenerelProjektInfo projektInfo,
      double elPris,
      double varmePris,
      pw.MemoryImage logo) {
    final fmtInt = NumberFormat.decimalPattern('da_DK')..maximumFractionDigits = 0;
    final fmtDec = NumberFormat.decimalPattern('da_DK')
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;

    final Map<String, List<VentilatorOekonomiSamlet>> grupperet = {};
    for (var v in alleForslag) {
      grupperet.putIfAbsent(v.anlaegsnavn, () => []).add(v);
    }

    final entries = grupperet.entries.map((e) {
      // Find matchende anlæg FØRST
      final match = projektInfo.alleAnlaeg.firstWhere(
            (a) => a.anlaegsNavn == e.key,
        orElse: () => AnlaegsData.empty(),
      );

      // Filtrer gyldige forslag
      final gyldigeForslag = e.value.where(erGyldigtVentilatorForslag).toList();
      final antalGyldige = gyldigeForslag.length;

      // Find manglende fabrikanter
      final alleFabrikanter = ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
      final gyldigeFabrikanter = gyldigeForslag.map((f) => f.fabrikant).toSet();
      final manglenedFabrikanter = alleFabrikanter.where((f) => !gyldigeFabrikanter.contains(f)).toList();

      // Hvis SPECIALANLÆG (0 matches), brug FØR-data fra AnlaegsData
      if (gyldigeForslag.isEmpty) {
        final driftstimer = projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) * projektInfo.ugerPerAar;
        final omkostningFoer = (match.kwInd + match.kwUd) * driftstimer * match.elpris;

        return _OversigtEntry(
          anlaegsType: match.valgtAnlaegstype,
          anlaegsnavn: e.key,
          omkostningFoer: omkostningFoer,
          omkostningEfter: omkostningFoer, // Ingen besparelse
          ventilatorBesparelse: 0, // Ingen besparelse
          varmeBesparelseKr: match.varmeAarsbesparelse ?? 0,
          varmeBesparelseKWh: match.varmeBesparelseKWh ?? 0,
          samletBesparelse: (match.varmeAarsbesparelse ?? 0),
          tilbagebetalingstid: double.infinity,
          varmeOmkostningFoer: match.varmeOmkostningFoer ?? 0,
          varmeOmkostningEfter: match.varmeOmkostningEfter ?? 0,
          valgtTilstand: match.valgtTilstand ?? '0',
          antalGyldige: antalGyldige,
          manglenedFabrikanter: manglenedFabrikanter,
          erNytVentilationsanlaeg: false,
        );
      }

      // NORMAL CASE: Vælg bedste gyldige forslag
      final valgtForslag = gyldigeForslag.reduce((a, b) {
        final aT = (a.oekonomi as OekonomiResultat).tilbagebetalingstid;
        final bT = (b.oekonomi as OekonomiResultat).tilbagebetalingstid;
        return aT < bT ? a : b;
      });

      final eco = valgtForslag.oekonomi as OekonomiResultat;
      final bool erNytAnlaeg = valgtForslag.fabrikant.contains('Nyt Ventilationsanlæg');

      return _OversigtEntry(
        anlaegsType: valgtForslag.anlaegstype ?? "Anlæg",
        anlaegsnavn: e.key,
        omkostningFoer: eco.omkostningFoer,
        omkostningEfter: eco.omkostningFoer - eco.aarsbesparelse,
        ventilatorBesparelse: eco.aarsbesparelse,
        varmeBesparelseKr: match.varmeAarsbesparelse ?? 0,
        varmeBesparelseKWh: match.varmeBesparelseKWh ?? 0,
        samletBesparelse: eco.aarsbesparelse + (match.varmeAarsbesparelse ?? 0),
        tilbagebetalingstid: eco.tilbagebetalingstid,
        varmeOmkostningFoer: match.varmeOmkostningFoer ?? 0,
        varmeOmkostningEfter: match.varmeOmkostningEfter ?? 0,
        valgtTilstand: match.valgtTilstand ?? '0',
        antalGyldige: antalGyldige,
        manglenedFabrikanter: manglenedFabrikanter,
        erNytVentilationsanlaeg: erNytAnlaeg,
      );
    }).toList();

    // Sorter efter tilbagebetalingstid
    entries.sort((a, b) => a.tilbagebetalingstid.compareTo(b.tilbagebetalingstid));

    // Find max værdier for at kunne sammenligne søjler på tværs af anlæg
    final maxElOmkostning = entries.isNotEmpty
        ? entries.map((e) => e.omkostningFoer).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final maxVarmeOmkostning = entries.isNotEmpty
        ? entries.map((e) => e.varmeOmkostningFoer).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final pages = <pw.Page>[];

    for (int i = 0; i < entries.length; i += 2) {
      final pair = entries.skip(i).take(2).toList();
      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Første anlæg
                  _buildCard(pair[0], fmtInt, fmtDec, maxElOmkostning, maxVarmeOmkostning, logo),

                  // Andet anlæg hvis det findes
                  if (pair.length > 1) ...[
                    pw.SizedBox(height: 20),
                    _buildCard(pair[1], fmtInt, fmtDec, maxElOmkostning, maxVarmeOmkostning, logo),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return pages;
  }

  static pw.Widget _buildCard(
      _OversigtEntry v,
      NumberFormat fmtInt,
      NumberFormat fmtDec,
      double maxElOmkostning,
      double maxVarmeOmkostning,
      pw.MemoryImage logo) {

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header med anlægsnavn og logo
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${v.anlaegsType} - ${v.anlaegsnavn}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
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

          // Indhold
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // VENTILATOROPTIMERING
                _sektionOverskrift("Ventilatoroptimering"),
                pw.SizedBox(height: 4),

                if (v.antalGyldige == 0) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFF3E0),
                      border: pw.Border.all(color: PdfColors.orange, width: 1),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('', style: pw.TextStyle(fontSize: 12, color: PdfColors.orange)),
                            pw.SizedBox(width: 6),
                            pw.Text(
                              'SPECIALANLÆG',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                                color: PdfColors.orange,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Dette anlæg ligger uden for de tre leverandørers standardsortiment. '
                              'Kontakt Bravida for skræddersyet løsning.',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Normal visning
                  _barLineSimple(
                      "Årlige EL-omkostninger Før",
                      "${fmtInt.format(v.omkostningFoer)} kr/år",
                      v.omkostningFoer,
                      maxElOmkostning,
                      PdfColors.red),
                  pw.SizedBox(height: 3),
                  _barLineSimple(
                      "Årlige EL-omkostninger Efter",
                      "${fmtInt.format(v.omkostningEfter)} kr/år",
                      v.omkostningEfter,
                      maxElOmkostning,
                      PdfColors.green),

                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Årlig besparelse EL: ${fmtInt.format(v.ventilatorBesparelse)} kr/år",
                    style: pw.TextStyle(
                      color: v.ventilatorBesparelse >= 0 ? PdfColors.green700 : PdfColors.red,
                      fontSize: 9,
                    ),
                  ),
                  pw.Text(
                    v.ventilatorBesparelse > 0
                        ? (v.erNytVentilationsanlaeg
                        ? "Tilbagebetalingstid: ${fmtDec.format(v.tilbagebetalingstid)} år"
                        : "Tilbagebetalingstid (ventilator): ${fmtDec.format(v.tilbagebetalingstid)} år")
                        : "Tilbagebetalingstid (ventilator): -",
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],

                pw.SizedBox(height: 10),

                // VARMEOPTIMERING - kun vis hvis der er varmedata
                if (v.varmeOmkostningFoer > 0) ...[
                  _sektionOverskrift("Varmeoptimering"),
                  pw.SizedBox(height: 4),

                  // VIS ALTID "FØR" - custom Row med farvelogik (IKKE _barLine)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          'Årlige varmeomkostninger Før: ${fmtInt.format(v.varmeOmkostningFoer)} kr/år',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        flex: 3,
                        child: pw.LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableWidth = constraints?.maxWidth ?? 100.0;
                            final double fraction = maxVarmeOmkostning > 0
                                ? (v.varmeOmkostningFoer / maxVarmeOmkostning).clamp(0.0, 1.0)
                                : 0.0;
                            final double barWidth = availableWidth * fraction;

                            // GRØN kun for ventilationsanlæg uden besparelse
                            final barColor = (v.varmeBesparelseKr > 0)
                                ? PdfColors.red
                                : (v.anlaegsType.toLowerCase().contains('ventilationsanlæg'))
                                ? PdfColors.green
                                : PdfColors.red;

                            return pw.Stack(
                              children: [
                                pw.Container(
                                  height: 7,
                                  width: availableWidth,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.grey300,
                                    borderRadius: pw.BorderRadius.circular(3.5),
                                  ),
                                ),
                                pw.Container(
                                  height: 7,
                                  width: barWidth,
                                  decoration: pw.BoxDecoration(
                                    color: barColor,
                                    borderRadius: pw.BorderRadius.circular(3.5),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: (v.varmeBesparelseKr > 0)
                              ? PdfColors.red
                              : (v.anlaegsType.toLowerCase().contains('ventilationsanlæg'))
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                      ),
                    ],
                  ),

                  // VIS KUN "EFTER" HVIS DER ER BESPARELSE
                  if (v.varmeBesparelseKr > 0) ...[
                    pw.SizedBox(height: 3),
                    _barLineSimple(
                      "Årlige varmeomkostninger Efter",
                      "${fmtInt.format(v.varmeOmkostningEfter)} kr/år",
                      v.varmeOmkostningEfter,
                      maxVarmeOmkostning,
                      PdfColors.green,
                    ),

                    pw.SizedBox(height: 9),
                    pw.Text(
                      "Varmebesparelse: ${fmtInt.format(v.varmeBesparelseKr)} kr/år (${fmtInt.format(v.varmeBesparelseKWh)} kWh/år)",
                      style: pw.TextStyle(
                        color: PdfColors.green700,
                        fontSize: 9,
                      ),
                    ),

                    pw.SizedBox(height: 6),
                    // Row med info ikon
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Text(
                            "Renovering af varmegenvinding er ikke prissat, da det kræver inspektion af anlæggets indre komponenter",
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // INGEN BESPARELSE - FORSKELLIG TEKST BASERET PÅ ANLÆGSTYPE
                    pw.SizedBox(height: 6),
                    pw.Text(
                      v.anlaegsType.toLowerCase().contains('ventilationsanlæg')
                          ? "Anlægget kan ikke optimeres yderligere på varmegenvinding"
                          : "Anlægget har ingen varmegenvinding. Varmetabet kan kun reduceres ved installation af varmegenvindingssystem eller udskiftning til anlæg med integreret varmegenvinding.",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],

                  pw.SizedBox(height: 10),
                ]
                else if (v.anlaegsType.toLowerCase().contains('ventilationsanlæg')) ...[
                  pw.Text(
                    "Da udetemperaturen har været over 10 °C, har det ikke været muligt at fastsætte virkningsgraden på varmegenvindingen.",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Samlet besparelse
                pw.Center(
                  child: pw.Text(
                    'Samlet årlig besparelse: ${fmtInt.format(v.samletBesparelse)} kr/år',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColor.fromHex('#006390'),
                    ),
                  ),
                ),

                pw.SizedBox(height: 10),

                // Tilstandsvurdering
                _sektionOverskrift("Tilstandsvurdering"),
                pw.SizedBox(height: 4),

                pw.Text(
                  "Anlægget er ${_tekstForTilstand(v.valgtTilstand)}",
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _getTilstandsfarve(v.valgtTilstand),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _tilstandsKommentar(v.valgtTilstand),
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sektionOverskrift(String tekst) {
    return pw.Text(
      tekst,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromInt(0xFF006390),
      ),
    );
  }

  static pw.Widget _barLineSimple(
      String label, String value, double current, double max, PdfColor color) {
    final fraction = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return pw.Row(
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Text(
            "$label: $value",
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          flex: 3,
          child: pw.LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints?.maxWidth ?? 100.0;
              final double barWidth = availableWidth * fraction;

              return pw.Stack(
                children: [
                  pw.Container(
                    height: 7,
                    width: availableWidth,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(3.5),
                    ),
                  ),
                  pw.Container(
                    height: 7,
                    width: barWidth,
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(3.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        pw.SizedBox(width: 6),
        // ✅ TILFØJ CIRKEL-IKON
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: color,
          ),
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
        return 'Da anlægget er i god stand, er det oplagt at gennemføre en energioptimering...';
      case '2':
        return 'Anlægget er i rimelig stand med mindre slitage registreret...';
      case '3':
        return 'Anlægget er slidt og har en restlevetid på 1 til 3 år...';
      case '4':
        return 'Anlægget er i kritisk stand og bør udskiftes eller gennemgå en større renovering...';
      case '5':
        return 'Anlægget er i meget kritisk stand og kræver en større indsats...';
      case '6':
        return 'Anlægget er ikke længere funktionsdygtigt og skal udskiftes...';
      default:
        return '';
    }
  }
}

class _OversigtEntry {
  final String anlaegsType;
  final String anlaegsnavn;
  final double omkostningFoer;
  final double omkostningEfter;
  final double ventilatorBesparelse;
  final double varmeBesparelseKr;
  final double varmeBesparelseKWh;
  final double samletBesparelse;
  final double tilbagebetalingstid;
  final double varmeOmkostningFoer;
  final double varmeOmkostningEfter;
  final String valgtTilstand;
  final int antalGyldige;
  final List<String> manglenedFabrikanter;
  final bool erNytVentilationsanlaeg;

  _OversigtEntry({
    required this.anlaegsType,
    required this.anlaegsnavn,
    required this.omkostningFoer,
    required this.omkostningEfter,
    required this.ventilatorBesparelse,
    required this.varmeBesparelseKr,
    required this.varmeBesparelseKWh,
    required this.samletBesparelse,
    required this.tilbagebetalingstid,
    required this.varmeOmkostningFoer,
    required this.varmeOmkostningEfter,
    required this.valgtTilstand,
    required this.antalGyldige,
    required this.manglenedFabrikanter,
    required this.erNytVentilationsanlaeg,
  });
}

















































