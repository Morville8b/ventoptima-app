import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:ventoptima/anlaegs_data.dart';
import 'package:ventoptima/generel_projekt_info.dart';
import 'package:ventoptima/filter_resultat.dart';
import 'dart:math' as math;

class RapportFilter {
  static Future<List<pw.Widget>> genererFilterSider(
      AnlaegsData anlaeg,
      GenerelProjektInfo projektInfo,
      pw.Font regularFont,
      pw.Font boldFont,
      ) async {
    final List<pw.Widget> sider = [];

    final int totalFiltreInd =
        (anlaeg.antalHeleFiltreInd ?? 0) + (anlaeg.antalHalveFiltreInd ?? 0);
    final int totalFiltreUd =
        (anlaeg.antalHeleFiltreUd ?? 0) + (anlaeg.antalHalveFiltreUd ?? 0);

    final resultat = beregnFilterResultat(
      antalFiltreInd: totalFiltreInd,
      antalFiltreUd: totalFiltreUd,
      kwInd: anlaeg.kwInd ?? 0,
      kwUd: anlaeg.kwUd ?? 0,
      elPris: anlaeg.elpris ?? 1.2,
      trykGamleFiltreInd: anlaeg.trykGamleFiltreInd ?? 0,
      trykGamleFiltreUd: anlaeg.trykGamleFiltreUd ?? 0,
      luftInd: anlaeg.luftInd,
      luftUd: anlaeg.luftUd,
      driftstimer: anlaeg.driftstimer,
      virkningsgradInd: anlaeg.virkningsgradInd,
      virkningsgradUd: anlaeg.virkningsgradUd,
      filterFoerInd: anlaeg.filterValg?.filterFoerInd,
      filterFoerUd: anlaeg.filterValg?.filterFoerUd,
    );

    if (anlaeg.filterValg == null || resultat == null) {
      return sider;
    }

    // 🔹 Find filterklasse automatisk
    final filterFoerInd = anlaeg.filterValg?.filterFoerInd ?? '';
    String filterKlasse = 'F7';
    if (filterFoerInd.contains('M5')) {
      filterKlasse = 'M5';
    } else if (filterFoerInd.contains('F9')) {
      filterKlasse = 'F9';
    }

    // 🔹 Luft per filter
    final double luftPerFilterInd =
        (anlaeg.luftInd ?? 5000) / (totalFiltreInd > 0 ? totalFiltreInd : 1);
    final double luftPerFilterUd =
        (anlaeg.luftUd ?? 5000) / (totalFiltreUd > 0 ? totalFiltreUd : 1);

    final bool indOK = luftPerFilterInd <= 3400;
    final bool udOK = luftPerFilterUd <= 3400;

    // 🔹 Efter-filtre
    final efterFilter520 = "Hiflo XLT $filterKlasse 592 x 592 x 520";
    final efterFilter640 = "Hiflo XLT $filterKlasse 592 x 592 x 640";

    // 🔹 Tryktab og energiforbrug som i appen
    double beregnTryktab(String filterNavn, double luftPerFilter) {
      switch (filterNavn) {
        case "Hiflo XLT M5 592 x 592 x 520":
          return 0.00004 * math.pow(luftPerFilter, 1.7032);
        case "Hiflo XLT M5 592 x 592 x 640":
          return 0.00001 * math.pow(luftPerFilter, 1.8578);
        case "Hiflo XLT F7 592 x 592 x 520":
          return 0.0004 * math.pow(luftPerFilter, 1.5109);
        case "Hiflo XLT F7 592 x 592 x 640":
          return 0.0006 * math.pow(luftPerFilter, 1.4364);
        default:
          return 0.0;
      }
    }

    double beregnEnergiforbrugVBA(
        double tryktab, double luft, double timer, double virkningsgrad) {
      return (luft / 3600) *
          tryktab *
          timer /
          ((virkningsgrad / 100) * 1000);
    }

    final tryktabXLT520Ind = beregnTryktab(efterFilter520, luftPerFilterInd);
    final tryktabXLT520Ud = beregnTryktab(efterFilter520, luftPerFilterUd);
    final tryktabXLT640Ind = beregnTryktab(efterFilter640, luftPerFilterInd);
    final tryktabXLT640Ud = beregnTryktab(efterFilter640, luftPerFilterUd);

    final energiXLT520Ind = beregnEnergiforbrugVBA(
        tryktabXLT520Ind,
        anlaeg.luftInd ?? 0,
        anlaeg.driftstimer ?? 8760,
        anlaeg.virkningsgradInd ?? 70);
    final energiXLT520Ud = beregnEnergiforbrugVBA(
        tryktabXLT520Ud,
        anlaeg.luftUd ?? 0,
        anlaeg.driftstimer ?? 8760,
        anlaeg.virkningsgradUd ?? 70);
    final energiXLT640Ind = beregnEnergiforbrugVBA(
        tryktabXLT640Ind,
        anlaeg.luftInd ?? 0,
        anlaeg.driftstimer ?? 8760,
        anlaeg.virkningsgradInd ?? 70);
    final energiXLT640Ud = beregnEnergiforbrugVBA(
        tryktabXLT640Ud,
        anlaeg.luftUd ?? 0,
        anlaeg.driftstimer ?? 8760,
        anlaeg.virkningsgradUd ?? 70);

    final samletEnergiXLT520 = energiXLT520Ind + energiXLT520Ud;
    final samletEnergiXLT640 = energiXLT640Ind + energiXLT640Ud;

    final besparelseXLT520 =
        (resultat.energiFoerInd + resultat.energiFoerUd) - samletEnergiXLT520;
    final besparelseXLT640 =
        (resultat.energiFoerInd + resultat.energiFoerUd) - samletEnergiXLT640;

    // 🔹 Priser
    final nuvaerenderPrisInd =
    hentFilterPris(anlaeg.filterValg?.filterFoerInd);
    final nuvaerenderPrisUd =
    hentFilterPris(anlaeg.filterValg?.filterFoerUd);
    final xlt520Pris = hentFilterPris(efterFilter520);
    final xlt640Pris = hentFilterPris(efterFilter640);

    // 🔹 Kammercheck
    final bool kammerForLille =
        (anlaeg.filterValg?.filterMaalIndMm ?? 1000) < 645 ||
            (anlaeg.filterValg?.filterMaalUdMm ?? 1000) < 645;

    // 🔹 Indlæs billeder
    pw.ImageProvider? camfilLogo;
    pw.ImageProvider? bravidaLogo;
    pw.ImageProvider? filterBillede;
    try {
      final logoData =
      await rootBundle.load('assets/images/camfil_logo.png');
      camfilLogo = pw.MemoryImage(logoData.buffer.asUint8List());
      final bravidaData = await rootBundle
          .load('assets/images/bravida_logo_rgb_pos.png');
      bravidaLogo = pw.MemoryImage(bravidaData.buffer.asUint8List());
      final filterData =
      await rootBundle.load('assets/images/filter.png');
      filterBillede = pw.MemoryImage(filterData.buffer.asUint8List());
    } catch (_) {}

    // 🔹 Opbyg PDF-side
    sider.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${anlaeg.valgtAnlaegstype} - ${anlaeg.anlaegsNavn}',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 13,
                      color: PdfColor.fromHex('#006390'))),
              if (bravidaLogo != null)
                pw.Image(bravidaLogo, height: 30),
            ],
          ),
          pw.Container(
              width: double.infinity,
              height: 1,
              color: PdfColor.fromHex('#34E0A1')),
          pw.SizedBox(height: 6),
          pw.Text('FILTEROPTIMERING',
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColor.fromHex('#006390'))),
          pw.SizedBox(height: 13),

          // Før-situationen
          pw.Text('FØR-situationen',
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColor.fromHex('#006390'))),
          pw.SizedBox(height: 6),

          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: PdfColor.fromHex('#34E0A1'), width: 2),
              borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nuværende filtre:',
                          style: pw.TextStyle(
                              font: boldFont, fontSize: 9)),
                      pw.SizedBox(height: 3),
                      _buildBulletPoint(
                          'Indblæsning: ${anlaeg.filterValg?.filterFoerInd ?? '-'}',
                          regularFont),
                      _buildBulletPoint(
                          'Udsugning: ${anlaeg.filterValg?.filterFoerUd ?? '-'}',
                          regularFont),
                      pw.SizedBox(height: 6),
                      _buildBulletPoint(
                          'Elforbrug (indblæsning): ${_formatTal(resultat.energiFoerInd)} kWh/år',
                          regularFont),
                      _buildBulletPoint(
                          'Elforbrug (udsugning): ${_formatTal(resultat.energiFoerUd)} kWh/år',
                          regularFont),
                      pw.SizedBox(height: 4),
                      _buildBulletPoint(
                          'Samlet elforbrug: ${_formatTal(resultat.energiFoerInd + resultat.energiFoerUd)} kWh/år',
                          regularFont),
                      _buildBulletPoint(
                          'Samlet omkostning: ${_formatTal((resultat.energiFoerInd + resultat.energiFoerUd) * (anlaeg.elpris ?? 1.2))} kr./år',
                          regularFont),
                    ],
                  ),
                ),
                if (filterBillede != null)
                  pw.Expanded(
                    flex: 2,
                    child: pw.Padding(
                      padding:
                      const pw.EdgeInsets.only(left: 12),
                      child: pw.Image(filterBillede,
                          fit: pw.BoxFit.contain, height: 130),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // Efter-situationen
          pw.Text('EFTER-situationen',
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColor.fromHex('#006390'))),
          pw.SizedBox(height: 6),

          if (kammerForLille) ...[
            _buildScenarie(
                'Scenarie 1 - Hiflo XLT $filterKlasse 520',
                samletEnergiXLT520,
                besparelseXLT520,
                xlt520Pris *
                    (totalFiltreInd + totalFiltreUd) -
                    (nuvaerenderPrisInd * totalFiltreInd +
                        nuvaerenderPrisUd * totalFiltreUd),
                anlaeg.elpris ?? 1.2,
                regularFont,
                boldFont,
                camfilLogo),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF3E0'),
                border: pw.Border.all(
                    color: PdfColor.fromHex('#FF9800'),
                    width: 2),
                borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                  'Filterkammeret er for lille til 640 mm filtre. '
                      'Minimum krævet: 645 mm.',
                  style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 7,
                      color: PdfColors.black)),
            ),
          ] else ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildScenarie(
                      'Scenarie 1 - Hiflo XLT $filterKlasse 520',
                      samletEnergiXLT520,
                      besparelseXLT520,
                      xlt520Pris *
                          (totalFiltreInd + totalFiltreUd) -
                          (nuvaerenderPrisInd *
                              totalFiltreInd +
                              nuvaerenderPrisUd *
                                  totalFiltreUd),
                      anlaeg.elpris ?? 1.2,
                      regularFont,
                      boldFont,
                      camfilLogo),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildScenarie(
                      'Scenarie 2 - Hiflo XLT $filterKlasse 640',
                      samletEnergiXLT640,
                      besparelseXLT640,
                      xlt640Pris *
                          (totalFiltreInd + totalFiltreUd) -
                          (nuvaerenderPrisInd *
                              totalFiltreInd +
                              nuvaerenderPrisUd *
                                  totalFiltreUd),
                      anlaeg.elpris ?? 1.2,
                      regularFont,
                      boldFont,
                      camfilLogo),
                ),
              ],
            ),
          ],

          pw.SizedBox(height: 15),

