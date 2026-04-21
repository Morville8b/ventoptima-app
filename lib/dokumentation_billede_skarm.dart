import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'ventilator_samlet_beregning.dart';
import 'beregning_varmeforbrug.dart';
import 'resultat_intern_skarm.dart';
import 'generel_projekt_info.dart';
import 'anlaegs_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DokumentationBilledeSkarm extends StatefulWidget {
  final int index;
  final List<AnlaegsData> alleAnlaeg;
  final String anlaegsNavn;
  final String anlaegsType;
  final Map<String, TextEditingController> driftstimer;
  final String logoPath;
  final GenerelProjektInfo projektInfo;
  final double kwInd;
  final double luftInd;
  final double trykInd;
  final double kwUd;
  final double luftUd;
  final double trykUd;
  final double hzInd;
  final double hzUd;
  final bool erBeregnetInd;
  final bool erBeregnetUd;
  final String eksisterendeVarenummerInd;
  final String eksisterendeVarenummerUd;
  final double? trykFoerIndMax;
  final double? trykEfterIndMax;
  final double? trykFoerUdMax;
  final double? trykEfterUdMax;
  final double? luftIndMax;
  final double? luftUdMax;
  final double elpris;
  final double? remUdskiftningPris;
  final double? kammerBredde;
  final double? kammerHoede;
  final double? kammerLaengde;
  final String valgtTilstand;
  final double omkostningFoer;
  final double omkostningEfter;
  final double samletOmkostning;
  final VarmeforbrugResultat? varmeforbrugResultat;

  const DokumentationBilledeSkarm({
    super.key,
    required this.index,
    required this.alleAnlaeg,
    required this.anlaegsNavn,
    required this.anlaegsType,
    required this.driftstimer,
    required this.logoPath,
    required this.projektInfo,
    required this.kwInd,
    required this.luftInd,
    required this.trykInd,
    required this.kwUd,
    required this.luftUd,
    required this.trykUd,
    required this.hzInd,
    required this.hzUd,
    required this.erBeregnetInd,
    required this.erBeregnetUd,
    required this.eksisterendeVarenummerInd,
    required this.eksisterendeVarenummerUd,
    required this.trykFoerIndMax,
    required this.trykEfterIndMax,
    required this.trykFoerUdMax,
    required this.trykEfterUdMax,
    required this.luftIndMax,
    required this.luftUdMax,
    required this.elpris,
    this.remUdskiftningPris,
    this.kammerBredde,
    this.kammerHoede,
    this.kammerLaengde,
    required this.valgtTilstand,
    required this.omkostningFoer,
    required this.omkostningEfter,
    required this.samletOmkostning,
    this.varmeforbrugResultat,
  });

  @override
  _DokumentationBilledeSkarmState createState() =>
      _DokumentationBilledeSkarmState();
}

