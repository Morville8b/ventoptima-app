import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'rapport_pdf_generator.dart';
import 'package:ventoptima/rapport/rapport_pdf_generator_intern.dart';
import 'package:ventoptima/generel_projekt_info.dart';
import 'package:ventoptima/anlaegs_data.dart';
import 'package:ventoptima/ventilator_samlet_beregning.dart';
import 'package:ventoptima/rapport/vis_send_rapport_popup.dart';
import 'package:ventoptima/rapport/rapport_pdf_generator_intern_projekt_forside.dart';
import 'package:ventoptima/ebmpapst.dart' as ebmpapst;
import 'package:ventoptima/novenco.dart' as novenco;
import 'package:ventoptima/ziehlabegg.dart' as ziehl;

class RapportPreview extends StatefulWidget {
  final GenerelProjektInfo projektInfo;
  final List<AnlaegsData> alleAnlaeg;
  final List<VentilatorOekonomiSamlet> alleForslag;
  final double elPris;
  final double varmePris;

  const RapportPreview({
    Key? key,
    required this.projektInfo,
    required this.alleAnlaeg,
    required this.alleForslag,
    required this.elPris,
    required this.varmePris,
  }) : super(key: key);

  @override
  State<RapportPreview> createState() => _RapportPreviewState();
}

class _RapportPreviewState extends State<RapportPreview> {
  bool _isLoading = true;
  String? _errorMessage;
  String _statusTekst = "Generer rapport";
  Uint8List? _kundePdf;
  Uint8List? _tekniskPdf;
  bool _visTeknikPdf = false;
  bool _isLoadingPdfSwitch = false;
  double _progress = 0.0;
  String _currentStep = "";

  @override
  void initState() {
    super.initState();
    _generatePdfs();
  }

  // ✅ HJÆLPEFUNKTION: Opret dummy-forslag for SPECIALANLÆG
  VentilatorOekonomiSamlet _createDummyForslag(String fabrikant) {
    // Brug korrekt resultat-type baseret på fabrikant
    dynamic emptyResult;

    if (fabrikant == 'Ebmpapst') {
      emptyResult = ebmpapst.EbmpapstResultat(
        tryk: 0,
        luftmaengde: 0,
        effekt: 0,
        aarsforbrugKWh: 0,
        omkostning: 0,
        varenummer: '',
        kommentar: '',
        virkningsgrad: 0.0,
        selvaerdi: 0.0,
        tilbagebetalingstid: 0,
        samletOmkostning: 0,
        aarsbesparelse: 0,
      );
    } else if (fabrikant == 'Novenco') {
      emptyResult = novenco.NovencoResultat(
        tryk: 0,
        luftmaengde: 0,
        effekt: 0,
        aarsforbrugKWh: 0,
        omkostning: 0,
        varenummer: '',
        kommentar: '',
        virkningsgrad: 0.0,
        selvaerdi: 0.0,
        tilbagebetalingstid: 0,
        samletOmkostning: 0,
        aarsbesparelse: 0,
      );
    } else { // Ziehl-Abegg
      emptyResult = ziehl.ZiehlAbeggResultat(
        tryk: 0,
        luftmaengde: 0,
        effekt: 0,
        aarsforbrugKWh: 0,
        omkostning: 0,
        varenummer: '',
        kommentar: '',
        virkningsgrad: 0.0,
        selvaerdi: 0.0,
        tilbagebetalingstid: 0,
        samletOmkostning: 0,
        aarsbesparelse: 0,
      );
    }

    return VentilatorOekonomiSamlet(
      anlaegstype: '',
      anlaegsnavn: '',
      fabrikant: fabrikant,
      logoPath: '',
      varenummerInd: '',
      varenummerUd: '',
      sammeVentilatorVedMax: false,
      kommentarInd: '',
      kommentarUd: '',
      oekonomi: OekonomiResultat(
        anlaegstype: '',
        anlaegsnavn: '',
        omkostningFoer: 0,
        varenummer: '',
        tilbagebetalingstid: 0,
        aarsforbrugKWh: 0,
        omkostning: 0,
        effekt: 0,
        tryk: 0,
        luftmaengde: 0,
        virkningsgrad: 0,
        selvaerdi: 0,
        indPris: 0,
        udPris: 0,
        totalPris: 0,
        aarsbesparelse: 0,
      ),
      indNormal: emptyResult,
      indMax: emptyResult,
      udNormal: emptyResult,
      udMax: emptyResult,
      totalPris: 0,
    );
  }

