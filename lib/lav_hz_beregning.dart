// BeregnVedLavHzWidget.dart

/*
────────────────────────────────────────────────────────────
🔒 Forklaring af ventilatoropslag ved lav frekvens (< 50 Hz)
────────────────────────────────────────────────────────────
Når en ventilator kører med en frekvens under 50 Hz, skal vi sikre,
at den valgte ventilator også kan levere det ønskede tryk og luftmængde
ved normal drift (50 Hz).

✔ Hvis det er muligt at få anlægget op på 50 Hz:
  • Så måler vi tryk og luftmængde ved 50 Hz
  • Vi bruger disse værdier til at slå en ventilator op i EBM-databasen

✔ Hvis det IKKE er muligt:
  • Så beregner vi værdierne (fx 350 Pa og 8000 m³/h) ud fra designdata
  • Og bruger disse til at slå ventilatoren op

🎯 Formål med dette opslag:
  • KUN for at sikre, at samme ventilator kan bruges ved både:
    - Normalt driftpunkt (fx 225 Pa og 5000 m³/h)
    - Og max belastning (fx 350 Pa og 8000 m³/h)
  • Vi sammenligner varenummeret fra begge opslag

⛔ Disse værdier bruges IKKE til:
  • Energiberegning
  • Elforbrug
  • Virkningsgrad
  • SEL-værdi

✅ Det er KUN et kontrollopslag for at sikre,
   at ventilatoren dækker begge driftspunkter.
────────────────────────────────────────────────────────────
*/
// 🔄 Ryddet op version af BeregnVedLavHzWidget – uden "gem" og uden mellemstep
import 'package:flutter/material.dart';
import 'dart:math';

class BeregnVedLavHzWidget extends StatefulWidget {
final String anlaegsType;
final double hzInd;
final double hzUd;
final double luftInd;
final double luftUd;
final double statiskTrykInd;
final double statiskTrykUd;

final TextEditingController maaltLuftmaengdeIndController; // ✅ Indblæsning
final TextEditingController maaltLuftmaengdeUdController;  // ✅ Udsugning

final void Function(double luft, double trykFoer, double trykEfter)? onGemMaxInd;
final void Function(double luft, double trykFoer, double trykEfter)? onGemMaxUd;

const BeregnVedLavHzWidget({
super.key,
required this.anlaegsType,
required this.hzInd,
required this.hzUd,
required this.luftInd,
required this.luftUd,
required this.statiskTrykInd,
required this.statiskTrykUd,
required this.maaltLuftmaengdeIndController,
required this.maaltLuftmaengdeUdController, // ✅ Tilføjet korrekt
this.onGemMaxInd,
this.onGemMaxUd,
});

@override
State<BeregnVedLavHzWidget> createState() => BeregnVedLavHzWidgetState();
}

class BeregnVedLavHzWidgetState extends State<BeregnVedLavHzWidget> {

  bool brugBeregningInd = true;
  bool brugBeregningUd = true;
  bool visNoteInd = false;
  bool visNoteUd = false;

  final _qNIndController = TextEditingController();
  final _hzIndController = TextEditingController();
  final _pNIndController = TextEditingController();
  final _pMaalIndController = TextEditingController();
  final _luftIndController = TextEditingController();
  final _trykFoerIndController = TextEditingController();
  final _trykEfterIndController = TextEditingController();
  final _hzDriftIndController = TextEditingController();
  final _hzMaxIndController = TextEditingController();
  final _hzDriftUdController = TextEditingController();
  final _hzMaxUdController = TextEditingController();

  final _qNUdController = TextEditingController();
  final _hzUdController = TextEditingController();
  final _pNUdController = TextEditingController();
  final _pMaalUdController = TextEditingController();
  final _luftUdController = TextEditingController();
  final _trykFoerUdController = TextEditingController();
  final _trykEfterUdController = TextEditingController();

  double? luftIndMax;
  double? trykFoerIndMax;
  double? trykEfterIndMax;
  double? luftIndManuel;
  double? trykFoerIndManuel;
  double? trykEfterIndManuel;
  double? _hzDriftInd;
  double? _hzDriftUd;

  double? luftUdMax;
  double? trykFoerUdMax;
  double? trykEfterUdMax;


