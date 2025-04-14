import 'package:flutter/material.dart';
import 'generel_info_skarm.dart'; // <-- opdateret

void main() {
  runApp(const VentOptimaApp());
}

class VentOptimaApp extends StatelessWidget {
  const VentOptimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VentOptima',
      debugShowCheckedModeBanner: false,
      home: const VelkomstSkarm(),
    );
  }
}

class VelkomstSkarm extends StatelessWidget {
  const VelkomstSkarm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GenerelInfoSkarm(), // <-- opdateret
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}