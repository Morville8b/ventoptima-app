import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<bool> visDokumentationsDialog(BuildContext context) async {
  bool vilVedhaefte = false;
  XFile? valgtBillede;
  final beskrivelseController = TextEditingController();

  return await showDialog<bool>(
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
                      final pickedFile = await picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        setState(() {
                          valgtBillede = pickedFile;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Tag billede'),
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
                    Navigator.pop(context, false); // signalerer "spring over"
                  } else {
                    setState(() {
                      vilVedhaefte = false; // brugeren fortryder vedhæftning
                    });
                  }
                },
                child: Text(vilVedhaefte ? 'Fortryd' : 'Spring over'),
              ),
              TextButton(
                onPressed: () {
                  if (!vilVedhaefte) {
                    setState(() {
                      vilVedhaefte = true; // brugeren vælger at vedhæfte
                    });
                  } else {
                    Navigator.pop(context, true); // fortsæt
                  }
                },
                child: Text(vilVedhaefte ? 'Fortsæt' : 'Vedhæft'),
              ),
            ],
          );
        },
      );
    },
  ) ?? false; // fallback hvis dialogen lukkes uden handling
}