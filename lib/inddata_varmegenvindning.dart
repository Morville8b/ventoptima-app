import 'package:flutter/material.dart';

// ——— Beregninger ———
double beregnVirkningsgradFraIndblaesning(double tind, double tfrisk, double tud) {
  if ((tud - tfrisk) == 0) return 0; // hvorfor: undgå division med 0
  return ((tind - tfrisk) / (tud - tfrisk)) * 100;
}

double beregnVirkningsgradFraAfkast(double tafkast, double tfrisk, double tud) {
  if ((tud - tfrisk) == 0) return 0; // hvorfor: undgå division med 0
  return ((tud - tafkast) / (tud - tfrisk)) * 100;
}

// ——— Popup ———
Future<void> visMaxBelastningPopup({
  required BuildContext context,
  required String titel,
  required TextEditingController luftController,
  required TextEditingController trykFoerController,
  required TextEditingController trykEfterController,
}) async {
  // hvorfor: brug await så returtype matcher Future<void>
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: luftController,
              decoration: const InputDecoration(labelText: 'Luftmængde ved maks belastning (m³/h)'),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: trykFoerController,
              decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)'),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: trykEfterController,
              decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)'),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annullér')),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Gem')),
      ],
    ),
  );
}

// ——— Widget ———
typedef OnMethodChanged = void Function(bool udFraIndblaesning);

class VarmegenvindingSektion extends StatelessWidget {
  final String anlaegstype;
  final bool visVarmegenvinding;
  final bool visBeregningsMetode;
  final bool beregnUdFraIndblaesning;
  final OnMethodChanged onMethodChanged;

  final TextEditingController tFriskController;
  final TextEditingController tIndEfterGenvindingController;
  final TextEditingController tIndEfterVarmefladeController;
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
    required this.tIndEfterGenvindingController,
    required this.tIndEfterVarmefladeController,
    required this.tUdController,
    required this.tAfkastController,
    required this.hzInd,
    required this.hzUd,
    required this.onVisPopupInd,
    required this.onVisPopupUd,
  });

  double _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    if (!visVarmegenvinding) return const SizedBox.shrink();

    final double tFrisk = _parse(tFriskController);
    final double tInd = _parse(beregnUdFraIndblaesning ? tIndEfterGenvindingController : tIndEfterVarmefladeController);
    final double tUd = _parse(tUdController);
    final double tAfkast = _parse(tAfkastController);

    final bool visAdvarsel = tFrisk > 10;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        if (anlaegstype == 'Ventilationsanlæg') ...[
          const Text('Beregningsmetode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            subtitle: Text('Beregn ud fra: ${beregnUdFraIndblaesning ? 'Indblæsningstemperatur' : 'Afkasttemperatur'}'),
            value: beregnUdFraIndblaesning,
            onChanged: visBeregningsMetode ? onMethodChanged : null,
            activeThumbColor: const Color(0xFF34E0A1),
            inactiveTrackColor: const Color(0xFF34E0A1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              beregnUdFraIndblaesning
                  ? 'η = (T_ind − T_frisk) ÷ (T_ud − T_frisk) × 100'
                  : 'η = (T_ud − T_afkast) ÷ (T_ud − T_frisk) × 100',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.grey),
            ),
          ),
          TextField(
            controller: tFriskController,
            decoration: const InputDecoration(labelText: 'Frisklufttemperatur (°C)'),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
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
              controller: tIndEfterGenvindingController,
              decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmegenvinding (°C)'),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: tIndEfterVarmefladeController,
              decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmeflade (°C)'),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: tUdController,
              decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)'),
              keyboardType: TextInputType.text,
            ),
          ] else ...[
            TextField(
              controller: tIndEfterVarmefladeController,
              decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmeflade (°C)'),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: tUdController,
              decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)'),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: tAfkastController,
              decoration: const InputDecoration(labelText: 'Afkasttemperatur (°C)'),
              keyboardType: TextInputType.text,
            ),
          ],
        ] else if (anlaegstype == 'Indblæsningsanlæg') ...[
          const Text('Er indblæsningsluften opvarmet?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: tIndEfterVarmefladeController,
            decoration: const InputDecoration(labelText: 'Indblæsningstemperatur efter varmeflade (°C)'),
            keyboardType: TextInputType.text,
          ),
        ] else if (anlaegstype == 'Udsugningsanlæg') ...[
          const Text('Er udsugningsluften opvarmet?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: tUdController,
            decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)'),
            keyboardType: TextInputType.text,
          ),
        ],

        const SizedBox(height: 16),



        // valgfrit: vis beregnet virkningsgrad

      ],
    );
  }
}


















































































