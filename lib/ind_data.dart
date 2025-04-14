import 'generel_projekt_info.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _kVaerdiIndController = TextEditingController();
  final TextEditingController _trykDiffIndBeregnetController = TextEditingController();
  final TextEditingController _kVaerdiUdController = TextEditingController();
  final TextEditingController _trykDiffUdBeregnetController = TextEditingController();

  bool _beregnUdFraKVaerdi = false;

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
    _kVaerdiIndController.dispose();
    _trykDiffIndBeregnetController.dispose();
    _kVaerdiUdController.dispose();
    _trykDiffUdBeregnetController.dispose();
    super.dispose();
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
            Text('Kunde: ${widget.projektInfo.kundeNavn}'),
            Text('Adresse: ${widget.projektInfo.adresse}'),
            Text('Postnr/By: ${widget.projektInfo.postnrBy}'),
            Text('Att: ${widget.projektInfo.att}'),
            const SizedBox(height: 16),
            const Text('Teknikeroplysninger:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Navn: ${widget.projektInfo.teknikerNavn}'),
            Text('Telefon: ${widget.projektInfo.telefon}'),
            Text('E-mail: ${widget.projektInfo.email}'),
            const SizedBox(height: 16),
            const Text('Projektoplysninger:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Antal anlæg: ${widget.projektInfo.antalAnlaeg}'),
            Text('Elpris: ${widget.projektInfo.elPris} kr/kWh'),
            Text('Varmepris: ${widget.projektInfo.varmePris} kr/kWh'),
            Text('Uger per år: ${widget.projektInfo.ugerPerAar}'),
            Text('Driftperiode: ${widget.projektInfo.driftperiode}'),
            const SizedBox(height: 16),
            const Text('Drifttimer pr. uge:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < widget.projektInfo.driftTimerPrUge.length; i++)
              Text('Dag ${i + 1}: ${widget.projektInfo.driftTimerPrUge[i]} timer'),

            const SizedBox(height: 24),
            const Text('Ventilatordata – Indblæsning', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _trykFoerIndController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
            TextField(controller: _trykEfterIndController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
            TextField(controller: _kwIndController, decoration: const InputDecoration(labelText: 'Effekt (kW)')),
            TextField(controller: _hzIndController, decoration: const InputDecoration(labelText: 'Driftfrekvens (Hz)')),

            const SizedBox(height: 24),
            const Text('Ventilatordata – Udsugning', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _trykFoerUdController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
            TextField(controller: _trykEfterUdController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
            TextField(controller: _kwUdController, decoration: const InputDecoration(labelText: 'Effekt (kW)')),
            TextField(controller: _hzUdController, decoration: const InputDecoration(labelText: 'Driftfrekvens (Hz)')),

            const SizedBox(height: 24),
            const Text('Luftmængde', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _luftmaengdeIndController, decoration: const InputDecoration(labelText: 'Indblæsning målt (m³/h)')),
            TextField(controller: _luftmaengdeUdController, decoration: const InputDecoration(labelText: 'Udsugning målt (m³/h)')),

            SwitchListTile(
              title: const Text('Beregn ud fra K-værdi og trykdifferens?'),
              value: _beregnUdFraKVaerdi,
              onChanged: (val) => setState(() => _beregnUdFraKVaerdi = val),
            ),
            if (_beregnUdFraKVaerdi) ...[
              TextField(controller: _kVaerdiIndController, decoration: const InputDecoration(labelText: 'K-værdi indblæsning')),
              TextField(controller: _trykDiffIndBeregnetController, decoration: const InputDecoration(labelText: 'Trykdifferens (Pa)')),
              TextField(controller: _kVaerdiUdController, decoration: const InputDecoration(labelText: 'K-værdi udsugning')),
              TextField(controller: _trykDiffUdBeregnetController, decoration: const InputDecoration(labelText: 'Trykdifferens (Pa)')),
            ],

            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Tilføj navigering eller beregning her
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