  void beregnInd() {
    print('✅ beregnInd() blev kaldt');

    final double? hzDrift = double.tryParse(_hzDriftIndController.text.replaceAll(',', '.'));
    final double? hzMax = double.tryParse(_hzMaxIndController.text.replaceAll(',', '.'));

    print('🧪 Hz indtastet (drift): ${_hzDriftIndController.text} → hzDrift = $hzDrift');
    print('🧪 Hz maks indtastet: ${_hzMaxIndController.text} → hzMax = $hzMax');

    final parsedLuft = double.tryParse(_luftIndController.text.replaceAll(',', '.')) ??
        double.tryParse(widget.maaltLuftmaengdeIndController.text.replaceAll(',', '.'));

    final double? luftInd = (parsedLuft != null && parsedLuft > 0)
          ? parsedLuft
          : (widget.luftInd > 0 ? widget.luftInd : null); // widget.luftInd er non-null

    final double? statiskTrykInd = widget.statiskTrykInd;

    print('📥 parsedLuft = $parsedLuft');
    print('📊 Beregning med: luftInd = $luftInd, statiskTrykInd = $statiskTrykInd, hzDrift = $hzDrift, hzMax = $hzMax');

    if (luftInd != null && luftInd > 0 &&
                statiskTrykInd != null && statiskTrykInd > 0 &&
                hzDrift != null && hzDrift > 0 &&
                hzMax != null && hzMax > hzDrift) {

      final forhold = hzMax / hzDrift;
      final luftVedMaxHz = luftInd * forhold;
      final trykVedMaxHz = statiskTrykInd * pow(forhold, 2);

      setState(() {
        _hzDriftInd = hzDrift;
        luftIndMax = luftVedMaxHz;
        trykFoerIndMax = 0;
        trykEfterIndMax = trykVedMaxHz;
        visNoteInd = hzDrift! < 50;

        _luftIndController.text = luftVedMaxHz.toStringAsFixed(0);
        _trykFoerIndController.text = '0';
        _trykEfterIndController.text = trykVedMaxHz.toStringAsFixed(0);
      });

      if (widget.onGemMaxInd != null) {
        widget.onGemMaxInd!(luftVedMaxHz, 0, trykVedMaxHz);
      }

      print('✅ Beregning gennemført');
    } else {
      setState(() => visNoteInd = false); // <- sluk note ved fejlede inputs
      print('❌ Fejl: Mangler gyldige inputværdier eller Drift Hz ≥ Maks Hz');
     }
  }

  void beregnUd() {

    // 🔹 Parse Hz-værdier
    final double? hzDrift = double.tryParse(_hzDriftUdController.text.replaceAll(',', '.'));
    final double? hzMax = double.tryParse(_hzMaxUdController.text.replaceAll(',', '.'));
    print('🧪 hzDrift = $hzDrift | hzMax = $hzMax');

    // 🔹 Parse luftmængde (bruger input først, derefter fallback til widget)
    final parsedLuft = double.tryParse(_luftUdController.text.replaceAll(',', '.')) ??
        double.tryParse(widget.maaltLuftmaengdeUdController.text.replaceAll(',', '.'));

    final double? luftUd = (parsedLuft != null && parsedLuft > 0)
        ? parsedLuft
        : (widget.luftUd > 0 ? widget.luftUd : null);

    print('📥 parsedLuft = $parsedLuft');
    print('📥 fallback widget.luftUd = ${widget.luftUd}');
    print('📊 Beregning med: luftUd = $luftUd, statiskTrykUd = statiskTrykUd, hzDrift = $hzDrift, hzMax = $hzMax');

    // 🔹 Tag tryk fra widget
    final double? statiskTrykUd = widget.statiskTrykUd;

    // 🔹 Debug info
    print('📥 parsedLuft = $parsedLuft');
    print('📊 Beregning med: luftUd = $luftUd, statiskTrykUd = $statiskTrykUd, hzDrift = $hzDrift, hzMax = $hzMax');

    // 🔹 Udfør beregning hvis alle værdier er valide
    if (luftUd != null && luftUd > 0 &&
        statiskTrykUd != null && statiskTrykUd > 0 &&
        hzDrift != null && hzDrift > 0 &&
        hzMax != null && hzMax > hzDrift) {

      final forhold = hzMax / hzDrift;
      final luftVedMaxHz = luftUd * forhold;
      final trykVedMaxHz = statiskTrykUd * pow(forhold, 2);

      setState(() {
        _hzDriftUd = hzDrift;
        luftUdMax = luftVedMaxHz;
        trykFoerUdMax = 0;
        trykEfterUdMax = trykVedMaxHz;
        visNoteUd = hzDrift! < 50;

        _luftUdController.text = luftVedMaxHz.toStringAsFixed(0);
        _trykFoerUdController.text = '0';
        _trykEfterUdController.text = trykVedMaxHz.toStringAsFixed(0);
      });

      if (widget.onGemMaxUd != null) {
        widget.onGemMaxUd!(luftVedMaxHz, 0, trykVedMaxHz);
      }

      print('✅ Beregning gennemført');
    } else {
        setState(() => visNoteUd = false);
        print('❌ Fejl: Mangler gyldige inputværdier eller Drift Hz ≥ Maks Hz');
     }
  }

