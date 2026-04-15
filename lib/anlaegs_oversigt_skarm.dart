import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ventoptima/ventilator_samlet_beregning.dart';
import 'package:ventoptima/besparelseforslag_skarm.dart';
import 'package:ventoptima/generel_projekt_info.dart';
import 'package:ventoptima/beregning_varmegenvinding_optimering.dart';
import 'package:ventoptima/anlaegs_data.dart';
import 'rapport_page_view.dart';
import 'filter_resultat.dart';
import 'rapport/rapport_forside_skarm.dart';
import 'rapport/rapport_preview.dart';
import 'package:ventoptima/maaledata_skarm.dart';

/// Tjek om et ventilatorforslag er gyldigt (har fundet en løsning)
bool erGyldigtVentilatorForslag(VentilatorOekonomiSamlet forslag) {
  final eco = forslag.oekonomi as OekonomiResultat;
  final double nytElforbrugInd = forslag.indNormal.aarsforbrugKWh;
  final double nytElforbrugUd = forslag.udNormal.aarsforbrugKWh;
  final double samletNytElforbrug = nytElforbrugInd + nytElforbrugUd;
  if (samletNytElforbrug <= 0) return false;
  if (eco.aarsbesparelse <= 0) return false;
  return true;
}

class AnlaegsOversigtSkarm extends StatelessWidget {
  final List<VentilatorOekonomiSamlet> alleForslag;
  final double elPris;
  final double varmePris;
  final GenerelProjektInfo projektInfo;

