import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resultat_skarm.dart' show ResultatSkarm;
class MaaledataSkarm extends StatefulWidget {
  const MaaledataSkarm({super.key});

  @override
  State<MaaledataSkarm> createState() => _MaaledataSkarmState();
}

class _MaaledataSkarmState extends State<MaaledataSkarm> {
  final decimalFormatter = FilteringTextInputFormatter.allow(RegExp(r'^[0-9,.]*'));

  final filterTrykIndController = TextEditingController();
  final antalFilterIndController = TextEditingController();
  final trykFoerIndController = TextEditingController();
  final trykEfterIndController = TextEditingController();
  final luftmaengdeIndController = TextEditingController();
  final hzIndController = TextEditingController();
  final kwIndController = TextEditingController();

  final filterTrykUdController = TextEditingController();
  final antalFilterUdController = TextEditingController();
  final trykFoerUdController = TextEditingController();
  final trykEfterUdController = TextEditingController();
  final luftmaengdeUdController = TextEditingController();
  final hzUdController = TextEditingController();
  final kwUdController = TextEditingController();

  final mandagController = TextEditingController();
  final tirsdagController = TextEditingController();
  final onsdagController = TextEditingController();
  final torsdagController = TextEditingController();
  final fredagController = TextEditingController();
  final loerdagController = TextEditingController();
  final soendagController = TextEditingController();
  final ugerController = TextEditingController(text: '52');

  final friskluftController = TextEditingController();
  final indblEfterGenvindingController = TextEditingController();
  final indblEfterVarmefladeController = TextEditingController();
  final udsugningTempController = TextEditingController();
  final afkastTempController = TextEditingController();

  String varmegenvindingstype = 'Krydsveksler';
  String driftperiode = 'Dagtimer';
  String beregnUdFra = 'indblæsning';
  bool erFriskluftOver10 = false;

