import 'package:flutter/material.dart';
import 'generel_info_skarm.dart'; // Sørg for at denne fil findes

void main() {
  runApp(const VentOptimaApp());
}

class VentOptimaApp extends StatelessWidget {
  const VentOptimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const VelkomstSkarm(),
    );
  }
}

class VelkomstSkarm extends StatelessWidget {
  const VelkomstSkarm({super.key});

  @override
  Widget build(BuildContext context) {
    // Grøn og blå farver
    final Color _matchingGreen = Color(0xFF34E0A1); // Farven HEX #34E0A1
    final Color _matchingBlue = Color(0xFF006390); // Farven HEX #006390

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Indhold centreret
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 100),
                const SizedBox(height: 40),
                const Text(
                  'Velkommen til VentOptima',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _matchingGreen, // Grøn farve til knapbaggrund
                    foregroundColor: _matchingBlue, // Blå farve til tekst
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GenerelInfoSkarm(),
                      ),
                    );
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),

          // Morville-logo som vandmærke med lavere opacitet
          Positioned(
            bottom: 16,
            right: 16,
            child: Opacity(
              opacity: 0.1,  // Nedtonet opacitet for et mere subtilt vandmærke
              child: Image.asset(
                'assets/images/morville_logo.png',
                width: 120,
              ),
            ),
          ),
        ],
      ),
    );
  }
}