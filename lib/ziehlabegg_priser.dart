// ziehlabegg_priser.dart

import 'base_oekonomi_resultat.dart';
import 'package:ventoptima/afdelingsdata.dart';

class OekonomiResultat implements BaseOekonomiResultat {
  @override final double indPris;
  @override final double udPris;
  @override final double totalPris;
  @override final double aarsbesparelse;
  @override final double tilbagebetalingstid;

  // Dummy-felter for BaseOekonomiResultat
  @override final String varenummer = '';
  @override final double aarsforbrugKWh = 0;
  @override final double omkostning = 0;
  @override final double effekt = 0;
  @override final double tryk = 0;
  @override final double luftmaengde = 0;
  @override final double virkningsgrad = 0;
  @override final double selvaerdi = 0;

  @override
  double get pris => totalPris;

  OekonomiResultat({
    required this.indPris,
    required this.udPris,
    required this.totalPris,
    required this.aarsbesparelse,
    required this.tilbagebetalingstid,
  });
}

final Map<String, int> ziehlAbeggPriser = {
  "116883/a01": 3014,
  "116885/a01": 3561,
  "116888/a01": 4173,
  "116889/a01": 4110,
  "116890/a01": 4736,
  "116892/a01": 4451,
  "116893/a01": 5077,
  "116896/a01": 5209,
  "116897/a01": 6223,
  "116901/a01": 5772,
  "116902/a01": 6204,
  "116903/a01": 6488,
  "116904/a01": 6467,
  "116905/a01": 7080,
  "118582/a01": 12145,
  "116907/a01": 7288,
  "116908/a01": 8543,
  "116909/a01": 9909,
};

// Hjælpeklasse til at returnere både pris og antal
class VentilatorInfo {
  final double pris;
  final int antal;

  VentilatorInfo({required this.pris, required this.antal});
}

// Opdateret hjælpefunktion der returnerer både pris og antal
VentilatorInfo beregnVentilatorInfo(String? varenummer) {
  if (varenummer == null || varenummer.isEmpty) {
    return VentilatorInfo(pris: 0.0, antal: 0);
  }

  // Tjek om varenummeret starter med et antal (f.eks. "2x", "3x")
  RegExp regex = RegExp(r'^(\d+)x', caseSensitive: false);
  Match? match = regex.firstMatch(varenummer);

  String basisVarenummer = varenummer;
  int antal = 1;

  if (match != null) {
    // Udtræk antal og basis varenummer
    antal = int.parse(match.group(1)!);
    basisVarenummer = varenummer.substring(match.group(0)!.length);
  }

  // Hent pris for basis varenummer og gang med antal
  double enkeltPris = ziehlAbeggPriser[basisVarenummer]?.toDouble() ?? 0.0;
  double totalPris = enkeltPris * antal;

  return VentilatorInfo(pris: totalPris, antal: antal);
}

OekonomiResultat beregnZiehlOekonomi({
  required String? afdeling,
  required String? varenummerInd,
  required String? varenummerUd,
  required double omkostningInd,
  required double omkostningUd,
  required double fradragRemtrukket,
}) {
  final double basisTimer = hentMontagetimer(afdeling);
  final double timeloen = hentTimeloen(afdeling);
  final double materialePris = hentMaterialePris(afdeling);
  final double daekning = hentDaekningProcent(afdeling);
  final double faktor = 1 + (daekning / 100);

  // 🔹 Indblæsning - med korrekt håndtering af antal
  double indPris = 0.0;
  if (varenummerInd != null && varenummerInd.isNotEmpty) {
    final ventilatorInfo = beregnVentilatorInfo(varenummerInd);
    if (ventilatorInfo.pris > 0) {
      // Montagetimer ganges med antal ventilatorer
      double montageTimer = basisTimer * ventilatorInfo.antal;
      // Materialepris ganges også med antal (flere ventilatorer = mere tilbehør)
      double totalMaterialePris = materialePris * ventilatorInfo.antal;

      indPris = (ventilatorInfo.pris + totalMaterialePris) * faktor + (montageTimer * timeloen);
    }
  }

  // 🔹 Udsugning - med korrekt håndtering af antal
  double udPris = 0.0;
  if (varenummerUd != null && varenummerUd.isNotEmpty) {
    final ventilatorInfo = beregnVentilatorInfo(varenummerUd);
    if (ventilatorInfo.pris > 0) {
      // Montagetimer ganges med antal ventilatorer
      double montageTimer = basisTimer * ventilatorInfo.antal;
      // Materialepris ganges også med antal (flere ventilatorer = mere tilbehør)
      double totalMaterialePris = materialePris * ventilatorInfo.antal;

      udPris = (ventilatorInfo.pris + totalMaterialePris) * faktor + (montageTimer * timeloen);
    }
  }

  final double totalPris = (indPris + udPris - fradragRemtrukket).clamp(0, double.infinity);

  final double aarsbesparelse = omkostningInd + omkostningUd;
  final double tilbagebetalingstid = aarsbesparelse > 0 ? totalPris / aarsbesparelse : 0;

  return OekonomiResultat(
    indPris: indPris,
    udPris: udPris,
    totalPris: totalPris,
    aarsbesparelse: aarsbesparelse,
    tilbagebetalingstid: tilbagebetalingstid,
  );
}

// 🔧 Hjælpefunktioner til at hente afdelingsspecifikke værdier

double hentMontagetimer(String? afdeling) {
  return afdelingsData[afdeling]?.montagetimer ?? 0;
}

double hentTimeloen(String? afdeling) {
  return afdelingsData[afdeling]?.timeloen ?? 0;
}

double hentMaterialePris(String? afdeling) {
  return afdelingsData[afdeling]?.materialePris ?? 0;
}

double hentDaekningProcent(String? afdeling) {
  return afdelingsData[afdeling]?.daekningProcent ?? 0;
}