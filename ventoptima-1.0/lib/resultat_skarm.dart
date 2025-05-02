import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultatSkarm extends StatelessWidget {
  final double kwInd;
  final double luftmaengdeInd;
  final double trykDifferensInd;
  final double driftTimer;
  final double kwUd;
  final double luftmaengdeUd;
  final double trykDifferensUd;
  final double friskluftTemp;
  final double indblTempEfterGenvinding;
  final double indblTempEfterVarmeflade;
  final double afkastTemp;
  final double udsugningTemp;
  final String varmegenvindingstype;
  final String driftType;
  final String beregnUdFra;

  const ResultatSkarm({
    super.key,
    required this.kwInd,
    required this.luftmaengdeInd,
    required this.trykDifferensInd,
    required this.driftTimer,
    required this.kwUd,
    required this.luftmaengdeUd,
    required this.trykDifferensUd,
    required this.friskluftTemp,
    required this.indblTempEfterGenvinding,
    required this.indblTempEfterVarmeflade,
    required this.afkastTemp,
    required this.udsugningTemp,
    required this.varmegenvindingstype,
    required this.driftType,
    required this.beregnUdFra,
  });

  double beregnElforbrug(double kw, double timer) => kw * timer;

  double beregnVirkningsgrad(double luftmaengde, double tryk, double kw) {
    if (kw == 0) return 0;
    return ((luftmaengde / 3600.0) * tryk) / (kw * 1000.0) * 100.0;
  }

  double beregnTemperaturReference() {
    switch (driftType.toLowerCase()) {
      case 'dagtimer':
        return 12.0;
      case 'nattetimer':
        return 5.6;
      case 'døgn':
      case 'døgndrift':
        return 8.9;
      default:
        return 0.0;
    }
  }

  double beregnVarmegenvindingVirkningsgrad() {
    final double delta = udsugningTemp - friskluftTemp;
    if (delta.abs() < 0.001) return -1;
    return beregnUdFra.toLowerCase() == "afkast"
        ? (udsugningTemp - afkastTemp) / delta * 100.0
        : (indblTempEfterGenvinding - friskluftTemp) / delta * 100.0;
  }

  double beregnVarmeforbrug() {
    final double tRef = beregnTemperaturReference();
    final double deltaT = indblTempEfterVarmeflade - tRef;
    return (luftmaengdeInd * 1.2 * 1.006 * deltaT * driftTimer) / 3600.0;
  }

  String vurderRenovering(String varmeType, double maaltVirkningsgrad) {
    double minGraense;

    String normaliser(String input) {
      var output = input.toLowerCase();
      output = output.replaceAll('ø', 'oe').replaceAll('æ', 'ae').replaceAll('å', 'aa');
      output = output.replaceAll(RegExp(r'[^\w\s]'), '');
      output = output.replaceAll(RegExp(r'\s+'), '');
      return output;
    }

    final input = normaliser(varmeType);

    if (input.contains('ingen')) minGraense = 0;
    else if (input.contains('dobbelkryds')) minGraense = 60;
    else if (input.contains('kryds')) minGraense = 40;
    else if (input.contains('roterende')) minGraense = 60;
    else if (input.contains('modstroem') || input.contains('modstroems')) minGraense = 30;
    else if (input.contains('vaeskekoblet')) minGraense = 30;
    else if (input.contains('blandekammer')) minGraense = 60;
    else return 'Ukendt type';

    return maaltVirkningsgrad < minGraense ? 'Ja' : 'Nej';
  }

  String formatNumber(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 'Ikke beregnet';
    final formatter = NumberFormat.decimalPattern('da_DK');
    return formatter.format(value.round());
  }

  @override
  Widget build(BuildContext context) {
    final double elforbrugInd = beregnElforbrug(kwInd, driftTimer);
    final double elforbrugUd = beregnElforbrug(kwUd, driftTimer);

    final double virkningsgradInd = beregnVirkningsgrad(luftmaengdeInd, trykDifferensInd, kwInd);
    final double virkningsgradUd = beregnVirkningsgrad(luftmaengdeUd, trykDifferensUd, kwUd);

    final bool erIndblaesning = luftmaengdeInd > 0 && luftmaengdeUd == 0;
    final bool erUdsugning = luftmaengdeUd > 0 && luftmaengdeInd == 0;
    final bool erVentilationsAnlaeg = luftmaengdeInd > 0 && luftmaengdeUd > 0;

    final double varmegenvindingVirkningsgrad = erVentilationsAnlaeg && friskluftTemp < 10
        ? beregnVarmegenvindingVirkningsgrad()
        : -1;

    final double varmeforbrug = erVentilationsAnlaeg && friskluftTemp < 10
        ? beregnVarmeforbrug()
        : -1;

    final String renoveringsVurdering = erVentilationsAnlaeg && friskluftTemp < 10
        ? vurderRenovering(varmegenvindingstype, varmegenvindingVirkningsgrad)
        : 'Ikke relevant';

    return Scaffold(
      appBar: AppBar(title: const Text('Resultat - Ventilatorer og Varmegenvinding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Beregning af ventilatorers elforbrug og virkningsgrad:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text('Indblæsningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Årligt elforbrug: ${formatNumber(elforbrugInd)} kWh/år'),
            Text('Virkningsgrad: ${formatNumber(virkningsgradInd)} %'),
            Text.rich(
              TextSpan(
                text: 'Kan indblæsningsventilator energioptimeres: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: virkningsgradInd < 50 ? 'Ja' : 'Nej',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Udsugningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Årligt elforbrug: ${formatNumber(elforbrugUd)} kWh/år'),
            Text('Virkningsgrad: ${formatNumber(virkningsgradUd)} %'),
            Text.rich(
              TextSpan(
                text: 'Kan udsugningsventilator energioptimeres: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: virkningsgradUd < 50 ? 'Ja' : 'Nej',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Varmegenvinding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Driftperiode: $driftType'),
            if (erVentilationsAnlaeg && friskluftTemp < 10) ...[
              Text('Beregnet ud fra: ${beregnUdFra == 'afkast' ? 'Afkasttemperatur' : 'Indblæsningstemperatur'}'),
              Text('Virkningsgrad varmegenvinding: ${varmegenvindingVirkningsgrad < 0 ? 'Ikke beregnet' : '${formatNumber(varmegenvindingVirkningsgrad)} %'}'),
              Text('Varmeforbrug: ${formatNumber(varmeforbrug)} kWh/år'),
              Text('Kan varmegenvinding energioptimeres: $renoveringsVurdering', style: const TextStyle(fontWeight: FontWeight.bold)),
            ] else if (erIndblaesning) ...[
              Text('Indblæsning efter varmeflade: ${formatNumber(indblTempEfterVarmeflade)} °C'),
            ] else if (erUdsugning) ...[
              Text('Udsugningstemperatur: ${formatNumber(udsugningTemp)} °C'),
            ]
          ],
        ),
      ),
    );
  }
}
