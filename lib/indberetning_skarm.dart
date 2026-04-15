import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'generel_projekt_info.dart';

class IndberetningSkarm extends StatefulWidget {
  final GenerelProjektInfo projektInfo;
  final VoidCallback onGemOgNaeste;

  const IndberetningSkarm({
    super.key,
    required this.projektInfo,
    required this.onGemOgNaeste,
  });

  @override
  State<IndberetningSkarm> createState() => _IndberetningSkarmState();
}

class _IndberetningSkarmState extends State<IndberetningSkarm> {
  final List<File> _billeder = [];
  final TextEditingController _beskrivelseController = TextEditingController();

  Future<void> _tagBillede() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _billeder.add(File(pickedFile.path));
      });

      final vilTageFlere = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tilføj flere billeder?'),
          content: const Text('Vil du tage endnu et billede?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nej'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ja'),
            ),
          ],
        ),
      );

      if (vilTageFlere == true) {
        await _tagBillede();
      }
    }
  }

  void _gemIndberetning() {
    final beskrivelse = _beskrivelseController.text;
    // TODO: Gem billeder og beskrivelse til database eller send til backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Indberetning gemt')),
    );
    widget.onGemOgNaeste();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indberetning')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vil du tilføje dokumentation og noter, hvis du har observeret noget unormalt ved anlægget?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _tagBillede,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tag billede'),
            ),
            const SizedBox(height: 16),
            if (_billeder.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _billeder.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.file(_billeder[index]),
                  ),
                ),
              ),
            TextField(
              controller: _beskrivelseController,
              decoration: const InputDecoration(labelText: 'Beskrivelse af observationen'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hvis der er yderligere informationer, du vil dele, kan du skrive dem herunder.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _gemIndberetning,
              child: const Text('Gem og fortsæt'),
            )
          ],
        ),
      ),
    );
  }
}
