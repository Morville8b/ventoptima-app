import 'package:intl/intl.dart';

/// Beregner elforbrug i kWh baseret på kW og driftstimer
double beregnElforbrug(double kw, double driftTimer) {
  return kw * driftTimer;
}

/// Beregner virkningsgraden for en ventilator i procent
double beregnVirkningsgrad(double luftmaengde, double tryk, double kw) {
  if (kw == 0) return 0;
  return ((luftmaengde / 3600) * tryk) / (kw * 1000) * 100;
}

/// Klasse til opsamling af resultater for en ventilator
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
    final formatter = NumberFormat.decimalPattern('da_DK');
    return '$navn\nElforbrug: ${formatter.format(elforbrug)} kWh\nVirkningsgrad: ${formatter.format(virkningsgrad)} %';
  }
}

/// Beregner både elforbrug og virkningsgrad for en ventilator
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

/// Returnerer reference-temperatur baseret på driftstype
double hentTemperaturReference(String driftType) {
  switch (driftType.toLowerCase()) {
    case 'døgn':
    case 'doegn':
      return 8.9;
    case 'dagtimer':
    case 'dags timer':
      return 12.0;
    case 'nattetimer':
    case 'natte timer':
      return 5.6;
    default:
      return 0.0;
  }
}

/// Beregner varmeforbrug i kWh ud fra luftmængde, temperatur og justeringsfaktor
/// Justeringsfaktor er typisk antal driftstimer
double beregnVarmeforbrug({
  required String anlaegstype,
  required String driftType,
  required double luftmaengde,
  required double temperaturEfterVarmeflade,
  required double justeringFaktor,
}) {
  final tRef = hentTemperaturReference(driftType);
  final deltaT = temperaturEfterVarmeflade - tRef;
  final varmeforbrug = luftmaengde * 1.2 * 1.006 * deltaT;
  return varmeforbrug * justeringFaktor / 3600;
}

/// Returnerer "Ja" eller "Nej" afhængig af om virkningsgraden er lavere end den fastsatte grænse for typen
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

  String normaliser(String input) {
    var output = input.toLowerCase();
    output = output.replaceAll(RegExp(r'[^\w\s]'), '');
    output = output.replaceAll(RegExp(r'\s+'), '');
    output = output.replaceAll('ø', 'oe').replaceAll('æ', 'ae').replaceAll('å', 'aa');
    return output;
  }

  final input = normaliser(varmeType);
  if (virkningsgrad.isNaN || virkningsgrad < 0) return 'Ikke beregnet';

  for (var key in graenser.keys) {
    if (input.contains(normaliser(key))) {
      return virkningsgrad < graenser[key]! ? 'Ja' : 'Nej';
    }
  }
  return 'Ukendt varmegenvindingstype';
}

/// Returnerer tilpasset tekst til temperaturspørgsmål
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
