import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:ventoptima/generel_projekt_info.dart';
import 'package:ventoptima/anlaegs_data.dart';
import 'package:ventoptima/ventilator_samlet_beregning.dart';
import 'package:ventoptima/rapport/rapport_pdf_generator.dart';
import 'package:ventoptima/rapport/rapport_preview.dart';
import 'package:ventoptima/services/supabase_service.dart';
import '../widgets/bravida_loading_indicator.dart';
import 'dart:typed_data';
import 'package:ventoptima/rapport/vis_send_rapport_popup.dart';

class RapportForsideSkarm extends StatefulWidget {
  final GenerelProjektInfo projektInfo;
  final List<AnlaegsData> alleAnlaeg;
  final List<VentilatorOekonomiSamlet> alleForslag;
  final double elPris;
  final double varmePris;

  const RapportForsideSkarm({
    Key? key,
    required this.projektInfo,
    required this.alleAnlaeg,
    required this.alleForslag,
    required this.elPris,
    required this.varmePris,
  }) : super(key: key);

  @override
  State<RapportForsideSkarm> createState() => _RapportForsideSkarmState();
}

class _RapportForsideSkarmState extends State<RapportForsideSkarm> {
  bool _isGenerating = false;
  pw.Document? _pdfDocument;
  String? _errorMessage;
  final ValueNotifier<String> _loadingMessage =
  ValueNotifier<String>("Rapporten genereres...");

  @override
  void initState() {
    super.initState();
    _generatePdf(); // 🔹 Generer automatisk
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _loadingMessage.value = "Rapporten genereres...";
    });

    try {
      await SupabaseService.logRapportGenereret(
        widget.projektInfo.montorNavn ?? '',
        widget.projektInfo.afdeling,
        widget.projektInfo.montorEmail ?? '',
        widget.projektInfo.rapportId ?? '',
      );

      final pdf = await RapportPdfGenerator.generateRapport(
        projektInfo: widget.projektInfo,
        alleForslag: widget.alleForslag,
        elPris: widget.elPris,
        varmePris: widget.varmePris,
      );

      if (mounted) {
        setState(() {
          _pdfDocument = pdf;
          _isGenerating = false;
        });

        await SupabaseService.logAftryk(
          haendelseType: 'Rapport genereret færdig',
          afsenderNavn: widget.projektInfo.montorNavn ?? '',
          afdeling: widget.projektInfo.afdeling,
          afsenderEmail: widget.projektInfo.montorEmail ?? '',
          rapportId: widget.projektInfo.rapportId ?? '',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isGenerating = false;
        });

        await SupabaseService.logAftryk(
          haendelseType: 'Fejl ved rapportgenerering',
          afsenderNavn: widget.projektInfo.montorNavn ?? '',
          afdeling: widget.projektInfo.afdeling,
          afsenderEmail: widget.projektInfo.montorEmail ?? '',
          rapportId: widget.projektInfo.rapportId ?? '',
          status: 'Fejl: $e',
        );
      }
    }
  }

  Future<void> _visRapport() async {
    await SupabaseService.logAftryk(
      haendelseType: 'Rapport vist',
      afsenderNavn: widget.projektInfo.montorNavn ?? '',
      afdeling: widget.projektInfo.afdeling,
      afsenderEmail: widget.projektInfo.montorEmail ?? '',
      rapportId: widget.projektInfo.rapportId ?? '',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RapportPreview(
          projektInfo: widget.projektInfo,
          alleAnlaeg: widget.alleAnlaeg,
          alleForslag: widget.alleForslag,
          elPris: widget.elPris,
          varmePris: widget.varmePris,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF006390);
    const Color primaryGreen = Color(0xFF34E0A1);

    Widget content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/images/bravida_logo_rgb_pos.png',
                height: 40,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: double.infinity, height: 2, color: primaryGreen),
            const Spacer(),

            Text(
              _isGenerating
                  ? "Rapporten genereres..."
                  : _errorMessage != null
                  ? "Fejl ved generering"
                  : "Rapporten er klar!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 50),
            Image.asset('assets/images/lunger.png', height: 250, fit: BoxFit.contain),
            const Spacer(),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Fejl: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const Text(
              "Et sundt indeklima begynder med et grønt valg",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: primaryGreen,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 Kun “Vis” og “Send” vises — intet “Generer”
            if (_pdfDocument != null && !_isGenerating) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                icon: const Icon(Icons.visibility, color: Colors.white),
                label: const Text(
                  "Vis rapport",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                onPressed: _visRapport,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "Send rapport",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                onPressed: () async {
                  await visSendRapportPopup(
                    context,
                    widget.projektInfo,
                    await _pdfDocument!.save(),
                    Uint8List(0),
                  );
                },
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          content,
          if (_isGenerating)
            BravidaLoadingIndicator(messageNotifier: _loadingMessage),
        ],
      ),
    );
  }
}