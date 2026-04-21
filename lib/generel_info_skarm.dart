import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'generel_projekt_info.dart';
import 'maaledata_skarm.dart';
import 'anlaegs_data.dart';
import 'ventilator_samlet_beregning.dart';
import 'package:ventoptima/services/app_sikkerhed.dart';
import 'generel_projekt_info.dart' as gpi;

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
  String? _valgtKundeType = 'Erhverv';
  String? _valgtEnergiType = 'Fjernvarme';

  final List<String> _kundeTyper = ['Erhverv', 'Offentlig'];
  final List<String> _energiTyper = [
    'Fjernvarme',
    'Varmepumpe',
    'Naturgas',
    'Elvarme'
  ];

  final Map<String, Map<String, Map<String, String>>> _standardPriser = {
    'Erhverv': {
      'Fjernvarme': {'el': '1,20', 'varme': '0,85'},
      'Varmepumpe': {'el': '1,20', 'varme': '0,45'},
      'Naturgas': {'el': '1,20', 'varme': '1,10'},
      'Elvarme': {'el': '1,20', 'varme': '2,00'},
    },
    'Offentlig': {
      'Fjernvarme': {'el': '2,40', 'varme': '1,40'},
      'Varmepumpe': {'el': '2,40', 'varme': '0,90'},
      'Naturgas': {'el': '2,40', 'varme': '2,20'},
      'Elvarme': {'el': '2,40', 'varme': '4,00'},
    },
  };

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
    'Aalborg', 'Randers', 'Aarhus', 'Horsens', 'Holstebro','Kolding', 'Esbjerg', 'Odense', 'Brøndby',
  ];
  String? _valgtAfdeling;
  Key _afdelingKey = UniqueKey();

  final Color _matchingGreen = const Color(0xFF34E0A1);
  final Color _matchingBlue = const Color(0xFF006390);

  @override
  void initState() {
    super.initState();
    _hentBrugerInfo();
  }

  Future<void> _hentBrugerInfo() async {
    try {
      final bruger = await AppSikkerhed.hentBrugerInfo();
      setState(() {
        if (_teknikerNavnController.text.isEmpty) {
          _teknikerNavnController.text = bruger['navn'] ?? '';
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = bruger['email'] ?? '';
        }
        if (_telefonController.text.isEmpty) {
          _telefonController.text = bruger['telefon'] ?? '';
        }
        if (_valgtAfdeling == null) {
          final afdeling = bruger['afdeling'] ?? '';
          if (_afdelinger.contains(afdeling)) {
            _valgtAfdeling = afdeling;
            _afdelingKey = UniqueKey(); // ✅ Tving dropdown til at genbygge
          }
        }
      });
    } catch (e) {
      debugPrint('Kunne ikke hente brugerinfo: $e');

    }
  }

  Driftstype _mapDriftperiode(String val) {
    switch (val) {
      case 'Døgn': return Driftstype.doegn;
      case 'Dagtimer': return Driftstype.dag;
      case 'Nattetimer': return Driftstype.nat;
      default: return Driftstype.doegn;
    }
  }

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

  void _opdaterPriser() {
    final el = _standardPriser[_valgtKundeType]![_valgtEnergiType]!['el']!;
    final varme = _standardPriser[_valgtKundeType]![_valgtEnergiType]!['varme']!;
    setState(() {
      _elPrisController.text = el;
      _varmePrisController.text = varme;
    });
  }

  void _gaVidere() {
    final driftTimerPrUge = _drifttimer.values
        .map((c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0)
        .toList();

    final elPris = double.tryParse(_elPrisController.text.replaceAll(',', '.')) ?? 1.20;
    final varmePris = double.tryParse(_varmePrisController.text.replaceAll(',', '.')) ?? 0.85;
    final antal = int.tryParse(_antalAnlaegController.text) ?? 1;

    final alleAnlaeg = List.generate(antal, (_) => AnlaegsData(
      anlaegsNavn: '',
      ventMaerkatNr: '',
      valgtAnlaegstype: '',
      luftInd: 0,
      luftUd: 0,
      trykInd: 0,
      trykUd: 0,
      kwInd: 0,
      kwUd: 0,
      hzInd: 0,
      hzUd: 0,
      elpris: elPris,
      varmepris: varmePris,
      valgtTilstand: '',
      erBeregnetInd: false,
      erBeregnetUd: false,
      eksisterendeVarenummerInd: '',
      eksisterendeVarenummerUd: '',
      kammerBredde: 0,
      kammerHoede: 0,
      kammerLaengde: 0,
      aarsbesparelse: 0,
      tilbagebetalingstid: 0,
      omkostningFoer: 0,
      omkostningEfter: 0,
    ));

    final rapportId = DateTime.now().millisecondsSinceEpoch.toString();

    final projektInfo = GenerelProjektInfo(
      kundeNavn: _kundeNavnController.text,
      adresse: _adresseController.text,
      postnrBy: _postnrByController.text,
      att: _attController.text,
      teknikerNavn: _teknikerNavnController.text,
      telefon: _telefonController.text,
      email: _emailController.text,
      afdeling: _valgtAfdeling ?? '',
      antalAnlaeg: antal,
      elPris: elPris,
      varmePris: varmePris,
      driftTimerPrUge: driftTimerPrUge,
      ugerPerAar: int.tryParse(_ugerPerAarController.text) ?? 52,
      driftstype: _mapDriftperiode(_valgtDriftperiode),
      index: 0,
      alleAnlaeg: alleAnlaeg,
      varmegenvindingsType: gpi.VarmegenvindingType.krydsveksler,
      rapportDato: DateTime.now(),
      montorNavn: _teknikerNavnController.text,
      montorEmail: _emailController.text,
      rapportId: rapportId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaaledataSkarm(
          forslag: <VentilatorOekonomiSamlet>[],
          projektInfo: projektInfo,
          index: 0,
          alleAnlaeg: alleAnlaeg,
          driftstimer: _drifttimer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decimalInputFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
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
            TextField(
              controller: _teknikerNavnController,
              decoration: const InputDecoration(labelText: 'Teknikers navn'),
            ),
            TextField(
              controller: _telefonController,
              decoration: const InputDecoration(labelText: 'Telefonnr.'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),

            const SizedBox(height: 24),
            _sektionTitel('Afdeling'),
            DropdownButtonFormField<String>(
              key: _afdelingKey,
              initialValue: _valgtAfdeling,
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
              keyboardType: TextInputType.text,
              inputFormatters: intInputFormatter,
            ),

            const SizedBox(height: 24),
            _sektionTitel('Energipriser'),
            DropdownButtonFormField<String>(
              initialValue: _valgtKundeType,
              decoration: const InputDecoration(labelText: 'Kundetype'),
              items: _kundeTyper.map((type) =>
                  DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) {
                setState(() {
                  _valgtKundeType = val;
                  _opdaterPriser();
                });
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _valgtEnergiType,
              decoration: const InputDecoration(labelText: 'Varmeleverandør'),
              items: _energiTyper.map((type) =>
                  DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) {
                setState(() {
                  _valgtEnergiType = val;
                  _opdaterPriser();
                });
              },
            ),
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
                decoration: InputDecoration(labelText: entry.key),
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
              initialValue: _valgtDriftperiode,
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