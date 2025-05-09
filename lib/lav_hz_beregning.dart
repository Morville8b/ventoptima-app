// BeregnVedLavHzWidget.dart
import 'package:flutter/material.dart';
import 'dart:math';

class BeregnVedLavHzWidget extends StatefulWidget {
  final Function(double luft, double tryk, {required bool erDesignData}) onBeregnResultatInd;
  final Function(double luft, double tryk, {required bool erDesignData}) onBeregnResultatUd;
  final double hzInd;
  final double hzUd;

  const BeregnVedLavHzWidget({
    super.key,
    required this.onBeregnResultatInd,
    required this.onBeregnResultatUd,
    required this.hzInd,
    required this.hzUd,
  });

  @override
  State<BeregnVedLavHzWidget> createState() => _BeregnVedLavHzWidgetState();
}

class _BeregnVedLavHzWidgetState extends State<BeregnVedLavHzWidget> {
  bool brugBeregningInd = true;
  bool brugBeregningUd = true;

  final _qNIndController = TextEditingController();
  final _pNIndController = TextEditingController();
  final _pMaalIndController = TextEditingController();
  final _luftIndController = TextEditingController();
  final _trykFoerIndController = TextEditingController();
  final _trykEfterIndController = TextEditingController();

  final _qNUdController = TextEditingController();
  final _pNUdController = TextEditingController();
  final _pMaalUdController = TextEditingController();
  final _luftUdController = TextEditingController();
  final _trykFoerUdController = TextEditingController();
  final _trykEfterUdController = TextEditingController();

  void beregnInd() {
    print('🔍 beregnInd kaldt');

    final qN = double.tryParse(_qNIndController.text.replaceAll(',', '.'));
    final pN = double.tryParse(_pNIndController.text.replaceAll(',', '.'));
    final p = double.tryParse(_pMaalIndController.text.replaceAll(',', '.'));

    if (qN != null && pN != null && p != null && p > 0 && pN > 0) {
      final luft = qN * pow((p / pN), 1 / 3);
      final afrundetLuft = luft.toDouble();
      print('📦 beregnet luft (Ind): ${afrundetLuft.toStringAsFixed(0)} m³/h');

      final tryk = 100.0; // midlertidig eller placeholder værdi
      widget.onBeregnResultatInd(afrundetLuft, tryk, erDesignData: true);

      // Valgfrit: opdater et tekstfelt direkte (hvis ønsket)
      _luftIndController.text = afrundetLuft.toStringAsFixed(0);
    }
  }

  void beregnUd() {
    print('🔍 beregnUd kaldt');

    final qN = double.tryParse(_qNUdController.text.replaceAll(',', '.'));
    final pN = double.tryParse(_pNUdController.text.replaceAll(',', '.'));
    final p = double.tryParse(_pMaalUdController.text.replaceAll(',', '.'));

    if (qN != null && pN != null && p != null && p > 0 && pN > 0) {
      final luft = qN * pow((p / pN), 1 / 3);
      final afrundetLuft = luft.toDouble();
      print('📦 beregnet luft (Ud): ${afrundetLuft.toStringAsFixed(0)} m³/h');

      final tryk = 100.0;
      widget.onBeregnResultatUd(afrundetLuft, tryk, erDesignData: true);

      _luftUdController.text = afrundetLuft.toStringAsFixed(0);
    }
  }

