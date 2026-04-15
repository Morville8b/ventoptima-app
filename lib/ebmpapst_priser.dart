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

final Map<String, int> ebmpapstPriser = {
  "8300100482": 3867,
  "8300100757": 4945,
  "8300100543": 4120,
  "8300100053": 5425,
  "8300100049": 6914,
  "8300100087": 7957,
  "8300100479": 6654,
  "8300100056": 7764,
  "8300100058": 7584,
  "8300100043": 8359,
  "8300100344": 7629,
  "8300100068": 10579,
  "8300100319": 8240,
  "8300100082": 8255,
  "8300100095": 10862,
  "8300100101": 11935,
  "8300100094": 9998,
  "8300100048": 12471,
};

OekonomiResultat beregnEbmpapstOekonomi({
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
  if (varenummerInd != null && varenummerInd.isNotEmpty && ebmpapstPriser.containsKey(varenummerInd)) {
    final ventilatorPrisInd = ebmpapstPriser[varenummerInd]!.toDouble();
    indPris = (ventilatorPrisInd + materialePris) * faktor + (timer * timeloen);
  }

  // 🔹 Udsugning
  double udPris = 0.0;
  if (varenummerUd != null && varenummerUd.isNotEmpty && ebmpapstPriser.containsKey(varenummerUd)) {
    final ventilatorPrisUd = ebmpapstPriser[varenummerUd]!.toDouble();
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