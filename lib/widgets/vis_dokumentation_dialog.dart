import 'package:flutter/material.dart';

Future<bool> visDokumentationsDialog(BuildContext context, String valgtTilstand) async {
  final bool kanSpringeOver = valgtTilstand == '1' || valgtTilstand == '2';

  final String tekst = kanSpringeOver
      ? 'Hvis du har dokumentation, kan du vedhæfte billede og en kort beskrivelse. '
      'Ellers kan du springe over og gå direkte til resultatet.'
      : 'Billede og kort beskrivelse er påkrævet for denne tilstand. '
      'Vedhæft dokumentation for at fortsætte.';

  const Color _matchingGreen = Color(0xFF34E0A1);
  const Color _matchingBlue = Color(0xFF006390);

  return await Navigator.of(context).push<bool>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1), // Start over skærmen
            end: Offset.zero, // Slut på normal position
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _matchingGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        kanSpringeOver ? Icons.photo_camera : Icons.warning,
                        size: 40,
                        color: kanSpringeOver ? _matchingBlue : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Vil du vedhæfte billede og beskrivelse?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _matchingBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      tekst,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    if (kanSpringeOver)
                      Column(
                        children: [
                          // Vedhæft button (primær)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _matchingGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Vedhæft',
                                style: TextStyle(
                                  color: _matchingBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Spring over button (sekundær)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: _matchingGreen, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Spring over',
                                style: TextStyle(
                                  color: _matchingBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                    // Kun Vedhæft button (påkrævet)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _matchingGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Vedhæft',
                            style: TextStyle(
                              color: _matchingBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  ) ?? false;
}