// 🔹 Tilføj vurdering af filterudskiftningsinterval og tekniske detaljer
          pw.SizedBox(height: 15),

          pw.Text(
            'Besparelsesforslaget er udarbejdet på baggrund af beregninger fra filterproducenter. '
                'De viste forslag repræsenterer den bedste energieffektivitet vs. omkostning.',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 7,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 20),

// 🔹 TEKNISKE DETALJER OG KONTROL
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#34E0A1'), width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Grøn topbjælke med blå tekst
                pw.Container(
                  width: double.infinity,
                  color: PdfColor.fromHex('#34E0A1'),
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'TEKNISKE DETALJER OG KONTROL',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9,
                      color: PdfColor.fromHex('#006390'), // Bravida blå
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 10),

                // KASSE 1 - Luftmængde kontrol
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#34E0A1'), width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Luftmængde kontrol',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                          color: PdfColor.fromHex('#006390'),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: indOK ? PdfColors.green : PdfColors.red,  // ✅ ÆNDRET
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            indOK
                                ? 'Luftmængde pr. filter (Indblæsning) er indenfor anbefalingen'
                                : 'Luftmængde pr. filter (Indblæsning) er uden for anbefalingen',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 9,
                              color: indOK ? PdfColors.black : PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: udOK ? PdfColors.green : PdfColors.red,  // ✅ ÆNDRET
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            udOK
                                ? 'Luftmængde pr. filter (Udsugning) er indenfor anbefalingen'
                                : 'Luftmængde pr. filter (Udsugning) er uden for anbefalingen',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 9,
                              color: udOK ? PdfColors.black : PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // KASSE 2 - Filter udskiftningsinterval
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#34E0A1'), width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Filter udskiftningsinterval',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                          color: PdfColor.fromHex('#006390'),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _filterUdskiftningsVurderingUdenKasserPdf(
                          anlaeg, resultat, regularFont),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

        ],
      ),
    );

    return sider;
  }

