import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class LuftmaengdeVisning extends StatelessWidget {
  final String anlaegstype;

  final TextEditingController maaltLuftmaengdeIndController;
  final TextEditingController luftmaengdeKVaerdiIndController;
  final TextEditingController trykDifferensIndController;
  final TextEditingController maksLuftIndController;
  final TextEditingController maksEffektIndController;
  final TextEditingController effektMaaltIndController;

  final TextEditingController maaltLuftmaengdeUdController;
  final TextEditingController luftmaengdeKVaerdiUdController;
  final TextEditingController trykDifferensUdController;
  final TextEditingController maksLuftUdController;
  final TextEditingController maksEffektUdController;
  final TextEditingController effektMaaltUdController;

  final bool visKVaerdiBeregningInd;
  final bool visEffektBeregningInd;
  final bool visKVaerdiBeregningUd;
  final bool visEffektBeregningUd;

  final VoidCallback onSkiftKVaerdiInd;
  final VoidCallback onSkiftEffektInd;
  final VoidCallback onSkiftKVaerdiUd;
  final VoidCallback onSkiftEffektUd;

  const LuftmaengdeVisning({
    super.key,
    required this.anlaegstype,
    required this.maaltLuftmaengdeIndController,
    required this.luftmaengdeKVaerdiIndController,
    required this.trykDifferensIndController,
    required this.maksLuftIndController,
    required this.maksEffektIndController,
    required this.effektMaaltIndController,
    required this.maaltLuftmaengdeUdController,
    required this.luftmaengdeKVaerdiUdController,
    required this.trykDifferensUdController,
    required this.maksLuftUdController,
    required this.maksEffektUdController,
    required this.effektMaaltUdController,
    required this.visKVaerdiBeregningInd,
    required this.visEffektBeregningInd,
    required this.visKVaerdiBeregningUd,
    required this.visEffektBeregningUd,
    required this.onSkiftKVaerdiInd,
    required this.onSkiftEffektInd,
    required this.onSkiftKVaerdiUd,
    required this.onSkiftEffektUd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anlaegstype != 'Udsugningsanlæg')
          _luftmaengdeSektion(
            title: 'Indblæsning – Luftmængde',
            maaltController: maaltLuftmaengdeIndController,
            kVaerdiController: luftmaengdeKVaerdiIndController,
            trykDifferensController: trykDifferensIndController,
            maksLuftController: maksLuftIndController,
            maksEffektController: maksEffektIndController,
            effektMaaltController: effektMaaltIndController,
            visKVaerdiBeregning: visKVaerdiBeregningInd,
            visEffektBeregning: visEffektBeregningInd,
            onSkiftKVaerdi: onSkiftKVaerdiInd,
            onSkiftEffekt: onSkiftEffektInd,
          ),
        if (anlaegstype != 'Indblæsningsanlæg')
          _luftmaengdeSektion(
            title: 'Udsugning – Luftmængde',
            maaltController: maaltLuftmaengdeUdController,
            kVaerdiController: luftmaengdeKVaerdiUdController,
            trykDifferensController: trykDifferensUdController,
            maksLuftController: maksLuftUdController,
            maksEffektController: maksEffektUdController,
            effektMaaltController: effektMaaltUdController,
            visKVaerdiBeregning: visKVaerdiBeregningUd,
            visEffektBeregning: visEffektBeregningUd,
            onSkiftKVaerdi: onSkiftKVaerdiUd,
            onSkiftEffekt: onSkiftEffektUd,
          ),
      ],
    );
  }

  Widget _luftmaengdeSektion({
    required String title,
    required TextEditingController maaltController,
    required TextEditingController kVaerdiController,
    required TextEditingController trykDifferensController,
    required TextEditingController maksLuftController,
    required TextEditingController maksEffektController,
    required TextEditingController effektMaaltController,
    required bool visKVaerdiBeregning,
    required bool visEffektBeregning,
    required VoidCallback onSkiftKVaerdi,
    required VoidCallback onSkiftEffekt,
  }) {
    if (visKVaerdiBeregning) {
      final double k = double.tryParse(kVaerdiController.text.replaceAll(',', '.')) ?? 0;
      final double dp = double.tryParse(trykDifferensController.text.replaceAll(',', '.')) ?? 0;
      final double q = k * sqrt(dp);
      maaltController.text = q.toStringAsFixed(0);
    } else if (visEffektBeregning) {
      final double qn = double.tryParse(maksLuftController.text.replaceAll(',', '.')) ?? 0;
      final double pn = double.tryParse(maksEffektController.text.replaceAll(',', '.')) ?? 0;
      final double p = double.tryParse(effektMaaltController.text.replaceAll(',', '.')) ?? 0;
      if (pn > 0 && qn > 0 && p > 0) {
        final double q = qn * pow(p / pn, 1 / 3);
        maaltController.text = q.toStringAsFixed(0);
      }
    }

    String labelText;
    if (visKVaerdiBeregning) {
      labelText = 'Beregnet luftmængde (K-værdi) (m³/h)';
    } else if (visEffektBeregning) {
      labelText = 'Beregnet luftmængde (designdata) (m³/h)';
    } else {
      labelText = 'Målt luftmængde (m³/h)';
    }

    final formatter = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'^[-+]?[\d]{0,5}(,\d{0,2})?$')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        TextField(
          controller: maaltController,
          decoration: InputDecoration(labelText: labelText),
          keyboardType: TextInputType.text,
          inputFormatters: formatter,
        ),

        SwitchListTile(
          title: const Text('Beregning med K-værdi'),
          value: visKVaerdiBeregning,
          onChanged: (_) => onSkiftKVaerdi(),
          activeThumbColor: Color(0xFF34E0A1),
          inactiveTrackColor: Color(0xFF34E0A1),
        ),
        if (visKVaerdiBeregning) ...[
          const Text('q = K × √(ΔP)', style: TextStyle(fontStyle: FontStyle.italic)),
          TextField(
            controller: kVaerdiController,
            decoration: const InputDecoration(labelText: 'K-værdi'),
            keyboardType: TextInputType.text,
            inputFormatters: formatter,
          ),
          TextField(
            controller: trykDifferensController,
            decoration: const InputDecoration(labelText: 'Tryktab over ventilatoren (Pa)'),
            keyboardType: TextInputType.text,
            inputFormatters: formatter,
            onSubmitted: (_) {
              final double k = double.tryParse(kVaerdiController.text.replaceAll(',', '.')) ?? 0;
              final double dp = double.tryParse(trykDifferensController.text.replaceAll(',', '.')) ?? 0;
              if (k > 0 && dp > 0) {
                final double luft = k * sqrt(dp);
                maaltController.text = luft.toStringAsFixed(0);
              }
            },
          ),
        ],

        SwitchListTile(
          title: const Text('Beregning ud fra designdata'),
          value: visEffektBeregning,
          onChanged: (_) => onSkiftEffekt(),
          activeThumbColor: Color(0xFF34E0A1),
          inactiveTrackColor: Color(0xFF34E0A1),
        ),
        if (visEffektBeregning) ...[
          const Text('q = qₙ × (P / Pₙ)^(1/3)', style: TextStyle(fontStyle: FontStyle.italic)),
          TextField(
            controller: maksLuftController,
            decoration: const InputDecoration(labelText: 'Maks. luftmængde (m³/h)'),
            keyboardType: TextInputType.text,
            inputFormatters: formatter,
          ),
          TextField(
            controller: maksEffektController,
            decoration: const InputDecoration(labelText: 'Maks. effekt (kW)'),
            keyboardType: TextInputType.text,
            inputFormatters: formatter,
          ),
          TextField(
            controller: effektMaaltController,
            decoration: const InputDecoration(labelText: 'Målt effekt (kW)'),
            keyboardType: TextInputType.text,
            inputFormatters: formatter,
            onSubmitted: (_) {
              final double qn = double.tryParse(maksLuftController.text.replaceAll(',', '.')) ?? 0;
              final double pn = double.tryParse(maksEffektController.text.replaceAll(',', '.')) ?? 0;
              final double p = double.tryParse(effektMaaltController.text.replaceAll(',', '.')) ?? 0;
              if (qn > 0 && pn > 0 && p > 0) {
                final double luft = qn * pow(p / pn, 1 / 3);
                maaltController.text = luft.toStringAsFixed(0);
              }
            },
          ),
        ],

        const Divider(height: 32),
      ],
    );
  }
}