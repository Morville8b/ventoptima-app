// Fil: inndata_varmegenvindning.dart

import 'package:flutter/material.dart';

double beregnVirkningsgradFraIndblaesning(double tind, double tfrisk, double tud) {
  if ((tud - tfrisk) == 0) return 0;
  return ((tind - tfrisk) / (tud - tfrisk)) * 100;
}

double beregnVirkningsgradFraAfkast(double tafkast, double tfrisk, double tud) {
  if ((tud - tfrisk) == 0) return 0;
  return ((tud - tafkast) / (tud - tfrisk)) * 100;
}

Future<void> visMaxBelastningPopup({
  required BuildContext context,
  required String titel,
  required TextEditingController luftController,
  required TextEditingController trykFoerController,
  required TextEditingController trykEfterController,
}) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: luftController,
            decoration: const InputDecoration(labelText: 'Luftmængde ved maks belastning (m³/h)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: trykFoerController,
            decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: trykEfterController,
            decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annullér')),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Gem')),
      ],
    ),
  );
}

typedef OnMethodChanged = void Function(bool udFraIndblaesning);

class VarmegenvindingSektion extends StatelessWidget {
  final String anlaegstype;
  final bool visVarmegenvinding;
  final bool visBeregningsMetode;
  final bool beregnUdFraIndblaesning;
  final OnMethodChanged onMethodChanged;

  final TextEditingController tFriskController;
  final TextEditingController tIndController;
  final TextEditingController tUdController;
  final TextEditingController tAfkastController;
  final double hzInd;
  final double hzUd;
  final VoidCallback onVisPopupInd;
  final VoidCallback onVisPopupUd;

  const VarmegenvindingSektion({
    super.key,
    required this.anlaegstype,
    required this.visVarmegenvinding,
    required this.visBeregningsMetode,
    required this.beregnUdFraIndblaesning,
    required this.onMethodChanged,
    required this.tFriskController,
    required this.tIndController,
    required this.tUdController,
    required this.tAfkastController,
    required this.hzInd,
    required this.hzUd,
    required this.onVisPopupInd,
    required this.onVisPopupUd,
  });

  @override
  Widget build(BuildContext context) {
    if (!visVarmegenvinding) return const SizedBox.shrink();

    final double tFrisk = double.tryParse(tFriskController.text.replaceAll(',', '.')) ?? 0;
    final double tInd = double.tryParse(tIndController.text.replaceAll(',', '.')) ?? 0;
    final double tUd = double.tryParse(tUdController.text.replaceAll(',', '.')) ?? 0;
    final double tAfkast = double.tryParse(tAfkastController.text.replaceAll(',', '.')) ?? 0;

    final bool visAdvarsel = tFrisk > 10;
    final double virkningsgrad = visAdvarsel
        ? 0
        : beregnUdFraIndblaesning
        ? beregnVirkningsgradFraIndblaesning(tInd, tFrisk, tUd)
        : beregnVirkningsgradFraAfkast(tAfkast, tFrisk, tUd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        if (anlaegstype == 'Ventilationsanlæg') ...[
          Text('Beregningsmetode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Beregningsmetode'),
            subtitle: Text(
              'Aktuelt: ' + (beregnUdFraIndblaesning ? 'Indblæsningstemperatur' : 'Afkasttemperatur'),
            ),
            value: beregnUdFraIndblaesning,
            onChanged: visBeregningsMetode ? onMethodChanged : null,
            activeColor: Color(0xFF34E0A1), // Grøn farve til aktiv switch
            inactiveTrackColor: Color(0xFF34E0A1), // Grøn farve til inaktiv switch
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              beregnUdFraIndblaesning
                  ? 'η = (Tᵢₙd - T𝒇𝒓𝒊𝒔𝒌) ÷ (Tᵤ𝒅 - T𝒇𝒓𝒊𝒔𝒌) × 100'
                  : 'η = (Tᵤ𝒅 - Tₐ𝒇𝒌ₐₛₜ) ÷ (Tᵤ𝒅 - T𝒇𝒓𝒊𝒔𝒌) × 100',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          TextField(
            controller: tFriskController,
            decoration: const InputDecoration(labelText: 'Frisklufttemperatur (°C)'),
            keyboardType: TextInputType.number,
          ),
          if (visAdvarsel)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Der beregnes ikke på varmegenvinding, da frisklufttemperaturen er over 10 °C.',
                style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
              ),
            ),
          if (beregnUdFraIndblaesning) ...[
            TextField(
              controller: tIndController,
              decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmegenvinding (°C)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tIndController,
              decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmeflade (°C)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tUdController,
              decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)'),
              keyboardType: TextInputType.number,
            ),
          ] else ...[
            TextField(
              controller: tIndController,
              decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmeflade (°C)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tUdController,
              decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tAfkastController,
              decoration: const InputDecoration(labelText: 'Afkasttemperatur (°C)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ] else if (anlaegstype == 'Indblæsningsanlæg') ...[
          Text(
            'Er indblæsningsluften opvarmet?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: tIndController,
            decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmeflade (°C)'),
            keyboardType: TextInputType.number,
          ),
        ] else if (anlaegstype == 'Udsugningsanlæg') ...[
          Text(
            'Er udsugningsluften opvarmet?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: tUdController,
            decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)'),
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 16),
        if (anlaegstype == 'Ventilationsanlæg')
          TextField(
            readOnly: true,
            controller: TextEditingController(text: virkningsgrad.toStringAsFixed(1)),
            decoration: const InputDecoration(
              labelText: 'Virkningsgrad (%)',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        if (hzInd > 0 && hzInd < 50)
          ElevatedButton(
            onPressed: onVisPopupInd,
            child: const Text('Indtast data for indblæsning (Hz < 50)'),
          ),
        if (hzUd > 0 && hzUd < 50)
          ElevatedButton(
            onPressed: onVisPopupUd,
            child: const Text('Indtast data for udsugning (Hz < 50)'),
          ),
      ],
    );
  }
}


















































































