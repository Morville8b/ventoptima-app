import 'package:flutter/material.dart';
import 'filter_resultat.dart';
import 'anlaegs_data.dart';
import 'dart:math' as math;
import 'generel_projekt_info.dart';

class FilterResultatSkarm extends StatelessWidget {
  final AnlaegsData anlaeg;
  final GenerelProjektInfo projektInfo;
  final int antalHeleFiltreInd;
  final int antalHalveFiltreInd;
  final int antalHeleFiltreUd;
  final int antalHalveFiltreUd;

  const FilterResultatSkarm({
    super.key,
    required this.anlaeg,
    required this.projektInfo,
    required this.antalHeleFiltreInd,
    required this.antalHalveFiltreInd,
    required this.antalHeleFiltreUd,
    required this.antalHalveFiltreUd,
  });

  // Funktion til at hente filterpris baseret på filternavn
  double hentFilterPris(String? filterNavn) {
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

  // Tilføj denne funktion som matcher VBA's beregning af tryktab
  double beregnTryktab(String? filterNavn, double luftPerFilter) {
    if (filterNavn == null || luftPerFilter <= 0) return 0.0;

    final key = filterNavn.trim();

    switch (key) {
    // M5 filtre
      case "Basic-Flo M5 G 1050 592 x 592 x 520":
        return 0.00004 * math.pow(luftPerFilter, 1.786);
      case "Basic-Flo M5 G 1050 592 x 592 x 600":
        return 0.00005 * math.pow(luftPerFilter, 1.723);

    // F7 filtre
      case "Basic-Flo F7 G 2570 592 x 592 x 520":
        return 0.0012 * math.pow(luftPerFilter, 1.4483);
      case "Basic-Flo F7 G 2570 592 x 592 x 600":
        return 0.001 * math.pow(luftPerFilter, 1.4604);

      case "Hiflo XLS M5 592 x 592 x 520":
        return 0.0002 * math.pow(luftPerFilter, 1.5365);
      case "Hiflo XLS M5 592 x 592 x 640":
        return 0.00009 * math.pow(luftPerFilter, 1.6155);

      case "Hiflo XLS F7 592 x 592 x 520":
        return 0.0015 * math.pow(luftPerFilter, 1.41);
      case "Hiflo XLS F7 592 x 592 x 640":
        return 0.005 * math.pow(luftPerFilter, 1.2255);

      case "Hiflo XLT M5 592 x 592 x 520":
        return 0.00004 * math.pow(luftPerFilter, 1.7032);
      case "Hiflo XLT M5 592 x 592 x 640":
        return 0.00001 * math.pow(luftPerFilter, 1.8578);

      case "Hiflo XLT F7 592 x 592 x 520":
        return 0.0004 * math.pow(luftPerFilter, 1.5109);
      case "Hiflo XLT F7 592 x 592 x 640":
        return 0.0006 * math.pow(luftPerFilter, 1.4364);

      case "Hiflo XLS 2550 592 x 592 x 520":
        return 0.0002 * math.pow(luftPerFilter, 1.6297);
      case "Hiflo XLT 2550 592 x 592 x 520":
        return 0.0005 * math.pow(luftPerFilter, 1.46);
      case "Hiflo XLS 2550 592 x 592 x 640":
        return 0.0003 * math.pow(luftPerFilter, 1.53);
      case "Hiflo XLT 2550 592 x 592 x 640":
        return 0.0004 * math.pow(luftPerFilter, 1.4629);

      default:
        return 0;
    }
  }

  // Opdateret energiberegning som matcher VBA
  double beregnEnergiforbrugVBA(
      double tryktab,
      double totalLuftmengde,
      double driftstimer,
      double virkningsgrad) {
    // Samme formel som VBA: (H20/3600) * tryktab * e41 / ((F29/100) * 1000)
    return (totalLuftmengde / 3600) * tryktab * driftstimer / ((virkningsgrad / 100) * 1000);
  }

  String formatTal(double? value, {int decimals = 0}) {
    if (value == null) return "-";

    String numStr = value.toStringAsFixed(decimals);
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 && decimals > 0 ? parts[1] : '';

    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerPart[i];
    }

    if (decimalPart.isNotEmpty) {
      return '$formattedInteger,$decimalPart';
    } else {
      return formattedInteger;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Før vi laver nogen beregning, skal vi sikre at alle nødvendige data er til stede
    if (anlaeg.driftstimer == null ||
        anlaeg.virkningsgradInd == null ||
        anlaeg.virkningsgradUd == null ||
        anlaeg.filterValg == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('FILTER BESPARELSESFORSLAG'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Text(
            '⚠️ Beregning kan ikke udføres.\n\nDer mangler nødvendige data for at beregne besparelsen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // 🔹 Brug de faktiske værdier fra anlaeg (nu garanteret til stede)
    final double luftIndTotal = anlaeg.luftInd;
    final double luftUdTotal = anlaeg.luftUd;
    final double driftstimerAar = anlaeg.driftstimer!;
    final double virkningsgradIndPct = anlaeg.virkningsgradInd!;
    final double virkningsgradUdPct = anlaeg.virkningsgradUd!;

    // 🔹 Antal filtre (hele + halve)
    final int totalFiltreInd = (anlaeg.antalHeleFiltreInd ?? 0) + (anlaeg.antalHalveFiltreInd ?? 0);
    final int totalFiltreUd = (anlaeg.antalHeleFiltreUd ?? 0) + (anlaeg.antalHalveFiltreUd ?? 0);

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

    final bool erTomtResultat = anlaeg.filterValg == null;

    // 🔹 Luft per filter
    final double luftPerFilterInd = luftIndTotal / (totalFiltreInd > 0 ? totalFiltreInd : 1);
    final double luftPerFilterUd = luftUdTotal / (totalFiltreUd > 0 ? totalFiltreUd : 1);

    // 🔹 Tjek hvilket filter der bruges i FØR-situationen
    String? filterFoerInd = anlaeg.filterValg?.filterFoerInd;
    String? filterFoerUd = anlaeg.filterValg?.filterFoerUd;

    // Hvis et af FØR-filtrene er M5, skal EFTER-situationen også bruge M5-filtre.
    // Ellers bruges F7 som standard.
    bool brugerM5 = false;
    if ((filterFoerInd?.contains('M5') ?? false) || (filterFoerUd?.contains('M5') ?? false)) {
      brugerM5 = true;
    }

    // 🔹 Vælg de korrekte efter-filtre baseret på før-situationen
    final String efterFilter520 = brugerM5
        ? "Hiflo XLT M5 592 x 592 x 520"
        : "Hiflo XLT F7 592 x 592 x 520";

    final String efterFilter640 = brugerM5
        ? "Hiflo XLT M5 592 x 592 x 640"
        : "Hiflo XLT F7 592 x 592 x 640";

    // 🟩 TILFØJET: Definer filterklasse til visning
    String filterKlasse = 'F7'; // standard
    if (filterFoerInd != null && filterFoerInd.contains('M5')) {
      filterKlasse = 'M5';
    } else if (filterFoerInd != null && filterFoerInd.contains('F7')) {
      filterKlasse = 'F7';
    }

    // -------------------------------------------------------------
    // EFTER-situationen – 520 mm filtre
    // -------------------------------------------------------------
    final double tryktabXLT520Ind = beregnTryktab(efterFilter520, luftPerFilterInd);
    final double tryktabXLT520Ud  = beregnTryktab(efterFilter520, luftPerFilterUd);

    final double energiXLT520Ind = beregnEnergiforbrugVBA(
      tryktabXLT520Ind,
      luftIndTotal,
      driftstimerAar,
      virkningsgradIndPct,
    );

    final double energiXLT520Ud = beregnEnergiforbrugVBA(
      tryktabXLT520Ud,
      luftUdTotal,
      driftstimerAar,
      virkningsgradUdPct,
    );

    // -------------------------------------------------------------
    // EFTER-situationen – 640 mm filtre
    // -------------------------------------------------------------
    final double tryktabXLT640Ind = beregnTryktab(efterFilter640, luftPerFilterInd);
    final double tryktabXLT640Ud  = beregnTryktab(efterFilter640, luftPerFilterUd);

    final double energiXLT640Ind = beregnEnergiforbrugVBA(
      tryktabXLT640Ind,
      luftIndTotal,
      driftstimerAar,
      virkningsgradIndPct,
    );

    final double energiXLT640Ud = beregnEnergiforbrugVBA(
      tryktabXLT640Ud,
      luftUdTotal,
      driftstimerAar,
      virkningsgradUdPct,
    );

    // -------------------------------------------------------------
    // Samlede energiforbrug og besparelser
    // -------------------------------------------------------------
    final double samletEnergiXLT520 = energiXLT520Ind + energiXLT520Ud;
    final double samletEnergiXLT640 = energiXLT640Ind + energiXLT640Ud;

    // 🔹 Sammenlign med FØR-situationen
    final double besparelseXLT520 = (resultat.energiFoerInd + resultat.energiFoerUd) - samletEnergiXLT520;
    final double besparelseXLT640 = (resultat.energiFoerInd + resultat.energiFoerUd) - samletEnergiXLT640;

    // 🔹 Hent filterpriser – både nuværende og anbefalede
    final double nuvaerenderPrisInd = hentFilterPris(anlaeg.filterValg?.filterFoerInd);
    final double nuvaerenderPrisUd = hentFilterPris(anlaeg.filterValg?.filterFoerUd);
    final double anbefaletPrisInd520 = hentFilterPris(efterFilter520);
    final double anbefaletPrisUd520  = hentFilterPris(efterFilter520);
    final double anbefaletPrisInd640 = hentFilterPris(efterFilter640);
    final double anbefaletPrisUd640  = hentFilterPris(efterFilter640);

    // 🔹 Tjek om kammeret er for lille til 640 mm
    final bool kammerForLille = (anlaeg.filterValg?.filterMaalIndMm ?? 1000) < 645 ||
        (anlaeg.filterValg?.filterMaalUdMm ?? 1000) < 645;

    // NU BYGGER VI UI'ET MED ALLE VARIABLER DEFINERET
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 45),
          ),
        ],
        title: Text(
          'FILTER BESPARELSESFORSLAG – ${anlaeg.anlaegsNavn}',
          style: const TextStyle(
            color: Color(0xFF006390),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: erTomtResultat
          ? const Center(
        child: Text(
          "Ingen filterberegning udført endnu",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      )
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _overskriftBoks('FILTEROPTIMERING'),
                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF006390), size: 20),
                      SizedBox(width: 6),
                      Text(
                        "FØR-situationen",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006390),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                _infoKort(
                  null,
                  "",
                  [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nuværende filtre',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              _infoLinje(Icons.filter_alt, 'Indblæsning', anlaeg.filterValg?.filterFoerInd ?? "-", ""),
                              _infoLinje(Icons.filter_alt, 'Udsugning', anlaeg.filterValg?.filterFoerUd ?? "-", ""),
                              const SizedBox(height: 12),
                              _infoLinje(Icons.flash_on, 'Energiforbrug (indblæsning)', resultat.energiFoerInd, 'kWh/år'),
                              _infoLinje(Icons.flash_on, 'Energiforbrug (udsugning)', resultat.energiFoerUd, 'kWh/år'),
                              const SizedBox(height: 12),
                              const Text('Samlet energiforbrug og driftsomkostning',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              _infoLinje(Icons.bolt, 'Samlet elforbrug', resultat.energiFoerInd + resultat.energiFoerUd, 'kWh/år'),
                              _infoLinje(Icons.payments, 'Samlet omkostning', (resultat.energiFoerInd + resultat.energiFoerUd) * (anlaeg.elpris ?? 1.2), 'kr./år'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(
                                'assets/images/filter.png',
                                fit: BoxFit.cover,
                                height: 220,
                                width: 220,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // EFTER-situationen
                _infoKort(
                  Icons.trending_down,
                  "EFTER-situationen",
                  [
                    if (kammerForLille) ...[
                      // Vis kun ét scenarie når kammer er for lille
                      _forslagKolonne(
                        overskrift: 'Scenarie 1 - Hiflo XLT $filterKlasse 520',
                        highlight: true,
                        energiforbrugKWh: samletEnergiXLT520,
                        energiomkostningKr: samletEnergiXLT520 * (anlaeg.elpris ?? 1.2),
                        filteromkostningKr:
                        hentFilterPris(efterFilter520) *
                            (totalFiltreInd + totalFiltreUd) -
                            (nuvaerenderPrisInd * totalFiltreInd + nuvaerenderPrisUd * totalFiltreUd),
                        filterPrisStk: hentFilterPris(efterFilter520),
                        besparelseKWh: besparelseXLT520,
                        besparelseKr: besparelseXLT520 * (anlaeg.elpris ?? 1.2),
                        logoText: '',
                        logoColor: Colors.white,
                        logoPath: 'assets/images/camfil_logo.png',
                      ),
                      const SizedBox(height: 16),
                      // Advarselsboks når kammer er for lille
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filterkammeret er for lille til 640 mm filtre. '
                                    'Målt: Indblæsning ${anlaeg.filterValg?.filterMaalIndMm?.toStringAsFixed(0) ?? "N/A"} mm, '
                                    'Udsugning ${anlaeg.filterValg?.filterMaalUdMm?.toStringAsFixed(0) ?? "N/A"} mm. '
                                    'Minimum krævet: 645 mm.',
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Vis begge scenarier når kammer er stort nok
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _forslagKolonne(
                              overskrift: 'Scenarie 1 - Hiflo XLT $filterKlasse 520',
                              highlight: true,
                              energiforbrugKWh: samletEnergiXLT520,
                              energiomkostningKr: samletEnergiXLT520 * (anlaeg.elpris ?? 1.2),
                              filteromkostningKr:
                              hentFilterPris(efterFilter520) *
                                  (totalFiltreInd + totalFiltreUd) -
                                  (nuvaerenderPrisInd * totalFiltreInd + nuvaerenderPrisUd * totalFiltreUd),
                              filterPrisStk: hentFilterPris(efterFilter520),
                              besparelseKWh: besparelseXLT520,
                              besparelseKr: besparelseXLT520 * (anlaeg.elpris ?? 1.2),
                              logoText: '',
                              logoColor: Colors.white,
                              logoPath: 'assets/images/camfil_logo.png',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _forslagKolonne(
                              overskrift: 'Scenarie 2 - Hiflo XLT $filterKlasse 640',
                              highlight: true,
                              energiforbrugKWh: samletEnergiXLT640,
                              energiomkostningKr: samletEnergiXLT640 * (anlaeg.elpris ?? 1.2),
                              filteromkostningKr:
                              hentFilterPris(efterFilter640) *
                                  (totalFiltreInd + totalFiltreUd) -
                                  (nuvaerenderPrisInd * totalFiltreInd + nuvaerenderPrisUd * totalFiltreUd),
                              filterPrisStk: hentFilterPris(efterFilter640),
                              besparelseKWh: besparelseXLT640,
                              besparelseKr: besparelseXLT640 * (anlaeg.elpris ?? 1.2),
                              logoText: '',
                              logoColor: Colors.white,
                              logoPath: 'assets/images/camfil_logo.png',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Besparelsesforslaget er udarbejdet på baggrund af beregninger fra filterproducenter. '
                        'De viste forslag repræsenterer den bedste energieffektivitet vs. omkostning.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                _overskriftBoks('TEKNISKE DETALJER OG KONTROL'),
                const SizedBox(height: 4),

                _infoKort(
                  Icons.warning,
                  'Luftmængde kontrol',
                  [
                    Row(
                      children: [
                        Icon(
                            resultat.luftPerFilterIndFoer > 3400 ? Icons.warning_amber : Icons.check_circle,
                            color: resultat.luftPerFilterIndFoer > 3400 ? Colors.red : Colors.green,
                            size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            resultat.luftPerFilterIndFoer > 3400
                                ? "Luftmængde pr. filter (Indblæsning) er over grænsen på 3.400 m³/h"
                                : "Luftmængde pr. filter (Indblæsning) er indenfor anbefalingen",
                            style: TextStyle(
                              fontSize: 14,
                              color: resultat.luftPerFilterIndFoer > 3400 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                            resultat.luftPerFilterUdFoer > 3400 ? Icons.warning_amber : Icons.check_circle,
                            color: resultat.luftPerFilterUdFoer > 3400 ? Colors.red : Colors.green,
                            size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            resultat.luftPerFilterUdFoer > 3400
                                ? "Luftmængde pr. filter (Udsugning) er over grænsen på 3.400 m³/h"
                                : "Luftmængde pr. filter (Udsugning) er indenfor anbefalingen",
                            style: TextStyle(
                              fontSize: 14,
                              color: resultat.luftPerFilterUdFoer > 3400 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                _infoKort(
                  Icons.schedule,
                  'Filter udskiftningsinterval',
                  [
                    _filterUdskiftningsVurderingUdenKasser(anlaeg, resultat),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  'Beregningerne er baseret på elpris: ${formatTal(anlaeg.elpris ?? 1.2, decimals: 2)} kr/kWh.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34E0A1),
                      foregroundColor: const Color(0xFF006390),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tilbage til oversigt'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overskriftBoks(String title) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF34E0A1), width: 2)),
      ),
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF34E0A1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF006390),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _forslagKolonne({
    required String overskrift,
    required bool highlight,
    required double energiforbrugKWh,
    required double energiomkostningKr,
    required double filteromkostningKr,
    required double filterPrisStk,
    required double besparelseKWh,
    required double besparelseKr,
    required String logoText,
    required Color logoColor,
    String? logoPath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: highlight ? const Color(0xFF34E0A1) : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: logoColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: logoPath != null
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                ),
              )
                  : Center(
                child: Text(
                  logoText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            overskrift,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: highlight ? const Color(0xFF006390) : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (besparelseKWh > 0) ...[
            _infoLinje(Icons.flash_on, 'El-besparelse', besparelseKWh, 'kWh/år'),
            _infoLinje(Icons.monetization_on, 'Økonomisk besparelse', besparelseKr, 'kr/år'),
            const SizedBox(height: 8),
          ],
          _infoLinje(Icons.electric_bolt, 'Elforbrug', energiforbrugKWh, 'kWh/år'),
          _infoLinje(Icons.payments, 'Elomkostning', energiomkostningKr, 'kr/år'),
          const SizedBox(height: 8),
          _infoLinje(Icons.filter_alt, 'Øgede filteromkostninger', filteromkostningKr, 'kr/år'),
        ],
      ),
    );
  }

  Widget _infoKort(IconData? icon, String overskrift, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF34E0A1), width: 2),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overskrift.isNotEmpty || icon != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF006390), size: 22),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    overskrift,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006390),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          if (overskrift.isNotEmpty || icon != null) const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoLinje(IconData icon, String label, dynamic value, String enhed, {int decimals = 0}) {
    String formattedValue;
    if (value is String) {
      formattedValue = value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF34E0A1), size: 18),
            const SizedBox(width: 5),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final double numValue = value is num ? value.toDouble() : 0.0;

      String formatDK(num value, {int decimals = 0}) {
        if (value.isNaN || !value.isFinite) {
          value = 0;
        }
        return value.toStringAsFixed(decimals).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
        );
      }

      formattedValue = formatDK(numValue, decimals: decimals);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF34E0A1), size: 18),
          const SizedBox(width: 5),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '$formattedValue $enhed',
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _filterUdskiftningsVurderingUdenKasser(AnlaegsData anlaeg, FilterResultat resultat) {
    final int totalFiltreInd =
    ((anlaeg.antalHeleFiltreInd ?? 0) + ((anlaeg.antalHalveFiltreInd ?? 0) / 2)).ceil();
    final int totalFiltreUd =
    ((anlaeg.antalHeleFiltreUd ?? 0) + ((anlaeg.antalHalveFiltreUd ?? 0) / 2)).ceil();

    final double luftPerFilterInd = (anlaeg.luftInd ?? 5000) / (totalFiltreInd > 0 ? totalFiltreInd : 1);
    final double luftPerFilterUd = (anlaeg.luftUd ?? 5000) / (totalFiltreUd > 0 ? totalFiltreUd : 1);

    final double N38 = beregnStartTryktab(anlaeg.filterValg?.filterFoerInd, luftPerFilterInd);
    final double N45 = beregnStartTryktab(anlaeg.filterValg?.filterFoerUd, luftPerFilterUd);

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

    return Column(
      children: [
        Row(
          children: [
            Icon(indOK ? Icons.check_circle : Icons.warning_amber,
                color: indOK ? Colors.green : Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                indOK
                    ? "OK tidsinterval for filter udskiftning (Indblæsning)"
                    : "Filter bør udskiftes oftere (Indblæsning)",
                style: TextStyle(
                  color: indOK ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(udOK ? Icons.check_circle : Icons.warning_amber,
                color: udOK ? Colors.green : Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                udOK
                    ? "OK tidsinterval for filter udskiftning (Udsugning)"
                    : "Filter bør udskiftes oftere (Udsugning)",
                style: TextStyle(
                  color: udOK ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