  @override
  void dispose() {
    for (var controller in [
      filterTrykIndController,
      antalFilterIndController,
      trykFoerIndController,
      trykEfterIndController,
      luftmaengdeIndController,
      hzIndController,
      kwIndController,
      filterTrykUdController,
      antalFilterUdController,
      trykFoerUdController,
      trykEfterUdController,
      luftmaengdeUdController,
      hzUdController,
      kwUdController,
      mandagController,
      tirsdagController,
      onsdagController,
      torsdagController,
      fredagController,
      loerdagController,
      soendagController,
      ugerController,
      friskluftController,
      indblEfterGenvindingController,
      indblEfterVarmefladeController,
      udsugningTempController,
      afkastTempController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Måledata')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 24),


            const SizedBox(height: 16),

            const Text('Indblæsningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(controller: filterTrykIndController, decoration: const InputDecoration(labelText: 'Tryk før filterudskiftning (Pa)')),
            TextFormField(controller: antalFilterIndController, decoration: const InputDecoration(labelText: 'Antal filtre')),
            TextFormField(controller: trykFoerIndController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
            TextFormField(controller: trykEfterIndController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
            TextFormField(controller: luftmaengdeIndController, decoration: const InputDecoration(labelText: 'Luftmængde (m³/h)')),
            TextFormField(controller: hzIndController, decoration: const InputDecoration(labelText: 'Hz')),
            TextFormField(controller: kwIndController, decoration: const InputDecoration(labelText: 'kW')),

            const SizedBox(height: 24),

            const Text('Udsugningsventilator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(controller: filterTrykUdController, decoration: const InputDecoration(labelText: 'Tryk før filterudskiftning (Pa)')),
            TextFormField(controller: antalFilterUdController, decoration: const InputDecoration(labelText: 'Antal filtre')),
            TextFormField(controller: trykFoerUdController, decoration: const InputDecoration(labelText: 'Tryk før ventilator (Pa)')),
            TextFormField(controller: trykEfterUdController, decoration: const InputDecoration(labelText: 'Tryk efter ventilator (Pa)')),
            TextFormField(controller: luftmaengdeUdController, decoration: const InputDecoration(labelText: 'Luftmængde (m³/h)')),
            TextFormField(controller: hzUdController, decoration: const InputDecoration(labelText: 'Hz')),
            TextFormField(controller: kwUdController, decoration: const InputDecoration(labelText: 'kW')),

            const SizedBox(height: 24),

            const Text('Driftstimer pr. dag (mandag–søndag)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(controller: mandagController, decoration: const InputDecoration(labelText: 'Mandag (timer)')),
            TextFormField(controller: tirsdagController, decoration: const InputDecoration(labelText: 'Tirsdag (timer)')),
            TextFormField(controller: onsdagController, decoration: const InputDecoration(labelText: 'Onsdag (timer)')),
            TextFormField(controller: torsdagController, decoration: const InputDecoration(labelText: 'Torsdag (timer)')),
            TextFormField(controller: fredagController, decoration: const InputDecoration(labelText: 'Fredag (timer)')),
            TextFormField(controller: loerdagController, decoration: const InputDecoration(labelText: 'Lørdag (timer)')),
            TextFormField(controller: soendagController, decoration: const InputDecoration(labelText: 'Søndag (timer)')),
            TextFormField(controller: ugerController, decoration: const InputDecoration(labelText: 'Antal uger pr. år')),

            const SizedBox(height: 24),

            const Text('Varmegenvinding og temperaturer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('Er udetemperaturen over 10 °C?'),
              value: erFriskluftOver10,
              onChanged: (val) => setState(() => erFriskluftOver10 = val),
            ),

            if (!erFriskluftOver10) ...[
              DropdownButtonFormField<String>(
                value: driftperiode,
                decoration: const InputDecoration(labelText: 'Anlæggets driftperiode'),
                items: const [
                  DropdownMenuItem(value: 'Dagtimer', child: Text('Dagtimer')),
                  DropdownMenuItem(value: 'Nattetimer', child: Text('Nattetimer')),
                  DropdownMenuItem(value: 'Døgn', child: Text('Døgndrift')),
                ],
                onChanged: (val) => setState(() => driftperiode = val!),
              ),

              DropdownButtonFormField<String>(
                value: varmegenvindingstype,
                decoration: const InputDecoration(labelText: 'Varmegenvindingstype'),
                items: const [
                  DropdownMenuItem(value: 'Ingen', child: Text('Ingen')),
                  DropdownMenuItem(value: 'Krydsveksler', child: Text('Krydsveksler')),
                  DropdownMenuItem(value: 'Dobbel krydsveksler', child: Text('Dobbel krydsveksler')),
                  DropdownMenuItem(value: 'Roterendeveksler', child: Text('Roterendeveksler')),
                  DropdownMenuItem(value: 'Modstrømveksler', child: Text('Modstrømveksler')),
                  DropdownMenuItem(value: 'Væskekobletveksler', child: Text('Væskekobletveksler')),
                  DropdownMenuItem(value: 'Blandekammer', child: Text('Blandekammer')),
                ],
                onChanged: (val) => setState(() => varmegenvindingstype = val!),
              ),

            ],


            if (!erFriskluftOver10) ...[
              DropdownButtonFormField<String>(
                value: beregnUdFra,
                decoration: const InputDecoration(labelText: 'Beregn varmegenvinding ud fra'),
                items: const [
                  DropdownMenuItem(value: 'indblæsning', child: Text('Indblæsningstemperatur')),
                  DropdownMenuItem(value: 'afkast', child: Text('Afkasttemperatur')),
                ],
                onChanged: (val) => setState(() => beregnUdFra = val!),
              ),
              TextFormField(controller: friskluftController, decoration: const InputDecoration(labelText: 'Frisklufttemperatur (°C)')),
              TextFormField(controller: indblEfterGenvindingController, decoration: const InputDecoration(labelText: 'Indblæsning efter varmegenvinding (°C)')),
              TextFormField(controller: indblEfterVarmefladeController, decoration: const InputDecoration(labelText: 'Indblæsning efter varmeflade (°C)')),
              TextFormField(controller: udsugningTempController, decoration: const InputDecoration(labelText: 'Udsugningstemperatur (°C)')),
              TextFormField(controller: afkastTempController, decoration: const InputDecoration(labelText: 'Afkasttemperatur (°C)')),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                final trykInd = (double.tryParse(trykEfterIndController.text.replaceAll(',', '.')) ?? 0) -
                    (double.tryParse(trykFoerIndController.text.replaceAll(',', '.')) ?? 0);
                final trykUd = (double.tryParse(trykEfterUdController.text.replaceAll(',', '.')) ?? 0) -
                    (double.tryParse(trykFoerUdController.text.replaceAll(',', '.')) ?? 0);
                final driftTimer = [
                  mandagController,
                  tirsdagController,
                  onsdagController,
                  torsdagController,
                  fredagController,
                  loerdagController,
                  soendagController
                ].map((c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0).reduce((a, b) => a + b) *
                    (double.tryParse(ugerController.text.replaceAll(',', '.')) ?? 52);

                final friskluftTemp = double.tryParse(friskluftController.text.replaceAll(',', '.')) ?? 0;
                final indblEfterGenvinding = double.tryParse(indblEfterGenvindingController.text.replaceAll(',', '.')) ?? 0;
                final indblEfterVarmeflade = double.tryParse(indblEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0;
                final udsugningTemp = double.tryParse(udsugningTempController.text.replaceAll(',', '.')) ?? 0;
                final afkastTemp = double.tryParse(afkastTempController.text.replaceAll(',', '.')) ?? 0;

                final renoveringsVurdering = friskluftTemp >= 10
                    ? 'Ikke relevant pga. udetemperatur'
                    : (beregnUdFra == 'afkast'
                    ? ((udsugningTemp - afkastTemp) / (udsugningTemp - friskluftTemp) * 100) < 60 ? 'Ja' : 'Nej'
                    : ((indblEfterGenvinding - friskluftTemp) / (udsugningTemp - friskluftTemp) * 100) < 60 ? 'Ja' : 'Nej');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultatSkarm(
                      kwInd: double.tryParse(kwIndController.text.replaceAll(',', '.')) ?? 0,
                      luftmaengdeInd: double.tryParse(luftmaengdeIndController.text.replaceAll(',', '.')) ?? 0,
                      trykDifferensInd: trykInd.abs(),
                      driftTimer: driftTimer,
                      kwUd: double.tryParse(kwUdController.text.replaceAll(',', '.')) ?? 0,
                      luftmaengdeUd: double.tryParse(luftmaengdeUdController.text.replaceAll(',', '.')) ?? 0,
                      trykDifferensUd: trykUd.abs(),
                      friskluftTemp: friskluftTemp,
                      indblTempEfterGenvinding: indblEfterGenvinding,
                      indblTempEfterVarmeflade: indblEfterVarmeflade,
                      afkastTemp: afkastTemp,
                      udsugningTemp: udsugningTemp,
                      varmegenvindingstype: varmegenvindingstype,
                      driftType: driftperiode,
                      beregnUdFra: beregnUdFra,
                      renoveringsVurdering: renoveringsVurdering,
                    ),
                  ),
                );
              },
              child: const Text('Beregn'),
            ),
          ],
        ),
      ),
    );
  }
}