// Opdateret version af ResultatInternSkarm med korrekt visning af tryk ved max drift
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'generel_projekt_info.dart';
import 'ebmpapst.dart';

class ResultatInternSkarm extends StatelessWidget {
  final String anlagsNavn;
  final double kwInd;
  final double luftInd;
  final double statiskTrykInd;
  final double statiskTrykUd;
  final double kwUd;
  final double luftUd;
  final double hzInd;
  final double hzUd;
  final GenerelProjektInfo projektInfo;
  final bool erBeregnetInd;
  final bool erBeregnetUd;
  final String eksisterendeVarenummerInd;
  final String eksisterendeVarenummerUd;
  final double? trykFoerIndMax;
  final double? trykEfterIndMax;
  final double? trykFoerUdMax;
  final double? trykEfterUdMax;

  const ResultatInternSkarm({
    super.key,
    required this.anlagsNavn,
    required this.kwInd,
    required this.luftInd,
    required this.statiskTrykInd,
    required this.statiskTrykUd,
    required this.kwUd,
    required this.luftUd,
    required this.hzInd,
    required this.hzUd,
    required this.projektInfo,
    required this.erBeregnetInd,
    required this.erBeregnetUd,
    required this.eksisterendeVarenummerInd,
    required this.eksisterendeVarenummerUd,
    this.trykFoerIndMax,
    this.trykEfterIndMax,
    this.trykFoerUdMax,
    this.trykEfterUdMax,
  });

  double beregnElforbrug(double kw, double timer) => kw * timer;

  double beregnVirkningsgrad(double luftmaengde, double tryk, double kw) {
    if (kw == 0) return 0;
    return ((luftmaengde / 3600.0) * tryk) / (kw * 1000.0) * 100.0;
  }

  double beregnSEL(double kw, double luftmaengde) {
    if (kw == 0 || luftmaengde == 0) return 0;
    return kw / (luftmaengde / 3600.0) * 1000;
  }

  double beregnOmkostning(double kWh, double elpris) => kWh * elpris;

