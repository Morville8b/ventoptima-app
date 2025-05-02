// Fil: inddata_ventilator.dart
import 'package:flutter/material.dart';

class VentilatorVisning extends StatelessWidget {
  final String anlaegstype;

  // Indblæsning
  final TextEditingController trykGamleFiltreIndController;
  final TextEditingController antalFiltreIndController;
  final TextEditingController trykFoerIndController;
  final TextEditingController trykEfterIndController;
  final TextEditingController hzIndController;
  final TextEditingController effektIndController;

  // Udsugning
  final TextEditingController trykGamleFiltreUdController;
  final TextEditingController antalFiltreUdController;
  final TextEditingController trykFoerUdController;
  final TextEditingController trykEfterUdController;
  final TextEditingController hzUdController;
  final TextEditingController effektUdController;

  const VentilatorVisning({
    super.key,
    required this.anlaegstype,
    required this.trykGamleFiltreIndController,
    required this.antalFiltreIndController,
    required this.trykFoerIndController,
    required this.trykEfterIndController,
    required this.hzIndController,
    required this.effektIndController,
    required this.trykGamleFiltreUdController,
    required this.antalFiltreUdController,
    required this.trykFoerUdController,
    required this.trykEfterUdController,
    required this.hzUdController,
    required this.effektUdController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anlaegstype != 'Udsugningsanlæg') ...[
          Text('Indblæsningsventilator', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: trykGamleFiltreIndController, decoration: const InputDecoration(labelText: 'Tryktab over gamle filtre (Pa)'), keyboardType: TextInputType.number),
          TextField(controller: antalFiltreIndController, decoration: const InputDecoration(labelText: 'Antal filtre'), keyboardType: TextInputType.number),
          TextField(controller: trykFoerIndController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)'), keyboardType: TextInputType.number),
          TextField(controller: trykEfterIndController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)'), keyboardType: TextInputType.number),
          TextField(controller: hzIndController, decoration: const InputDecoration(labelText: 'Frekvens (Hz)'), keyboardType: TextInputType.number),
          TextField(controller: effektIndController, decoration: const InputDecoration(labelText: 'Effekt (kW)'), keyboardType: TextInputType.number),
          const Divider(height: 32),
        ],
        if (anlaegstype != 'Indblæsningsanlæg') ...[
          Text('Udsugningsventilator', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: trykGamleFiltreUdController, decoration: const InputDecoration(labelText: 'Tryktab over gamle filtre (Pa)'), keyboardType: TextInputType.number),
          TextField(controller: antalFiltreUdController, decoration: const InputDecoration(labelText: 'Antal filtre'), keyboardType: TextInputType.number),
          TextField(controller: trykFoerUdController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)'), keyboardType: TextInputType.number),
          TextField(controller: trykEfterUdController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)'), keyboardType: TextInputType.number),
          TextField(controller: hzUdController, decoration: const InputDecoration(labelText: 'Frekvens (Hz)'), keyboardType: TextInputType.number),
          TextField(controller: effektUdController, decoration: const InputDecoration(labelText: 'Effekt (kW)'), keyboardType: TextInputType.number),
        ],
      ],
    );
  }
}