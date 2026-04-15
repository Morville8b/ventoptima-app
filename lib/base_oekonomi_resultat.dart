abstract class BaseOekonomiResultat {
  double get tryk;
  double get luftmaengde;
  double get effekt;
  double get aarsforbrugKWh;
  double get omkostning;
  double get virkningsgrad;
  double get selvaerdi;
  double get tilbagebetalingstid;
  double get pris; // 👈 denne gør forskellen!
  String get varenummer;
  double get indPris;
  double get udPris;
  double get totalPris;
  double get aarsbesparelse;
}
class OekonomiResultat implements BaseOekonomiResultat {
  @override final double tryk;
  @override final double luftmaengde;
  @override final double effekt;
  @override final double aarsforbrugKWh;
  @override final double omkostning;
  @override final double virkningsgrad;
  @override final double selvaerdi;
  @override final double tilbagebetalingstid;
  @override final String varenummer;

  final double _indPris;
  final double _udPris;
  final double _totalPris;
  final double _aarsbesparelse;

  @override
  double get pris => _totalPris;

  @override
  double get indPris => _indPris;

  @override
  double get udPris => _udPris;

  @override
  double get totalPris => _totalPris;

  @override
  double get aarsbesparelse => _aarsbesparelse;

  OekonomiResultat({
    required this.tryk,
    required this.luftmaengde,
    required this.effekt,
    required this.aarsforbrugKWh,
    required this.omkostning,
    required this.virkningsgrad,
    required this.selvaerdi,
    required this.tilbagebetalingstid,
    required this.varenummer,
    required double indPris,
    required double udPris,
    required double totalPris,
    required double aarsbesparelse,
  })  : _indPris = indPris,
        _udPris = udPris,
        _totalPris = totalPris,
        _aarsbesparelse = aarsbesparelse;
}