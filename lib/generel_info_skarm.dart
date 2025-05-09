import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'generel_projekt_info.dart';
import 'maaledata_skarm.dart';

class GenerelInfoSkarm extends StatefulWidget {
  const GenerelInfoSkarm({super.key});

  @override
  State<GenerelInfoSkarm> createState() => _GenerelInfoSkarmState();
}

class _GenerelInfoSkarmState extends State<GenerelInfoSkarm> {
  final _kundeNavnController = TextEditingController();
  final _adresseController = TextEditingController();
  final _postnrByController = TextEditingController();
  final _attController = TextEditingController();
  final _teknikerNavnController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _antalAnlaegController = TextEditingController();
  final _elPrisController = TextEditingController(text: '1,20');
  final _varmePrisController = TextEditingController(text: '0,85');

  final Map<String, TextEditingController> _drifttimer = {
    'Mandag': TextEditingController(),
    'Tirsdag': TextEditingController(),
    'Onsdag': TextEditingController(),
    'Torsdag': TextEditingController(),
    'Fredag': TextEditingController(),
    'Lørdag': TextEditingController(),
    'Søndag': TextEditingController(),
  };

  final _ugerPerAarController = TextEditingController(text: '52');
  final List<String> _driftperioder = ['Døgn', 'Dagtimer', 'Nattetimer'];
  String _valgtDriftperiode = 'Dagtimer';

  final List<String> _afdelinger = [
    'Aalborg', 'Randers', 'Aarhus', 'Horsens', 'Kolding', 'Esbjerg', 'Odense', 'Brøndby',
  ];
  String? _valgtAfdeling;

  final Color _matchingGreen = Color(0xFF34E0A1);
  final Color _matchingBlue = Color(0xFF006390);

  @override
  void dispose() {
    _kundeNavnController.dispose();
    _adresseController.dispose();
    _postnrByController.dispose();
    _attController.dispose();
    _teknikerNavnController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _antalAnlaegController.dispose();
    _elPrisController.dispose();
    _varmePrisController.dispose();
    _ugerPerAarController.dispose();
    for (final controller in _drifttimer.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _gaVidere() {
    final driftTimerPrUge = _drifttimer.values
        .map((c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0)
        .toList();

    final elPris = double.tryParse(_elPrisController.text.replaceAll(',', '.')) ?? 1.20;
    final varmePris = double.tryParse(_varmePrisController.text.replaceAll(',', '.')) ?? 0.85;

    final projektInfo = GenerelProjektInfo(
      kundeNavn: _kundeNavnController.text,
      adresse: _adresseController.text,
      postnrBy: _postnrByController.text,
      att: _attController.text,
      teknikerNavn: _teknikerNavnController.text,
      telefon: _telefonController.text,
      email: _emailController.text,
      afdeling: _valgtAfdeling ?? '',
      antalAnlaeg: int.tryParse(_antalAnlaegController.text) ?? 1,
      elPris: elPris,
      varmePris: varmePris,
      driftTimerPrUge: driftTimerPrUge,
      ugerPerAar: int.tryParse(_ugerPerAarController.text) ?? 52,
      driftperiode: _valgtDriftperiode,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaaledataSkarm(projektInfo: projektInfo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decimalInputFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,\-+]')),
    ];
    final intInputFormatter = [
      FilteringTextInputFormatter.digitsOnly,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generel Projektinformation'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/star_logo.png', height: 45),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sektionTitel('Kundens oplysninger'),
            TextField(controller: _kundeNavnController, decoration: const InputDecoration(labelText: 'Kundens navn')),
            TextField(controller: _adresseController, decoration: const InputDecoration(labelText: 'Adresse')),
            TextField(controller: _postnrByController, decoration: const InputDecoration(labelText: 'Postnr./By')),
            TextField(controller: _attController, decoration: const InputDecoration(labelText: 'Att.')),

            const SizedBox(height: 24),
            _sektionTitel('Rapporten er udført af'),
            TextField(controller: _teknikerNavnController, decoration: const InputDecoration(labelText: 'Teknikers navn')),
            TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefonnr.')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail')),

            const SizedBox(height: 24),
            _sektionTitel('Afdeling'),
            DropdownButtonFormField<String>(
              value: _valgtAfdeling,
              decoration: const InputDecoration(labelText: 'Vælg afdeling'),
              items: _afdelinger.map((afdeling) {
                return DropdownMenuItem(value: afdeling, child: Text(afdeling));
              }).toList(),
              onChanged: (val) => setState(() => _valgtAfdeling = val),
            ),

            const SizedBox(height: 24),
            _sektionTitel('Antal anlæg i alt'),
            TextField(
              controller: _antalAnlaegController,
              decoration: const InputDecoration(labelText: 'Antal anlæg'),
              keyboardType: TextInputType.number,
              inputFormatters: intInputFormatter,
            ),

            const SizedBox(height: 24),
            _sektionTitel('Energipriser'),
            TextField(
              controller: _elPrisController,
              decoration: const InputDecoration(labelText: 'El-pris (kr./kWh)'),
              keyboardType: TextInputType.text,
              inputFormatters: decimalInputFormatter,
            ),
            TextField(
              controller: _varmePrisController,
              decoration: const InputDecoration(labelText: 'Varmepris (kr./kWh)'),
              keyboardType: TextInputType.text,
              inputFormatters: decimalInputFormatter,
            ),

            const SizedBox(height: 24),
            _sektionTitel('Drifttimer'),
            ..._drifttimer.entries.map((entry) {
              return TextField(
                controller: entry.value,
                decoration: InputDecoration(labelText: '${entry.key}'),
                keyboardType: TextInputType.text,
                inputFormatters: decimalInputFormatter,
              );
            }),

            TextField(
              controller: _ugerPerAarController,
              decoration: const InputDecoration(labelText: 'Antal uger pr. år'),
              keyboardType: TextInputType.text,
              inputFormatters: decimalInputFormatter,
            ),

            const SizedBox(height: 24),
            _sektionTitel('Tidsrum for drift'),
            DropdownButtonFormField<String>(
              value: _valgtDriftperiode,
              decoration: const InputDecoration(labelText: 'Driftperiode'),
              items: _driftperioder.map((periode) => DropdownMenuItem(
                value: periode,
                child: Text(periode),
              )).toList(),
              onChanged: (val) => setState(() => _valgtDriftperiode = val!),
            ),

            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _matchingGreen,
                  foregroundColor: _matchingBlue,
                ),
                onPressed: _gaVidere,
                child: const Text('Næste'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sektionTitel(String tekst) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: _matchingGreen,
      child: Text(
        tekst,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _matchingBlue,
        ),
      ),
    );
  }
}
