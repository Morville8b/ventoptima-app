import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VentilatorVisning extends StatefulWidget {
  final String anlaegstype;

  final TextEditingController trykGamleFiltreIndController;
  final TextEditingController antalFiltreIndController;
  final TextEditingController trykFoerIndController;
  final TextEditingController trykEfterIndController;
  final TextEditingController hzIndController;
  final TextEditingController effektIndController;

  final TextEditingController trykGamleFiltreUdController;
  final TextEditingController antalFiltreUdController;
  final TextEditingController trykFoerUdController;
  final TextEditingController trykEfterUdController;
  final TextEditingController hzUdController;
  final TextEditingController effektUdController;

  final Function(double)? onSamletTrykIndChanged;
  final Function(double)? onSamletTrykUdChanged;

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
    this.onSamletTrykIndChanged,
    this.onSamletTrykUdChanged,
  });

  @override
  State<VentilatorVisning> createState() => _VentilatorVisningState();
}

class _VentilatorVisningState extends State<VentilatorVisning> {
  double samletTrykInd = 0;
  double samletTrykUd = 0;
  bool visFejlInd = false;
  bool visFejlUd = false;

  @override
  void initState() {
    super.initState();
    widget.trykFoerIndController.addListener(_opdaterTryk);
    widget.trykEfterIndController.addListener(_opdaterTryk);
    widget.trykFoerUdController.addListener(_opdaterTryk);
    widget.trykEfterUdController.addListener(_opdaterTryk);
  }

  void _visPopup(String titel, String besked) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: const Color(0xFF34E0A1),
          title: Text(titel, style: const TextStyle(color: Color(0xFF006390))),
          content: Text(besked, style: const TextStyle(color: Color(0xFF006390))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFF006390))),
            ),
          ],
        ),
      );
    });
  }

  void _opdaterTryk() {
    final trykFoerIndText = widget.trykFoerIndController.text;
    final trykFoerInd = double.tryParse(trykFoerIndText.replaceAll(',', '.')) ?? 0;

    final trykFoerUdText = widget.trykFoerUdController.text;
    final trykFoerUd = double.tryParse(trykFoerUdText.replaceAll(',', '.')) ?? 0;

    setState(() {
      visFejlInd = trykFoerIndText.isNotEmpty && !trykFoerIndText.trim().startsWith('-');
      visFejlUd = trykFoerUdText.isNotEmpty && !trykFoerUdText.trim().startsWith('-');

      if (visFejlInd) {
        _visPopup('Manglende minustegn', 'Indblæsning: Husk at sætte minus foran sugtrykket før ventilatoren.');
      }
      if (visFejlUd) {
        _visPopup('Manglende minustegn', 'Udsugning: Husk at sætte minus foran sugtrykket før ventilatoren.');
      }

      samletTrykInd = trykFoerInd.abs() +
          (double.tryParse(widget.trykEfterIndController.text.replaceAll(',', '.')) ?? 0).abs();
      samletTrykUd = trykFoerUd.abs() +
          (double.tryParse(widget.trykEfterUdController.text.replaceAll(',', '.')) ?? 0).abs();

      widget.onSamletTrykIndChanged?.call(samletTrykInd);
      widget.onSamletTrykUdChanged?.call(samletTrykUd);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textKeyboard = TextInputType.text;
    final inputFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'^[-+]?[0-9]{0,5}(,[0-9]{0,2})?')),
    ];

    InputDecoration dekoration(String label, {bool visFejl = false}) {
      return InputDecoration(
        labelText: label,
        errorText: visFejl ? 'Husk minus foran sugtryk' : null,
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF34E0A1), width: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.anlaegstype != 'Udsugningsanlæg') ...[
          const Text('Indblæsningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: widget.trykGamleFiltreIndController,
            decoration: dekoration('Tryktab over gamle filtre (Pa)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.antalFiltreIndController,
            decoration: dekoration('Antal filtre'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykFoerIndController,
            decoration: dekoration('Tryk før ventilator (Pa)', visFejl: visFejlInd),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykEfterIndController,
            decoration: dekoration('Tryk efter ventilator (Pa)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('Statisk tryk i alt: ${samletTrykInd.toStringAsFixed(1)} Pa',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextField(
            controller: widget.hzIndController,
            decoration: dekoration('Frekvens (Hz)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.effektIndController,
            decoration: dekoration('Effekt (kW)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const Divider(height: 32),
        ],
        if (widget.anlaegstype != 'Indblæsningsanlæg') ...[
          const Text('Udsugningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: widget.trykGamleFiltreUdController,
            decoration: dekoration('Tryktab over gamle filtre (Pa)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.antalFiltreUdController,
            decoration: dekoration('Antal filtre'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykFoerUdController,
            decoration: dekoration('Tryk før ventilator (Pa)', visFejl: visFejlUd),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykEfterUdController,
            decoration: dekoration('Tryk efter ventilator (Pa)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('Statisk tryk i alt: ${samletTrykUd.toStringAsFixed(1)} Pa',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextField(
            controller: widget.hzUdController,
            decoration: dekoration('Frekvens (Hz)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.effektUdController,
            decoration: dekoration('Effekt (kW)'),
            keyboardType: textKeyboard,
            inputFormatters: inputFormatter,
          ),
        ],
      ],
    );
  }
}