class _DokumentationBilledeSkarmState
    extends State<DokumentationBilledeSkarm> {
  final List<_DokumentationsElement> _elementer = [];
  final ImagePicker _picker = ImagePicker();

  // ---- METODER ----

  Future<void> _tilfoejBillede() async {
    final ImageSource source = Platform.isWindows
        ? ImageSource.gallery
        : ImageSource.camera;

    final XFile? valgt = await _picker.pickImage(source: source);

    if (valgt != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = p.join(
        directory.path,
        "billede_${DateTime.now().millisecondsSinceEpoch}${p.extension(valgt.path)}",
      );

      final File permanentImage = await File(valgt.path).copy(newPath);

      setState(() {
        _elementer.add(_DokumentationsElement(
          billede: permanentImage,
          beskrivelseController: TextEditingController(),
        ));
      });
    }
  }

  void _fjernElement(int index) async {
    final bekraeft = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet billede'),
        content: const Text('Er du sikker på, at du vil slette dette billede?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuller')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Slet')),
        ],
      ),
    );
    if (bekraeft == true) {
      setState(() {
        _elementer.removeAt(index);
      });
    }
  }

  void _visStortBillede(File billede) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.file(billede),
        ),
      ),
    );
  }

  void _gaVidereHvisMuligt() {
    if (_elementer.isNotEmpty) {
      final docs = _elementer.map((e) => {
        "path": e.billede.path,
        "beskrivelse": e.beskrivelseController.text,
      }).toList();

      print("DEBUG >>> Gemmer dokumentation for ${widget.anlaegsNavn}");
      for (var d in docs) {
        print("  Path: ${d["path"]}, Beskrivelse: ${d["beskrivelse"]}");
      }

      widget.alleAnlaeg[widget.index] =
          widget.alleAnlaeg[widget.index].copyWith(dokumentation: docs);

      print("DEBUG >>> Efter copyWith: "
          "${widget.alleAnlaeg[widget.index].dokumentation}");
    }

    final double beregnetAarsbesparelse =
        widget.omkostningFoer - widget.omkostningEfter;
    final double beregnetTilbagebetalingstid = beregnetAarsbesparelse == 0
        ? 0
        : (widget.remUdskiftningPris ?? 0) / beregnetAarsbesparelse;

    final int driftstimer = (widget.projektInfo.driftTimerPrUge
        .fold(0.0, (sum, t) => sum + t) *
        widget.projektInfo.ugerPerAar)
        .toInt();

    final List<VentilatorOekonomiSamlet> forslag = [
      ebmpapst_beregnEbmpapstVentilatorer(
        afdeling: widget.projektInfo.afdeling,
        trykIndNormal: widget.trykInd,
        luftIndNormal: widget.luftInd,
        trykIndMax: widget.trykFoerIndMax ?? 0,
        luftIndMax: widget.luftIndMax ?? 0,
        trykUdNormal: widget.trykUd,
        luftUdNormal: widget.luftUd,
        trykUdMax: widget.trykEfterUdMax ?? 0,
        luftUdMax: widget.luftUdMax ?? 0,
        fradragRemtrukket: widget.remUdskiftningPris ?? 0,
        driftstimer: driftstimer,
        elpris: widget.elpris,
        omkostningInd: widget.omkostningFoer,
        omkostningUd: widget.omkostningEfter,
        anlaegsNavn: widget.anlaegsNavn,
        anlaegstype: widget.anlaegsType,
        projektInfo: widget.projektInfo,
      ),
      novenco_beregnNovencoVentilatorer(
        afdeling: widget.projektInfo.afdeling,
        trykIndNormal: widget.trykInd,
        luftIndNormal: widget.luftInd,
        trykIndMax: widget.trykFoerIndMax ?? 0,
        luftIndMax: widget.luftIndMax ?? 0,
        trykUdNormal: widget.trykUd,
        luftUdNormal: widget.luftUd,
        trykUdMax: widget.trykEfterUdMax ?? 0,
        luftUdMax: widget.luftUdMax ?? 0,
        fradragRemtrukket: widget.remUdskiftningPris ?? 0,
        driftstimer: driftstimer,
        elpris: widget.elpris,
        omkostningInd: widget.omkostningFoer,
        omkostningUd: widget.omkostningEfter,
        anlaegsNavn: widget.anlaegsNavn,
        anlaegstype: widget.anlaegsType,
        projektInfo: widget.projektInfo,
      ),
      ziehl_beregnZiehlVentilatorer(
        afdeling: widget.projektInfo.afdeling,
        trykIndNormal: widget.trykInd,
        luftIndNormal: widget.luftInd,
        trykIndMax: widget.trykFoerIndMax ?? 0,
        luftIndMax: widget.luftIndMax ?? 0,
        trykUdNormal: widget.trykUd,
        luftUdNormal: widget.luftUd,
        trykUdMax: widget.trykEfterUdMax ?? 0,
        luftUdMax: widget.luftUdMax ?? 0,
        fradragRemtrukket: widget.remUdskiftningPris ?? 0,
        driftstimer: driftstimer,
        elpris: widget.elpris,
        omkostningInd: widget.omkostningFoer,
        omkostningUd: widget.omkostningEfter,
        anlaegsNavn: widget.anlaegsNavn,
        anlaegstype: widget.anlaegsType,
        projektInfo: widget.projektInfo,
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultatInternSkarm(
          forslag: forslag,
          anlaeg: widget.alleAnlaeg[widget.index],
          index: widget.index,
          alleAnlaeg: widget.alleAnlaeg,
          anlaegsNavn: widget.anlaegsNavn,
          anlaegsType: widget.anlaegsType,
          kwInd: widget.kwInd,
          luftInd: widget.luftInd,
          statiskTrykInd: widget.trykInd,
          kwUd: widget.kwUd,
          luftUd: widget.luftUd,
          statiskTrykUd: widget.trykUd,
          hzInd: widget.hzInd,
          hzUd: widget.hzUd,
          projektInfo: widget.projektInfo,
          erBeregnetInd: widget.erBeregnetInd,
          erBeregnetUd: widget.erBeregnetUd,
          eksisterendeVarenummerInd: widget.eksisterendeVarenummerInd,
          eksisterendeVarenummerUd: widget.eksisterendeVarenummerUd,
          trykFoerIndMax: widget.trykFoerIndMax,
          trykEfterIndMax: widget.trykEfterIndMax,
          trykFoerUdMax: widget.trykFoerUdMax,
          trykEfterUdMax: widget.trykEfterUdMax,
          luftIndMax: widget.luftIndMax,
          luftUdMax: widget.luftUdMax,
          elpris: widget.elpris,
          omkostningFoer: widget.omkostningFoer,
          omkostningEfter: widget.omkostningEfter,
          kammerBredde: widget.kammerBredde,
          kammerHoede: widget.kammerHoede,
          kammerLaengde: widget.kammerLaengde,
          valgtTilstand: widget.valgtTilstand,
          samletOmkostning: widget.samletOmkostning,
          erBeregnetUdFraKVaerdiInd: false,
          erBeregnetUdFraKVaerdiUd: false,
          erLuftmaengdeMaaeltIndtastetInd: true,
          erLuftmaengdeMaaeltIndtastetUd: true,
          luftmaengdeLabelInd: 'Målt luftmængde (m³/h)',
          luftmaengdeLabelUd: 'Målt luftmængde (m³/h)',
          driftstimer: widget.driftstimer,
          aarsbesparelse: beregnetAarsbesparelse,
          tilbagebetalingstid: beregnetTilbagebetalingstid,
          varmeforbrugResultat: widget.varmeforbrugResultat,
        ),
      ),
    );
  }

  // ---- BUILD ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tilfoejBillede,
        backgroundColor: const Color(0xFF34E0A1),
        foregroundColor: const Color(0xFF006390),
        icon: Icon(Platform.isWindows ? Icons.add_photo_alternate : Icons.add_a_photo),
        label: Text(Platform.isWindows ? 'Tilføj billede' : 'Tag billede'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // ---- Header ----
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Billede samt beskrivelse',
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
                      const Icon(Icons.error),
                    ),
                  ],
                ),
              ),

              // ---- Anlægsnavn ----
              Container(
                width: double.infinity,
                color: const Color(0xFF34E0A1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Anlægsnavn: ${widget.anlaegsNavn}',
                  style: const TextStyle(
                    color: Color(0xFF006390),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ---- Liste over billeder ----
              Expanded(
                child: _elementer.isEmpty
                    ? const Center(child: Text('Ingen billeder tilføjet endnu'))
                    : ListView.separated(
                  itemCount: _elementer.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final element = _elementer[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _visStortBillede(element.billede),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  element.billede,
                                  height: element.billedeHoejde,  // 🔧 Dynamisk højde
                                  width: double.infinity,
                                  fit: BoxFit.contain,  // 🔧 Ændret til contain
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 🆕 Slider til at justere størrelse
                            Row(
                              children: [
                                const Icon(Icons.photo_size_select_small, size: 20, color: Color(0xFF006390)),
                                Expanded(
                                  child: Slider(
                                    value: element.billedeHoejde,
                                    min: 150.0,
                                    max: 600.0,
                                    divisions: 45,
                                    label: '${element.billedeHoejde.round()}px',
                                    activeColor: const Color(0xFF34E0A1),
                                    inactiveColor: const Color(0xFF006390).withOpacity(0.3),
                                    onChanged: (double value) {
                                      setState(() {
                                        element.billedeHoejde = value;
                                      });
                                    },
                                  ),
                                ),
                                const Icon(Icons.photo_size_select_large, size: 20, color: Color(0xFF006390)),
                              ],
                            ),

                            const SizedBox(height: 10),
                            TextField(
                              controller: element.beskrivelseController,
                              decoration: const InputDecoration(
                                labelText: 'Beskrivelse',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () =>
                                  FocusScope.of(context).unfocus(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _fjernElement(index),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ---- Knapper ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34E0A1),
                        foregroundColor: const Color(0xFF006390),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Tilbage'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_elementer.isNotEmpty) {
                          final docs = _elementer.map((e) => {
                            "path": e.billede.path,
                            "beskrivelse": e.beskrivelseController.text,
                          }).toList();

                          widget.alleAnlaeg[widget.index] =
                              widget.alleAnlaeg[widget.index].copyWith(dokumentation: docs);
                        }

                        Navigator.pop(context, {
                          "status": "completed",
                          "alleAnlaeg": widget.alleAnlaeg,
                          "opdateretIndex": widget.index,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34E0A1),
                        foregroundColor: const Color(0xFF006390),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Gem og næste'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- ELEMENT CLASS ----
class _DokumentationsElement {
  final File billede;
  final TextEditingController beskrivelseController;
  double billedeHoejde;  // 🆕 Tilføjet

  _DokumentationsElement({
    required this.billede,
    required this.beskrivelseController,  // 🆕 Standard størrelse
  });
}
