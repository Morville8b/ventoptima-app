import 'package:flutter/material.dart';

class AnlaegsdataWidget extends StatelessWidget {
  final TextEditingController anlaegsNavnController;
  final TextEditingController ventMaerkatNrController;
  final String valgtAnlaegstype;
  final void Function(String?) onAnlaegstypeChanged;

  const AnlaegsdataWidget({
    super.key,
    required this.anlaegsNavnController,
    required this.ventMaerkatNrController,
    required this.valgtAnlaegstype,
    required this.onAnlaegstypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Anlægs nr./navn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(
          controller: anlaegsNavnController,
          decoration: const InputDecoration(labelText: 'Anlægs nr./navn'),
        ),
        const SizedBox(height: 16),
        const Text('Vent mærkat nr.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(
          controller: ventMaerkatNrController,
          decoration: const InputDecoration(labelText: 'Vent mærkat nr.'),
        ),
        const SizedBox(height: 24),
        const Text('Anlægstype', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: valgtAnlaegstype,
          items: const [
            DropdownMenuItem(value: 'Ventilationsanlæg', child: Text('Ventilationsanlæg')),
            DropdownMenuItem(value: 'Indblæsningsanlæg', child: Text('Indblæsningsanlæg')),
            DropdownMenuItem(value: 'Udsugningsanlæg', child: Text('Udsugningsanlæg')),
          ],
          onChanged: onAnlaegstypeChanged,
          decoration: const InputDecoration(labelText: 'Vælg anlægstype'),
        ),
      ],
    );
  }
}