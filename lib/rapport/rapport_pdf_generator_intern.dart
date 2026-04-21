import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:ventoptima/ventilator_samlet_beregning.dart';
import 'package:ventoptima/beregning_varmeforbrug.dart';

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

/// Tjek om et ventilatorforslag er gyldigt (har fundet en løsning)
bool erGyldigtVentilatorForslag(VentilatorOekonomiSamlet forslag) {
  final eco = forslag.oekonomi as OekonomiResultat;

  final double nytElforbrugInd = forslag.indNormal.aarsforbrugKWh;
  final double nytElforbrugUd = forslag.udNormal.aarsforbrugKWh;
  final double samletNytElforbrug = nytElforbrugInd + nytElforbrugUd;

  if (samletNytElforbrug <= 0) {
    return false;
  }

  if (eco.aarsbesparelse <= 0) {
    return false;
  }

  return true;
}

/// Hent tilstandsbeskrivelse baseret på valgt tilstand
String getTilstandsbeskrivelse(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return 'Meget god stand';
    case '2':
      return 'God stand';
    case '3':
      return 'Mindre fejl og mangler';
    case '4':
      return 'Større fejl og mangler';
    case '5':
      return 'Alvorlige fejl og mangler';
    case '6':
      return 'Kritisk stand';
    default:
      return 'Ikke vurderet';
  }
}

/// Hent tilstandsfarve baseret på valgt tilstand
PdfColor getTilstandsfarvePdf(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return PdfColors.green;
    case '2':
      return PdfColor.fromInt(0xFF90EE90); // lightGreen
    case '3':
      return PdfColor.fromInt(0xFFFFD54F); // orangeAccent
    case '4':
      return PdfColors.orange;
    case '5':
      return PdfColor.fromInt(0xFFFF5722); // deepOrange
    case '6':
      return PdfColors.red;
    default:
      return PdfColors.black;
  }
}

/// Generer kommentar for varmeforbrug (ventilationsanlæg)
String _getVarmeforbrugKommentar(VarmeforbrugResultat varmeforbrugResultat) {
  if (!varmeforbrugResultat.harBeregning) {
    return "Det har ikke været muligt at fastsætte varmeforbruget under service. "
        "En mulig årsag kan være, at udetemperaturen var over 10 °C under service.";
  } else if (varmeforbrugResultat.optimering != null &&
      !(varmeforbrugResultat.optimering!.kanOptimeres)) {
    return "Anlæggets varmegenvinding er allerede tæt på det forventede niveau "
        "og vurderes ikke at kunne optimeres yderligere.";
  } else if (varmeforbrugResultat.optimering?.korrigeretVirkningsgrad != null) {
    return "Virkningsgrad faldet fra "
        "${formatDK(varmeforbrugResultat.optimering!.standardVirkningsgrad, decimals: 1)} % "
        "til ${formatDK(varmeforbrugResultat.optimering!.nyVirkningsgrad, decimals: 1)} % pga. ulige luftmængder. "
        "Dette medfører et ekstra varmeforbrug på ca. "
        "${formatDK(varmeforbrugResultat.optimering!.besparelseKWh ?? 0)} kWh/år "
        "til en meromkostning på "
        "${formatDK(varmeforbrugResultat.optimering!.besparelseKr ?? 0)} kr./år.";
  } else {
    return "Standard virkningsgrad anvendt: "
        "${formatDK(varmeforbrugResultat.optimering?.valgtVirkningsgrad ?? 0, decimals: 1)} %";
  }
}

