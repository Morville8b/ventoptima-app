import 'package:flutter/material.dart';

Future<bool> visVirkningsgradAdvarsel(
    BuildContext context, {
      required bool indblaesningHoj,
      required bool udsugningHoj,
    }) async {
  const Color matchingGreen = Color(0xFF34E0A1);
  const Color matchingBlue = Color(0xFF006390);

  String besked = 'Virkningsgraden for ';
  if (indblaesningHoj && udsugningHoj) {
    besked += 'både indblæsnings- og udsugningsventilatoren';
  } else if (indblaesningHoj) {
    besked += 'indblæsningsventilatoren';
  } else if (udsugningHoj) {
    besked += 'udsugningsventilatoren';
  }

  besked +=
  ' er over 70 %, hvilket typisk tyder på for høje eller unøjagtige målinger.\n\n'
      'En typisk fejlkilde er, at måleinstrumentet er indstillet til 1-faset måling i stedet for 3-faset – '
      'vær derfor særligt opmærksom på, at kW-værdien er målt korrekt.\n\n'
      'Gennemgå venligst måledataene. Hvis du er sikker på, at dine målinger er korrekte, kan du trykke videre.';

  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: matchingGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Text(
          '⚠️ Unormalt høj virkningsgrad på ventilatoren',
          style: TextStyle(
            color: matchingBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(besked, style: const TextStyle(color: Colors.black87)),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: matchingGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Gå tilbage og kontroller',
                style: TextStyle(color: matchingBlue),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: matchingGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Målingerne er korrekte',
                style: TextStyle(color: matchingBlue),
              ),
            ),
          ],
        ),
      ],
    ),
  ) ?? false;
}