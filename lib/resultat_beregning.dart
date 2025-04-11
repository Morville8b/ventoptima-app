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

double beregnVarmeforbrug({
  required String anlaegstype,
  required String driftType,
  required double luftmaengde,
  required double temperaturEfterVarmeflade,
  required double justeringFaktor,
}) {
  final double tRef;
  switch (driftType.toLowerCase()) {
    case 'døgn':
    case 'doegn':
      tRef = 8.9;
      break;
    case 'dagtimer':
    case 'dags timer':
      tRef = 12.0;
      break;
    case 'nattetimer':
    case 'natte timer':
      tRef = 5.6;
      break;
    default:
      throw ArgumentError('Ugyldig driftType: $driftType');
  }

  double deltaT = temperaturEfterVarmeflade - tRef;
  final varmeforbrug = luftmaengde * 1.2 * 1.006 * deltaT;
  return justeringFaktor > 0 ? varmeforbrug * justeringFaktor / 3600 : varmeforbrug;
}

String beregnRenoveringsvurdering({
  required String varmeType,
  required double virkningsgrad,
}) {
  final Map<String, double> graenser = {
    'ingen': 0,
    'kryds': 40,
    'dobbelkryds': 60,
    'roterende': 60,
    'modstrøm': 30,
    'væskekoblet': 30,
    'blandekammer': 60,
  };

  // Normaliser input ved at fjerne specialtegn og gøre små bogstaver
  String normaliser(String input) {
    var output = input.toLowerCase();
    output = output.replaceAll(RegExp(r'[^\w\s]'), ''); // Fjern specialtegn
    output = output.replaceAll(RegExp(r'\s+'), ''); // Fjern mellemrum
    output = output.replaceAll('ø', 'oe');
    output = output.replaceAll('æ', 'ae');
    output = output.replaceAll('å', 'aa');
    return output;
  }

  final normaliseretInput = normaliser(varmeType);

  // Find matchende nøgle i graenser
  String? matchKey;
  for (var key in graenser.keys) {
    if (normaliseretInput.contains(normaliser(key))) {
      matchKey = key;
      break;
    }
  }

  if (matchKey == null) {
    return 'Ukendt varmegenvindingstype';
  }

  final graense = graenser[matchKey]!;

  return virkningsgrad < graense ? 'Ja' : 'Nej';
}
String hentTemperaturTekst(String anlaegstype) {
  switch (anlaegstype.toLowerCase()) {
    case 'indblæsningsanlæg':
    case 'indblaesningsanlaeg':
      return 'Er indblæsningstemperaturen opvarmet?';
    case 'udsugningsanlæg':
    case 'udsugningsanlaeg':
      return 'Er udsugningsluften opvarmet?';
    case 'ventilationsanlaeg':
    case 'ventilationsanlæg':
      return 'Er udetemperaturen over 10 °C?';
    default:
      return 'Er temperaturen opvarmet?';
  }
}