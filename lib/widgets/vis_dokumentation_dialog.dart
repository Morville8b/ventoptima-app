import 'package:flutter/material.dart';

Future<bool> visDokumentationsDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white, // resten af dialogen er hvid
      titlePadding: EdgeInsets.zero, // vi laver selv toppen
      title: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF34E0A1), // grøn topbjælke
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Text(
          'Vil du vedhæfte billede og beskrivelse?',
          style: TextStyle(
            color: Color(0xFF006390), // blå tekst
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Text(
        'Hvis du har dokumentation, kan du vedhæfte billede og en kort beskrivelse. '
            'Ellers kan du springe over og gå direkte til resultatet.',
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false), // Spring over
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF34E0A1),
            foregroundColor: Color(0xFF006390),
            shape: StadiumBorder(),
          ),
          child: Text('Spring over'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // Vedhæft
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF34E0A1),
            foregroundColor: Color(0xFF006390),
            shape: StadiumBorder(),
          ),
          child: Text('Vedhæft'),
        ),
      ],
    ),
  ) ?? false;
}