  const AnlaegsOversigtSkarm({
    Key? key,
    required this.alleForslag,
    required this.elPris,
    required this.varmePris,
    required this.projektInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fmtInt = NumberFormat.decimalPattern('da_DK')..maximumFractionDigits = 0;
    final fmtDec = NumberFormat.decimalPattern('da_DK')
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;

    final Map<String, List<VentilatorOekonomiSamlet>> grupperet = {};
    for (var v in alleForslag) {
      grupperet.putIfAbsent(v.anlaegsnavn, () => []).add(v);
    }

    final List<_OversigtEntry> entries = grupperet.entries.map((e) {
      final match = projektInfo.alleAnlaeg.firstWhere(
            (a) => a.anlaegsNavn == e.key,
        orElse: () => AnlaegsData.empty(),
      );

      final gyldigeForslag = e.value.where(erGyldigtVentilatorForslag).toList();

      if (gyldigeForslag.isEmpty) {
        final alleAnlaegsForslag = e.value;

        final harManuelData = alleAnlaegsForslag.any((f) =>
        f.varenummerInd.contains('Manuel') ||
            f.varenummerInd.contains('Nyt anlæg'));

        if (harManuelData) {
          final manuelForslag = alleAnlaegsForslag.firstWhere((f) =>
          f.varenummerInd.contains('Manuel') ||
              f.varenummerInd.contains('Nyt anlæg'));

          final eco = manuelForslag.oekonomi as OekonomiResultat;
          final bool erNytAnlaeg = manuelForslag.fabrikant.contains('Nyt Ventilationsanlæg');

          return _OversigtEntry(
            anlaegsType: manuelForslag.anlaegstype ?? "Anlæg",
            anlaegsnavn: e.key,
            omkostningFoer: match.omkostningFoer ?? eco.omkostningFoer,
            omkostningEfter: eco.omkostning,
            ventilatorBesparelse: eco.aarsbesparelse,
            varmeBesparelseKr: eco.varmeAarsbesparelse ?? 0,
            varmeBesparelseKWh: eco.varmeBesparelseKWh ?? 0,
            samletBesparelse: eco.aarsbesparelse + (eco.varmeAarsbesparelse ?? 0),
            tilbagebetalingstid: eco.tilbagebetalingstid,
            varmeOmkostningFoer: eco.varmeOmkostningFoer ?? 0,
            varmeOmkostningEfter: eco.varmeOmkostningEfter ?? 0,
            valgtTilstand: match.valgtTilstand ?? '0',
            antalGyldige: 1,
            manglenedFabrikanter: [],
            erNytVentilationsanlaeg: erNytAnlaeg,
          );
        }

        final driftstimer = projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) * projektInfo.ugerPerAar;
        final omkostningFoer = (match.kwInd + match.kwUd) * driftstimer * match.elpris;

        return _OversigtEntry(
          anlaegsType: match.valgtAnlaegstype,
          anlaegsnavn: e.key,
          omkostningFoer: omkostningFoer,
          omkostningEfter: omkostningFoer,
          ventilatorBesparelse: 0,
          varmeBesparelseKr: match.varmeAarsbesparelse ?? 0,
          varmeBesparelseKWh: match.varmeBesparelseKWh ?? 0,
          samletBesparelse: (match.varmeAarsbesparelse ?? 0),
          tilbagebetalingstid: double.infinity,
          varmeOmkostningFoer: match.varmeOmkostningFoer ?? 0,
          varmeOmkostningEfter: match.varmeOmkostningEfter ?? 0,
          valgtTilstand: match.valgtTilstand ?? '0',
          antalGyldige: 0,
          manglenedFabrikanter: ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'],
          erNytVentilationsanlaeg: false,
        );
      }

      final valgtForslag = gyldigeForslag.reduce((a, b) {
        final aT = (a.oekonomi as OekonomiResultat).tilbagebetalingstid;
        final bT = (b.oekonomi as OekonomiResultat).tilbagebetalingstid;
        return aT < bT ? a : b;
      });

      final eco = valgtForslag.oekonomi as OekonomiResultat;
      final alleFabrikanter = ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
      final gyldigeFabrikanter = gyldigeForslag.map((f) => f.fabrikant).toSet();
      final manglenedFabrikanter = alleFabrikanter.where((f) => !gyldigeFabrikanter.contains(f)).toList();
      final bool erNytAnlaeg = valgtForslag.fabrikant.contains('Nyt Ventilationsanlæg');

      return _OversigtEntry(
        anlaegsType: valgtForslag.anlaegstype ?? "Anlæg",
        anlaegsnavn: e.key,
        omkostningFoer: match.omkostningFoer ?? eco.omkostningFoer,
        omkostningEfter: eco.omkostning,
        ventilatorBesparelse: eco.aarsbesparelse,
        varmeBesparelseKr: match.varmeAarsbesparelse ?? 0,
        varmeBesparelseKWh: match.varmeBesparelseKWh ?? 0,
        samletBesparelse: eco.aarsbesparelse + (match.varmeAarsbesparelse ?? 0),
        tilbagebetalingstid: eco.tilbagebetalingstid,
        varmeOmkostningFoer: match.varmeOmkostningFoer ?? 0,
        varmeOmkostningEfter: match.varmeOmkostningEfter ?? 0,
        valgtTilstand: match.valgtTilstand ?? '0',
        antalGyldige: gyldigeForslag.length,
        manglenedFabrikanter: manglenedFabrikanter,
        erNytVentilationsanlaeg: erNytAnlaeg,
      );
    }).toList();

    entries.sort((a, b) => a.tilbagebetalingstid.compareTo(b.tilbagebetalingstid));

    final maxFoer = entries.isNotEmpty
        ? entries.map((e) => e.omkostningFoer).reduce((a, b) => a > b ? a : b)
        : 1.0;

    final maxVarmeFoer = entries.isNotEmpty
        ? entries.map((e) => e.varmeOmkostningFoer).reduce((a, b) => a > b ? a : b)
        : 1.0;

    const Color primaryGreen = Color(0xFF34E0A1);
    const Color primaryBlue = Color(0xFF006390);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Samlet besparelsespotentiale', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 45),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: entries.isEmpty
                  ? const Center(child: Text('Ingen forslag at vise'))
                  : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (ctx, idx) {
                  final v = entries[idx];
                  final foer = fmtInt.format(v.omkostningFoer);
                  final efter = fmtInt.format(v.omkostningEfter);
                  final ventBesp = fmtInt.format(v.ventilatorBesparelse);
                  final varmeBespKr = fmtInt.format(v.varmeBesparelseKr);
                  final varmeBespKWh = fmtInt.format(v.varmeBesparelseKWh);
                  final total = fmtInt.format(v.samletBesparelse);
                  final tid = v.ventilatorBesparelse > 0 ? fmtDec.format(v.tilbagebetalingstid) : '-';
                  final barF = v.omkostningFoer / maxFoer;
                  final barE = v.omkostningEfter / maxFoer;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: const BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Text(
                              "${v.anlaegsType} - ${v.anlaegsnavn}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ventilatoroptimering', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                                const SizedBox(height: 8),

                                if (v.antalGyldige > 0) ...[
                                  _barLine('Årlige EL - omkostninger Før', foer, barF, Colors.black),
                                  const SizedBox(height: 4),
                                  _barLine('Årlige EL - omkostninger Efter', efter, barE, Colors.black),
                                  const SizedBox(height: 12),
                                  Text('Årlig besparelse EL: $ventBesp kr/år', style: const TextStyle(fontSize: 14, color: Colors.green)),
                                  const SizedBox(height: 12),
                                  Text(
                                    v.erNytVentilationsanlaeg
                                        ? 'Tilbagebetalingstid (nyt anlæg): $tid år'
                                        : 'Tilbagebetalingstid (ventilator): $tid år',
                                    style: const TextStyle(fontSize: 15, color: Colors.black),
                                  ),
                                ] else ...[
                                  _barLine('Årlige EL - omkostninger Før', foer, barF, Colors.black),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange, width: 1.5),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(child: Text('SPECIALANLÆG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('Dette anlæg ligger uden for de tre leverandørers standardsortiment.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                if (v.varmeOmkostningFoer > 0) ...[
                                  const Text('Varmeoptimering', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          'Årlige varmeomkostninger Før: ${fmtInt.format(v.varmeOmkostningFoer)} kr/år',
                                          style: const TextStyle(fontSize: 14, color: Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 4,
                                        child: Stack(
                                          children: [
                                            Container(height: 10, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
                                            FractionallySizedBox(
                                              widthFactor: (v.varmeOmkostningFoer / maxVarmeFoer).clamp(0.0, 1.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  height: 10,
                                                  color: (v.varmeBesparelseKr > 0) ? Colors.red : (v.anlaegsType.toLowerCase().contains('ventilationsanlæg')) ? Colors.green : Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.circle, size: 12, color: (v.varmeBesparelseKr > 0) ? Colors.red : (v.anlaegsType.toLowerCase().contains('ventilationsanlæg')) ? Colors.green : Colors.red),
                                    ],
                                  ),

                                  if (v.varmeBesparelseKr > 0) ...[
                                    const SizedBox(height: 4),
                                    _barLine('Årlige varmeomkostninger Efter', fmtInt.format(v.varmeOmkostningEfter), v.varmeOmkostningFoer > 0 ? v.varmeOmkostningEfter / maxVarmeFoer : 0, Colors.black),
                                    const SizedBox(height: 12),
                                    Text('Varmebesparelse: $varmeBespKr kr/år ($varmeBespKWh kWh/år)', style: const TextStyle(fontSize: 15, color: Colors.green)),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.info_outline, color: Colors.grey, size: 18),
                                        const SizedBox(width: 6),
                                        const Expanded(
                                          child: Text(
                                            'Renovering af varmegenvinding er ikke prissat, da det kræver inspektion af anlæggets indre komponenter',
                                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      v.anlaegsType.toLowerCase().contains('ventilationsanlæg')
                                          ? 'Anlægget kan ikke optimeres yderligere på varmegenvinding'
                                          : 'Anlægget har ingen varmegenvinding. Varmetabet kan kun reduceres ved installation af varmegenvindingssystem eller udskiftning til anlæg med integreret varmegenvinding.',
                                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                                    ),
                                  ],
                                ] else if (v.varmeOmkostningEfter > 0) ...[
                                  Text(
                                    "Da udetemperaturen har været over 10 °C, har det ikke været muligt at fastsætte virkningsgraden på varmegenvindingen.",
                                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                                  ),
                                ],

                                const SizedBox(height: 20),
                                Text('Samlet årlig besparelse: $total kr/år', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),

                                const SizedBox(height: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tilstandsvurdering', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                                    const SizedBox(height: 4),
                                    Text('Anlægget er ${_tekstForTilstand(v.valgtTilstand)}', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: _getTilstandsfarve(v.valgtTilstand))),
                                    const SizedBox(height: 8),
                                    Text(_tilstandsKommentar(v.valgtTilstand), textAlign: TextAlign.left, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: primaryBlue,
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () {
                            final entriesSorterede = grupperet.entries.toList()
                              ..sort((a, b) {
                                final ecoA = (a.value.first.oekonomi as OekonomiResultat).tilbagebetalingstid;
                                final ecoB = (b.value.first.oekonomi as OekonomiResultat).tilbagebetalingstid;
                                return ecoA.compareTo(ecoB);
                              });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RapportPageView(
                                  rapporter: entriesSorterede.map((e) {
                                    final anlaegsForslag = alleForslag.where((f) => f.anlaegsnavn == e.key).toList();
                                    final match = projektInfo.alleAnlaeg.firstWhere((a) => a.anlaegsNavn == e.key, orElse: () => AnlaegsData.empty());
                                    final driftstimer = projektInfo.driftTimerPrUge.fold(0.0, (sum, timer) => sum + timer) * projektInfo.ugerPerAar;
                                    final elforbrugInd = match.kwInd * driftstimer;
                                    final elforbrugUd = match.kwUd * driftstimer;

                                    return BesparelseForslagSkarm(
                                      alleForslag: anlaegsForslag,
                                      elPris: elPris,
                                      varmePris: varmePris,
                                      projektInfo: projektInfo,
                                      anlaegsNavn: e.key,
                                      anlaegsType: match.valgtAnlaegstype,
                                      varmeforbrugResultat: match.varmeResultat,
                                      elforbrugInd: elforbrugInd,
                                      omkostningInd: match.elOmkostningIndFoer ?? 0,
                                      elforbrugUd: elforbrugUd,
                                      omkostningUd: match.elOmkostningUdFoer ?? 0,
                                      samletFoerKWh: elforbrugInd + elforbrugUd,
                                      samletFoerKr: match.omkostningFoer ?? 0,
                                      valgtTilstand: match.valgtTilstand,
                                      filterResultat: match.filterResultat,
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                          child: const Text('Videre til resultat'),
                        ),
                      ),

                      SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: primaryBlue,
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RapportPreview(
                                  projektInfo: projektInfo,
                                  alleAnlaeg: projektInfo.alleAnlaeg,
                                  alleForslag: alleForslag,
                                  elPris: elPris,
                                  varmePris: varmePris,
                                ),
                              ),
                            );
                          },
                          child: const Text('Generer rapport'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🆕 RET ET ANLÆG KNAP
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, color: primaryBlue),
                      label: const Text('Ret et anlæg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryGreen, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () async {
                        final valgtIndex = await showDialog<int>(
                          context: context,
                          builder: (context) => AlertDialog(
                            titlePadding: EdgeInsets.zero,
                            title: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: const Text('Vælg anlæg der skal rettes', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: projektInfo.alleAnlaeg.length,
                                itemBuilder: (context, i) {
                                  final anlaeg = projektInfo.alleAnlaeg[i];
                                  return ListTile(
                                    leading: const Icon(Icons.settings, color: primaryBlue),
                                    title: Text('${anlaeg.valgtAnlaegstype} - ${anlaeg.anlaegsNavn}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    onTap: () => Navigator.pop(context, i),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('Annuller', style: TextStyle(color: primaryBlue)),
                              ),
                            ],
                          ),
                        );

                        if (valgtIndex == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaaledataSkarm(
                              forslag: alleForslag,
                              projektInfo: projektInfo.copyWithIndex(valgtIndex),
                              index: valgtIndex,
                              alleAnlaeg: projektInfo.alleAnlaeg,
                              driftstimer: {
                                'Mandag': TextEditingController(text: projektInfo.driftTimerPrUge.isNotEmpty ? projektInfo.driftTimerPrUge[0].toInt().toString() : '0'),
                                'Tirsdag': TextEditingController(text: projektInfo.driftTimerPrUge.length > 1 ? projektInfo.driftTimerPrUge[1].toInt().toString() : '0'),
                                'Onsdag': TextEditingController(text: projektInfo.driftTimerPrUge.length > 2 ? projektInfo.driftTimerPrUge[2].toInt().toString() : '0'),
                                'Torsdag': TextEditingController(text: projektInfo.driftTimerPrUge.length > 3 ? projektInfo.driftTimerPrUge[3].toInt().toString() : '0'),
                                'Fredag': TextEditingController(text: projektInfo.driftTimerPrUge.length > 4 ? projektInfo.driftTimerPrUge[4].toInt().toString() : '0'),
                                'Lørdag': TextEditingController(text: projektInfo.driftTimerPrUge.length > 5 ? projektInfo.driftTimerPrUge[5].toInt().toString() : '0'),
                                'Søndag': TextEditingController(text: projektInfo.driftTimerPrUge.length > 6 ? projektInfo.driftTimerPrUge[6].toInt().toString() : '0'),
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _barLine(String label, String value, double fraction, Color textColor) {
    final Color barColor = label.contains('Før') ? Colors.red : Colors.green;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Text('$label: $value kr/år', style: TextStyle(fontSize: 14, color: textColor), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              Container(height: 10, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(height: 10, color: barColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.circle, size: 12, color: barColor),
      ],
    );
  }

  String _tekstForTilstand(String valgtTilstand) {
    switch (valgtTilstand) {
      case '1': return 'i god stand';
      case '2': return 'rimelig stand';
      case '3': return 'slidt – kræver opmærksomhed';
      case '4': return 'kritisk – bør optimeres';
      case '5': return 'meget kritisk – akut behov';
      case '6': return 'ude af drift';
      default: return 'uden vurdering';
    }
  }

  Color _getTilstandsfarve(String valgtTilstand) {
    switch (valgtTilstand) {
      case '1': return Colors.green;
      case '2': return Colors.lightGreen;
      case '3': return Colors.orange;
      case '4': return Colors.deepOrange;
      case '5': return Colors.red;
      case '6': return Colors.black;
      default: return Colors.grey;
    }
  }

  String _tilstandsKommentar(String valgtTilstand) {
    switch (valgtTilstand) {
      case '1': return 'Da anlægget er i god stand, er det oplagt at gennemføre en energioptimering, da investeringen kan udnyttes fuldt ud og skabe størst mulig værdi.';
      case '2': return 'Anlægget er i rimelig stand med mindre slitage registreret. Det kan fortsat fungere uden større problemer, men en energioptimering kan være fordelagtig for at reducere driftsomkostninger og forlænge levetiden.';
      case '3': return 'Anlægget er slidt og har en restlevetid på 1–3 år. Det bør vurderes, om en renovering kan forlænge levetiden, eller om en udskiftning er mere hensigtsmæssig. Ved begge løsninger bør energioptimering indgå som en naturlig del af indsatsen.';
      case '4': return 'Anlægget er i kritisk stand og bør udskiftes eller gennemgå en større renovering inden for det næste år. Det anbefales at planlægge indsatsen i god tid og samtidig inddrage energioptimering som en central del af løsningen.';
      case '5': return 'Anlægget er i meget kritisk stand og kræver en større indsats. Der bør planlægges omfattende renovering eller udskiftning, hvor energioptimering indgå som en del af løsningen.';
      case '6': return 'Anlægget er ikke længere funktionsdygtigt og skal udskiftes. I forbindelse med udskiftningen anbefales det at vælge en løsning med fokus på energioptimering.';
      default: return '';
    }
  }
}

class _OversigtEntry {
  final String anlaegsType;
  final String anlaegsnavn;
  final double omkostningFoer;
  final double omkostningEfter;
  final double ventilatorBesparelse;
  final double varmeBesparelseKr;
  final double varmeBesparelseKWh;
  final double samletBesparelse;
  final double tilbagebetalingstid;
  final double varmeOmkostningFoer;
  final double varmeOmkostningEfter;
  final String valgtTilstand;
  final int antalGyldige;
  final List<String> manglenedFabrikanter;
  final bool erNytVentilationsanlaeg;

  _OversigtEntry({
    required this.anlaegsType,
    required this.anlaegsnavn,
    required this.omkostningFoer,
    required this.omkostningEfter,
    required this.ventilatorBesparelse,
    required this.varmeBesparelseKr,
    required this.varmeBesparelseKWh,
    required this.samletBesparelse,
    required this.tilbagebetalingstid,
    required this.varmeOmkostningFoer,
    required this.varmeOmkostningEfter,
    required this.valgtTilstand,
    required this.antalGyldige,
    required this.manglenedFabrikanter,
    required this.erNytVentilationsanlaeg,
  });
}