// 🔹 Hjælpefunktioner
  static pw.Widget _buildBulletPoint(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('-',
              style:
              pw.TextStyle(font: font, fontSize: 8, color: PdfColors.black)),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: 8)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildScenarie(
      String overskrift,
      double energiforbrug,
      double besparelse,
      double filteromkostning,
      double elpris,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.ImageProvider? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#34E0A1'), width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            height: 50,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: logo != null
                ? pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            )
                : pw.Container(),
          ),
          pw.SizedBox(height: 8),
          pw.Text(overskrift,
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: PdfColor.fromHex('#006390')),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 8),
          if (besparelse > 0) ...[
            _buildBulletPoint(
                'El-besparelse: ${_formatTal(besparelse)} kWh/år', regularFont),
            _buildBulletPoint(
                'Økonomisk besparelse: ${_formatTal(besparelse * elpris)} kr/år',
                regularFont),
          ],
          _buildBulletPoint(
              'Elforbrug: ${_formatTal(energiforbrug)} kWh/år', regularFont),
          _buildBulletPoint(
              'Elomkostning: ${_formatTal(energiforbrug * elpris)} kr/år',
              regularFont),
          _buildBulletPoint(
              'Øgede filteromkostninger: ${_formatTal(filteromkostning)} kr/år',
              regularFont),
        ],
      ),
    );
  }

  static String _formatTal(double value, {int decimals = 0}) {
    String numStr = value.toStringAsFixed(decimals);
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 && decimals > 0 ? parts[1] : '';
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) formattedInteger += '.';
      formattedInteger += integerPart[i];
    }
    return decimalPart.isNotEmpty
        ? '$formattedInteger,$decimalPart'
        : formattedInteger;
  }

