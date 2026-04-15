import 'dart:io';
import 'package:flutter/material.dart';
import 'anlaegs_data.dart';
import 'filter_skarm.dart';
import 'rapport_page_view.dart';
import 'besparelseforslag_skarm.dart';
import 'generel_projekt_info.dart';

class DokumentationVisningSkarm extends StatelessWidget {
  final AnlaegsData anlaeg;
  final List<AnlaegsData> alleAnlaeg;
  final int index;
  final GenerelProjektInfo projektInfo;
  final List<BesparelseForslagSkarm> rapporter;

  const DokumentationVisningSkarm({
    super.key,
    required this.anlaeg,
    required this.alleAnlaeg,
    required this.index,
    required this.projektInfo,
    required this.rapporter,
  });

  @override
  Widget build(BuildContext context) {
    print("DEBUG >>> DokumentationVisningSkarm viser anlæg: ${anlaeg.anlaegsNavn}");
    print("DEBUG >>> anlaeg.dokumentation = ${anlaeg.dokumentation}");

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header med titel + logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dokumentation',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.asset(
                    'assets/images/bravida_logo_rgb_pos.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                  ),
                ],
              ),
            ),

            // Anlægsnavn felt
            Container(
              width: double.infinity,
              color: const Color(0xFF34E0A1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Anlægsnavn: ${anlaeg.anlaegsNavn}',
                style: const TextStyle(
                  color: Color(0xFF006390),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Liste med billeder + beskrivelser
            Expanded(
              child: (anlaeg.dokumentation == null || anlaeg.dokumentation!.isEmpty)
                  ? const Center(child: Text("Ingen billeder tilføjet"))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: anlaeg.dokumentation!.length,
                itemBuilder: (context, index) {
                  final doc = anlaeg.dokumentation![index];
                  final path = doc["path"] ?? "";
                  final beskrivelse = doc["beskrivelse"] ?? "";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (path.isNotEmpty && File(path).existsSync())
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print("❌ Kunne ikke loade billede: $path");
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.image_not_supported)),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            beskrivelse.isNotEmpty ? beskrivelse : "(Ingen beskrivelse)",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔘 Næste-knap
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Beregn total antal filtre (hele = 1, halve = 0.5)
                  final totalFiltreInd = (anlaeg.antalHeleFiltreInd ?? 0) + 0.5 * (anlaeg.antalHalveFiltreInd ?? 0);
                  final totalFiltreUd = (anlaeg.antalHeleFiltreUd ?? 0) + 0.5 * (anlaeg.antalHalveFiltreUd ?? 0);

                  if (totalFiltreInd > 0 || totalFiltreUd > 0) {
                    // Hvis der er filtre → gå til FilterSkarm
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FilterSkarm(
                          alleAnlaeg: alleAnlaeg,
                          index: index,
                          anlaeg: anlaeg,
                          projektInfo: projektInfo,
                          antalHeleFiltreInd: anlaeg.antalHeleFiltreInd ?? 0,
                          antalHalveFiltreInd: anlaeg.antalHalveFiltreInd ?? 0,
                          antalHeleFiltreUd: anlaeg.antalHeleFiltreUd ?? 0,
                          antalHalveFiltreUd: anlaeg.antalHalveFiltreUd ?? 0,
                        ),
                      ),
                    );
                  } else {
                    // Ellers gå direkte til RapportPageView
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RapportPageView(rapporter: rapporter),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34E0A1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Næste"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}