Future<Uint8List> generateInternPdfKort({
  required String anlaegsNavn,
  required String anlaegsType,
  required double luftInd,
  required double luftUd,
  required double statiskTrykInd,
  required double statiskTrykUd,
  required double kwInd,
  required double kwUd,
  required double hzInd,
  required double hzUd,
  required double elforbrugInd,
  required double elforbrugUd,
  required double virkningsgradInd,
  required double virkningsgradUd,
  required double selInd,
  required double selUd,
  required double omkostningInd,
  required double omkostningUd,
  required double samletFoerKWh,
  required double samletFoerKr,
  required double? luftIndMax,
  required double? luftUdMax,
  required double? statiskTrykMaxInd,
  required double? statiskTrykMaxUd,
  required VarmeforbrugResultat? varmeforbrugResultat,
  required double? kammerBredde,
  required double? kammerHoede,
  required double? kammerLaengde,
  required VentilatorOekonomiSamlet ebmpapstResultat,
  required VentilatorOekonomiSamlet novencoResultat,
  required VentilatorOekonomiSamlet ziehlResultat,
  required List<VentilatorOekonomiSamlet> alleForslag,
  required bool erBeregnetUdFraDesignData,
  required bool erBeregnetUdFraLavHz,
  required bool erBeregnetUdFraKVaerdi,
  required String valgtTilstand,
  required bool beregnetDesignInd,
  required bool beregnetDesignUd,
  required bool beregnetKVaerdiInd,
  required bool beregnetKVaerdiUd,
  required bool erMaalteVaerdier,
  String? internKommentar,
  double? trykFoerInd,
  double? trykEfterInd,
  double? trykFoerUd,
  double? trykEfterUd,
}) async {
  final pdf = pw.Document();

  const PdfColor matchingGreen = PdfColor.fromInt(0xFF34E0A1);
  const PdfColor matchingBlue = PdfColor.fromInt(0xFF006390);
  const double titleFontSize = 26.0;
  const double subtitleFontSize = 20.0;
  const double headerFontSize = 16.0;
  const double subheaderFontSize = 13.0;
  const double bodyFontSize = 10.5;
  const double smallFontSize = 9.5;
  const double pageMargin = 28.0;
  const double sectionSpacing = 16.0;
  const double itemSpacing = 8.0;

  pw.MemoryImage? kammerBillede;
  try {
    final ByteData data = await rootBundle.load('assets/images/opmaaling_af_ventilatorkammer.png');
    kammerBillede = pw.MemoryImage(data.buffer.asUint8List());
  } catch (e) {
    print('Kunne ikke loade kammer-billede: $e');
  }

  // ✅ TJEK OM DET ER NYT VENTILATIONSANLÆG
  final gyldigeForslagForCheck = alleForslag.where(erGyldigtVentilatorForslag).toList();
  final bool erNytVentilationsanlaeg = gyldigeForslagForCheck.isNotEmpty &&
      gyldigeForslagForCheck.first.fabrikant.contains('Nyt Ventilationsanlæg');

  // FORSIDE
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(pageMargin),
      build: (ctx) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Intern teknisk rapport',
              style: pw.TextStyle(
                fontSize: titleFontSize,
                fontWeight: pw.FontWeight.bold,
                color: matchingBlue,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              '$anlaegsType $anlaegsNavn',
              style: pw.TextStyle(
                fontSize: subtitleFontSize,
                fontWeight: pw.FontWeight.bold,
                color: matchingBlue,
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              DateFormat('dd. MMMM yyyy', 'da_DK').format(DateTime.now()),
              style: pw.TextStyle(
                fontSize: headerFontSize,
                color: matchingBlue,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // FØR SITUATION
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(pageMargin),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: matchingGreen,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Før situation',
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: matchingBlue,
              ),
            ),
          ),
          pw.SizedBox(height: sectionSpacing),

          // ✅ TILFØJ INDIKATOR FOR NYT VENTILATIONSANLÆG
          if (erNytVentilationsanlaeg) ...[
            pw.Center(
              child: pw.Text(
                'Komplet nyt ventilationsanlæg',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: matchingBlue,
                ),
              ),
            ),
            pw.SizedBox(height: sectionSpacing),
          ],

          // Indblæsning sektion (hvis relevant)
          if (anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') ...[
            pw.Text(
              'Indblæsning',
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: itemSpacing),
            _buildDataRow('Luftmængde:', '${formatDK(luftInd)} m³/h', bodyFontSize),
            if (luftIndMax != null && luftIndMax > 0)
              _buildDataRow('Luftmængde (max):', '${formatDK(luftIndMax)} m³/h', bodyFontSize),
            if (trykFoerInd != null && trykFoerInd != 0)
              _buildDataRow('Tryk før ventilator:', '${formatDK(trykFoerInd)} Pa', bodyFontSize),
            if (trykEfterInd != null && trykEfterInd != 0)
              _buildDataRow('Tryk efter ventilator:', '${formatDK(trykEfterInd)} Pa', bodyFontSize),
            _buildDataRow('Statisk tryk (samlet):', '${formatDK(statiskTrykInd)} Pa', bodyFontSize),
            if (statiskTrykMaxInd != null && statiskTrykMaxInd > 0)
              _buildDataRow('Statisk tryk (max):', '${formatDK(statiskTrykMaxInd)} Pa', bodyFontSize),
            _buildDataRow('Effekt:', '${formatDK(kwInd, decimals: 2)} kW', bodyFontSize),
            _buildDataRow('Frekvens:', '${formatDK(hzInd, decimals: 1)} Hz', bodyFontSize),
            _buildDataRow('Virkningsgrad:', '${formatDK(virkningsgradInd, decimals: 1)} %', bodyFontSize),
            _buildDataRow('SEL-værdi:', '${formatDK(selInd, decimals: 1)} kJ/m³', bodyFontSize),
            _buildDataRow('Årligt elforbrug:', '${formatDK(elforbrugInd)} kWh', bodyFontSize),
            _buildDataRow('Omkostning:', '${formatDK(omkostningInd)} kr./år', bodyFontSize),
            pw.SizedBox(height: sectionSpacing),
          ],

          // Udsugning sektion (hvis relevant)
          if (anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') ...[
            pw.Text(
              'Udsugning',
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: itemSpacing),
            _buildDataRow('Luftmængde:', '${formatDK(luftUd)} m³/h', bodyFontSize),
            if (luftUdMax != null && luftUdMax > 0)
              _buildDataRow('Luftmængde (max):', '${formatDK(luftUdMax)} m³/h', bodyFontSize),
            if (trykFoerUd != null && trykFoerUd != 0)
              _buildDataRow('Tryk før ventilator:', '${formatDK(trykFoerUd)} Pa', bodyFontSize),
            if (trykEfterUd != null && trykEfterUd != 0)
              _buildDataRow('Tryk efter ventilator:', '${formatDK(trykEfterUd)} Pa', bodyFontSize),
            _buildDataRow('Statisk tryk (samlet):', '${formatDK(statiskTrykUd)} Pa', bodyFontSize),
            if (statiskTrykMaxUd != null && statiskTrykMaxUd > 0)
              _buildDataRow('Statisk tryk (max):', '${formatDK(statiskTrykMaxUd)} Pa', bodyFontSize),
            _buildDataRow('Effekt:', '${formatDK(kwUd, decimals: 2)} kW', bodyFontSize),
            _buildDataRow('Frekvens:', '${formatDK(hzUd, decimals: 1)} Hz', bodyFontSize),
            _buildDataRow('Virkningsgrad:', '${formatDK(virkningsgradUd, decimals: 1)} %', bodyFontSize),
            _buildDataRow('SEL-værdi:', '${formatDK(selUd, decimals: 1)} kJ/m³', bodyFontSize),
            _buildDataRow('Årligt elforbrug:', '${formatDK(elforbrugUd)} kWh', bodyFontSize),
            _buildDataRow('Omkostning:', '${formatDK(omkostningUd)} kr./år', bodyFontSize),
            pw.SizedBox(height: sectionSpacing),
          ],

          // ✅ NY: TILFØJ VARMEFORBRUG TIL FØR-SITUATION (kun for nyt ventilationsanlæg)
          if (erNytVentilationsanlaeg && varmeforbrugResultat != null && varmeforbrugResultat.harBeregning) ...[
            pw.Text(
              'Varmeforbrug',
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: itemSpacing),
            _buildDataRow('Årsforbrug:', '${formatDK(varmeforbrugResultat.varmeforbrugKWh)} kWh/år', bodyFontSize),
            _buildDataRow('Årlig omkostning:', '${formatDK(varmeforbrugResultat.varmeOmkostning)} kr./år', bodyFontSize),
            if (varmeforbrugResultat.recirkuleringProcent != null &&
                varmeforbrugResultat.recirkuleringProcent! > 0) ...[
              _buildDataRow(
                'Recirkulering:',
                '${formatDK(varmeforbrugResultat.recirkuleringProcent!, decimals: 0)} %',
                bodyFontSize,
              ),
              if (varmeforbrugResultat.varmegenvindingVirkningsgrad != null &&
                  varmeforbrugResultat.varmegenvindingVirkningsgrad! > 0)
                _buildDataRow(
                  'Varmegenvinding:',
                  '${formatDK(varmeforbrugResultat.varmegenvindingVirkningsgrad!, decimals: 0)} %',
                  bodyFontSize,
                ),
              _buildDataRow(
                varmeforbrugResultat.varmegenvindingVirkningsgrad != null && varmeforbrugResultat.varmegenvindingVirkningsgrad! > 0
                    ? 'Temp. efter blanding + genvinding:'
                    : 'Blandingstemperatur:',
                '${formatDK(varmeforbrugResultat.gennemsnitTemp, decimals: 1)} °C',
                bodyFontSize,
              ),
            ] else ...[
              _buildDataRow(
                'Målt virkningsgrad:',
                '${formatDK(varmeforbrugResultat.maaltVirkningsgrad, decimals: 1)} %',
                bodyFontSize,
              ),
              _buildDataRow(
                'Temp. efter varmegenvinding:',
                '${formatDK(varmeforbrugResultat.gennemsnitTemp, decimals: 1)} °C',
                bodyFontSize,
              ),
            ],
            pw.SizedBox(height: sectionSpacing),
          ],


          // Samlet energiforbrug
          pw.Text(
            erNytVentilationsanlaeg && varmeforbrugResultat != null && varmeforbrugResultat.harBeregning
                ? 'Samlet energiforbrug og driftsomkostning (el + varme)'
                : 'Samlet energiforbrug og driftsomkostning',
            style: pw.TextStyle(
              fontSize: subheaderFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: itemSpacing),
          _buildDataRow('Samlet elforbrug:', '${formatDK(samletFoerKWh)} kWh/år', bodyFontSize),
          _buildDataRow('Samlet el-omkostning:', '${formatDK(samletFoerKr)} kr./år', bodyFontSize),

          // ✅ NY: VIS SAMLET OMKOSTNING (EL + VARME) FOR NYT ANLÆG
          if (erNytVentilationsanlaeg && varmeforbrugResultat != null && varmeforbrugResultat.harBeregning) ...[
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 8),
            _buildDataRow(
              'SAMLET omkostning:',
              '${formatDK(samletFoerKr + varmeforbrugResultat.varmeOmkostning)} kr./år',
              bodyFontSize,
              bold: true,
            ),
          ],

          // Beregningsmetode note
          if (!erMaalteVaerdier && (beregnetDesignInd || beregnetDesignUd || erBeregnetUdFraLavHz || beregnetKVaerdiInd || beregnetKVaerdiUd)) ...[
            pw.SizedBox(height: sectionSpacing),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Den anvendte metode til beregning af luftmængden fremgår nedenfor.',
                    style: pw.TextStyle(
                      fontSize: subheaderFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  if (beregnetDesignInd || beregnetDesignUd) ...[
                    pw.Text(
                      'Luftmængde beregnet ud fra designdata${(beregnetDesignInd && beregnetDesignUd)
                              ? ''
                              : beregnetDesignUd
                              ? ' (kun udsugning)'
                              : ' (kun indblæsning)'}',
                      style: pw.TextStyle(fontSize: bodyFontSize, color: PdfColors.red),
                    ),
                  ],
                  if (erBeregnetUdFraLavHz) ...[
                    pw.Text(
                      'Frekvensen er under 30 Hz - luftmængde estimeret',
                      style: pw.TextStyle(fontSize: bodyFontSize, color: PdfColors.red),
                    ),
                  ],
                  if (beregnetKVaerdiInd || beregnetKVaerdiUd) ...[
                    pw.Text(
                      'Luftmængden er beregnet ud fra K-værdi${(beregnetKVaerdiInd && beregnetKVaerdiUd)
                              ? ' (indblæsning og udsugning)'
                              : beregnetKVaerdiUd
                              ? ' (kun udsugning)'
                              : ' (kun indblæsning)'}',
                      style: pw.TextStyle(fontSize: bodyFontSize, color: PdfColors.red),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // VENTILATORFORSLAG SIDER
  final List<VentilatorOekonomiSamlet> gyldigeResultater = alleForslag
      .where((r) => erGyldigtVentilatorForslag(r))
      .toList();

  gyldigeResultater.sort((a, b) {
    final ecoA = a.oekonomi as OekonomiResultat;
    final ecoB = b.oekonomi as OekonomiResultat;
    return ecoA.tilbagebetalingstid.compareTo(ecoB.tilbagebetalingstid);
  });

  final int antalGyldige = gyldigeResultater.length;

  if (antalGyldige > 0) {
    for (int i = 0; i < gyldigeResultater.length; i++) {
      final resultat = gyldigeResultater[i];
      final eco = resultat.oekonomi as OekonomiResultat;

      // ✅ REDUCERET SPACING FOR NYT VENTILATIONSANLÆG
      final bool erNytAnlaeg = resultat.fabrikant.contains('Nyt Ventilationsanlæg');
      final double reducedSpacing = erNytAnlaeg ? 6.0 : sectionSpacing;
      final double reducedItemSpacing = erNytAnlaeg ? 3.0 : itemSpacing;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(pageMargin),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: erNytAnlaeg
                    ? const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                    : const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: i == 0 ? matchingGreen : PdfColor.fromInt(0xFFE0E0E0),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  resultat.fabrikant.contains('Nyt Ventilationsanlæg')
                      ? 'NYT VENTILATIONSANLÆG'
                      : 'OPTIMERINGSFORSLAG ${i + 1}',
                  style: pw.TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: matchingBlue,
                  ),
                ),
              ),
              pw.SizedBox(height: reducedSpacing),

              // ✅ FJERN EKSTRA FABRIKANT-TEKST FOR NYT ANLÆG
              if (!erNytAnlaeg) ...[
                pw.Text(
                  resultat.fabrikant,
                  style: pw.TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: matchingBlue,
                  ),
                ),
                pw.SizedBox(height: sectionSpacing),
              ],

              // Indblæsning
              if ((anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
                  resultat.indNormal.varenummer.isNotEmpty) ...[
                pw.Text(
                  'Efter optimering  Indblæsning',
                  style: pw.TextStyle(
                    fontSize: subheaderFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: reducedItemSpacing),
                _buildDataRow('Varenummer:', resultat.indNormal.varenummer, bodyFontSize, bold: true),
                _buildDataRow('Årligt elforbrug:', '${formatDK(resultat.indNormal.aarsforbrugKWh)} kWh', bodyFontSize),
                _buildDataRow('Omkostning:', '${formatDK(resultat.indNormal.omkostning)} kr./år', bodyFontSize),
                _buildDataRow('Effekt:', '${formatDK(resultat.indNormal.effekt / 1000, decimals: 2)} kW', bodyFontSize),
                _buildDataRow('Tryk:', '${formatDK(resultat.indNormal.tryk)} Pa', bodyFontSize),
                _buildDataRow('Luftmængde:', '${formatDK(resultat.indNormal.luftmaengde)} m³/h', bodyFontSize),
                _buildDataRow('Virkningsgrad:', '${formatDK(resultat.indNormal.virkningsgrad, decimals: 1)} %', bodyFontSize),
                _buildDataRow('SEL-værdi:', '${formatDK(resultat.indNormal.selvaerdi, decimals: 1)} kJ/m³', bodyFontSize),

                if (resultat.indMax.varenummer.isNotEmpty &&
                    resultat.indMax.luftmaengde > 0 &&
                    resultat.indMax.tryk > 0) ...[
                  pw.SizedBox(height: reducedItemSpacing),
                  if (resultat.indMax.varenummer != resultat.indNormal.varenummer) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFFFEBEE),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bemærk: Kræver anden ventilator ved maksimal drift',
                            style: pw.TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Ved maksimal drift:',
                            style: pw.TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          _buildDataRow('Varenummer:', resultat.indMax.varenummer, smallFontSize, bold: true),
                          _buildDataRow('Luftmængde:', '${formatDK(resultat.indMax.luftmaengde)} m³/h', smallFontSize),
                          _buildDataRow('Tryk:', '${formatDK(resultat.indMax.tryk)} Pa', smallFontSize),
                        ],
                      ),
                    ),
                  ] else if (!resultat.fabrikant.contains('Nyt Ventilationsanlæg')) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE8F5E9),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'Ventilatoren kan klare begge driftspunkter',
                        style: pw.TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                    ),
                  ],
                ],
                pw.SizedBox(height: reducedSpacing),
              ],

              // Udsugning
              if ((anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
                  resultat.udNormal.varenummer.isNotEmpty) ...[
                pw.Text(
                  'Efter optimering  Udsugning',
                  style: pw.TextStyle(
                    fontSize: subheaderFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: reducedItemSpacing),
                _buildDataRow('Varenummer:', resultat.udNormal.varenummer, bodyFontSize, bold: true),
                _buildDataRow('Årligt elforbrug:', '${formatDK(resultat.udNormal.aarsforbrugKWh)} kWh', bodyFontSize),
                _buildDataRow('Omkostning:', '${formatDK(resultat.udNormal.omkostning)} kr./år', bodyFontSize),
                _buildDataRow('Effekt:', '${formatDK(resultat.udNormal.effekt / 1000, decimals: 2)} kW', bodyFontSize),
                _buildDataRow('Tryk:', '${formatDK(resultat.udNormal.tryk)} Pa', bodyFontSize),
                _buildDataRow('Luftmængde:', '${formatDK(resultat.udNormal.luftmaengde)} m³/h', bodyFontSize),
                _buildDataRow('Virkningsgrad:', '${formatDK(resultat.udNormal.virkningsgrad, decimals: 1)} %', bodyFontSize),
                _buildDataRow('SEL-værdi:', '${formatDK(resultat.udNormal.selvaerdi, decimals: 1)} kJ/m³', bodyFontSize),

                if (resultat.udMax.varenummer.isNotEmpty &&
                    resultat.udMax.luftmaengde > 0 &&
                    resultat.udMax.tryk > 0) ...[
                  pw.SizedBox(height: reducedItemSpacing),
                  if (resultat.udMax.varenummer != resultat.udNormal.varenummer) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFFFEBEE),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bemærk: Kræver anden ventilator ved maksimal drift',
                            style: pw.TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Ved maksimal drift:',
                            style: pw.TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          _buildDataRow('Varenummer:', resultat.udMax.varenummer, smallFontSize, bold: true),
                          _buildDataRow('Luftmængde:', '${formatDK(resultat.udMax.luftmaengde)} m³/h', smallFontSize),
                          _buildDataRow('Tryk:', '${formatDK(resultat.udMax.tryk)} Pa', smallFontSize),
                        ],
                      ),
                    ),
                  ] else if (!resultat.fabrikant.contains('Nyt Ventilationsanlæg')) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE8F5E9),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'Ventilatoren kan klare begge driftspunkter',
                        style: pw.TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                    ),
                  ],
                ],
                pw.SizedBox(height: sectionSpacing),
              ],

              // ✅ NY: TILFØJ VARMEFORBRUG EFTER OPTIMERING (kun for nyt ventilationsanlæg)
              if (resultat.fabrikant.contains('Nyt Ventilationsanlæg') &&
                  varmeforbrugResultat != null &&
                  varmeforbrugResultat.harBeregning &&
                  varmeforbrugResultat.optimering != null) ...[
                pw.Text(
                  'Efter optimering  Varmeforbrug',
                  style: pw.TextStyle(
                    fontSize: subheaderFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: itemSpacing),
                _buildDataRow(
                  'Nyt varmeforbrug:',
                  '${formatDK(varmeforbrugResultat.optimering!.nytVarmeforbrugKWh ?? 0)} kWh/år',
                  bodyFontSize,
                ),
                _buildDataRow(
                  'Ny omkostning:',
                  '${formatDK(varmeforbrugResultat.optimering!.nytVarmeforbrugKr ?? 0)} kr./år',
                  bodyFontSize,
                ),
                _buildDataRow(
                  'Ny virkningsgrad:',
                  '${formatDK(varmeforbrugResultat.optimering!.nyVirkningsgrad, decimals: 1)} %',
                  bodyFontSize,
                ),
                pw.SizedBox(height: reducedSpacing),
              ],

              // ØKONOMI (altid på første side)
              pw.Container(
                padding: erNytAnlaeg ? const pw.EdgeInsets.all(6) : const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: i == 0 ? PdfColor.fromInt(0xFFE8F9F3) : PdfColor.fromInt(0xFFF5F5F5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Økonomi',
                      style: pw.TextStyle(
                        fontSize: subheaderFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: reducedItemSpacing),

                    if (eco.indPris > 0)
                      _buildDataRow('Indblæsningsventilator:', '${formatDK(eco.indPris)} kr.', bodyFontSize),
                    if (eco.udPris > 0)
                      _buildDataRow('Udsugningsventilator:', '${formatDK(eco.udPris)} kr.', bodyFontSize),
                    if ((resultat.remUdskiftningPris ?? 0) > 0)
                      _buildDataRow('Fradrag (rem og skiver):', '-${formatDK(resultat.remUdskiftningPris ?? 0)} kr.', bodyFontSize),
                    pw.SizedBox(height: reducedItemSpacing),
                    pw.Divider(thickness: 1.5),
                    pw.SizedBox(height: erNytAnlaeg ? 3 : 8),
                    _buildDataRow('Pris total:', '${formatDK(eco.totalPris)} kr.', bodyFontSize, bold: true),
                    pw.SizedBox(height: reducedItemSpacing),

                    ...(() {
                      final gyldigeForslag = alleForslag.where(erGyldigtVentilatorForslag).toList();
                      final bool erNytVentilationsanlaeg = gyldigeForslag.isNotEmpty &&
                          gyldigeForslag.first.fabrikant.contains('Nyt Ventilationsanlæg');
                      final bool harVarmeberegning = varmeforbrugResultat != null &&
                          varmeforbrugResultat.harBeregning &&
                          varmeforbrugResultat.optimering != null;
                      final double varmeBesparelseKr = (erNytVentilationsanlaeg && harVarmeberegning)
                          ? ((varmeforbrugResultat.varmeOmkostning.toDouble() ?? 0) -
                          (varmeforbrugResultat.optimering?.nytVarmeforbrugKr?.toDouble() ?? 0))
                          : 0;
                      final double samletBesparelseKr = eco.aarsbesparelse + varmeBesparelseKr;
                      final double korrektTilbagebetalingstid = samletBesparelseKr > 0
                          ? eco.totalPris / samletBesparelseKr
                          : 0;

                      return [
                        if (erNytVentilationsanlaeg && varmeBesparelseKr > 0) ...[
                          _buildDataRow('Ventilatorbesparelse:', '${formatDK(eco.aarsbesparelse)} kr./år', bodyFontSize),
                          _buildDataRow('Varmebesparelse:', '${formatDK(varmeBesparelseKr)} kr./år', bodyFontSize),
                          pw.SizedBox(height: erNytAnlaeg ? 3 : 8),
                          pw.Divider(thickness: 1.5),
                          pw.SizedBox(height: erNytAnlaeg ? 3 : 8),
                          _buildDataRow('Samlet besparelse:', '${formatDK(samletBesparelseKr)} kr./år', bodyFontSize, bold: true),
                        ] else ...[
                          _buildDataRow('Økonomisk besparelse:', '${formatDK(eco.aarsbesparelse)} kr./år', bodyFontSize, bold: true),
                        ],
                        _buildDataRow(
                          'Tilbagebetalingstid:',
                          '${formatDK(erNytVentilationsanlaeg && varmeBesparelseKr > 0 ? korrektTilbagebetalingstid : eco.tilbagebetalingstid, decimals: 1)} år',
                          bodyFontSize,
                          bold: true,
                        ),
                      ];
                    })(),
                  ],
                ),
              ),
              pw.SizedBox(height: reducedSpacing),

              pw.Text(
                erNytAnlaeg && varmeforbrugResultat != null && varmeforbrugResultat.harBeregning
                    ? 'Samlet energiforbrug og driftsomkostning (el + varme)'
                    : 'Samlet energiforbrug og driftsomkostning',
                style: pw.TextStyle(
                  fontSize: subheaderFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: reducedItemSpacing),
              _buildDataRow(
                'Samlet elforbrug:',
                '${formatDK(resultat.indNormal.aarsforbrugKWh + resultat.udNormal.aarsforbrugKWh)} kWh/år',
                bodyFontSize,
              ),
              _buildDataRow(
                erNytAnlaeg && varmeforbrugResultat != null && varmeforbrugResultat.harBeregning
                    ? 'Samlet el-omkostning:'
                    : 'Samlet omkostning:',
                '${formatDK(resultat.indNormal.omkostning + resultat.udNormal.omkostning)} kr./år',
                bodyFontSize,
              ),

              // ✅ TILFØJ VARMEFORBRUG FOR NYT VENTILATIONSANLÆG
              if (erNytAnlaeg &&
                  varmeforbrugResultat != null &&
                  varmeforbrugResultat.harBeregning &&
                  varmeforbrugResultat.optimering != null) ...[
                _buildDataRow(
                  'Varmeforbrug:',
                  '${formatDK(varmeforbrugResultat.optimering!.nytVarmeforbrugKWh ?? 0)} kWh/år',
                  bodyFontSize,
                ),
                _buildDataRow(
                  'Varmeomkostning:',
                  '${formatDK(varmeforbrugResultat.optimering!.nytVarmeforbrugKr ?? 0)} kr./år',
                  bodyFontSize,
                ),
                pw.SizedBox(height: erNytAnlaeg ? 5 : 8),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: erNytAnlaeg ? 5 : 8),
                _buildDataRow(
                  'SAMLET omkostning:',
                  '${formatDK((resultat.indNormal.omkostning + resultat.udNormal.omkostning) + (varmeforbrugResultat.optimering!.nytVarmeforbrugKr ?? 0))} kr./år',
                  bodyFontSize,
                  bold: true,
                ),
              ],
            ],

          ),
        ),
      );
    }