  Future<void> _generatePdfs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0.0;
      _currentStep = "Starter...";
    });

    try {
      setState(() {
        _progress = 0.2;
        _currentStep = "Genererer kunderapport...";
      });

      final kundePdf = await RapportPdfGenerator.generateRapport(
        projektInfo: widget.projektInfo,
        alleForslag: widget.alleForslag,
        elPris: widget.elPris,
        varmePris: widget.varmePris,
      );
      final kundeBytes = Uint8List.fromList(await kundePdf.save());

      setState(() {
        _progress = 0.5;
        _currentStep = "Beregner projekt-økonomi...";
      });

// ════════════════════════════════════════════════════════════
// 🧮 BEREGN PROJEKT-ØKONOMI (VENTILATOR-DEL)
// ════════════════════════════════════════════════════════════
      double samletInvestering = 0.0;
      double samletBesparelse = 0.0;
      double samletVarmebesparelse = 0.0;

      final List<Map<String, dynamic>> anlaegMedTBT = [];

      print('═══════════════════════════════════════════════════════════');
      print('🔍 STARTER PROJEKT-ØKONOMI BEREGNING');
      print('═══════════════════════════════════════════════════════════');

      for (final anlaeg in widget.alleAnlaeg) {
        print('\n📍 Behandler anlæg: ${anlaeg.anlaegsNavn}');

        // Filtrér forslag til dette anlæg
        final anlaegsForslag = widget.alleForslag
            .where((f) => f.anlaegsnavn == anlaeg.anlaegsNavn)
            .toList();

        // Ventilatorforslag med økonomi
        final ventilatorForslag = anlaegsForslag.where((f) {
          final eco = f.oekonomi as OekonomiResultat;
          return eco.totalPris > 0 && eco.aarsbesparelse > 0;
        }).toList();

        // Varmebesparelse KUN for "Nyt Ventilationsanlæg"
        final bool erNytVentilationsAnlaeg = anlaegsForslag.isNotEmpty &&
            anlaegsForslag.first.fabrikant.contains("Nyt Ventilationsanlæg");

        if (erNytVentilationsAnlaeg &&
            anlaeg.varmeResultat != null &&
            anlaeg.varmeResultat!.harBeregning &&
            anlaeg.varmeResultat!.optimering != null) {
          final beforeKr = anlaeg.varmeResultat!.varmeOmkostning ?? 0;
          final afterKr = anlaeg.varmeResultat!.optimering!.nytVarmeforbrugKr ?? 0;
          final varmeBesparelse = beforeKr - afterKr;

          samletVarmebesparelse += varmeBesparelse;
          print("🔥 Varmebesparelse for ${anlaeg.anlaegsNavn}: $varmeBesparelse kr/år");
        }

        if (ventilatorForslag.isNotEmpty) {
          ventilatorForslag.sort((a, b) {
            final ecoA = a.oekonomi as OekonomiResultat;
            final ecoB = b.oekonomi as OekonomiResultat;
            return ecoA.tilbagebetalingstid.compareTo(ecoB.tilbagebetalingstid);
          });

          final bedste = ventilatorForslag.first;
          final eco = bedste.oekonomi as OekonomiResultat;

          samletInvestering += eco.totalPris;
          samletBesparelse += eco.aarsbesparelse;

          anlaegMedTBT.add({
            'anlaeg': anlaeg,
            'tbt': eco.tilbagebetalingstid,
          });

          print("  ✔ Bedste ventilator: ${bedste.fabrikant}");
        } else {
          anlaegMedTBT.add({'anlaeg': anlaeg, 'tbt': 999.0});
          print("  ⚠ Ingen gyldige ventilatorforslag");
        }
      }

      print("\n═══════════════════════════════════════════════════════════");
      print("📊 El-besparelse i alt: $samletBesparelse kr/år");
      print("🔥 Varmebesparelse i alt: $samletVarmebesparelse kr/år");
      print("═══════════════════════════════════════════════════════════");

      final double samletTBT =
      samletBesparelse > 0 ? samletInvestering / samletBesparelse : 0;

      anlaegMedTBT.sort((a, b) => (a['tbt'] as double).compareTo(b['tbt'] as double));

      setState(() {
        _progress = 0.55;
        _currentStep = "Genererer projekt-forside...";
      });

// ════════════════════════════════════════════════════════════
// 📝 GENERER PROJEKT-FORSIDE MED KORREKT VARMEBESPARELSE
// ════════════════════════════════════════════════════════════
      final internPdfs = <Uint8List>[];

      final projektForsideBytes = await generateInternProjektForside(
        projektNavn: widget.projektInfo.adresse,
        antalAnlaeg: anlaegMedTBT.length,
        samletInvestering: samletInvestering,
        samletBesparelse: samletBesparelse,
        samletTBT: samletTBT,
        samletVarmebesparelse: samletVarmebesparelse, // 🔥 DEN VIGTIGE LINJE
      );

      print("🎯 Projektforside genereret");
      internPdfs.add(projektForsideBytes);

      setState(() {
        _progress = 0.6;
        _currentStep = "Genererer tekniske rapporter...";
      });

      // ════════════════════════════════════════════════════════════
      // 🆕 GENERER ANLÆGS-PDF'ER I SORTERET RÆKKEFØLGE
      // ════════════════════════════════════════════════════════════
      final antalAnlaeg = anlaegMedTBT.length;

      for (int i = 0; i < anlaegMedTBT.length; i++) {
        final anlaeg = anlaegMedTBT[i]['anlaeg'] as AnlaegsData;

        setState(() {
          _progress = 0.6 + (0.3 * (i / antalAnlaeg));
          _currentStep = "Genererer rapport ${i + 1} af $antalAnlaeg...";
        });

        final driftstimer = widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) *
            widget.projektInfo.ugerPerAar;

        final elforbrugInd = anlaeg.kwInd * driftstimer;
        final elforbrugUd = anlaeg.kwUd * driftstimer;

        final virkningsgradInd = (anlaeg.kwInd > 0)
            ? ((anlaeg.luftInd / 3600.0) * anlaeg.trykInd) / (anlaeg.kwInd * 1000.0) * 100.0
            : 0.0;
        final virkningsgradUd = (anlaeg.kwUd > 0)
            ? ((anlaeg.luftUd / 3600.0) * anlaeg.trykUd) / (anlaeg.kwUd * 1000.0) * 100.0
            : 0.0;

        final selInd = (anlaeg.kwInd > 0 && anlaeg.luftInd > 0)
            ? anlaeg.kwInd / (anlaeg.luftInd / 3600.0) * 1000
            : 0.0;
        final selUd = (anlaeg.kwUd > 0 && anlaeg.luftUd > 0)
            ? anlaeg.kwUd / (anlaeg.luftUd / 3600.0) * 1000
            : 0.0;

        final omkostningInd = elforbrugInd * widget.elPris;
        final omkostningUd = elforbrugUd * widget.elPris;

        final statiskTrykMaxInd = (anlaeg.trykEfterIndMax != null && anlaeg.trykFoerIndMax != null)
            ? anlaeg.trykEfterIndMax! - anlaeg.trykFoerIndMax!
            : null;
        final statiskTrykMaxUd = (anlaeg.trykEfterUdMax != null && anlaeg.trykFoerUdMax != null)
            ? anlaeg.trykEfterUdMax! - anlaeg.trykFoerUdMax!
            : null;

        final anlaegsForslag = widget.alleForslag
            .where((f) => f.anlaegsnavn == anlaeg.anlaegsNavn)
            .toList();

        final ebmList = anlaegsForslag.where((f) => f.fabrikant == 'Ebmpapst').toList();
        final novList = anlaegsForslag.where((f) => f.fabrikant == 'Novenco').toList();
        final zieList = anlaegsForslag.where((f) => f.fabrikant == 'Ziehl-Abegg').toList();

        // ✅ CHECK: Er der overhovedet nogle forslag?
        // ✅ Generer ALTID rapport - også for SPECIALANLÆG uden ventilatorforslag
        print('📄 Genererer rapport for ${anlaeg.anlaegsNavn}');


        // ✅ Opret forslag - brug dummy hvis mangler
        final ebm = ebmList.isNotEmpty ? ebmList.first : _createDummyForslag('Ebmpapst');
        final nov = novList.isNotEmpty ? novList.first : _createDummyForslag('Novenco');
        final zie = zieList.isNotEmpty ? zieList.first : _createDummyForslag('Ziehl-Abegg');

        print('✅ Genererer rapport for ${anlaeg.anlaegsNavn}');

        // ✅ BEREGN erMaalteVaerdier baseret på anlægstype
        bool erMaalteVaerdier;
        if (anlaeg.valgtAnlaegstype == 'Indblæsningsanlæg') {
          erMaalteVaerdier = anlaeg.erLuftmaengdeMaaeltIndtastetInd;
        } else if (anlaeg.valgtAnlaegstype == 'Udsugningsanlæg') {
          erMaalteVaerdier = anlaeg.erLuftmaengdeMaaeltIndtastetUd;
        } else {
          // Ventilationsanlæg - begge skal være målt
          erMaalteVaerdier = anlaeg.erLuftmaengdeMaaeltIndtastetInd && anlaeg.erLuftmaengdeMaaeltIndtastetUd;
        }

        final pdfBytes = await generateInternPdfKort(
          anlaegsNavn: anlaeg.anlaegsNavn,
          anlaegsType: anlaeg.valgtAnlaegstype,
          luftInd: anlaeg.luftInd,
          luftUd: anlaeg.luftUd,
          statiskTrykInd: anlaeg.trykInd,
          statiskTrykUd: anlaeg.trykUd,
          kwInd: anlaeg.kwInd,
          kwUd: anlaeg.kwUd,
          hzInd: anlaeg.hzInd,
          hzUd: anlaeg.hzUd,
          elforbrugInd: elforbrugInd,
          elforbrugUd: elforbrugUd,
          virkningsgradInd: virkningsgradInd,
          virkningsgradUd: virkningsgradUd,
          selInd: selInd,
          selUd: selUd,
          omkostningInd: omkostningInd,
          omkostningUd: omkostningUd,
          samletFoerKWh: elforbrugInd + elforbrugUd,
          samletFoerKr: omkostningInd + omkostningUd,
          luftIndMax: anlaeg.luftIndMax,
          luftUdMax: anlaeg.luftUdMax,
          statiskTrykMaxInd: statiskTrykMaxInd,
          statiskTrykMaxUd: statiskTrykMaxUd,
          varmeforbrugResultat: anlaeg.varmeResultat,
          kammerBredde: anlaeg.kammerBredde,
          kammerHoede: anlaeg.kammerHoede,
          kammerLaengde: anlaeg.kammerLaengde,
          ebmpapstResultat: ebm,
          novencoResultat: nov,
          ziehlResultat: zie,
          alleForslag: anlaegsForslag,  // ✅ Send ALLE forslag inkl. manuelle!
          erBeregnetUdFraDesignData: anlaeg.erBeregnetInd || anlaeg.erBeregnetUd,
          erBeregnetUdFraLavHz: (anlaeg.hzInd < 50 && anlaeg.luftIndMax != null) ||
              (anlaeg.hzUd < 50 && anlaeg.luftUdMax != null),
          erBeregnetUdFraKVaerdi: (anlaeg.erBeregnetUdFraKVaerdiInd == true) ||
              (anlaeg.erBeregnetUdFraKVaerdiUd == true),
          valgtTilstand: anlaeg.valgtTilstand ?? '',
          beregnetDesignInd: anlaeg.erBeregnetInd,
          beregnetDesignUd: anlaeg.erBeregnetUd,
          beregnetKVaerdiInd: anlaeg.erBeregnetUdFraKVaerdiInd,
          beregnetKVaerdiUd: anlaeg.erBeregnetUdFraKVaerdiUd,
          erMaalteVaerdier: erMaalteVaerdier,
          internKommentar: anlaeg.internKommentar,
          trykFoerInd: anlaeg.trykFoerInd,
          trykEfterInd: anlaeg.trykEfterInd,
          trykFoerUd: anlaeg.trykFoerUd,
          trykEfterUd: anlaeg.trykEfterUd,
        );

        internPdfs.add(pdfBytes);
      }

      setState(() {
        _progress = 0.9;
        _currentStep = "Sammensætter rapporter...";
      });

      final PdfDocument merged = PdfDocument();
      for (final pdfBytes in internPdfs) {
        final PdfDocument input = PdfDocument(inputBytes: pdfBytes);
        for (int i = 0; i < input.pages.count; i++) {
          merged.pages.add().graphics.drawPdfTemplate(
            input.pages[i].createTemplate(),
            const Offset(0, 0),
          );
        }
        input.dispose();
      }

      final tekniskBytes = Uint8List.fromList(merged.saveSync());
      merged.dispose();

      setState(() {
        _progress = 1.0;
        _currentStep = "Færdig!";
      });

      if (mounted) {
        setState(() {
          _kundePdf = kundeBytes;
          _tekniskPdf = tekniskBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fejl ved PDF-generering: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF34E0A1);
    const Color primaryBlue = Color(0xFF006390);

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Rapport – ${widget.projektInfo.kundeNavn}"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Genopfrisk PDF\'er',
              onPressed: _generatePdfs,
            ),
          ],
        ),
        body: _isLoading
            ? _buildGeneratingScreen(primaryGreen)
            : _errorMessage != null
            ? _buildErrorScreen()
            : _buildPreview(context),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF006390),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingPdfSwitch = true;
                        _visTeknikPdf = false;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          setState(() => _isLoadingPdfSwitch = false);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_visTeknikPdf ? const Color(0xFF34E0A1) : Colors.white70,
                      foregroundColor: !_visTeknikPdf ? Colors.white : const Color(0xFF006390),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Kunderapport', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingPdfSwitch = true;
                        _visTeknikPdf = true;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          setState(() => _isLoadingPdfSwitch = false);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _visTeknikPdf ? const Color(0xFF34E0A1) : Colors.white70,
                      foregroundColor: _visTeknikPdf ? Colors.white : const Color(0xFF006390),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Teknisk rapport', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (format) async => _visTeknikPdf ? _tekniskPdf! : _kundePdf!,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text("Send rapport", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34E0A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () async {
                    try {
                      if (_kundePdf == null || _tekniskPdf == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF\'er mangler')));
                        return;
                      }
                      await visSendRapportPopup(context, widget.projektInfo, _kundePdf!, _tekniskPdf!);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fejl: $e')));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        if (_isLoadingPdfSwitch)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF34E0A1)),
                  SizedBox(height: 16),
                  Text('Indlæser PDF...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeneratingScreen(Color primaryGreen) {
    const Color primaryBlue = Color(0xFF006390);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 90),
            Align(alignment: Alignment.centerRight, child: Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 45)),
            const SizedBox(height: 10),
            Container(width: double.infinity, height: 2, color: primaryGreen),
            const SizedBox(height: 80),
            Text(_statusTekst, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(primaryGreen), minHeight: 8),
                  const SizedBox(height: 12),
                  Text(_currentStep, style: TextStyle(fontSize: 14, color: primaryGreen, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Image.asset('assets/images/lunger.png', height: 200, fit: BoxFit.contain),
            const Spacer(),
            Text("Et sundt indeklima begynder med et grønt valg", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: primaryGreen, fontStyle: FontStyle.italic)),
            const SizedBox(height: 30),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text("Der opstod en fejl:", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_errorMessage ?? "", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _generatePdfs, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34E0A1), foregroundColor: Colors.black), child: const Text("Prøv igen")),
          ],
        ),
      ),
    );
  }
}