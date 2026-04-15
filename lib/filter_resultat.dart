import 'dart:math' as math;
import 'package:flutter/material.dart';

class FilterResultat {
  final double energiFoerInd;
  final double energiEfterInd;
  final double energiFoerUd;
  final double energiEfterUd;
  final double samletBesparelseKWh;
  final double samletBesparelseKr;
  final double trykGamleFiltreInd;
  final double trykGamleFiltreUd;
  final double luftPerFilterIndFoer;
  final double luftPerFilterUdFoer;

  const FilterResultat({
    required this.energiFoerInd,
    required this.energiEfterInd,
    required this.energiFoerUd,
    required this.energiEfterUd,
    required this.samletBesparelseKWh,
    required this.samletBesparelseKr,
    required this.trykGamleFiltreInd,
    required this.trykGamleFiltreUd,
    required this.luftPerFilterIndFoer,
    required this.luftPerFilterUdFoer,
  });

  bool get advarselInd => luftPerFilterIndFoer > 3400;
  bool get advarselUd => luftPerFilterUdFoer > 3400;
}

// Opslags-tabel for filterformler (samme som VBA Select Case)
final Map<String, double Function(double)> filterFormler = {
  "Basic-Flo M5 G 1050 592 x 592 x 520": (luft) => 0.00004 * math.pow(luft, 1.786),
  "Basic-Flo M5 G 1050 592 x 592 x 600": (luft) => 0.00005 * math.pow(luft, 1.723),
  "Basic-Flo F7 G 2570 592 x 592 x 520": (luft) => 0.0012 * math.pow(luft, 1.4483),
  "Basic-Flo F7 G 2570 592 x 592 x 600": (luft) => 0.001 * math.pow(luft, 1.4604),
  "Hiflo XLS M5 592 x 592 x 520": (luft) => 0.0002 * math.pow(luft, 1.5365),
  "Hiflo XLS M5 592 x 592 x 640": (luft) => 0.00009 * math.pow(luft, 1.6155),
  "Hiflo XLS F7 592 x 592 x 520": (luft) => 0.0015 * math.pow(luft, 1.41),
  "Hiflo XLS F7 592 x 592 x 640": (luft) => 0.005 * math.pow(luft, 1.2255),
  "Hiflo XLT M5 592 x 592 x 520": (luft) => 0.00004 * math.pow(luft, 1.7032),
  "Hiflo XLT M5 592 x 592 x 640": (luft) => 0.00001 * math.pow(luft, 1.8578),
  "Hiflo XLT F7 592 x 592 x 520": (luft) => 0.0004 * math.pow(luft, 1.5109),
  "Hiflo XLT F7 592 x 592 x 640": (luft) => 0.0006 * math.pow(luft, 1.4364),
  "Hiflo XLS 2550 592 x 592 x 520": (luft) => 0.0002 * math.pow(luft, 1.6297),
  "Hiflo XLT 2550 592 x 592 x 520": (luft) => 0.0005 * math.pow(luft, 1.46),
  "Hiflo XLS 2550 592 x 592 x 640": (luft) => 0.0003 * math.pow(luft, 1.53),
  "Hiflo XLT 2550 592 x 592 x 640": (luft) => 0.0004 * math.pow(luft, 1.4629),
};

// TRIN 1: Beregn energiforbrug per filter (svarer til BeregnEnergiForbrugIndblæsningFør)
double beregnEnergiForbrug(String? filterNavn, double luftPerFilter) {
  debugPrint("DEBUG beregnEnergiForbrug:");
  debugPrint("  filterNavn: '$filterNavn'");
  debugPrint("  luftPerFilter: $luftPerFilter");

  if (filterNavn == null || luftPerFilter <= 0) return 0.0;

  final key = filterNavn.trim();
  if (filterFormler.containsKey(key)) {
    final result = filterFormler[key]!(luftPerFilter).toDouble();
    debugPrint("  beregnet energiforbrug: $result");
    return result;
  }

  debugPrint("❌ Ukendt filter: '$filterNavn'");
  return 0.0;
}