  void gemManueltInd() {
    final luft = double.tryParse(_luftIndController.text.replaceAll(',', '.'));
    final trykFoer = double.tryParse(_trykFoerIndController.text.replaceAll(',', '.'));
    final trykEfter = double.tryParse(_trykEfterIndController.text.replaceAll(',', '.'));

    if (luft != null && trykFoer != null && trykEfter != null) {
      final statiskTryk = trykFoer + trykEfter;
      if (trykFoer > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF34E0A1),
            title: const Text('Manglende minustegn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text('Indblæsning: Husk at sætte minus foran sugtrykket før ventilatoren.', style: TextStyle(color: Colors.white)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))],
          ),
        );
      }
      widget.onBeregnResultatInd(luft, statiskTryk, erDesignData: false);
    }
  }

  void gemManueltUd() {
    final luft = double.tryParse(_luftUdController.text.replaceAll(',', '.'));
    final trykFoer = double.tryParse(_trykFoerUdController.text.replaceAll(',', '.'));
    final trykEfter = double.tryParse(_trykEfterUdController.text.replaceAll(',', '.'));

    if (luft != null && trykFoer != null && trykEfter != null) {
      final statiskTryk = trykFoer + trykEfter;
      if (trykFoer > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF34E0A1),
            title: const Text('Manglende minustegn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text('Udsugning: Husk at sætte minus foran sugtrykket før ventilatoren.', style: TextStyle(color: Colors.white)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))],
          ),
        );
      }
      widget.onBeregnResultatUd(luft, statiskTryk, erDesignData: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hzInd >= 2 && widget.hzInd < 50) ...[
          const SizedBox(height: 16),
          const Text('⚠ Indblæsningsventilator kører med lav frekvens (< 50 Hz)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beregn ud fra designdata'),
              Switch(
                value: brugBeregningInd,
                onChanged: (val) => setState(() => brugBeregningInd = val),
                activeColor: const Color(0xFF34E0A1),
                activeTrackColor: const Color(0xFF34E0A1),
                thumbColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF4A4A4A)),
              )
            ],
          ),
          if (brugBeregningInd) ...[
            TextField(controller: _pMaalIndController, decoration: const InputDecoration(labelText: 'Mærkeplade effekt P (kW)')),
            TextField(controller: _qNIndController, decoration: const InputDecoration(labelText: 'Maks. luftmængde qₙ (m³/h)')),
            TextField(controller: _pNIndController, decoration: const InputDecoration(labelText: 'Nominel effekt Pₙ (kW)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: beregnInd,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34E0A1), foregroundColor: const Color(0xFF006390), shape: const StadiumBorder()),
              child: const Text('Beregn luft og tryk (design)'),
            )
          ] else ...[
            TextField(controller: _luftIndController, decoration: const InputDecoration(labelText: 'Målt luftmængde (m³/h)')),
            TextField(controller: _trykFoerIndController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
            TextField(controller: _trykEfterIndController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: gemManueltInd,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34E0A1), foregroundColor: const Color(0xFF006390), shape: const StadiumBorder()),
              child: const Text('Gem værdier (målt ved max drift)'),
            )
          ]
        ],

        if (widget.hzUd >= 2 && widget.hzUd < 50) ...[
          const SizedBox(height: 24),
          const Text('⚠ Udsugningsventilator kører med lav frekvens (< 50 Hz)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beregn ud fra designdata'),
              Switch(
                value: brugBeregningUd,
                onChanged: (val) => setState(() => brugBeregningUd = val),
                activeColor: const Color(0xFF34E0A1),
                activeTrackColor: const Color(0xFF34E0A1),
                thumbColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF4A4A4A)),
              )
            ],
          ),
          if (brugBeregningUd) ...[
            TextField(controller: _pMaalUdController, decoration: const InputDecoration(labelText: 'Mærkeplade effekt P (kW)')),
            TextField(controller: _qNUdController, decoration: const InputDecoration(labelText: 'Maks. luftmængde qₙ (m³/h)')),
            TextField(controller: _pNUdController, decoration: const InputDecoration(labelText: 'Nominel effekt Pₙ (kW)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: beregnUd,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34E0A1), foregroundColor: const Color(0xFF006390), shape: const StadiumBorder()),
              child: const Text('Beregn luft og tryk (design)'),
            )
          ] else ...[
            TextField(controller: _luftUdController, decoration: const InputDecoration(labelText: 'Målt luftmængde (m³/h)')),
            TextField(controller: _trykFoerUdController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
            TextField(controller: _trykEfterUdController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: gemManueltUd,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34E0A1), foregroundColor: const Color(0xFF006390), shape: const StadiumBorder()),
              child: const Text('Gem værdier (målt ved max drift)'),
            )
          ]
        ]
      ],
    );
  }
}

