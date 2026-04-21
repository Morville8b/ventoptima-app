import 'package:flutter/material.dart';
import 'ventilator_samlet_beregning.dart';

class VentilatorKortData {
  final VentilatorOekonomiSamlet resultat;
  final String logoAsset;
  final String producentNavn;
  final double logoHeight;
  final double logoWidth;

  VentilatorKortData({
    required this.resultat,
    required this.logoAsset,
    required this.producentNavn,
    required this.logoHeight,
    required this.logoWidth,
  });
}

class VentilatorOekonomiKort extends StatelessWidget {
  final VentilatorOekonomiSamlet resultat;
  final String logoAsset;
  final String producentNavn;
  final double logoHeight;
  final double logoWidth;
  final BaseOekonomiResultat resultatInd;
  final BaseOekonomiResultat resultatUd;
  final BaseOekonomiResultat resultatMaxInd;
  final BaseOekonomiResultat resultatMaxUd;
  final double samletAarsforbrugKWh;
  final double samletOmkostning;
  final String anlaegsType;

  const VentilatorOekonomiKort({
    super.key,
    required this.resultat,
    required this.logoAsset,
    required this.producentNavn,
    required this.logoHeight,
    required this.logoWidth,
    required this.resultatInd,
    required this.resultatUd,
    required this.resultatMaxInd,
    required this.resultatMaxUd,
    required this.samletAarsforbrugKWh,
    required this.samletOmkostning,
    required this.anlaegsType,
  });

