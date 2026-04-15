import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VentilatorVisning extends StatefulWidget {
  final String anlaegstype;

  final TextEditingController trykGamleFiltreIndController;
  final TextEditingController antalHeleFiltreIndController;
  final TextEditingController antalHalveFiltreIndController;
  final TextEditingController trykFoerIndController;
  final TextEditingController trykEfterIndController;
  final TextEditingController hzIndController;
  final TextEditingController effektIndController;

  final TextEditingController trykGamleFiltreUdController;
  final TextEditingController antalHeleFiltreUdController;
  final TextEditingController antalHalveFiltreUdController;
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
    required this.antalHeleFiltreIndController,
    required this.antalHalveFiltreIndController,
    required this.trykFoerIndController,
    required this.trykEfterIndController,
    required this.hzIndController,
    required this.effektIndController,
    required this.trykGamleFiltreUdController,
    required this.antalHeleFiltreUdController,
    required this.antalHalveFiltreUdController,
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

  void _opdaterTryk() {
    final trykFoerInd = double.tryParse(widget.trykFoerIndController.text.replaceAll(',', '.')) ?? 0;
    final trykFoerUd = double.tryParse(widget.trykFoerUdController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      visFejlInd = widget.trykFoerIndController.text.isNotEmpty &&
          !widget.trykFoerIndController.text.trim().startsWith('-');
      visFejlUd = widget.trykFoerUdController.text.isNotEmpty &&
          !widget.trykFoerUdController.text.trim().startsWith('-');

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
    final inputFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'^[-+]?[0-9]{0,5}(,[0-9]{0,2})?')),
    ];

    InputDecoration dekoration(String label, {bool visFejl = false}) {
      return InputDecoration(
        labelText: label,
        errorText: visFejl ? 'Husk minus foran sugtryk' : null,
        border: const UnderlineInputBorder(),
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
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.antalHeleFiltreIndController,
                  decoration: dekoration('Antal hele filtre'),
                  keyboardType: TextInputType.text,
                  inputFormatters: inputFormatter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.antalHalveFiltreIndController,
                  decoration: dekoration('Antal halve filtre'),
                  keyboardType: TextInputType.text,
                  inputFormatters: inputFormatter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykFoerIndController,
            decoration: dekoration('Tryk før ventilator (Pa)', visFejl: visFejlInd),
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykEfterIndController,
            decoration: dekoration('Tryk efter ventilator (Pa)'),
            keyboardType: TextInputType.text,
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
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.effektIndController,
            decoration: dekoration('Effekt (kW)'),
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const Divider(height: 32),
        ],
        if (widget.anlaegstype != 'Indblæsningsanlæg') ...[
          const Text('Udsugningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: widget.trykGamleFiltreUdController,
            decoration: dekoration('Tryktab over gamle filtre (Pa)'),
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.antalHeleFiltreUdController,
                  decoration: dekoration('Antal hele filtre'),
                  keyboardType: TextInputType.text,
                  inputFormatters: inputFormatter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.antalHalveFiltreUdController,
                  decoration: dekoration('Antal halve filtre'),
                  keyboardType: TextInputType.text,
                  inputFormatters: inputFormatter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykFoerUdController,
            decoration: dekoration('Tryk før ventilator (Pa)', visFejl: visFejlUd),
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.trykEfterUdController,
            decoration: dekoration('Tryk efter ventilator (Pa)'),
            keyboardType: TextInputType.text,
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
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.effektUdController,
            decoration: dekoration('Effekt (kW)'),
            keyboardType: TextInputType.text,
            inputFormatters: inputFormatter,
          ),
        ],
      ],
    );
  }
}