// Hovedberegning - følger VBA-struktur præcis
FilterResultat beregnFilterResultat({
  required int antalFiltreInd,
  required int antalFiltreUd,
  required double kwInd,
  required double kwUd,
  required double elPris,
  required double trykGamleFiltreInd,
  required double trykGamleFiltreUd,
  double? luftInd,
  double? luftUd,
  double? driftstimer,
  double? virkningsgradInd,
  double? virkningsgradUd,
  String? filterFoerInd,
  String? filterEfterInd,
  String? filterFoerUd,
  String? filterEfterUd,
}) {
  debugPrint("🔍 VBA-STYLE BEREGNING START:");
  debugPrint("filterFoerInd: $filterFoerInd");
  debugPrint("filterFoerUd: $filterFoerUd");

  // Brug faktiske værdier eller Excel-fallbacks
  // ✅ Stop beregning, hvis der mangler nødvendige input
  if (luftInd == null ||
      luftUd == null ||
      driftstimer == null ||
      virkningsgradInd == null ||
      virkningsgradUd == null ||
      elPris.isNaN ||
      filterFoerInd == null ||
      filterFoerUd == null) {
    debugPrint("❌ Beregning afbrudt – manglende data");
    return const FilterResultat(
      energiFoerInd: 0,
      energiEfterInd: 0,
      energiFoerUd: 0,
      energiEfterUd: 0,
      samletBesparelseKWh: 0,
      samletBesparelseKr: 0,
      trykGamleFiltreInd: 0,
      trykGamleFiltreUd: 0,
      luftPerFilterIndFoer: 0,
      luftPerFilterUdFoer: 0,
    );
  }

// Brug kun faktiske værdier – ingen fallback
  final double luftIndVal = luftInd;
  final double luftUdVal = luftUd;
  final double driftVal = driftstimer;
  final double virknInd = virkningsgradInd;
  final double virknUd = virkningsgradUd;

  // Debug for at verificere værdier
  debugPrint("VÆRDI CHECK:");
  debugPrint("luftIndVal: $luftIndVal");
  debugPrint("luftUdVal: $luftUdVal");
  debugPrint("driftVal: $driftVal");
  debugPrint("virknInd: $virknInd");
  debugPrint("virknUd: $virknUd");
  debugPrint("elPris: $elPris");

  // TRIN 1: Beregn luftmængde per filter (BeregnLuftmængdePerFilterIndblæsningFør)
  final double luftPerFilterIndFoer = antalFiltreInd > 0 ? luftIndVal / antalFiltreInd : 0.0; // N37 i VBA
  final double luftPerFilterUdFoer = antalFiltreUd > 0 ? luftUdVal / antalFiltreUd : 0.0;     // N44 i VBA

  debugPrint("TRIN 1 - Luft per filter:");
  debugPrint("luftPerFilterIndFoer (N37): $luftPerFilterIndFoer");
  debugPrint("luftPerFilterUdFoer (N44): $luftPerFilterUdFoer");

  // TRIN 2: Beregn energiforbrug per filter FØR (BeregnEnergiForbrugIndblæsningFør)
  final double N38_forbrugFoerInd = beregnEnergiForbrug(filterFoerInd, luftPerFilterIndFoer); // N38 i VBA
  final double N45_forbrugFoerUd = beregnEnergiForbrug(filterFoerUd, luftPerFilterUdFoer);    // N45 i VBA

  debugPrint("TRIN 2 - Energiforbrug per filter FØR:");
  debugPrint("N38_forbrugFoerInd: $N38_forbrugFoerInd");
  debugPrint("N45_forbrugFoerUd: $N45_forbrugFoerUd");

  // TRIN 3: Beregn energiforbrug per filter EFTER - FASTE FILTRE
  final String anbefaletFilterInd = "Hiflo XLT F7 592 x 592 x 520";  // FAST ANBEFALING
  final String anbefaletFilterUd = "Hiflo XLT F7 592 x 592 x 520";   // FAST ANBEFALING

  final double O38_forbrugEfterInd = beregnEnergiForbrug(anbefaletFilterInd, luftPerFilterIndFoer); // O38 i VBA
  final double O45_forbrugEfterUd = beregnEnergiForbrug(anbefaletFilterUd, luftPerFilterUdFoer);    // O45 i VBA

  debugPrint("TRIN 3 - Energiforbrug per filter EFTER:");
  debugPrint("anbefaletFilterInd: $anbefaletFilterInd");
  debugPrint("O38_forbrugEfterInd: $O38_forbrugEfterInd");
  debugPrint("anbefaletFilterUd: $anbefaletFilterUd");
  debugPrint("O45_forbrugEfterUd: $O45_forbrugEfterUd");

  // TRIN 4: Beregn total kWh FØR (BeregnEnergiForbrugVidereIndblæsningFør)
  // VBA: resultat = (H20 / 3600) * N38 * e41 / ((F29 / 100) * 1000)
  final double K38_energiFoerInd = (luftIndVal / 3600) * N38_forbrugFoerInd * driftVal / ((virknInd / 100) * 1000); // K38 i VBA
  final double K44_energiFoerUd = (luftUdVal / 3600) * N45_forbrugFoerUd * driftVal / ((virknUd / 100) * 1000);    // K44 i VBA

  // TRIN 5: Beregn total kWh EFTER (BeregnEnergiForbrugVidereIndblæsningEfter)
  // VBA: resultat = (H20 / 3600) * O38 * e41 / ((F29 / 100) * 1000)
  final double K39_energiEfterInd = (luftIndVal / 3600) * O38_forbrugEfterInd * driftVal / ((virknInd / 100) * 1000); // K39 i VBA
  final double K45_energiEfterUd = (luftUdVal / 3600) * O45_forbrugEfterUd * driftVal / ((virknUd / 100) * 1000);    // K45 i VBA

  debugPrint("TRIN 4+5 - Total kWh:");
  debugPrint("K38_energiFoerInd: $K38_energiFoerInd");
  debugPrint("K39_energiEfterInd: $K39_energiEfterInd");
  debugPrint("K44_energiFoerUd: $K44_energiFoerUd");
  debugPrint("K45_energiEfterUd: $K45_energiEfterUd");

  // SPECIFIKT DEBUG FOR INDBLÆSNING
  debugPrint("INDBLÆSNING DEBUG:");
  debugPrint("luftIndVal: $luftIndVal");
  debugPrint("N38_forbrugFoerInd: $N38_forbrugFoerInd");
  debugPrint("driftVal: $driftVal");
  debugPrint("virknInd: $virknInd");
  debugPrint("Beregning: ($luftIndVal / 3600) * $N38_forbrugFoerInd * $driftVal / (($virknInd / 100) * 1000)");
  debugPrint("= ${(luftIndVal / 3600) * N38_forbrugFoerInd * driftVal / ((virknInd / 100) * 1000)}");

  // TRIN 6: Beregn besparelser (K40 = K38 - K39, K46 = K44 - K45)
  final double K40_besparelseInd = K38_energiFoerInd - K39_energiEfterInd; // K40 i VBA
  final double K46_besparelseUd = K44_energiFoerUd - K45_energiEfterUd;    // K46 i VBA
  final double samletBesparelseKWh = K40_besparelseInd + K46_besparelseUd;
  final double samletBesparelseKr = samletBesparelseKWh * elPris;

  debugPrint("TRIN 6 - Besparelser:");
  debugPrint("K40_besparelseInd: $K40_besparelseInd");
  debugPrint("K46_besparelseUd: $K46_besparelseUd");
  debugPrint("samletBesparelseKWh: $samletBesparelseKWh");
  debugPrint("samletBesparelseKr: $samletBesparelseKr");

  return FilterResultat(
    energiFoerInd: K38_energiFoerInd,
    energiEfterInd: K39_energiEfterInd,
    energiFoerUd: K44_energiFoerUd,
    energiEfterUd: K45_energiEfterUd,
    samletBesparelseKWh: samletBesparelseKWh,
    samletBesparelseKr: samletBesparelseKr,
    trykGamleFiltreInd: trykGamleFiltreInd,
    trykGamleFiltreUd: trykGamleFiltreUd,
    luftPerFilterIndFoer: luftPerFilterIndFoer,
    luftPerFilterUdFoer: luftPerFilterUdFoer,
  );
}

// Gemte valg af filtre
class FilterValg {
  final String? filterFoerInd;
  final String? filterFoerUd;
  final String? filterEfterInd;
  final String? filterEfterUd;
  final double? filterMaalIndMm;
  final double? filterMaalUdMm;

  const FilterValg({
    this.filterFoerInd,
    this.filterFoerUd,
    this.filterEfterInd,
    this.filterEfterUd,
    this.filterMaalIndMm,
    this.filterMaalUdMm,
  });

  @override
  String toString() {
    return 'FilterValg(ind: $filterFoerInd → $filterEfterInd, ud: $filterFoerUd → $filterEfterUd)';
  }
}