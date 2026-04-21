import 'package:flutter/material.dart';
import 'generel_projekt_info.dart'; // ✅ herfra henter vi Driftstype
import 'beregning_varmeforbrug.dart';
import 'besparelseforslag_skarm.dart';

class MaaledataSkarm extends StatefulWidget {
  final GenerelProjektInfo projektInfo;

  const MaaledataSkarm({super.key, required this.projektInfo});

  @override
  State<MaaledataSkarm> createState() => _MaaledataSkarmState();
}

class _MaaledataSkarmState extends State<MaaledataSkarm> {
  // Controllers
  final _trykFoerIndController = TextEditingController();
  final _trykEfterIndController = TextEditingController();
  final _trykFoerUdController = TextEditingController();
  final _trykEfterUdController = TextEditingController();
  final _kwIndController = TextEditingController();
  final _kwUdController = TextEditingController();
  final _hzIndController = TextEditingController();
  final _hzUdController = TextEditingController();

  final _luftIndCtrl = TextEditingController();
  final _luftUdCtrl = TextEditingController();
  final _friskluftTempCtrl = TextEditingController();
  final _tempIndEfterGenvindingCtrl = TextEditingController();
  final _tempIndEfterVarmefladeCtrl = TextEditingController();
  final _tempUdCtrl = TextEditingController();
  final _tempAfkastCtrl = TextEditingController();
  final _driftstimerCtrl = TextEditingController();
  final _driftstypeCtrl = TextEditingController();
  final _varmegenvindingsTypeCtrl = TextEditingController();

  // 🔥 Manglende controllers fra fejl-log
  final _aarsVirkningsgradCtrl = TextEditingController();
  final _varmePrisCtrl = TextEditingController();
  final String _valgtAnlaegstype = "Ventilationsanlæg";
  final String _valgtTilstand = '1';

  final bool _beregnUdFraKVaerdi = false;

  @override
  void dispose() {
    _trykFoerIndController.dispose();
    _trykEfterIndController.dispose();
    _trykFoerUdController.dispose();
    _trykEfterUdController.dispose();
    _kwIndController.dispose();
    _kwUdController.dispose();
    _hzIndController.dispose();
    _hzUdController.dispose();
    _luftIndCtrl.dispose();
    _luftUdCtrl.dispose();
    _friskluftTempCtrl.dispose();
    _tempIndEfterGenvindingCtrl.dispose();
    _tempIndEfterVarmefladeCtrl.dispose();
    _tempUdCtrl.dispose();
    _tempAfkastCtrl.dispose();
    _driftstimerCtrl.dispose();
    _driftstypeCtrl.dispose();
    _varmegenvindingsTypeCtrl.dispose();
    _aarsVirkningsgradCtrl.dispose();
    _varmePrisCtrl.dispose();
    super.dispose();
  }

  // ✅ Bruger nu kun Driftstype fra generel_projekt_info.dart
  Driftstype _mapDriftstype(String input) {
    switch (input.toLowerCase()) {
      case 'dag':
      case 'dagtimer':
        return Driftstype.dag;
      case 'nat':
      case 'nattetimer':
        return Driftstype.nat;
      default:
        return Driftstype.doegn;
    }
  }

  void _beregnOgNaviger() {
    final resultat = beregnVarmeforbrugOgVirkningsgrad(
      anlaegsType: _valgtAnlaegstype,
      luftInd: double.tryParse(_luftIndCtrl.text.replaceAll(',', '.')) ?? 0,
      luftUd: double.tryParse(_luftUdCtrl.text.replaceAll(',', '.')) ?? 0,
      driftstimer: double.tryParse(_driftstimerCtrl.text.replaceAll(',', '.')) ?? 0,
      friskluftTemp: double.tryParse(_friskluftTempCtrl.text.replaceAll(',', '.')) ?? 0,
      tempUd: double.tryParse(_tempUdCtrl.text.replaceAll(',', '.')) ?? 0,
      tempIndEfterGenvinding: double.tryParse(_tempIndEfterGenvindingCtrl.text.replaceAll(',', '.')) ?? 0,
      tempIndEfterVarmeflade: double.tryParse(_tempIndEfterVarmefladeCtrl.text.replaceAll(',', '.')) ?? 0,
      varmePris: double.tryParse(_varmePrisCtrl.text.replaceAll(',', '.')) ?? widget.projektInfo.varmePris,

      // optionals
      tempAfkast: double.tryParse(_tempAfkastCtrl.text.replaceAll(',', '.')),
      varmegenvindingsType: _varmegenvindingsTypeCtrl.text.isNotEmpty
          ? _varmegenvindingsTypeCtrl.text
          : null,
      driftstype: _mapDriftstype(_driftstypeCtrl.text), // ✅ mapper til enum
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BesparelseForslagSkarm(
          alleForslag: [], // TODO: udfyld forslag
          elPris: widget.projektInfo.elPris,
          varmePris: widget.projektInfo.varmePris,
          projektInfo: widget.projektInfo,
          anlaegsNavn: "Mit anlæg", // TODO: sæt korrekt navn
          varmeforbrugResultat: resultat,
          friskluftTemp: double.tryParse(_friskluftTempCtrl.text.replaceAll(',', '.')) ?? 0,
          anlaegsType: _valgtAnlaegstype,
          valgtTilstand: _valgtTilstand,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Måledata')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _luftIndCtrl, decoration: const InputDecoration(labelText: 'Indblæsning (m³/h)')),
            TextField(controller: _luftUdCtrl, decoration: const InputDecoration(labelText: 'Udsugning (m³/h)')),
            TextField(controller: _friskluftTempCtrl, decoration: const InputDecoration(labelText: 'Friskluft (°C)')),
            TextField(controller: _tempIndEfterGenvindingCtrl, decoration: const InputDecoration(labelText: 'Efter genvinding (°C)')),
            TextField(controller: _tempIndEfterVarmefladeCtrl, decoration: const InputDecoration(labelText: 'Efter varmeflade (°C)')),
            TextField(controller: _tempUdCtrl, decoration: const InputDecoration(labelText: 'Udsugning (°C)')),
            TextField(controller: _tempAfkastCtrl, decoration: const InputDecoration(labelText: 'Afkast (°C)')),
            TextField(controller: _aarsVirkningsgradCtrl, decoration: const InputDecoration(labelText: 'Årsvirkningsgrad (%)')),
            TextField(controller: _varmePrisCtrl, decoration: const InputDecoration(labelText: 'Varmepris (kr/kWh)')),
            TextField(controller: _driftstimerCtrl, decoration: const InputDecoration(labelText: 'Driftstimer')),
            TextField(controller: _driftstypeCtrl, decoration: const InputDecoration(labelText: 'Driftstype (dag/dagTimer/nat/døgn)')),
            TextField(controller: _varmegenvindingsTypeCtrl, decoration: const InputDecoration(labelText: 'Varmegenvindings-type')),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _beregnOgNaviger,
                child: const Text('Beregn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}