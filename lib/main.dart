import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ventoptima/services/supabase_service.dart';
import 'package:ventoptima/services/app_sikkerhed.dart';
import 'package:ventoptima/screens/login_screen.dart';
import 'package:ventoptima/generel_info_skarm.dart';
import 'package:ventoptima/services/version_checker.dart';
import 'package:ventoptima/widgets/opdater_app_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ventoptima/ventoptima_projekt_serializer.dart';
import 'package:ventoptima/maaledata_skarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path)
        .listSync()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    for (final file in files) {
      await File(file.path).delete();
    }
    debugPrint('🧹 Gamle screenshots slettet ved app-start.');
  } catch (e) {
    debugPrint('⚠️ Kunne ikke slette screenshots ved opstart: $e');
  }

  await initializeDateFormatting('da_DK', null);

  await Supabase.initialize(
    url: 'https://akauavrbwmrgkuroelsr.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFrYXVhdnJid21yZ2t1cm9lbHNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3NDg5MDIsImV4cCI6MjA3NTMyNDkwMn0.HxjvBQQUQDVJg13RDfNDXaPoFxjKVk5twUpbV9Nv6Gk',
  );

  runApp(const VentOptimaApp());
}

class VentOptimaApp extends StatelessWidget {
  const VentOptimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color matchingGreen = Color(0xFF34E0A1);
    const Color matchingBlue = Color(0xFF006390);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: matchingBlue,
        colorScheme: const ColorScheme.light(
          primary: matchingBlue,
          secondary: matchingGreen,
          surface: Colors.white,
          background: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: matchingGreen, width: 2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: matchingBlue),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: matchingBlue),
          ),
          labelStyle: TextStyle(color: matchingBlue),
          floatingLabelStyle: TextStyle(color: matchingGreen),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: matchingGreen,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 3,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
          ),
        ),
      ),
      home: const StartScreen(),
      routes: {
        '/home': (context) => const VelkomstSkarm(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class UdloebetScreen extends StatelessWidget {
  const UdloebetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 100, color: Colors.red),
                const SizedBox(height: 32),
                const Text(
                  'App udløbet',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006390),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Denne version af VentOptima er udløbet.\n\nKontakt Bravida IT for at få en opdateret version af appen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 40),
                Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (AppSikkerhed.erUdloebet()) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UdloebetScreen()),
        );
      }
      return;
    }

    final erLoggetInd = await AppSikkerhed.erLoggetInd();

    if (mounted) {
      if (erLoggetInd) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VelkomstSkarm()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34E0A1)),
            ),
            SizedBox(height: 20),
            Text(
              'Starter VentOptima...',
              style: TextStyle(fontSize: 16, color: Color(0xFF006390)),
            ),
          ],
        ),
      ),
    );
  }
}

class VelkomstSkarm extends StatefulWidget {
  const VelkomstSkarm({super.key});

  @override
  State<VelkomstSkarm> createState() => _VelkomstSkarmState();
}

class _VelkomstSkarmState extends State<VelkomstSkarm> {
  String _brugerNavn = 'Montør';

  @override
  void initState() {
    super.initState();
    _hentBrugerNavn();
    _logAppAabnet();
    _tjekVersion();
  }

  Future<void> _tjekVersion() async {
    final skalTjekke = await VersionChecker.skalTjekkeVersion();
    if (!skalTjekke) return;

    final nyVersion = await VersionChecker.erNyVersionTilgaengelig();
    if (nyVersion && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const OpdaterAppDialog(),
      );
    }
    await VersionChecker.opdaterSidsteTjek();
  }

  Future<void> _hentBrugerNavn() async {
    final bruger = await AppSikkerhed.hentBrugerInfo();
    setState(() {
      _brugerNavn = bruger['navn'] ?? 'Montør';
    });
  }

  Future<void> _logAppAabnet() async {
    final bruger = await AppSikkerhed.hentBrugerInfo();
    await SupabaseService.logAppAabnet(
      bruger['navn'] ?? 'Ukendt montør',
      'Ukendt afdeling',
      bruger['email'] ?? 'ukendt@bravida.dk',
    );
  }

  Future<void> _aabneEksisterendeProjekt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ventoptima'],
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final projektInfo = await indlaesVentoptimaFil(result.files.single.path!);

      final navne = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
      final Map<String, TextEditingController> driftstimerControllers = {};
      for (int i = 0; i < projektInfo.driftTimerPrUge.length; i++) {
        driftstimerControllers[navne[i]] = TextEditingController(
          text: projektInfo.driftTimerPrUge[i].toStringAsFixed(0),
        );
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaaledataSkarm(
            projektInfo: projektInfo,
            index: 0,
            alleAnlaeg: projektInfo.alleAnlaeg,
            driftstimer: driftstimerControllers,
            forslag: [],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text('Kunne ikke åbne projektfilen: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color matchingGreen = Color(0xFF34E0A1);
    const Color matchingBlue = Color(0xFF006390);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 100),
                  const SizedBox(height: 30),
                  Text(
                    'Velkommen $_brugerNavn',
                    style: const TextStyle(
                      fontSize: 18,
                      color: matchingBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'VentOptima',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: matchingGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                      shadowColor: matchingBlue.withOpacity(0.4),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GenerelInfoSkarm()),
                      );
                    },
                    child: const Text('Start nyt projekt', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open, color: matchingBlue),
                    label: const Text(
                      'Åbn eksisterende projekt',
                      style: TextStyle(fontSize: 16, color: matchingBlue),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                      side: const BorderSide(color: matchingGreen, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _aabneEksisterendeProjekt,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Opacity(
                opacity: 0.25,
                child: Image.asset('assets/images/morville_logo.png', width: 80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
