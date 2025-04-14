import 'package:flutter/material.dart';
import 'dart:math';
import 'generel_projekt_info.dart';

class MaaledataSkarm extends StatefulWidget {
  final GenerelProjektInfo projektInfo;

  const MaaledataSkarm({super.key, required this.projektInfo});

  @override
  State<MaaledataSkarm> createState() => _MaaledataSkarmState();
}

class _MaaledataSkarmState extends State<MaaledataSkarm> {
  final TextEditingController _trykFoerIndController = TextEditingController();
  final TextEditingController _trykEfterIndController = TextEditingController();
  final TextEditingController _trykFoerUdController = TextEditingController();
  final TextEditingController _trykEfterUdController = TextEditingController();
  final TextEditingController _kwIndController = TextEditingController();
  final TextEditingController _kwUdController = TextEditingController();
  final TextEditingController _hzIndController = TextEditingController();
  final TextEditingController _hzUdController = TextEditingController();
  final TextEditingController _luftmaengdeIndController = TextEditingController();
  final TextEditingController _luftmaengdeUdController = TextEditingController();
  final TextEditingController _hzMaxIndController = TextEditingController();
  final TextEditingController _hzMaxUdController = TextEditingController();
  final TextEditingController _tempUdeController = TextEditingController();
  final TextEditingController _tempEfterVarmegenvindingController = TextEditingController();
  final TextEditingController _tempEfterVarmefladeController = TextEditingController();
  final TextEditingController _tempUdsugningController = TextEditingController();
  final TextEditingController _afkastTempController = TextEditingController();

  bool _visBeregnVed50HzInd = false;
  bool _visBeregnVed50HzUd = false;
  bool _visVarmegenvinding = false;
  bool _brugAfkast = false;
  String _valgtType = 'Kryds';
  final List<String> _typer = ['Kryds', 'Dobbelkryds', 'Roterende', 'Modstrøm', 'Væskekoblet', 'Blandekammer'];

