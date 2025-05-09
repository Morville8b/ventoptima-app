import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'resultat_intern_skarm.dart';
import 'generel_projekt_info.dart';

class DokumentationBilledeSkarm extends StatefulWidget {
  final String anlaegsNavn;
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


  const DokumentationBilledeSkarm({
    required this.anlaegsNavn,
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
    Key? key,
  }) : super(key: key);

  @override
  _DokumentationBilledeSkarmState createState() => _DokumentationBilledeSkarmState();
}

class _DokumentationBilledeSkarmState extends State<DokumentationBilledeSkarm> {
  final List<_DokumentationsElement> _elementer = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _tilfoejBillede() async {
    final XFile? valgt = await _picker.pickImage(source: ImageSource.camera);
    if (valgt != null) {
      setState(() {
        _elementer.add(_DokumentationsElement(
          billede: File(valgt.path),
          beskrivelseController: TextEditingController(),
        ));
      });
    }
  }

  void _fjernElement(int index) async {
    final bekraeft = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Slet billede'),
        content: Text('Er du sikker på, at du vil slette dette billede?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Annuller')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Slet')),
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
    if (_elementer.isEmpty || _elementer.every((e) => e.beskrivelseController.text.trim().isNotEmpty)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultatInternSkarm(
            anlagsNavn: widget.anlaegsNavn,
            kwInd: widget.kwInd,
            luftInd: widget.luftInd,
            statiskTrykInd: widget.trykInd,
            kwUd: widget.kwUd,
            luftUd: widget.luftUd,
            statiskTrykUd: widget.trykUd,
            hzInd: widget.hzInd,  // korrekt videreført
            hzUd: widget.hzUd,
            projektInfo: widget.projektInfo,
            erBeregnetInd: widget.erBeregnetInd,
            erBeregnetUd: widget.erBeregnetUd,
            eksisterendeVarenummerInd: widget.eksisterendeVarenummerInd,
            eksisterendeVarenummerUd: widget.eksisterendeVarenummerUd,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Manglende beskrivelse'),
          content: Text('Alle billeder skal have en beskrivelse for at fortsætte.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tilfoejBillede,
        backgroundColor: Color(0xFF34E0A1),
        foregroundColor: Color(0xFF006390),
        icon: Icon(Icons.add_a_photo),
        label: Text('Tilføj billede'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Billede samt beskrivelse',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      widget.logoPath,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: Color(0xFF34E0A1),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Anlægsnavn: ${widget.anlaegsNavn}',
                  style: TextStyle(
                    color: Color(0xFF006390),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _elementer.isEmpty
                    ? Center(child: Text('Ingen billeder tilføjet endnu'))
                    : ListView.separated(
                  itemCount: _elementer.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, index) {
                    final element = _elementer[index];
                    return Card(
                      margin: EdgeInsets.all(10),
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
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: element.beskrivelseController,
                              decoration: InputDecoration(
                                labelText: 'Beskrivelse',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () => FocusScope.of(context).unfocus(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34E0A1),
                        foregroundColor: Color(0xFF006390),
                        shape: StadiumBorder(),
                      ),
                      child: Text('Tilbage'),
                    ),
                    ElevatedButton(
                      onPressed: _gaVidereHvisMuligt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34E0A1),
                        foregroundColor: Color(0xFF006390),
                        shape: StadiumBorder(),
                      ),
                      child: Text('Næste'),
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

class _DokumentationsElement {
  final File billede;
  final TextEditingController beskrivelseController;

  _DokumentationsElement({
    required this.billede,
    required this.beskrivelseController,
  });
}