// 🔹 Tilføjet: PDF-version af filterudskiftningsvurdering uden kasser
  static pw.Widget _filterUdskiftningsVurderingUdenKasserPdf(
      AnlaegsData anlaeg, FilterResultat resultat, pw.Font regularFont) {
    final int totalFiltreInd =
    ((anlaeg.antalHeleFiltreInd ?? 0) +
        ((anlaeg.antalHalveFiltreInd ?? 0) / 2))
        .ceil();
    final int totalFiltreUd =
    ((anlaeg.antalHeleFiltreUd ?? 0) +
        ((anlaeg.antalHalveFiltreUd ?? 0) / 2))
        .ceil();

    final double luftPerFilterInd =
        (anlaeg.luftInd ?? 5000) / (totalFiltreInd > 0 ? totalFiltreInd : 1);
    final double luftPerFilterUd =
        (anlaeg.luftUd ?? 5000) / (totalFiltreUd > 0 ? totalFiltreUd : 1);

    double beregnStartTryktab(String? filterNavn, double luftPerFilter) {
      if (filterNavn == null || luftPerFilter <= 0) return 0.0;
      final key = filterNavn.trim();
      switch (key) {
        case "Basic-Flo M5 G 1050 592 x 592 x 520":
          return 0.003 * math.pow(luftPerFilter, 1.25);
        case "Basic-Flo F7 G 2570 592 x 592 x 520":
          return 0.0045 * math.pow(luftPerFilter, 1.2548);
        case "Hiflo XLT F7 592 x 592 x 520":
          return 0.002 * math.pow(luftPerFilter, 1.3);
        default:
          return 0.0045 * math.pow(luftPerFilter, 1.2548);
      }
    }

    final double N38 =
    beregnStartTryktab(anlaeg.filterValg?.filterFoerInd, luftPerFilterInd);
    final double N45 =
    beregnStartTryktab(anlaeg.filterValg?.filterFoerUd, luftPerFilterUd);

    final double N39 = N38 * 2;
    final double N40 = N38 + 100;
    final double N46 = N45 * 2;
    final double N47 = N45 + 100;

    final double taerskelInd = N39 > N40 ? N39 : N40;
    final double taerskelUd = N46 > N47 ? N46 : N47;

    final double H5 = anlaeg.trykGamleFiltreInd ?? 0;
    final double H12 = anlaeg.trykGamleFiltreUd ?? 0;

    final bool indOK = H5 <= taerskelInd;
    final bool udOK = H12 <= taerskelUd;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                color: indOK ? PdfColors.green : PdfColors.red,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                indOK
                    ? "OK tidsinterval for filter udskiftning (Indblæsning)"
                    : "Filter bør udskiftes oftere (Indblæsning)",
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: indOK ? PdfColors.black: PdfColors.red,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                color: udOK ? PdfColors.green : PdfColors.red,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                udOK
                    ? "OK tidsinterval for filter udskiftning (Udsugning)"
                    : "Filter bør udskiftes oftere (Udsugning)",
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: udOK ? PdfColors.black : PdfColors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static double hentFilterPris(String? filterNavn) {
  if (filterNavn == null) return 0.0;
  final noegle = filterNavn.trim();
  switch (noegle) {
    case "Basic-Flo M5 G 1050 592 x 592 x 520": return 462;
    case "Basic-Flo M5 G 1050 592 x 287 x 520": return 341;
    case "Basic-Flo M5 G 1050 592 x 592 x 600": return 497;
    case "Basic-Flo M5 G 1050 592 x 287 x 600": return 531;
    case "Hiflo XLS M5 592 x 592 x 520": return 635;
    case "Hiflo XLS M5 592 x 287 x 520": return 655;
    case "Hiflo XLS M5 592 x 592 x 640": return 728;
    case "Hiflo XLS M5 592 x 287 x 640": return 784;
    case "Hiflo XLT M5 592 x 592 x 520": return 887;
    case "Hiflo XLT M5 592 x 287 x 520": return 705;
    case "Hiflo XLT M5 592 x 592 x 640": return 1044;
    case "Hiflo XLT M5 592 x 287 x 640": return 767;

    case "Basic-Flo F7 G 2570 592 x 592 x 520": return 526;
    case "Basic-Flo F7 G 2570 592 x 287 x 520": return 500;
    case "Basic-Flo F7 G 2570 592 x 592 x 600": return 791;
    case "Basic-Flo F7 G 2570 592 x 287 x 600": return 639;
    case "Hiflo XLS F7 592 x 592 x 520": return 996;
    case "Hiflo XLS F7 592 x 287 x 520": return 904;
    case "Hiflo XLS F7 592 x 592 x 640": return 1084;
    case "Hiflo XLS F7 592 x 287 x 640": return 960;
    case "Hiflo XLT F7 592 x 592 x 520": return 1159;
    case "Hiflo XLT F7 592 x 287 x 520": return 996;
    case "Hiflo XLT F7 592 x 592 x 640": return 1357;
    case "Hiflo XLT F7 592 x 287 x 640": return 1177;

    case "Hiflo XLS 2550 592 x 592 x 520": return 916;
    case "Hiflo XLS 2550 592 x 287 x 520": return 806;
    case "Hiflo XLT 2550 592 x 592 x 520": return 1084;
    case "Hiflo XLT 2550 592 x 287 x 520": return 912;
    case "Hiflo XLS 2550 592 x 592 x 640": return 1023;
    case "Hiflo XLS 2550 592 x 287 x 640": return 892;
    case "Hiflo XLT 2550 592 x 592 x 640": return 1287;
    case "Hiflo XLT 2550 592 x 287 x 640": return 1021;
    default: return 0;
  }
}
}