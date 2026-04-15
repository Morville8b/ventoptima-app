import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> visDokumentationsDialog(BuildContext context) async {
  bool vilVedhaefte = false;
  XFile? valgtBillede;
  final beskrivelseController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Vil du vedhæfte billede og beskrivelse?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hvis du har dokumentation, kan du vedhæfte billede og en kort beskrivelse. '
                      'Ellers kan du springe over og gå direkte til resultatet.',
                ),
                const SizedBox(height: 16),
                if (vilVedhaefte) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          valgtBillede = pickedFile;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Vælg billede'),
                  ),
                  if (valgtBillede != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Billede valgt: ${valgtBillede!.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: beskrivelseController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Beskrivelse',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!vilVedhaefte) {
                    Navigator.pop(context); // Spring over
                  } else {
                    setState(() {
                      vilVedhaefte = false;
                    });
                  }
                },
                child: Text(vilVedhaefte ? 'Fortryd' : 'Spring over'),
              ),
              TextButton(
                onPressed: () {
                  if (!vilVedhaefte) {
                    setState(() {
                      vilVedhaefte = true;
                    });
                  } else {
                    Navigator.pop(context); // Fortsæt
                  }
                },
                child: Text(vilVedhaefte ? 'Fortsæt' : 'Vedhæft'),
              ),
            ],
          );
        },
      );
    },
  );
}
