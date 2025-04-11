double beregnElforbrug(double kw, double driftTimer) {
  return kw * driftTimer;
}

double beregnVirkningsgrad(double luftmaengde, double tryk, double kw) {
  if (kw == 0) return 0;
  return ((luftmaengde / 3600) * tryk) / (kw * 1000) * 100;
}

class VentilatorResultat {
  final String navn;
  final double elforbrug;
  final double virkningsgrad;

  VentilatorResultat({
    required this.navn,
    required this.elforbrug,
    required this.virkningsgrad,
  });

  @override
  String toString() {
    return '$navn\nElforbrug: ${elforbrug.toStringAsFixed(2)} kWh\nVirkningsgrad: ${virkningsgrad.toStringAsFixed(2)} %';
  }
}

VentilatorResultat beregnVentilator({
  required String navn,
  required double kw,
  required double driftTimer,
  required double luftmaengde,
  required double tryk,
}) {
  final elforbrug = beregnElforbrug(kw, driftTimer);
  final virkningsgrad = beregnVirkningsgrad(luftmaengde, tryk, kw);
  return VentilatorResultat(
    navn: navn,
    elforbrug: elforbrug,
    virkningsgrad: virkningsgrad,
  );
}