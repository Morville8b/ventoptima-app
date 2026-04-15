import 'package:flutter/material.dart';
import 'anlaegs_data.dart';
import 'generel_projekt_info.dart';
import 'filter_resultat.dart';
import 'filter_resultat_skarm.dart';


class FilterSkarm extends StatefulWidget {
  final AnlaegsData anlaeg;
  final GenerelProjektInfo projektInfo;
  final int antalHeleFiltreInd;
  final int antalHalveFiltreInd;
  final int antalHeleFiltreUd;
  final int antalHalveFiltreUd;
  final List<AnlaegsData> alleAnlaeg;
  final int index;

  const FilterSkarm({
    super.key,
    required this.anlaeg,
    required this.projektInfo,
    required this.antalHeleFiltreInd,
    required this.antalHalveFiltreInd,
    required this.antalHeleFiltreUd,
    required this.antalHalveFiltreUd,
    required this.alleAnlaeg,
    required this.index,
  });

  @override
  State<FilterSkarm> createState() => _FilterSkarmState();
}

class _FilterSkarmState extends State<FilterSkarm> {
  String? valgtFilterFoerInd;
  String? valgtFilterFoerUd;

  // 🔹 Liste af filtertyper
  final List<String> filterTyper = [
    "Basic-Flo M5 G 1050 592 x 592 x 520",
    "Basic-Flo M5 G 1050 592 x 592 x 600",
    "Basic-Flo F7 G 2570 592 x 592 x 520",
    "Basic-Flo F7 G 2570 592 x 592 x 600",
    "Hiflo XLS M5 592 x 592 x 520",
    "Hiflo XLS M5 592 x 592 x 640",
    "Hiflo XLS F7 592 x 592 x 520",
    "Hiflo XLS F7 592 x 592 x 640",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filterberegning"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Indblæsning dropdown
            const Text("Indblæsning - gammelt filter"),
            DropdownButton<String>(
              isExpanded: true,
              value: valgtFilterFoerInd,
              hint: const Text("Vælg gammelt filter"),
              items: filterTyper
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) => setState(() => valgtFilterFoerInd = val),
            ),
            const Divider(height: 32),

            // Udsugning dropdown
            const Text("Udsugning - gammelt filter"),
            DropdownButton<String>(
              isExpanded: true,
              value: valgtFilterFoerUd,
              hint: const Text("Vælg gammelt filter"),
              items: filterTyper
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) => setState(() => valgtFilterFoerUd = val),
            ),
            const Spacer(),

            // 🔘 Beregn-knap
            ElevatedButton(
              onPressed: () {
                // 👉 Beregn total antal filtre
                final totalFiltreInd = (widget.antalHeleFiltreInd) + (widget.antalHalveFiltreInd);
                final totalFiltreUd = (widget.antalHeleFiltreUd) + (widget.antalHalveFiltreUd);

                debugPrint("🔍 I FilterSkarm - valgte filtre:");
                debugPrint("valgtFilterFoerInd: $valgtFilterFoerInd");
                debugPrint("valgtFilterFoerUd: $valgtFilterFoerUd");
                debugPrint("Hele ind=${widget.antalHeleFiltreInd}, Halve ind=${widget.antalHalveFiltreInd}");
                debugPrint("Hele ud=${widget.antalHeleFiltreUd}, Halve ud=${widget.antalHalveFiltreUd}");

                final filterValg = FilterValg(
                  filterFoerInd: valgtFilterFoerInd ?? "Basic-Flo F7 G 2570 592 x 592 x 520",
                  filterEfterInd: null,
                  filterFoerUd: valgtFilterFoerUd ?? "Basic-Flo F7 G 2570 592 x 592 x 520",
                  filterEfterUd: null,
                );

                final filterResultat = beregnFilterResultat(
                  antalFiltreInd: totalFiltreInd,
                  antalFiltreUd: totalFiltreUd,
                  kwInd: widget.anlaeg.kwInd,
                  kwUd: widget.anlaeg.kwUd,
                  elPris: widget.anlaeg.elpris,
                  trykGamleFiltreInd: widget.anlaeg.trykGamleFiltreInd ?? 0,
                  trykGamleFiltreUd: widget.anlaeg.trykGamleFiltreUd ?? 0,
                  luftInd: widget.anlaeg.luftInd,
                  luftUd: widget.anlaeg.luftUd,
                  driftstimer: widget.anlaeg.driftstimer,
                  virkningsgradInd: widget.anlaeg.virkningsgradInd,
                  virkningsgradUd: widget.anlaeg.virkningsgradUd,
                  filterFoerInd: filterValg.filterFoerInd,
                  filterFoerUd: filterValg.filterFoerUd,
                );

                // 👉 Lav opdateret anlæg med både valg og resultat
                final opdateret = widget.anlaeg.copyWith(
                  filterValg: filterValg,
                  filterResultat: filterResultat,
                  antalHeleFiltreInd: widget.antalHeleFiltreInd,
                  antalHalveFiltreInd: widget.antalHalveFiltreInd,
                  antalHeleFiltreUd: widget.antalHeleFiltreUd,
                  antalHalveFiltreUd: widget.antalHalveFiltreUd,
                  trykGamleFiltreInd: widget.anlaeg.trykGamleFiltreInd,
                  trykGamleFiltreUd: widget.anlaeg.trykGamleFiltreUd,
                  luftInd: widget.anlaeg.luftInd,
                  luftUd: widget.anlaeg.luftUd,
                  kwInd: widget.anlaeg.kwInd,
                  kwUd: widget.anlaeg.kwUd,
                  elpris: widget.anlaeg.elpris,
                  driftstimer: widget.anlaeg.driftstimer,
                  virkningsgradInd: widget.anlaeg.virkningsgradInd,
                  virkningsgradUd: widget.anlaeg.virkningsgradUd,
                );

                widget.alleAnlaeg[widget.index] = opdateret;
                widget.projektInfo.alleAnlaeg[widget.index] = opdateret;

                debugPrint("✅ GEMT FILTERVALG & RESULTAT:");
                debugPrint("Anlæg: ${opdateret.anlaegsNavn}");
                debugPrint("Hele ind=${opdateret.antalHeleFiltreInd}, Halve ind=${opdateret.antalHalveFiltreInd}");
                debugPrint("Hele ud=${opdateret.antalHeleFiltreUd}, Halve ud=${opdateret.antalHalveFiltreUd}");
                debugPrint("Resultat besparelse kWh: ${filterResultat.samletBesparelseKWh}");
                debugPrint("Resultat besparelse kr: ${filterResultat.samletBesparelseKr}");

                // 👉 Videre til resultatvisning
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FilterResultatSkarm(
                      anlaeg: opdateret,
                      projektInfo: widget.projektInfo,
                      antalHeleFiltreInd: widget.antalHeleFiltreInd,
                      antalHalveFiltreInd: widget.antalHalveFiltreInd,
                      antalHeleFiltreUd: widget.antalHeleFiltreUd,
                      antalHalveFiltreUd: widget.antalHalveFiltreUd,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34E0A1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Gem og vis resultat"),
            ),
          ],
        ),
      ),
    );
  }
}