// ✅ VIS KUN "MANGLENDE STANDARDLØSNINGER" HVIS IKKE NYT VENTILATIONSANLÆG
    final bool erNytVentAnlaeg = gyldigeResultater.isNotEmpty &&
        gyldigeResultater.first.fabrikant.contains('Nyt Ventilationsanlæg');

    if (antalGyldige < 3 && !erNytVentAnlaeg) {
      final alleFabrikanter = ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
      final gyldigeFabrikanter = gyldigeResultater.map((f) => f.fabrikant).toSet();
      final manglenedFabrikanter = alleFabrikanter
          .where((f) => !gyldigeFabrikanter.contains(f))
          .toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(pageMargin),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE3F2FD),
                  border: pw.Border.all(color: PdfColors.blue, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          '',
                          style: pw.TextStyle(
                            fontSize: 24,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Text(
                            'MANGLENDE STANDARDLØSNINGER',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          antalGyldige == 1
                              ? 'For dette anlæg har vi kun kunnet finde standardløsning fra én leverandør.'
                              : 'For dette anlæg har vi ikke kunnet finde standardløsning fra\n${manglenedFabrikanter.join(', ')}.',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          antalGyldige == 1
                              ? 'De øvrige leverandører (${manglenedFabrikanter.join(', ')}) kan kontaktes direkte for\nskræddersyede løsninger tilpasset anlæggets specifikke behov.'
                              : 'Leverandørerne kan kontaktes direkte for et skræddersyet tilbud.',
                          style: pw.TextStyle(fontSize: 9.5),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Indhent tilbud fra leverandørerne og præsenter kundens behov.',  // ✅ INTERN VEJLEDNING
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // VARMEFORBRUG SIDE (kun hvis IKKE nyt ventilationsanlæg)
  if (varmeforbrugResultat != null && varmeforbrugResultat.harBeregning && !erNytVentilationsanlaeg) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMargin),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: matchingGreen,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'VARMEFORBRUG',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: matchingBlue,
                ),
              ),
            ),
            pw.SizedBox(height: sectionSpacing),

            pw.Text(
              'Før optimering',
              style: pw.TextStyle(
                fontSize: subheaderFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: itemSpacing),

            _buildDataRow(
              'Årsforbrug:',
              '${formatDK(varmeforbrugResultat.varmeforbrugKWh)} kWh/år',
              bodyFontSize,
            ),
            _buildDataRow(
              'Årlig omkostning:',
              '${formatDK(varmeforbrugResultat.varmeOmkostning)} kr./år',
              bodyFontSize,
            ),
            _buildDataRow(
              'Målt virkningsgrad:',
              '${formatDK(varmeforbrugResultat.maaltVirkningsgrad, decimals: 1)} %',
              bodyFontSize,
            ),
// ✅ NY: Vekslertype og målte temperaturer
            if (varmeforbrugResultat.varmegenvindingsType != null &&
                varmeforbrugResultat.varmegenvindingsType!.isNotEmpty)
              _buildDataRow('Vekslertype:', varmeforbrugResultat.varmegenvindingsType!, bodyFontSize),
            if (varmeforbrugResultat.friskluftTemp != null && varmeforbrugResultat.friskluftTemp! != 0)
              _buildDataRow('Frisklufttemperatur:', '${formatDK(varmeforbrugResultat.friskluftTemp!, decimals: 1)} °C', bodyFontSize),
            if (varmeforbrugResultat.tempIndEfterGenvinding != null && varmeforbrugResultat.tempIndEfterGenvinding! != 0)
              _buildDataRow('Temp. efter genvinding:', '${formatDK(varmeforbrugResultat.tempIndEfterGenvinding!, decimals: 1)} °C', bodyFontSize),
            if (varmeforbrugResultat.tempUd != null && varmeforbrugResultat.tempUd! != 0)
              _buildDataRow('Afkasttemperatur:', '${formatDK(varmeforbrugResultat.tempUd!, decimals: 1)} °C', bodyFontSize),
            _buildDataRow(
              'Temp. efter varmegenvinding:',
              '${formatDK(varmeforbrugResultat.gennemsnitTemp, decimals: 1)} °C',
              bodyFontSize,
            ),

            if (varmeforbrugResultat.optimering?.kanOptimeres ?? false) ...[
              pw.SizedBox(height: sectionSpacing),
              pw.Text(
                'Efter optimering',
                style: pw.TextStyle(
                  fontSize: subheaderFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: itemSpacing),
              _buildDataRow(
                'Nyt varmeforbrug:',
                '${formatDK(varmeforbrugResultat.optimering!.nytVarmeforbrugKWh ?? 0)} kWh/år',
                bodyFontSize,
              ),
              _buildDataRow(
                'Ny omkostning:',
                '${formatDK(varmeforbrugResultat.optimering!.nytVarmeforbrugKr ?? 0)} kr./år',
                bodyFontSize,
              ),
              _buildDataRow(
                'Ny virkningsgrad:',
                '${formatDK(varmeforbrugResultat.optimering!.nyVirkningsgrad, decimals: 1)} %',
                bodyFontSize,
              ),

              pw.SizedBox(height: sectionSpacing),
              pw.Text(
                'Besparelse',
                style: pw.TextStyle(
                  fontSize: subheaderFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: itemSpacing),
              _buildDataRow(
                'Energibesparelse:',
                '${formatDK((varmeforbrugResultat.varmeforbrugKWh - (varmeforbrugResultat.optimering!.nytVarmeforbrugKWh ?? 0)))} kWh/år',
                bodyFontSize,
              ),
              _buildDataRow(
                'Økonomisk besparelse:',
                '${formatDK((varmeforbrugResultat.varmeOmkostning - (varmeforbrugResultat.optimering!.nytVarmeforbrugKr ?? 0)))} kr./år',
                bodyFontSize,
              ),
              if ((varmeforbrugResultat.optimering!.co2Besparelse ?? 0) > 0)
                _buildDataRow(
                  'CO2-besparelse:',
                  '${formatDK(varmeforbrugResultat.optimering!.co2Besparelse ?? 0)} kg/år',
                  bodyFontSize,
                ),
            ],

            pw.SizedBox(height: sectionSpacing),

            if (varmeforbrugResultat.optimering?.kommentar != null &&
                varmeforbrugResultat.optimering!.kommentar.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF5F5F5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  varmeforbrugResultat.optimering!.kommentar,
                  style: pw.TextStyle(fontSize: bodyFontSize),
                ),
              ),
          ],
        ),
      ),
    );
  }