  String _valgtAnlaegstype = 'Ventilationsanlæg';
  final List<String> _anlaegstyper = ['Ventilationsanlæg', 'Indblæsningsanlæg', 'Udsugningsanlæg'];

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
    _luftmaengdeIndController.dispose();
    _luftmaengdeUdController.dispose();
    _hzMaxIndController.dispose();
    _hzMaxUdController.dispose();
    _tempUdeController.dispose();
    _tempEfterVarmegenvindingController.dispose();
    _tempEfterVarmefladeController.dispose();
    _tempUdsugningController.dispose();
    _afkastTempController.dispose();
    super.dispose();
  }

  double _beregnLuftmaengdeVed50Hz(double luftmaengde, double hz) {
    if (hz <= 0) return 0;
    return luftmaengde * pow((50 / hz), 3);
  }

  @override
  Widget build(BuildContext context) {
    final double? udetemp = double.tryParse(_tempUdeController.text.replaceAll(',', '.'));
    final bool udetempOver10 = udetemp != null && udetemp > 10;
    final bool erVentilationsanlaeg = _valgtAnlaegstype == 'Ventilationsanlæg';
    final bool erIndblaesningsanlaeg = _valgtAnlaegstype == 'Indblæsningsanlæg';
    final bool erUdsugningsanlaeg = _valgtAnlaegstype == 'Udsugningsanlæg';

    String varmegenvindingLabel = erUdsugningsanlaeg
        ? 'Er udsugningsluften opvarmet?'
        : 'Er indblæsningsluften opvarmet?';

    return Scaffold(
      appBar: AppBar(title: const Text('Måledata')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anlægstype', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _valgtAnlaegstype,
              decoration: const InputDecoration(labelText: 'Vælg anlægstype'),
              items: _anlaegstyper.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) => setState(() => _valgtAnlaegstype = val!),
            ),

            const SizedBox(height: 24),
            if (erVentilationsanlaeg || erIndblaesningsanlaeg) ...[
              const Text('Ventilatordata – Indblæsning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: _trykFoerIndController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
              TextField(controller: _trykEfterIndController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
              TextField(controller: _kwIndController, decoration: const InputDecoration(labelText: 'Effekt (kW)')),
              TextField(controller: _hzIndController, decoration: const InputDecoration(labelText: 'Målt frekvens (Hz)')),
            ],

            const SizedBox(height: 24),
            if (erVentilationsanlaeg || erUdsugningsanlaeg) ...[
              const Text('Ventilatordata – Udsugning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: _trykFoerUdController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
              TextField(controller: _trykEfterUdController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
              TextField(controller: _kwUdController, decoration: const InputDecoration(labelText: 'Effekt (kW)')),
              TextField(controller: _hzUdController, decoration: const InputDecoration(labelText: 'Målt frekvens (Hz)')),
            ],

            const SizedBox(height: 24),
            const Text('Luftmængde', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (erVentilationsanlaeg || erIndblaesningsanlaeg) ...[
              TextField(controller: _luftmaengdeIndController, decoration: const InputDecoration(labelText: 'Indblæsning (m³/h)')),
              SwitchListTile(
                title: const Text('Beregn luftmængde ved 50 Hz (indblæsning)'),
                value: _visBeregnVed50HzInd,
                onChanged: (val) => setState(() => _visBeregnVed50HzInd = val),
              ),
              if (_visBeregnVed50HzInd) ...[
                TextField(controller: _hzMaxIndController, decoration: const InputDecoration(labelText: 'Målt luftmængde (m³/h)')),
                Builder(builder: (context) {
                  final hz = double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0;
                  final luft = double.tryParse(_hzMaxIndController.text.replaceAll(',', '.')) ?? 0;
                  final beregnet = _beregnLuftmaengdeVed50Hz(luft, hz);
                  return Text('Beregnet luftmængde ved 50 Hz: ${beregnet.toStringAsFixed(0)} m³/h');
                })
              ]
            ],
            if (erVentilationsanlaeg || erUdsugningsanlaeg) ...[
              TextField(controller: _luftmaengdeUdController, decoration: const InputDecoration(labelText: 'Udsugning (m³/h)')),
              SwitchListTile(
                title: const Text('Beregn luftmængde ved 50 Hz (udsugning)'),
                value: _visBeregnVed50HzUd,
                onChanged: (val) => setState(() => _visBeregnVed50HzUd = val),
              ),
              if (_visBeregnVed50HzUd) ...[
                TextField(controller: _hzMaxUdController, decoration: const InputDecoration(labelText: 'Målt luftmængde (m³/h)')),
                Builder(builder: (context) {
                  final hz = double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0;
                  final luft = double.tryParse(_hzMaxUdController.text.replaceAll(',', '.')) ?? 0;
                  final beregnet = _beregnLuftmaengdeVed50Hz(luft, hz);
                  return Text('Beregnet luftmængde ved 50 Hz: ${beregnet.toStringAsFixed(0)} m³/h');
                })
              ]
            ],

            const SizedBox(height: 24),
            const Text('Varmegenvinding', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: Text(varmegenvindingLabel),
              value: _visVarmegenvinding,
              onChanged: (val) => setState(() => _visVarmegenvinding = val),
            ),
            if (_visVarmegenvinding && erVentilationsanlaeg) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Vælg type varmegenvinding'),
                value: _valgtType,
                items: _typer.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => _valgtType = val!),
              ),
              SwitchListTile(
                title: const Text('Beregn ud fra afkasttemperatur?'),
                value: _brugAfkast,
                onChanged: (val) => setState(() => _brugAfkast = val),
              ),
              TextField(controller: _tempUdeController, decoration: const InputDecoration(labelText: 'Udetemperatur (°C)')),
              if (udetempOver10)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'OBS: Udetemperaturen er over 10 °C – varmegenvinding kan ikke beregnes.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              if (!udetempOver10) ...[
                if (_brugAfkast) ...[
                  TextField(controller: _tempEfterVarmefladeController, decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmefladen (°C)')),
                  TextField(controller: _tempUdsugningController, decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)')),
                  TextField(controller: _afkastTempController, decoration: const InputDecoration(labelText: 'Afkasttemperatur (°C)')),
                ] else ...[
                  TextField(controller: _tempEfterVarmegenvindingController, decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmegenvinding (°C)')),
                  TextField(controller: _tempEfterVarmefladeController, decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmefladen (°C)')),
                  TextField(controller: _tempUdsugningController, decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)')),
                ]
              ]
            ],
            if (_visVarmegenvinding && erIndblaesningsanlaeg)
              TextField(controller: _tempEfterVarmefladeController, decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmefladen (°C)')),
            if (_visVarmegenvinding && erUdsugningsanlaeg)
              TextField(controller: _tempUdsugningController, decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)')),

            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Beregning igangsat...')),
                  );
                },
                child: const Text('Beregn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}