  @override
  Widget build(BuildContext context) {
    final dynamic oekonomi = resultat.oekonomi;

    // ✅ BEREGN VISNINGSVÆRDIER MED VARME
    final double visAarsbesparelse = oekonomi.aarsbesparelse + (oekonomi.varmeAarsbesparelse ?? 0);
    final double visSamletOmkostning = samletOmkostning + (oekonomi.varmeOmkostningEfter ?? 0);

    String formatNumber(double value, {int decimals = 1}) {
      if (value.isNaN || value.isInfinite) return '-';

      // Formatér med punktum som tusindtalsseparator
      final parts = value.toStringAsFixed(decimals).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]}.',
      );

      if (decimals > 0 && parts.length > 1) {
        return '$intPart,${parts[1]}';
      }
      return intPart;
    }

    final bool erTomtInd = resultatInd.varenummer.isEmpty;
    final bool erTomtUd = resultatUd.varenummer.isEmpty;
    final bool erTomtMaxInd = resultatMaxInd.varenummer.isEmpty;
    final bool erTomtMaxUd = resultatMaxUd.varenummer.isEmpty;

    String? kontakttekst;
    if (erTomtInd && erTomtUd && erTomtMaxInd && erTomtMaxUd) {
      if (producentNavn.toLowerCase().contains('ebmpapst')) {
        kontakttekst =
        'Ingen ventilator matcher de angivne tryk- og luftmængdeværdier. Kontakt Ebmpapst.';
      } else if (producentNavn.toLowerCase().contains('novenco')) {
        kontakttekst =
        'Ingen ventilator matcher de angivne tryk- og luftmængdeværdier. Kontakt Novenco.';
      } else if (producentNavn.toLowerCase().contains('ziehl')) {
        kontakttekst =
        'Ingen ventilator matcher de angivne tryk- og luftmængdeværdier. Kontakt Ziehl-Abegg.';
      } else {
        kontakttekst =
        'Ingen ventilator matcher de angivne tryk- og luftmængdeværdier. Kontakt producenten.';
      }
    }

    // ✅ TJEK OM DET ER NYT ANLÆG
    final bool erNytAnlaeg = resultat.varenummerInd.contains('Nyt anlæg');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  logoAsset,
                  width: logoWidth,
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Text(
                  producentNavn,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (kontakttekst != null) ...[
              const SizedBox(height: 12),
              Text(
                kontakttekst,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              // --- Indblæsning ---
              if ((anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') && !erTomtInd) ...[
                const SizedBox(height: 12),
                const Text('Efter optimering – Indblæsning',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Årligt elforbrug: ${formatNumber(resultatInd.aarsforbrugKWh)} kWh'),
                Text('Omkostning: ${formatNumber(resultatInd.omkostning)} kr./år'),
                Text('Effekt: ${formatNumber(resultatInd.effekt / 1000, decimals: 2)} kW'),
                Text('Tryk: ${formatNumber(resultatInd.tryk, decimals: 0)} Pa'),
                Text('Luftmængde: ${formatNumber(resultatInd.luftmaengde, decimals: 0)} m³/h'),
                Text('Virkningsgrad: ${formatNumber(resultatInd.virkningsgrad)} %'),
                Text('SEL-værdi: ${formatNumber(resultatInd.selvaerdi)} kJ/m³'),
                Text('Varenummer: ${resultatInd.varenummer}'),

                // ✅ Ved maksimal drift - vis kun hvis der faktisk ER max drift data
                if (!erTomtMaxInd && resultatMaxInd.varenummer.isNotEmpty &&
                    resultatMaxInd.luftmaengde > 0 && resultatMaxInd.tryk > 0) ...[
                  const SizedBox(height: 12),
                  // Hvis FORSKELLIG ventilator ved max drift - RØD ADVARSEL
                  if (resultatMaxInd.varenummer != resultatInd.varenummer) ...[
                    const Text('⚠️ Bemærk: Kræver anden ventilator ved maksimal drift',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Ved maksimal drift:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    Text('Varenummer: ${resultatMaxInd.varenummer}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Luftmængde: ${formatNumber(resultatMaxInd.luftmaengde, decimals: 0)} m³/h'),
                    Text('Tryk: ${formatNumber(resultatMaxInd.tryk, decimals: 0)} Pa'),
                  ]
                  // Hvis SAMME ventilator kan klare begge driftspunkter - GRØN BEKRÆFTELSE
                  else if (!resultatInd.varenummer.contains('Special anlæg - Indblæsning') &&
                      !resultatInd.varenummer.contains('Manuel') &&
                      !resultatInd.varenummer.contains('Nyt anlæg')) ...[
                    const Text('✓ Ventilatoren kan klare begge driftspunkter',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ],

              // --- Udsugning ---
              if ((anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') && !erTomtUd) ...[
                const SizedBox(height: 16),
                const Text('Efter optimering – Udsugning',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Årligt elforbrug: ${formatNumber(resultatUd.aarsforbrugKWh)} kWh'),
                Text('Omkostning: ${formatNumber(resultatUd.omkostning)} kr./år'),
                Text('Effekt: ${formatNumber(resultatUd.effekt / 1000, decimals: 2)} kW'),
                Text('Tryk: ${formatNumber(resultatUd.tryk, decimals: 0)} Pa'),
                Text('Luftmængde: ${formatNumber(resultatUd.luftmaengde, decimals: 0)} m³/h'),
                Text('Virkningsgrad: ${formatNumber(resultatUd.virkningsgrad)} %'),
                Text('SEL-værdi: ${formatNumber(resultatUd.selvaerdi)} kJ/m³'),
                Text('Varenummer: ${resultatUd.varenummer}'),

                // ✅ Ved maksimal drift - vis kun hvis der faktisk ER max drift data
                if (!erTomtMaxUd && resultatMaxUd.varenummer.isNotEmpty &&
                    resultatMaxUd.luftmaengde > 0 && resultatMaxUd.tryk > 0) ...[
                  const SizedBox(height: 12),
                  // Hvis FORSKELLIG ventilator ved max drift - RØD ADVARSEL
                  if (resultatMaxUd.varenummer != resultatUd.varenummer) ...[
                    const Text('⚠️ Bemærk: Kræver anden ventilator ved maksimal drift',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Ved maksimal drift:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    Text('Varenummer: ${resultatMaxUd.varenummer}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Luftmængde: ${formatNumber(resultatMaxUd.luftmaengde, decimals: 0)} m³/h'),
                    Text('Tryk: ${formatNumber(resultatMaxUd.tryk, decimals: 0)} Pa'),
                  ]
                  // Hvis SAMME ventilator kan klare begge driftspunkter - GRØN BEKRÆFTELSE
                  else if (!resultatUd.varenummer.contains('Special anlæg - Udsugning') &&
                      !resultatUd.varenummer.contains('Manuel') &&
                      !resultatUd.varenummer.contains('Nyt anlæg')) ...[
                    const Text('✓ Ventilatoren kan klare begge driftspunkter',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ],

              // ✅ RÆKKEFØLGE AFHÆNGER AF OM DET ER NYT ANLÆG
              if (erNytAnlaeg) ...[
                // NYT ANLÆG: Energiforbrug først, derefter Økonomi
                const SizedBox(height: 16),
                const Text('Samlet energiforbrug og driftsomkostning',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Samlet elforbrug: ${formatNumber(samletAarsforbrugKWh)} kWh/år'),
                Text('Samlet omkostning: ${formatNumber(visSamletOmkostning)} kr./år'),

                const SizedBox(height: 16),
                const Text('Økonomi', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Pris total: ${formatNumber(oekonomi.totalPris)} kr.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Økonomisk besparelse: ${formatNumber(visAarsbesparelse)} kr./år'),
                Text('Tilbagebetalingstid: ${formatNumber(oekonomi.tilbagebetalingstid)} år'),
              ] else ...[
                // VENTILATORER: Økonomi først, derefter Energiforbrug (som før)
                const SizedBox(height: 16),
                const Text('Økonomi', style: TextStyle(fontWeight: FontWeight.bold)),

                if ((anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
                    !erTomtInd &&
                    oekonomi.indPris > 0)
                  Text('Indblæsningsventilator: ${formatNumber(oekonomi.indPris)} kr.'),

                if ((anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
                    !erTomtUd &&
                    oekonomi.udPris > 0)
                  Text('Udsugningsventilator: ${formatNumber(oekonomi.udPris)} kr.'),

                if ((resultat.remUdskiftningPris ?? 0) > 0)
                  Text('Fradrag (rem og skiver): -${formatNumber(resultat.remUdskiftningPris ?? 0)} kr.'),

                const SizedBox(height: 8),
                Text(
                  'Pris total: ${formatNumber(oekonomi.totalPris)} kr.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),
                Text('Økonomisk besparelse: ${formatNumber(visAarsbesparelse)} kr./år'),  // ✅ RETTET!
                Text('Tilbagebetalingstid: ${formatNumber(oekonomi.tilbagebetalingstid)} år'),

                const SizedBox(height: 12),
                const Text('Samlet energiforbrug og driftsomkostning',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Samlet elforbrug: ${formatNumber(samletAarsforbrugKWh)} kWh/år'),
                Text('Samlet omkostning: ${formatNumber(visSamletOmkostning)} kr./år'),  // ✅ RETTET!
              ],
            ],
          ],
        ),
      ),
    );
  }
}

