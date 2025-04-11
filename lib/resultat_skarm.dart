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
  final String renoveringsVurdering;

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
    required this.renoveringsVurdering,
  });

  double beregnElforbrug(double kw, double timer) => kw * timer;

  double beregnVirkningsgrad(double luftmaengde, double tryk, double kw) {
    if (kw == 0) return 0;
    return ((luftmaengde / 3600) * tryk) / (kw * 1000) * 100;
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
    if (friskluftTemp >= 10) return -1;

    final delta = udsugningTemp - friskluftTemp;
    if (delta.abs() < 0.001) return -1;

    return beregnUdFra.toLowerCase() == "afkast"
        ? (udsugningTemp - afkastTemp) / delta * 100
        : (indblTempEfterGenvinding - friskluftTemp) / delta * 100;
  }

  double beregnVarmeforbrug() {
    final tRef = beregnTemperaturReference();
    final deltaT = indblTempEfterVarmeflade - tRef;
    return (luftmaengdeInd * 1.2 * 1.006 * deltaT * driftTimer) / 3600;
  }

  String formatNumber(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 'Ikke beregnet';
    final formatter = NumberFormat.decimalPattern('da_DK');
    return formatter.format(value.round());
  }

  @override
  Widget build(BuildContext context) {
    final elforbrugInd = beregnElforbrug(kwInd, driftTimer);
    final elforbrugUd = beregnElforbrug(kwUd, driftTimer);

    final virkningsgradInd = beregnVirkningsgrad(luftmaengdeInd, trykDifferensInd, kwInd);
    final virkningsgradUd = beregnVirkningsgrad(luftmaengdeUd, trykDifferensUd, kwUd);

    final varmegenvindingVirkningsgrad = beregnVarmegenvindingVirkningsgrad();
    final varmeforbrug = beregnVarmeforbrug();

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
            Text('Beregnet ud fra: ${beregnUdFra == 'afkast' ? 'Afkasttemperatur' : 'Indblæsningstemperatur'}'),
            Text('Virkningsgrad varmegenvinding: ${varmegenvindingVirkningsgrad < 0 ? 'Ikke beregnet' : '${formatNumber(varmegenvindingVirkningsgrad)} %'}'),
            Text('Varmeforbrug: ${formatNumber(varmeforbrug)} kWh/år'),
            Text('Kan varmegenvinding energioptimeres: $renoveringsVurdering',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