  String formatNumber(double value, {int decimalPlaces = 1}) {
    if (value.isNaN || value.isInfinite || value < 0) return 'Ikke beregnet';
    final formatter = NumberFormat.decimalPattern('da_DK');
    return formatter.format(double.parse(value.toStringAsFixed(decimalPlaces)));
  }
  double beregnDriftstimer() {
    return projektInfo.driftTimerPrUge.fold(0.0, (sum, timer) => sum + timer) * projektInfo.ugerPerAar;
  }
  @override
  Widget build(BuildContext context) {

    // DEBUG: Udskriv inputværdier til virkningsgrad og SEL
    print('🔧 DEBUG: luftInd = $luftInd, statiskTrykInd = $statiskTrykInd, kwInd = $kwInd');
    print('🔧 DEBUG: luftUd = $luftUd, statiskTrykUd = $statiskTrykUd, kwUd = $kwUd');

    final double driftstimer = beregnDriftstimer();
    final double elforbrugInd = beregnElforbrug(kwInd, driftstimer);
    final double elforbrugUd = beregnElforbrug(kwUd, driftstimer);
    final double virkningsgradInd = beregnVirkningsgrad(luftInd, statiskTrykInd, kwInd);
    final double virkningsgradUd = beregnVirkningsgrad(luftUd, statiskTrykUd, kwUd);
    final double selInd = beregnSEL(kwInd, luftInd);
    final double selUd = beregnSEL(kwUd, luftUd);
    final double omkostningInd = beregnOmkostning(elforbrugInd, projektInfo.elPris);
    final double omkostningUd = beregnOmkostning(elforbrugUd, projektInfo.elPris);

    final EbmpapstResultat resultatInd = luftInd > 0 && statiskTrykInd > 0
        ? findNaermesteVentilator(statiskTrykInd, luftInd, driftstimer: driftstimer)
        : EbmpapstResultat(tryk: 0, luftmaengde: 0, effekt: 0, aarsforbrugKWh: 0, omkostning: 0, varenummer: '', kommentar: '', virkningsgrad: 0.0, selvaerdi: 0.0);

    final EbmpapstResultat resultatUd = luftUd > 0 && statiskTrykUd > 0
        ? findNaermesteVentilator(statiskTrykUd, luftUd, driftstimer: driftstimer)
        : EbmpapstResultat(tryk: 0, luftmaengde: 0, effekt: 0, aarsforbrugKWh: 0, omkostning: 0, varenummer: '', kommentar: '', virkningsgrad: 0.0, selvaerdi: 0.0);

    final double? statiskTrykMaxInd = (trykEfterIndMax != null && trykFoerIndMax != null)
        ? trykEfterIndMax! - trykFoerIndMax!
        : null;

    final double? statiskTrykMaxUd = (trykEfterUdMax != null && trykFoerUdMax != null)
        ? trykEfterUdMax! - trykFoerUdMax!
        : null;

    final bool visIndblaesningNote = erBeregnetInd && eksisterendeVarenummerInd.isNotEmpty && resultatInd.varenummer.isNotEmpty;
    final bool visUdsugningNote = erBeregnetUd && eksisterendeVarenummerUd.isNotEmpty && resultatUd.varenummer.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Intern beregning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Image.asset('assets/images/star_logo.png', height: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF34E0A1),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text('Anlægsnavn: $anlagsNavn', style: const TextStyle(color: Color(0xFF006390), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Før optimering – Indblæsning', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Elforbrug indblæsning: ${formatNumber(elforbrugInd)} kWh'),
                    Text('Virkningsgrad indblæsning: ${formatNumber(virkningsgradInd)} %'),
                    Text('SEL indblæsning: ${formatNumber(selInd)} W/(m³/s)'),
                    Text('Omkostning indblæsning: ${formatNumber(omkostningInd)} kr.'),

                    const SizedBox(height: 24),
                    const Text('Før optimering – Udsugning', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Elforbrug udsugning: ${formatNumber(elforbrugUd)} kWh'),
                    Text('Virkningsgrad udsugning: ${formatNumber(virkningsgradUd)} %'),
                    Text('SEL udsugning: ${formatNumber(selUd)} W/(m³/s)'),
                    Text('Omkostning udsugning: ${formatNumber(omkostningUd)} kr.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF34E0A1),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Beregnet med Ebmpapst', style: TextStyle(color: Color(0xFF006390), fontSize: 18, fontWeight: FontWeight.bold)),
                  Image.asset('assets/images/ebmpapst.png', height: 28),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Her vises data for efter optimering – indblæsning og udsugning som før
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Efter optimering – Indblæsning', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Årligt elforbrug: ${formatNumber(resultatInd.aarsforbrugKWh)} kWh'),
                    Text('Omkostning: ${formatNumber(resultatInd.omkostning)} kr./år'),
                    Text('Effekt: ${formatNumber(resultatInd.effekt)} W'),
                    Text('Tryk: ${formatNumber(resultatInd.tryk, decimalPlaces: 0)} Pa'),
                    Text('Luftmængde: ${formatNumber(resultatInd.luftmaengde, decimalPlaces: 0)} m³/h'),
                    Text('Virkningsgrad: ${formatNumber(resultatInd.virkningsgrad, decimalPlaces: 1)} %'),
                    Text('SEL-værdi: ${formatNumber(resultatInd.selvaerdi, decimalPlaces: 1)} kJ/m³'),
                    Text('Varenummer: ${resultatInd.varenummer}'),
                    if (visIndblaesningNote && eksisterendeVarenummerInd != resultatInd.varenummer)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('⚠ Den valgte ventilator ved maks. drift er ikke den samme som ved normal drift.', style: TextStyle(color: Colors.red)),
                      ),
                    if (hzInd < 50 && statiskTrykMaxInd != null) ...[
                      const SizedBox(height: 8),
                      const Text('Luftmængde samt statisk driftstryk ved max drift:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Luftmængde (max drift): ${formatNumber(luftInd, decimalPlaces: 0)} m³/h'),
                      Text('Statisk tryk (max drift): ${formatNumber(statiskTrykMaxInd)} Pa'),
                    ],
                    const SizedBox(height: 16),
                    const Text('Efter optimering – Udsugning', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Årligt elforbrug: ${formatNumber(resultatUd.aarsforbrugKWh)} kWh'),
                    Text('Omkostning: ${formatNumber(resultatUd.omkostning)} kr./år'),
                    Text('Effekt: ${formatNumber(resultatUd.effekt)} W'),
                    Text('Tryk: ${formatNumber(resultatUd.tryk, decimalPlaces: 0)} Pa'),
                    Text('Luftmængde: ${formatNumber(resultatUd.luftmaengde, decimalPlaces: 0)} m³/h'),
                    Text('Virkningsgrad: ${formatNumber(resultatUd.virkningsgrad, decimalPlaces: 1)} %'),
                    Text('SEL-værdi: ${formatNumber(resultatUd.selvaerdi, decimalPlaces: 1)} kJ/m³'),
                    Text('Varenummer: ${resultatUd.varenummer}'),
                    if (visUdsugningNote && eksisterendeVarenummerUd != resultatUd.varenummer)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('⚠ Den valgte ventilator ved maks. drift er ikke den samme som ved normal drift.', style: TextStyle(color: Colors.red)),
                      ),
                    if (hzUd < 50 && statiskTrykMaxUd != null) ...[
                      const SizedBox(height: 8),
                      const Text('Luftmængde samt statisk driftstryk ved max drift:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Luftmængde (max drift): ${formatNumber(luftUd, decimalPlaces: 0)} m³/h'),
                      Text('Statisk tryk (max drift): ${formatNumber(statiskTrykMaxUd)} Pa'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








