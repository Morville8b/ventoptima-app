// novenco_priser.dart

import 'base_oekonomi_resultat.dart';
import 'package:ventoptima/afdelingsdata.dart'; // 🔗 Fælles data

class OekonomiResultat implements BaseOekonomiResultat {
  @override final double indPris;
  @override final double udPris;
  @override final double totalPris;
  @override final double aarsbesparelse;
  @override final double tilbagebetalingstid;

  // Dummy-værdier for at opfylde BaseOekonomiResultat
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

final Map<String, int> novencoPriser = {
  "30056961": 13599,
  "30056958": 13599,
  "30056949": 15113,
  "30056962": 14817,
  "30056948": 14817,
  "30056960": 15610,
  "30056950": 15610,
  "30056951": 15869,
  "30056953": 16754,
  "30056955": 16992,
  "30056963": 17343,
  "30056952": 18827,
  "30056959": 19015,
  "30056964": 18486,
  "30056954": 20159,
  "30056956": 20397,
  "30056957": 23411,
  "30047862": 24358,
  "30046057": 24614,
  "30046056": 24614,
  "30046055": 24614,
  "30050716": 24358,
  "30046063": 25781,
  "30046058": 25825,
  "30046064": 26991,
  "30046069": 27756,
  "30046065": 29166,
  "30046067": 19166,
  "30046071": 29931,
  "30046070": 29931,
  "30046078": 30544,
  "30047863": 33464,
  "30050718": 33464,
  "30047864": 34135,
  "30056944": 28791,
  "30047870": 35265,
  "30046072": 37959,
  "30046079": 38572,
  "30047873": 37540,
  "30047871": 38126,
  "30046082": 31879,
  "30047881": 37927,
  "30047879": 43523,
  "30047875": 43523,
  "30046083": 39293,
  "30047885": 43909,
  "30047901": 44523,
  "30047897": 44523,
  "30047890": 44523,
  "30046084": 52052,
};

OekonomiResultat beregnNovencoOekonomi({
  required String? afdeling,
  required String? varenummerInd,
  required String? varenummerUd,
  required double omkostningInd,
  required double omkostningUd,
  required double fradragRemtrukket,
}) {
  final double timer = hentMontagetimer(afdeling);
  final double timeloen = hentTimeloen(afdeling);
  final double materialePris = hentMaterialePris(afdeling);
  final double daekning = hentDaekningProcent(afdeling);
  final double faktor = 1 + (daekning / 100);

  // 🔹 Indblæsning
  double indPris = 0.0;
  if (varenummerInd != null && varenummerInd.isNotEmpty && novencoPriser.containsKey(varenummerInd)) {
    final ventilatorPrisInd = novencoPriser[varenummerInd]!.toDouble();
    indPris = (ventilatorPrisInd + materialePris) * faktor + (timer * timeloen);
  }

  // 🔹 Udsugning
  double udPris = 0.0;
  if (varenummerUd != null && varenummerUd.isNotEmpty && novencoPriser.containsKey(varenummerUd)) {
    final ventilatorPrisUd = novencoPriser[varenummerUd]!.toDouble();
    udPris = (ventilatorPrisUd + materialePris) * faktor + (timer * timeloen);
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