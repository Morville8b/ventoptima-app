import 'package:flutter/material.dart';

const Color _matchingGreen = Color(0xFF34E0A1);
const Color _matchingBlue = Color(0xFF006390);

Future<String?> visTilstandsvurderingPopup(BuildContext context) async {
  String valgtTilstand = '1';

  return await Navigator.of(context).push<String>(
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
              child: StatefulBuilder(
                builder: (context, setState) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 450),
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
                        child: const Icon(
                          Icons.assignment_turned_in,
                          size: 40,
                          color: _matchingBlue,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Vurdering af anlæggets tilstand',
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
                        'Vælg den tilstand der bedst beskriver anlægget',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.info_outline,
                            color: getTilstandsfarve(valgtTilstand),
                          ),
                        ),
                        initialValue: valgtTilstand,
                        items: const [
                          DropdownMenuItem(
                            value: '1',
                            child: Text(
                              'Anlægget er i god stand',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text(
                              'Mindre slid registreret',
                              style: TextStyle(color: Colors.lightGreen),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '3',
                            child: Text(
                              'Restlevetid 1–3 år',
                              style: TextStyle(color: Colors.orangeAccent),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '4',
                            child: Text(
                              'Udskiftning inden for 1 år',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '5',
                            child: Text(
                              'Vedligeholdelse nødvendig',
                              style: TextStyle(color: Colors.deepOrange),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '6',
                            child: Text(
                              'Ude af drift – akut reparation nødvendig',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        selectedItemBuilder: (context) {
                          return [
                            'Anlægget er i god stand',
                            'Mindre slid registreret',
                            'Restlevetid 1–3 år',
                            'Udskiftning inden for 1 år',
                            'Vedligeholdelse nødvendig',
                            'Ude af drift – akut reparation nødvendig',
                          ].map((text) {
                            return Text(
                              text,
                              style: const TextStyle(color: Colors.black),
                            );
                          }).toList();
                        },
                        onChanged: (val) => setState(() => valgtTilstand = val ?? '1'),
                      ),
                      const SizedBox(height: 24),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, valgtTilstand),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _matchingGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Bekræft',
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
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}

Color getTilstandsfarve(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return Colors.green;
    case '2':
      return Colors.lightGreen;
    case '3':
      return Colors.orangeAccent;
    case '4':
      return Colors.orange;
    case '5':
      return Colors.deepOrange;
    case '6':
      return Colors.red;
    default:
      return Colors.black87;
  }
}

String getTilstandsbeskrivelse(String tilstand) {
  switch (tilstand) {
    case '1':
      return 'Anlægget er i god stand';
    case '2':
      return 'Mindre slid registreret';
    case '3':
      return 'Restlevetid 1–3 år';
    case '4':
      return 'Udskiftning inden for 1 år';
    case '5':
      return 'Vedligeholdelse nødvendig';
    case '6':
      return 'Ude af drift – akut reparation nødvendig';
    default:
      return 'Ukendt tilstand';
  }
}

