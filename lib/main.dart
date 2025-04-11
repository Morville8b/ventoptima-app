import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ind_data.dart'; // Her antager vi MaaledataSkarm ligger

void main() {
  runApp(const VentOptimaApp());
}

class VentOptimaApp extends StatelessWidget {
  const VentOptimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VentOptima',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VelkomstSkarm(),
    );
  }
}

class VelkomstSkarm extends StatelessWidget {
  const VelkomstSkarm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Column(
        children: [
          const Spacer(flex: 2),
          Center(
            child: Image.asset(
              'assets/images/bravida_logo_rgb_pos.png',
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Velkommen til VentOptima!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(flex: 3),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForsideSkarm()),
              );
            },
            child: const Text('Start beregning'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ✅ Kun én version af ForsideSkarm
class ForsideSkarm extends StatefulWidget {
  const ForsideSkarm({super.key});

  @override
  State<ForsideSkarm> createState() => _ForsideSkarmState();
}

class _ForsideSkarmState extends State<ForsideSkarm> {
  final _formKey = GlobalKey<FormState>();

  String kundenavn = '';
  String adresse = '';
  String postnummerBy = '';
  String att = '';
  String anlaegNavn = '';
  String anlaegstype = 'Ventilationsanlaeg';
  String elpris = '';
  String varmepris = '';
  String maerkatnummer = '';
  String teknikerNavn = '';
  String telefonnummer = '';
  String email = '';
  String afdeling = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VentOptima - Forside'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Kundeoplysninger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Kundens navn'),
                onChanged: (value) => kundenavn = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Adresse'),
                onChanged: (value) => adresse = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Postnummer/By'),
                onChanged: (value) => postnummerBy = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Att. (Kontaktperson)'),
                onChanged: (value) => att = value,
              ),
              const SizedBox(height: 48),

              const Text('Anlægsoplysninger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Anlægsnavn (f.eks. VE-01)'),
                onChanged: (value) => anlaegNavn = value,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Anlægstype'),
                value: anlaegstype,
                items: const [
                  DropdownMenuItem(value: 'Ventilationsanlaeg', child: Text('Ventilationsanlæg')),
                  DropdownMenuItem(value: 'Indblaesningsanlaeg', child: Text('Indblæsningsanlæg')),
                  DropdownMenuItem(value: 'Udsugningsanlaeg', child: Text('Udsugningsanlæg')),
                ],
                onChanged: (value) => setState(() => anlaegstype = value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Vent mærkat nummer'),
                onChanged: (value) => maerkatnummer = value,
              ),
              const SizedBox(height: 48),

              const Text('Energipriser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Elpris (kr/kWh)'),
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onChanged: (value) => elpris = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Varmepris (kr/kWh)'),
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onChanged: (value) => varmepris = value,
              ),
              const SizedBox(height: 48),

              const Text('Rapport udført af', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teknikerens navn'),
                onChanged: (value) => teknikerNavn = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Telefonnummer'),
                keyboardType: TextInputType.phone,
                onChanged: (value) => telefonnummer = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Afdeling'),
                onChanged: (value) => afdeling = value,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MaaledataSkarm(),
                      ),
                    );
                  }
                },
                child: const Text('Næste'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}