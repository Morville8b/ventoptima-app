import 'package:flutter/material.dart';

class SamletResultatSkarm extends StatelessWidget {
  const SamletResultatSkarm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samlet resultat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nøgletal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildNoegletalKort(),
            const SizedBox(height: 24),
            const Text('Sammenligning af ventilatorer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildVentilatorSammenligningTabel(),
            const SizedBox(height: 24),
            const Text('Varmegenvinding', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildVarmegenvindingKort(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Generer PDF eller gå videre
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generér rapport som PDF'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoegletalKort() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Anlægsnavn: VE-01'),
            Text('Driftsmønster: Døgn'),
            Text('Luftmængde: 8.000 m³/h'),
            Text('Driftstimer: 6.500 timer/år'),
            Text('Anlæggets tilstand: Slidt')
          ],
        ),
      ),
    );
  }

  Widget _buildVentilatorSammenligningTabel() {
    final headers = ['Parameter', 'Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
    final rows = [
      ['Effekt før (kW)', '1.20', '1.20', '1.20'],
      ['Effekt efter (kW)', '0.75', '0.80', '0.78'],
      ['Virkningsgrad (%)', '55', '53', '54'],
      ['SEL-værdi', '1.2', '1.3', '1.25'],
      ['Elforbrug før (kWh)', '3.200', '3.200', '3.200'],
      ['Elforbrug efter (kWh)', '2.100', '2.200', '2.180'],
      ['Årlig besparelse (kr)', '4.200', '4.000', '4.100'],
      ['Tilbagebetalingstid (år)', '2.1', '2.3', '2.2']
    ];

    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth()
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.grey),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.all(6),
            child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)),
          )).toList(),
        ),
        ...rows.map((r) => TableRow(
          children: r.map((c) => Padding(
            padding: const EdgeInsets.all(6),
            child: Text(c),
          )).toList(),
        ))
      ],
    );
  }

  Widget _buildVarmegenvindingKort() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Type: Modstrømsveksler'),
            Text('Virkningsgrad før: 68 %'),
            Text('Virkningsgrad efter: 80 %'),
            Text('Luftmængde ind/ud: 8.000 / 7.500 m³/h'),
            Text('Varmeforbrug før: 24.000 kWh'),
            Text('Varmeforbrug efter: 16.500 kWh')
          ],
        ),
      ),
    );
  }
}