import 'package:flutter/material.dart';
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
final _elPrisController = TextEditingController();
final _varmePrisController = TextEditingController();
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

final projektInfo = GenerelProjektInfo(
kundeNavn: _kundeNavnController.text,
adresse: _adresseController.text,
postnrBy: _postnrByController.text,
att: _attController.text,
teknikerNavn: _teknikerNavnController.text,
telefon: _telefonController.text,
email: _emailController.text,
antalAnlaeg: int.tryParse(_antalAnlaegController.text) ?? 1,
elPris: double.tryParse(_elPrisController.text.replaceAll(',', '.')) ?? 0,
varmePris: double.tryParse(_varmePrisController.text.replaceAll(',', '.')) ?? 0,
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
return Scaffold(
appBar: AppBar(title: const Text('Generel Projektinformation')),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Kundens oplysninger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
TextField(controller: _kundeNavnController, decoration: const InputDecoration(labelText: 'Kundens navn')),
TextField(controller: _adresseController, decoration: const InputDecoration(labelText: 'Adresse')),
TextField(controller: _postnrByController, decoration: const InputDecoration(labelText: 'Postnr./By')),
TextField(controller: _attController, decoration: const InputDecoration(labelText: 'Att.')),

const SizedBox(height: 24),
const Text('Rapporten er udført af', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
TextField(controller: _teknikerNavnController, decoration: const InputDecoration(labelText: 'Teknikers navn')),
TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefonnr.')),
TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail')),

const SizedBox(height: 24),
const Text('Antal anlæg i alt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
TextField(
controller: _antalAnlaegController,
decoration: const InputDecoration(labelText: 'Antal anlæg'),
keyboardType: TextInputType.number,
),

const SizedBox(height: 24),
const Text('Energipriser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
TextField(
controller: _elPrisController,
decoration: const InputDecoration(labelText: 'El-pris (kr./kWh)'),
keyboardType: TextInputType.number,
),
TextField(
controller: _varmePrisController,
decoration: const InputDecoration(labelText: 'Varmepris (kr./kWh)'),
keyboardType: TextInputType.number,
),

const SizedBox(height: 24),
const Text('Drifttimer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
..._drifttimer.entries.map((entry) {
return TextField(
controller: entry.value,
decoration: InputDecoration(labelText: '${entry.key}'),
keyboardType: TextInputType.number,
);
}),

TextField(
controller: _ugerPerAarController,
decoration: const InputDecoration(labelText: 'Antal uger pr. år'),
keyboardType: TextInputType.number,
),

const SizedBox(height: 24),
const Text('Tidsrum for drift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
onPressed: _gaVidere,
child: const Text('Næste'),
),
),
],
),
),
);
}
}