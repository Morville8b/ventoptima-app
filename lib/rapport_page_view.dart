import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'besparelseforslag_skarm.dart';
import 'dokumentation_visning_skarm.dart';
import 'anlaegs_data.dart';
import 'filter_resultat_skarm.dart';
import 'ventilator_samlet_beregning.dart'; // indeholder OekonomiResultat

class RapportPageView extends StatefulWidget {
  final List<BesparelseForslagSkarm> rapporter;

  const RapportPageView({super.key, required this.rapporter});

  @override
  State<RapportPageView> createState() => _RapportPageViewState();
}

class _RapportPageViewState extends State<RapportPageView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 Hvis der ingen rapporter er → vis fallback i stedet for sort skærm
    if (widget.rapporter.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Rapport"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Text(
            "Ingen rapporter tilgængelige",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final sider = <Widget>[];

// Hent den opdaterede alleAnlaeg liste fra første rapport
    var alleAnlaeg = widget.rapporter.isNotEmpty
        ? widget.rapporter[0].projektInfo.alleAnlaeg
        : <AnlaegsData>[];

// Sortér anlæggene efter korteste tilbagebetalingstid (TBT)
    alleAnlaeg = [...alleAnlaeg]..sort((a, b) {
      final ecoA = (widget.rapporter.firstWhere(
            (r) => r.anlaegsNavn == a.anlaegsNavn,
      ).alleForslag.first.oekonomi as OekonomiResultat)
          .tilbagebetalingstid;

      final ecoB = (widget.rapporter.firstWhere(
            (r) => r.anlaegsNavn == b.anlaegsNavn,
      ).alleForslag.first.oekonomi as OekonomiResultat)
          .tilbagebetalingstid;

      return ecoA.compareTo(ecoB);
    });

// Iterer gennem alle anlæg i korrekt rækkefølge
    for (int i = 0; i < alleAnlaeg.length; i++) {
      final anlaeg = alleAnlaeg[i];

      // Find tilsvarende rapport for dette anlæg
      BesparelseForslagSkarm? forslagSkarmNullable;
      try {
        forslagSkarmNullable = widget.rapporter.firstWhere(
              (r) => r.anlaegsNavn == anlaeg.anlaegsNavn,
        );
      } catch (e) {
        forslagSkarmNullable = null;
      }

      // Spring over hvis ingen rapport findes for dette anlæg
      if (forslagSkarmNullable == null) {
        debugPrint("⚠️ Ingen rapport fundet for ${anlaeg.anlaegsNavn} - springer over");
        continue;
      }

      // Nu kan vi sikkert bruge forslagSkarm som non-null
      final forslagSkarm = forslagSkarmNullable;

      debugPrint("📊 RAPPORT VISNING [$i]");
      debugPrint("Anlæg: ${anlaeg.anlaegsNavn}");
      debugPrint("Hele Ind-filtre: ${anlaeg.antalHeleFiltreInd}, Halve Ind-filtre: ${anlaeg.antalHalveFiltreInd}");
      debugPrint("Hele Ud-filtre: ${anlaeg.antalHeleFiltreUd}, Halve Ud-filtre: ${anlaeg.antalHalveFiltreUd}");
      debugPrint("FilterResultat = ${anlaeg.filterResultat}");

// 1️⃣ Besparelsesforslag
      sider.add(
        Builder(builder: (context) {
          try {
            return BesparelseForslagSkarm(
              alleForslag: forslagSkarm.alleForslag,
              elPris: forslagSkarm.elPris,
              varmePris: forslagSkarm.varmePris,
              projektInfo: forslagSkarm.projektInfo,
              anlaegsNavn: forslagSkarm.anlaegsNavn,
              anlaegsType: forslagSkarm.anlaegsType,
              valgtTilstand: forslagSkarm.valgtTilstand,
              varmeforbrugResultat: forslagSkarm.varmeforbrugResultat,
              friskluftTemp: forslagSkarm.friskluftTemp,
              elforbrugInd: forslagSkarm.elforbrugInd,
              virkningsgradInd: forslagSkarm.virkningsgradInd,
              selInd: forslagSkarm.selInd,
              omkostningInd: forslagSkarm.omkostningInd,
              elforbrugUd: forslagSkarm.elforbrugUd,
              virkningsgradUd: forslagSkarm.virkningsgradUd,
              selUd: forslagSkarm.selUd,
              omkostningUd: forslagSkarm.omkostningUd,
              samletFoerKWh: forslagSkarm.samletFoerKWh,
              samletFoerKr: forslagSkarm.samletFoerKr,
              filterResultat: anlaeg.filterResultat,
              onVisFilter: () {
                final current = _pageController.hasClients
                    ? _pageController.page?.toInt() ?? 0
                    : 0;
                if (current + 1 < sider.length) {
                  _pageController.animateToPage(
                    current + 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } else {
                  debugPrint("⚠️ Ingen næste side at vise");
                }
              },
            );
          } catch (e, s) {
            debugPrint("❌ FEJL i BesparelseForslagSkarm: $e\n$s");
            return const Scaffold(
              body: Center(child: Text("Fejl i besparelsesforslag")),
            );
          }
        }),
      );

// 2️⃣ Dokumentation
      sider.add(
        DokumentationVisningSkarm(
          anlaeg: anlaeg, // Brug det opdaterede anlæg fra alleAnlaeg
          projektInfo: forslagSkarm.projektInfo,
          rapporter: widget.rapporter,
          alleAnlaeg: alleAnlaeg, // Brug den opdaterede liste
          index: i,
        ),
      );

// 3️⃣ Filterresultat eller placeholder
      try {
        if ((anlaeg.antalHeleFiltreInd ?? 0) > 0 ||
            (anlaeg.antalHalveFiltreInd ?? 0) > 0 ||
            (anlaeg.antalHeleFiltreUd ?? 0) > 0 ||
            (anlaeg.antalHalveFiltreUd ?? 0) > 0) {
          sider.add(
            FilterResultatSkarm(
              anlaeg: anlaeg,
              projektInfo: forslagSkarm.projektInfo,
              antalHeleFiltreInd: anlaeg.antalHeleFiltreInd ?? 0,
              antalHalveFiltreInd: anlaeg.antalHalveFiltreInd ?? 0,
              antalHeleFiltreUd: anlaeg.antalHeleFiltreUd ?? 0,
              antalHalveFiltreUd: anlaeg.antalHalveFiltreUd ?? 0,
            ),
          );
        } else {
          sider.add(
            Scaffold(
              appBar: AppBar(
                title: const Text("Filter"),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              body: const Center(
                child: Text(
                  "Ingen filtre tilknyttet dette anlæg",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        }
      } catch (e, s) {
        debugPrint("❌ FEJL i FilterResultatSkarm: $e\n$s");
        sider.add(
          const Scaffold(
            body: Center(child: Text("Fejl i filterresultat")),
          ),
        );
      }
    } // 👈 lukker for-loop

    debugPrint("📑 Antal sider bygget: ${sider.length}");

// ✅ Normal visning
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rapport"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                try {
                  return PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    children: sider,
                  );
                } catch (e, s) {
                  debugPrint("❌ FEJL i PageView: $e\n$s");
                  return const Center(child: Text("Fejl under visning af rapport"));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: sider.length,
              effect: const WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: Color(0xFF34E0A1),
                dotColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