  Map<String, double> hentMaxDataInd() {
    return {
      'luft': double.tryParse(_luftIndController.text.replaceAll(',', '.')) ?? 0,
      'trykFoer': double.tryParse(_trykFoerIndController.text.replaceAll(',', '.')) ?? 0,
      'trykEfter': double.tryParse(_trykEfterIndController.text.replaceAll(',', '.')) ?? 0,
    };
  }

  Map<String, double> hentMaxDataUd() {
    return {
      'luft': double.tryParse(_luftUdController.text.replaceAll(',', '.')) ?? 0,
      'trykFoer': double.tryParse(_trykFoerUdController.text.replaceAll(',', '.')) ?? 0,
      'trykEfter': double.tryParse(_trykEfterUdController.text.replaceAll(',', '.')) ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((widget.hzInd >= 2 && widget.hzInd < 50) &&
            (widget.anlaegsType == 'Indblæsningsanlæg' || widget.anlaegsType == 'Ventilationsanlæg')) ...[
          const SizedBox(height: 16),

          // 🚫 Fjernet tekst-advarsel (visNoteInd) – beholdt alt andet

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beregn ud fra designdata'),
              Switch(
                value: brugBeregningInd,
                onChanged: (val) {
                  setState(() {
                    brugBeregningInd = val;
                    if (val) beregnInd();
                  });
                },
                activeColor: const Color(0xFF34E0A1),
                activeTrackColor: const Color(0xFF34E0A1),
                thumbColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
          if (brugBeregningInd) ...[
            TextField(
              controller: _hzDriftIndController,
              decoration: const InputDecoration(labelText: 'Drift Hz'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _hzMaxIndController,
              decoration: const InputDecoration(labelText: 'Maks Hz'),
              keyboardType: TextInputType.text,
              onSubmitted: (_) => beregnInd(),
            ),
            if (trykEfterIndMax != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Beregnede maksimal Tryk: ${trykEfterIndMax!.toStringAsFixed(0)} Pa'),
              ),
            if (luftIndMax != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Beregnede maksimal Luftmængde: ${luftIndMax!.toStringAsFixed(0)} m³/h'),
              ),
            if (luftIndMax != null && trykEfterIndMax != null) ...[
              const SizedBox(height: 12),
              const Text('📘 Beregnet maksimal drift – formler', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('qₘₐₓ = qₙ × (Hzₘₐₓ / Hzₗₐᵥ)'),
              Text('→ ${_qNIndController.text} × (${_hzMaxIndController.text} / ${_hzDriftIndController.text}) = ${luftIndMax!.toStringAsFixed(0)} m³/h'),
              const SizedBox(height: 8),
              Text('ΔPₘₐₓ = ΔPₙ × (Hzₘₐₓ / Hzₗₐᵥ)²'),
              Text('→ ${widget.statiskTrykInd.toStringAsFixed(0)} × '
                  '(${_hzMaxIndController.text} / ${_hzDriftIndController.text})² = ${trykEfterIndMax!.toStringAsFixed(0)} Pa'),
              const SizedBox(height: 12),
            ],
          ] else ...[
            TextField(
              controller: _luftIndController,
              decoration: const InputDecoration(labelText: 'Målt luftmængde (m³/h)'),
              keyboardType: TextInputType.text,
              onChanged: (val) {
                luftIndManuel = double.tryParse(val.replaceAll(',', '.'));
              },
            ),
            TextField(
              controller: _trykFoerIndController,
              decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)'),
              keyboardType: TextInputType.text,
              onChanged: (val) {
                trykFoerIndManuel = double.tryParse(val.replaceAll(',', '.'));
              },
            ),
            TextField(
              controller: _trykEfterIndController,
              decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)'),
              keyboardType: TextInputType.text,
              onChanged: (val) {
                trykEfterIndManuel = double.tryParse(val.replaceAll(',', '.'));
              },
            ),
          ],
        ],

        if ((widget.hzUd >= 2 && widget.hzUd < 50) &&
            (widget.anlaegsType == 'Udsugningsanlæg' || widget.anlaegsType == 'Ventilationsanlæg')) ...[
          const SizedBox(height: 16),

          // 🚫 Fjernet tekst-advarsel (visNoteUd) – beholdt alt andet

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beregn ud fra designdata'),
              Switch(
                value: brugBeregningUd,
                onChanged: (val) {
                  setState(() {
                    brugBeregningUd = val;
                    if (val) beregnUd();
                  });
                },
                activeColor: const Color(0xFF34E0A1),
                activeTrackColor: const Color(0xFF34E0A1),
                thumbColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
          if (brugBeregningUd) ...[
            TextField(
              controller: _hzDriftUdController,
              decoration: const InputDecoration(labelText: 'Drift Hz'),
              keyboardType: TextInputType.text,
              onSubmitted: (_) => beregnUd(),
            ),
            TextField(
              controller: _hzMaxUdController,
              decoration: const InputDecoration(labelText: 'Maks Hz'),
              keyboardType: TextInputType.text,
              onSubmitted: (_) => beregnUd(),
            ),
            const SizedBox(height: 12),
            if (trykEfterUdMax != null)
              Text('Beregnet maksimal Tryk: ${trykEfterUdMax!.toStringAsFixed(0)} Pa'),
            if (luftUdMax != null)
              Text('Beregnet maksimal luftmængde: ${luftUdMax!.toStringAsFixed(0)} m³/h'),
            if (luftUdMax != null && trykFoerUdMax != null && trykEfterUdMax != null) ...[
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  '📘 Beregnet maksimal drift – formler',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              Text('qₙmax = qₙ × (Hzₘₐₓ / Hzₗₐᵥ)'),
              Text('→ ${_qNUdController.text} × (${_hzMaxUdController.text} / ${_hzDriftUdController.text}) = ${luftUdMax!.toStringAsFixed(0)} m³/h'),
              const SizedBox(height: 8),
              Text('ΔPₘₐₓ = ΔPₙ × (Hzₘₐₓ / Hzₗₐᵥ)²'),
              Text('→ ${widget.statiskTrykUd.toStringAsFixed(0)} × '
                  '(${_hzMaxUdController.text} / ${_hzDriftUdController.text})² = ${trykEfterUdMax!.toStringAsFixed(0)} Pa'),
              const SizedBox(height: 12),
            ],
          ] else ...[
            TextField(
              controller: _luftUdController,
              decoration: const InputDecoration(labelText: 'Målt luftmængde (m³/h)'),
              keyboardType: TextInputType.text,
              onChanged: (val) {
                setState(() {
                  luftUdMax = double.tryParse(val.replaceAll(',', '.'));
                });
              },
            ),
            TextField(
              controller: _trykFoerUdController,
              decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)'),
              keyboardType: TextInputType.text,
              onChanged: (val) {
                setState(() {
                  trykFoerUdMax = double.tryParse(val.replaceAll(',', '.'));
                });
              },
            ),
            TextField(
              controller: _trykEfterUdController,
              decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)'),
              keyboardType: TextInputType.text,
              onChanged: (val) {
                setState(() {
                  trykEfterUdMax = double.tryParse(val.replaceAll(',', '.'));
                });
              },
            ),
          ],
        ],
      ],
    );
  }
}