// ✅ NY SEPARAT TILSTANDSVURDERING SIDE (VISES ALTID)
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(pageMargin),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: matchingGreen,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'TILSTANDSVURDERING',
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: matchingBlue,
              ),
            ),
          ),
          pw.SizedBox(height: sectionSpacing),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: getTilstandsfarvePdf(valgtTilstand),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  getTilstandsbeskrivelse(valgtTilstand),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  _getTilstandsKommentar(valgtTilstand),
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],  // ✅ 1. Lukker children i pw.Column
      ),    // ✅ 2. Lukker pw.Column
    ),      // ✅ 3. Lukker pw.Page
  );        // ✅ 4. Lukker pdf.addPage

// ✅ NY: INTERN KOMMENTAR SIDE (vises kun hvis non-null og non-empty)
  if (internKommentar != null && internKommentar.trim().isNotEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMargin),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: matchingGreen,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'INTERN KOMMENTAR',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: matchingBlue,
                ),
              ),
            ),
            pw.SizedBox(height: sectionSpacing),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                internKommentar.trim(),
                style: pw.TextStyle(
                  fontSize: bodyFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
// KAMMER-MÅLINGER
  if (kammerHoede != null && kammerLaengde != null && kammerBredde != null) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMargin),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: matchingGreen,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'OPMÅLING AF VENTILATORKAMMER',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: matchingBlue,
                ),
              ),
            ),
            pw.SizedBox(height: sectionSpacing),
            if (kammerBillede != null) ...[
              pw.Center(
                child: pw.Image(kammerBillede, height: 200, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(height: sectionSpacing),
            ],
            _buildDataRow('Højde:', '${kammerHoede.toStringAsFixed(0)} mm', bodyFontSize),
            _buildDataRow('Længde:', '${kammerLaengde.toStringAsFixed(0)} mm', bodyFontSize),
            _buildDataRow('Bredde:', '${kammerBredde.toStringAsFixed(0)} mm', bodyFontSize),
          ],
        ),
      ),
    );
  }

  return await pdf.save();
}

pw.Widget _buildDataRow(String label, String value, double fontSize, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 145,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

// ✅ NY HELPER FUNKTION FOR TILSTANDSKOMMENTARER
String _getTilstandsKommentar(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return 'Da anlægget er i god stand, er det oplagt at gennemføre en energioptimering,\n\n'
          'da investeringen kan udnyttes fuldt ud og skabe størst mulig værdi.';
    case '2':
      return 'Anlægget er i rimelig stand med mindre slitage registreret.\n\n'
          'Det kan fortsat fungere uden større problemer, men en energioptimering kan være fordelagtig\n'
          'for at reducere driftsomkostninger og forlænge levetiden.';
    case '3':
      return 'Anlægget er slidt og har en restlevetid på 1 til 3 år.\n\n'
          'Det bør vurderes, om en renovering kan forlænge levetiden,\n'
          'eller om en udskiftning er mere hensigtsmæssig.\n\n'
          'Ved begge løsninger bør energioptimering indgå som en naturlig del af indsatsen.';
    case '4':
      return 'Anlægget er i kritisk stand og bør udskiftes eller gennemgå en større renovering\n'
          'inden for det næste år.\n\n'
          'Det anbefales at planlægge indsatsen i god tid og samtidig inddrage energioptimering\n'
          'som en central del af løsningen.';
    case '5':
      return 'Anlægget er i meget kritisk stand og kræver en større indsats.\n\n'
          'Der bør planlægges omfattende renovering eller udskiftning,\n'
          'hvor energioptimering indgår som en del af løsningen.';
    case '6':
      return 'Anlægget er ikke længere funktionsdygtigt og skal udskiftes.\n\n'
          'I forbindelse med udskiftningen anbefales det at vælge en løsning\n'
          'med fokus på energioptimering.';
    default:
      return '';
  }
}