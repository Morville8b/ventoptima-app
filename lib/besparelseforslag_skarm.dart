import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ventilator_samlet_beregning.dart';
import 'generel_projekt_info.dart';
import 'beregning_varmeforbrug.dart';
import 'anlaegs_data.dart';
import 'dart:io';
import 'filter_resultat.dart';


String formatDK(num value, {int decimals = 0}) {
  if (value.isNaN || !value.isFinite) {
    value = 0;
  }
  final f = NumberFormat.decimalPattern('da_DK')
    ..minimumFractionDigits = decimals
    ..maximumFractionDigits = decimals;
  return f.format(value);
}
/// Tjek om et ventilatorforslag er gyldigt (har fundet en løsning)
bool erGyldigtVentilatorForslag(VentilatorOekonomiSamlet forslag) {
  final eco = forslag.oekonomi as OekonomiResultat;

  // Simpel check: Hvis nyt årligt elforbrug er 0, er der ingen løsning fundet
  final double nytElforbrugInd = forslag.indNormal.aarsforbrugKWh;
  final double nytElforbrugUd = forslag.udNormal.aarsforbrugKWh;
  final double samletNytElforbrug = nytElforbrugInd + nytElforbrugUd;

  // Hvis samlet nyt elforbrug er 0, er der ingen løsning
  if (samletNytElforbrug <= 0) {
    return false;
  }

  // Ekstra check: Hvis besparelse er 0 eller negativ, er det heller ikke gyldigt
  if (eco.aarsbesparelse <= 0) {
    return false;
  }

  return true;
}
class BesparelseForslagSkarm extends StatelessWidget {
  final List<VentilatorOekonomiSamlet> alleForslag;
  final double elPris;
  final double varmePris;
  final GenerelProjektInfo projektInfo;
  final String anlaegsNavn;
  final VarmeforbrugResultat? varmeforbrugResultat;
  final double? friskluftTemp;

  // 🔹 Tilføjet så vi kan vise før-situationen
  final String anlaegsType; // kun én gang!
  final double elforbrugInd;
  final double virkningsgradInd;
  final double selInd;
  final double omkostningInd;

  final double elforbrugUd;
  final double virkningsgradUd;
  final double selUd;
  final double omkostningUd;

  final double samletFoerKWh;
  final double samletFoerKr;

  final String valgtTilstand;
  final FilterResultat? filterResultat;
  final VoidCallback? onVisFilter;



  const BesparelseForslagSkarm({
    super.key,
    required this.alleForslag,
    required this.elPris,
    required this.varmePris,
    required this.projektInfo,
    required this.anlaegsNavn,
    this.varmeforbrugResultat,
    this.friskluftTemp,
    this.onVisFilter,

    // 🔹 Vælg en af de to løsninger:

    // 1) Hvis anlaegsType altid findes:
    required this.anlaegsType,

    // 2) Hvis den må være tom, så brug i stedet:
    // this.anlaegsType = '',

    this.elforbrugInd = 0,
    this.virkningsgradInd = 0,
    this.selInd = 0,
    this.omkostningInd = 0,
    this.elforbrugUd = 0,
    this.virkningsgradUd = 0,
    this.selUd = 0,
    this.omkostningUd = 0,
    this.samletFoerKWh = 0,
    this.samletFoerKr = 0,
    required this.valgtTilstand,
    this.filterResultat,
  });

  // 🔹 Tilføj denne helper
  String formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',  // mellemrum i stedet for punktum
    );
  }

  @override
  Widget build(BuildContext context) {


    OekonomiResultat? eco(VentilatorOekonomiSamlet v) {
      try {
        return v.oekonomi as OekonomiResultat?;
      } catch (e) {
        debugPrint('❌ Casting fejl: $e');
        return null;
      }
    }

    final fmtInt = NumberFormat.decimalPattern('da_DK')
      ..maximumFractionDigits = 0;

    double safeNum(num? x, {double forNaN = -1e300}) {
      if (x == null) return forNaN;
      final d = x.toDouble();
      if (d.isNaN || !d.isFinite) return forNaN;
      return d;
    }

    if (alleForslag.isEmpty) {
      return const Scaffold(body: Center(child: Text('Ingen forslag')));
    }

// ✅ Sortér med null-checks
    final sorteredeForslag = [...alleForslag]
      ..sort((a, b) {
        final ecoA = eco(a);
        final ecoB = eco(b);
        // ✅ Hvis en af dem er null, placer den sidst
        if (ecoA == null && ecoB == null) return 0;
        if (ecoA == null) return 1;
        if (ecoB == null) return -1;
        return ecoA.tilbagebetalingstid.compareTo(ecoB.tilbagebetalingstid);
      });

// 🔹 Vælg korteste tilbagebetalingstid (Scenarie 1)
    final valgKorteste = sorteredeForslag.first;

// 🔹 Vælg største årlige besparelse (Scenarie 2)
    final valgStoerste = ([...sorteredeForslag]
      ..sort((a, b) =>
          (b.oekonomi as OekonomiResultat).aarsbesparelse
              .compareTo((a.oekonomi as OekonomiResultat).aarsbesparelse)))
        .first;

// ✅ Afgør her om scenarie 1 er optimerbart
    final double tbtScenarie1 = (valgKorteste.oekonomi as OekonomiResultat).tilbagebetalingstid;
    final bool scenarie1KanOptimeres = tbtScenarie1 <= 5;

// ✅ Hent anlægget vi er på
    final valgtAnlaeg = projektInfo.alleAnlaeg.firstWhere(
          (a) => a.anlaegsNavn == anlaegsNavn,
      orElse: () => AnlaegsData.empty(),
    );

// ✅ Tjek om det er et nyt ventilationsanlæg (manuel indtastning af HELE systemet)
    final gyldigeForslag = sorteredeForslag.where(erGyldigtVentilatorForslag).toList();
    final bool erNytVentilationsanlaeg = gyldigeForslag.length == 1 &&
        gyldigeForslag.first.fabrikant.contains('Nyt Ventilationsanlæg') &&
        anlaegsType == 'Ventilationsanlæg';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/bravida_logo_rgb_pos.png', height: 45),
          ),
        ],
        title: Text(
          'BESPARELSESFORSLAG – $anlaegsNavn',
          style: const TextStyle(
            color: Color(0xFF006390),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

// 🔹 Ventilatoroptimering (øverst)
                _overskriftBoks(erNytVentilationsanlaeg ? 'NYT VENTILATIONSANLÆG' : 'VENTILATOROPTIMERING'),
                const SizedBox(height: 16),

// 🔹 FØR-situationen – overskrift + ikon udenfor boksen
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF006390), size: 20),
                      SizedBox(width: 6),
                      Text(
                        "FØR-situationen",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006390),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

// 🔹 Selve boksen (uden overskrift/ikon internt)
                _infoKort(
                  null,
                  "",
                  [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tekst-delen
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
                                  elforbrugInd > 0) ...[
                                const Text('Indblæsningsventilator',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                _infoLinje(Icons.flash_on, 'Elforbrug', elforbrugInd, 'kWh', decimals: 0),
                                _infoLinje(Icons.payments, 'Omkostning', omkostningInd, 'kr.', decimals: 0),
                                const SizedBox(height: 12),
                              ],

                              if ((anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
                                  elforbrugUd > 0) ...[
                                const Text('Udsugningsventilator',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                _infoLinje(Icons.flash_on, 'Elforbrug', elforbrugUd, 'kWh', decimals: 0),
                                _infoLinje(Icons.payments, 'Omkostning', omkostningUd, 'kr.', decimals: 0),
                                const SizedBox(height: 12),
                              ],

                              if ((elforbrugInd > 0 || elforbrugUd > 0)) ...[
                                const Text('Samlet energiforbrug og driftsomkostning',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                _infoLinje(Icons.bolt, 'Samlet elforbrug', samletFoerKWh, 'kWh/år', decimals: 0),
                                _infoLinje(Icons.payments, 'Samlet omkostning', samletFoerKr, 'kr./år', decimals: 0),
                              ],

                              // ✅ VARMEFORBRUG (kun for NYE ventilationsanlæg)
                              if (erNytVentilationsanlaeg && varmeforbrugResultat != null) ...[
                                const SizedBox(height: 12),
                                const Text('Varmeforbrug',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                _infoLinje(Icons.local_fire_department, 'Årligt varmeforbrug',
                                    varmeforbrugResultat!.varmeforbrugKWh ?? 0, 'kWh/år', decimals: 0),
                                _infoLinje(Icons.payments, 'Årlig varmeomkostning',
                                    varmeforbrugResultat!.varmeOmkostning ?? 0, 'kr./år', decimals: 0),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Billed-delen
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Builder(
                                builder: (context) {
                                  final String? path = (valgtAnlaeg.dokumentation != null &&
                                      valgtAnlaeg.dokumentation!.isNotEmpty)
                                      ? valgtAnlaeg.dokumentation!.first["path"]
                                      : null;

                                  final file = (path != null && path.isNotEmpty) ? File(path) : null;

                                  if (file != null && file.existsSync()) {
                                    return Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      height: 220,
                                      width: 220,
                                    );
                                  } else {
                                    return const Text(
                                      "Intet billede tilgængeligt",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 🔹 EFTER-sektionen
                Builder(
                  builder: (context) {
                    // Filtrer gyldige forslag
                    final gyldigeForslag = sorteredeForslag.where(erGyldigtVentilatorForslag).toList();
                    final antalGyldige = gyldigeForslag.length;

                    // Find manglende fabrikanter
                    final alleFabrikanter = ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
                    final gyldigeFabrikanter = gyldigeForslag.map((f) => f.fabrikant).toSet();
                    final manglenedFabrikanter = alleFabrikanter.where((f) => !gyldigeFabrikanter.contains(f)).toList();

                    // SCENARIE D: 0 matches
                    if (antalGyldige == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _infoKort(
                            Icons.warning,
                            "SPECIALANLÆG",
                            [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange, width: 2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Dette anlæg ligger uden for standardløsningerne fra vores leverandører.',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Årsag:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Builder(
                                      builder: (ctx) {
                                        final anlaeg = projektInfo.alleAnlaeg.firstWhere(
                                              (a) => a.anlaegsNavn == anlaegsNavn,
                                          orElse: () => AnlaegsData.empty(),
                                        );
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('• Luftmængde: ${formatDK(anlaeg.luftInd > 0 ? anlaeg.luftInd : anlaeg.luftUd)} m³/h'),
                                            Text('• Tryk: ${formatDK(anlaeg.trykInd > 0 ? anlaeg.trykInd : anlaeg.trykUd)} Pa'),
                                          ],
                                        );
                                      },
                                    ),
                                    const Text('• Kombination kræver specialdesign'),
                                    const SizedBox(height: 12),
                                    const Text('NÆSTE SKRIDT:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const Text('Bravida kan tilbyde en skræddersyet løsning baseret på:'),
                                    const Text('✓ Nøjagtige målinger af anlægget'),
                                    const Text('✓ Tilbud fra flere leverandører'),
                                    const Text('✓ Teknisk rådgivning om optimal løsning'),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Kontakt din serviceleder for videre assistance.',
                                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // SCENARIE A, B, C: 1-3 matches
                    final valgKorteste = gyldigeForslag.first;
                    final valgStoerste = ([...gyldigeForslag]
                      ..sort((a, b) =>
                          (b.oekonomi as OekonomiResultat).aarsbesparelse
                              .compareTo((a.oekonomi as OekonomiResultat).aarsbesparelse)))
                        .first;

                    final double tbtScenarie1 = (valgKorteste.oekonomi as OekonomiResultat).tilbagebetalingstid;
                    final bool scenarie1KanOptimeres = tbtScenarie1 <= 5;

                    // ✅ Tjek om det er manuel data
                    final bool erManuelData = antalGyldige == 1 && (
                        valgKorteste.fabrikant.contains('Nyt Ventilationsanlæg') ||
                            valgKorteste.fabrikant.contains('Special anlæg')
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _infoKort(
                          Icons.trending_down,
                          "EFTER-situationen",
                          [
                            // ✅ FORKLARENDE TEKST FOR MANUEL DATA (TILFØJ DETTE)
                            if (erManuelData) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    valgKorteste.fabrikant.contains('Nyt Ventilationsanlæg')
                                        ? 'Komplet nyt ventilationsanlæg'
                                        : 'Udskiftning af ventilatorer med manuel pris og effekt',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF006390),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],

                            // ✅ HVIS MANUEL DATA: Vis kun ÉN boks centreret
                            if (erManuelData)
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 500),
                                  child: _forslagKolonne(
                                    overskrift: 'Besparelsesforslag',
                                    forslag: valgKorteste,
                                    highlight: true,
                                    elFaktor: 0.34,
                                    elPris: elPris,
                                    samletFoerKWh: samletFoerKWh,
                                    samletFoerKr: samletFoerKr,
                                    scenarie1KanOptimeres: scenarie1KanOptimeres,
                                    anlaegsType: anlaegsType,
                                    varmeforbrugResultat: varmeforbrugResultat,
                                  ),
                                ),
                              )
                            else
                            // ✅ HVIS NORMAL DATABASE: Vis 2 scenarier
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _forslagKolonne(
                                      overskrift: 'Scenarie 1 Korteste tilbagebetalingstid',
                                      forslag: valgKorteste,
                                      highlight: true,
                                      elFaktor: 0.34,
                                      elPris: elPris,
                                      samletFoerKWh: samletFoerKWh,
                                      samletFoerKr: samletFoerKr,
                                      scenarie1KanOptimeres: scenarie1KanOptimeres,
                                      anlaegsType: anlaegsType,
                                      varmeforbrugResultat: varmeforbrugResultat,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _forslagKolonne(
                                      overskrift: 'Scenarie 2 Største besparelse over 10 år',
                                      forslag: valgStoerste,
                                      highlight: true,
                                      elFaktor: 0.34,
                                      elPris: elPris,
                                      samletFoerKWh: samletFoerKWh,
                                      samletFoerKr: samletFoerKr,
                                      scenarie1KanOptimeres: scenarie1KanOptimeres,
                                      anlaegsType: anlaegsType,
                                      varmeforbrugResultat: varmeforbrugResultat,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // ✅ Note kun hvis IKKE manuel data OG 1-2 fabrikanter mangler
                        if (!erManuelData && antalGyldige < 3) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ BRUG EMOJI I STEDET FOR IKON
                                const Text(
                                  'ℹ',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    antalGyldige == 1
                                        ? 'For dette anlæg har vi kun kunnet finde standardløsning fra én leverandør.\n\n'
                                        'De øvrige leverandører (${manglenedFabrikanter.join(', ')}) kan kontaktes for '
                                        'skræddersyede løsninger tilpasset anlæggets specifikke behov. Kontakt Bravida for assistance.'
                                        : 'For dette anlæg har vi ikke kunnet finde standardløsning fra ${manglenedFabrikanter.join(', ')}.',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Besparelsesforslaget er udarbejdet på baggrund af beregninger fra tre ventilatorproducenter. '
                                'De viste forslag repræsenterer hhv. den korteste tilbagebetalingstid og den største økonomiske besparelse.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // 🔹 VARMEOPTIMERING (kun for standard løsninger - IKKE nye ventilationsanlæg)
                if (!erNytVentilationsanlaeg) ...[
                  _overskriftBoks('VARMEOPTIMERING'),
                  const SizedBox(height: 4),
                  _varmeKolonne(
                    varmeforbrugResultat: varmeforbrugResultat,
                    varmePris: varmePris,
                    anlaeg: projektInfo.alleAnlaeg.firstWhere(
                          (a) => a.anlaegsNavn == anlaegsNavn,
                      orElse: () => AnlaegsData.empty(),
                    ),
                    anlaegsType: anlaegsType,
                  ),
                  const SizedBox(height: 32),
                ],

// 🔹 SAMLET RESULTAT OG TILSTANDSVURDERING
                _overskriftBoks(erNytVentilationsanlaeg ? 'TILSTANDSVURDERING' : 'SAMLET RESULTAT OG TILSTANDSVURDERING'),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final ecoResult = eco(valgStoerste);
                    if (ecoResult == null) {
                      return const Center(
                        child: Text('Kunne ikke beregne resultat'),
                      );
                    }
                    return _samletResultatKort(
                      ecoResult,
                      varmeforbrugResultat,
                      elPris,
                      valgtTilstand,
                      erNytVentilationsanlaeg: erNytVentilationsanlaeg,
                    );
                  },
                ),

                const SizedBox(height: 32),
                const Divider(
                  thickness: 1.2,
                  color: Color(0xFF34E0A1),
                  height: 32,
                ),
                Text(
                  'Beregningerne er baseret på elpris: ${formatDK(elPris, decimals: 2)} kr/kWh '
                      'og varmepris: ${formatDK(varmePris, decimals: 2)} kr/kWh.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Energi- og varmepriser kan variere. Justér gerne, hvis du kender dine egne priser.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text(
                  'CO₂-faktorer: El 0,34 kg/kWh, Fjernvarme 0,10 kg/kWh, Naturgas 0,20 kg/kWh.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34E0A1),
                      foregroundColor: const Color(0xFF006390),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      if (onVisFilter != null) {
                        onVisFilter!();   // kalder callback fra RapportPageView
                      }
                    },
                    child: const Text('Tilbage til oversigt'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _overskriftBoks(String title) {
  return Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF34E0A1), width: 2)),
    ),
    padding: const EdgeInsets.only(bottom: 10, top: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF34E0A1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
          color: Color(0xFF006390),
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _forslagKolonne({
  required String overskrift,
  required VentilatorOekonomiSamlet forslag,
  required bool highlight,
  required double elFaktor,
  required double elPris,
  required double samletFoerKWh,
  required double samletFoerKr,
  required bool scenarie1KanOptimeres,
  required String anlaegsType,
  VarmeforbrugResultat? varmeforbrugResultat,
}) {
  final eco = forslag.oekonomi as OekonomiResultat;

  // ✅ Ventilatorbesparelse (kun el)
  final double ventilatorBesparelseKr = eco.aarsbesparelse;
  final double ventilatorBesparelseKWh = elPris > 0 ? ventilatorBesparelseKr / elPris : 0;
  final double ventilatorCo2 = ventilatorBesparelseKWh * elFaktor;

  // ✅ Varmebesparelse (hvis ventilationsanlæg og der er varmedata)
  final bool erVentilationsanlaeg = anlaegsType == 'Ventilationsanlæg';
  final bool harVarmeOptimering = varmeforbrugResultat?.optimering?.kanOptimeres ?? false;

  final double varmeBesparelseKWh = (erVentilationsanlaeg && harVarmeOptimering)
      ? ((varmeforbrugResultat?.varmeforbrugKWh.toDouble() ?? 0) -
      (varmeforbrugResultat?.optimering?.nytVarmeforbrugKWh?.toDouble() ?? 0))
      : 0;

  final double varmeBesparelseKr = (erVentilationsanlaeg && harVarmeOptimering)
      ? ((varmeforbrugResultat?.varmeOmkostning.toDouble() ?? 0) -
      (varmeforbrugResultat?.optimering?.nytVarmeforbrugKr?.toDouble() ?? 0))
      : 0;

  final double varmeCo2 = varmeBesparelseKWh * 0.10; // 0,10 kg/kWh for varme

  // ✅ SAMLET besparelse
  final double samletBesparelseKWh = ventilatorBesparelseKWh + varmeBesparelseKWh;
  final double samletBesparelseKr = ventilatorBesparelseKr + varmeBesparelseKr;
  final double samletCo2 = ventilatorCo2 + varmeCo2;

  // Nyt elforbrug og omkostning (kun ventilator)
  final double nytElforbrugKWh = samletFoerKWh - ventilatorBesparelseKWh;
  final double nyOmkostningKr = samletFoerKr - ventilatorBesparelseKr;

  // 🔹 Bruges KUN til note — skjuler IKKE længere data
  final bool kanOptimeres = scenarie1KanOptimeres;

  return Column(
    children: [
      // ✅ Selve boksen
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: highlight ? const Color(0xFF34E0A1) : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Logo øverst (kun hvis ikke nyt anlæg)
            if (!forslag.fabrikant.contains('Nyt Ventilationsanlæg'))
              Padding(
                padding: EdgeInsets.only(
                  top: forslag.fabrikant == 'Ebmpapst' ? 24 : forslag.fabrikant == 'Novenco' ? 4 : forslag.fabrikant == 'Ziehl-Abegg' ? 6 : 4,
                  bottom: forslag.fabrikant == 'Ebmpapst' ? 31 : forslag.fabrikant == 'Novenco' ? 9 : forslag.fabrikant == 'Ziehl-Abegg' ? 0 : 10,
                ),
                child: Center(
                  child: Image.asset(
                    forslag.logoPath,
                    height: forslag.fabrikant == 'Ebmpapst' ? 25 : forslag.fabrikant == 'Novenco' ? 70 : forslag.fabrikant == 'Ziehl-Abegg' ? 80 : 90,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // ✅ VIS OVERSKRIFT HER (efter logo, kun for standardløsninger)
            if (!forslag.fabrikant.contains('Nyt Ventilationsanlæg') &&
                !forslag.fabrikant.contains('Special anlæg')) ...[
              const SizedBox(height: 4),
              Text(
                overskrift,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006390),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ] else if (!forslag.fabrikant.contains('Nyt Ventilationsanlæg'))
              const SizedBox(height: 12),

            // ✅ RETTET: Besparelsesdata vises ALTID (ingen if kanOptimeres wrapper)

            // ✅ TJEK: Er det et NYT VENTILATIONSANLÆG?
            if (erVentilationsanlaeg && forslag.fabrikant.contains('Nyt Ventilationsanlæg')) ...[
              // VENTILATORBESPARELSE
              const Text('VENTILATORBESPARELSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF006390))),
              const SizedBox(height: 6),
              _infoLinje(Icons.flash_on, 'El-besparelse', ventilatorBesparelseKWh, 'kWh/år'),
              _infoLinje(Icons.monetization_on, 'Økonomisk', ventilatorBesparelseKr, 'kr/år'),
              _infoLinje(Icons.electric_bolt, 'Nyt elforbrug', nytElforbrugKWh, 'kWh/år'),
              _infoLinje(Icons.payments, 'Ny elomkostning', nyOmkostningKr, 'kr/år'),

              // VARMEBESPARELSE (hvis der er varmedata)
              if (harVarmeOptimering) ...[
                const SizedBox(height: 12),
                const Text('VARMEBESPARELSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF006390))),
                const SizedBox(height: 6),
                _infoLinje(Icons.local_fire_department, 'Energibesparelse', varmeBesparelseKWh, 'kWh/år'),
                _infoLinje(Icons.monetization_on, 'Økonomisk', varmeBesparelseKr, 'kr/år'),
                _infoLinje(Icons.local_fire_department, 'Nyt varmeforbrug', varmeforbrugResultat?.optimering?.nytVarmeforbrugKWh ?? 0, 'kWh/år'),
                _infoLinje(Icons.payments, 'Ny varmeomkostning', varmeforbrugResultat?.optimering?.nytVarmeforbrugKr ?? 0, 'kr/år'),
              ],

              // SAMLET BESPARELSE
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF34E0A1), thickness: 2),
              const SizedBox(height: 8),
              const Text('SAMLET BESPARELSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF006390))),
              const SizedBox(height: 6),
              _infoLinje(Icons.savings, 'Samlet energi', samletBesparelseKWh, 'kWh/år'),
              _infoLinje(Icons.payments, 'Samlet økonomi', samletBesparelseKr, 'kr/år'),
              _infoLinje(Icons.cloud, 'CO₂', samletCo2, 'kg/år'),

              const SizedBox(height: 12),
              const Divider(color: Color(0xFF34E0A1), thickness: 1),
              const SizedBox(height: 8),
            ] else ...[
              // STANDARD LØSNINGER + MANUEL VENTILATORER → NORMAL STRUKTUR
              _infoLinje(Icons.flash_on, 'El-besparelse', ventilatorBesparelseKWh, 'kWh/år'),
              _infoLinje(Icons.monetization_on, 'Økonomisk besparelse', ventilatorBesparelseKr, 'kr/år'),
              _infoLinje(Icons.cloud, 'CO₂-besparelse', ventilatorCo2, 'kg/år'),
              const SizedBox(height: 10),
            ],

            // RESTEN (VISES FOR ALLE ANLÆGSTYPER)
            _infoLinje(Icons.account_balance_wallet, 'Investering', eco.pris, 'kr'),
            _infoLinje(Icons.timer, 'Tilbagebetalingstid', eco.tilbagebetalingstid, 'år', decimals: 1),
            const SizedBox(height: 10),

            // ✅ KUN vis "Nyt elforbrug" og "Ny elomkostning" for STANDARD løsninger (IKKE nye ventilationsanlæg)
            if (!(erVentilationsanlaeg && forslag.fabrikant.contains('Nyt Ventilationsanlæg'))) ...[
              _infoLinje(Icons.electric_bolt, 'Nyt elforbrug', nytElforbrugKWh, 'kWh/år'),
              _infoLinje(Icons.payments, 'Ny elomkostning', nyOmkostningKr, 'kr/år'),
              const SizedBox(height: 10),
            ],

            // ✅ KRITISK FIX: 10-års besparelse afhænger af om det er NYT VENTILATIONSANLÆG eller ej
            _infoLinje(
                Icons.savings,
                '10 års besparelse',
                (erVentilationsanlaeg && forslag.fabrikant.contains('Nyt Ventilationsanlæg'))
                    ? samletBesparelseKr * 10  // HELE systemet
                    : ventilatorBesparelseKr * 10,  // KUN ventilatorer
                'kr'
            ),

            // ✅ RETTET: Note vises som info NÅR TBT > 5 år (data skjules IKKE)
            if (!kanOptimeres) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  "👉 Tilbagebetalingstiden er over 5 år. Optimering kan stadig være relevant afhængigt af anlæggets tilstand og forventede restlevetid.",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget _varmeKolonne({
  required VarmeforbrugResultat? varmeforbrugResultat,
  required double varmePris,
  required AnlaegsData anlaeg,
  required String anlaegsType,
}) {
  if (varmeforbrugResultat == null) return const SizedBox.shrink();

  final num nuvEnergiKWh = varmeforbrugResultat.varmeforbrugKWh ?? 0;
  final num nuvEnergiKr = varmeforbrugResultat.varmeOmkostning ?? (nuvEnergiKWh * varmePris);
  final num co2Foer = varmeforbrugResultat.co2Udledning ?? 0;

  // ✅ Brug kanOptimeres direkte fra optimering-objektet
  final bool kanOptimeres = varmeforbrugResultat.optimering?.kanOptimeres ?? false;

  // ✅ VIGTIG FIX: Hvis kanOptimeres = false, skal efter-værdier være SAMME som før-værdier
  // Dette sikrer at besparelsen bliver 0 for anlæg uden varmegenvinding
  final num efterEnergiKWh = kanOptimeres
      ? (varmeforbrugResultat.optimering?.nytVarmeforbrugKWh ?? nuvEnergiKWh)
      : nuvEnergiKWh;
  final num efterEnergiKr = kanOptimeres
      ? (varmeforbrugResultat.optimering?.nytVarmeforbrugKr ?? nuvEnergiKr)
      : nuvEnergiKr;
  final num nyVirkningsgrad = varmeforbrugResultat.optimering?.nyVirkningsgrad ?? 0;

  // ✅ Beregn CO2-besparelse
  final num besparelseKWh = nuvEnergiKWh - efterEnergiKWh;
  final num besparelseKr = nuvEnergiKr - efterEnergiKr;
  final num co2Besparelse = varmeforbrugResultat.optimering?.co2Besparelse ?? 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _infoKort(
        Icons.local_fire_department,
        'Varmeforbrug',
        [
          // 🔹 Før optimering (hvis der er beregning)
          if (varmeforbrugResultat.harBeregning) ...[
            const Text('Før optimering', style: TextStyle(fontWeight: FontWeight.bold)),
            _infoLinje(Icons.local_fire_department, 'Årsforbrug', nuvEnergiKWh, 'kWh/år'),
            _infoLinje(Icons.payments, 'Årlig omkostning', nuvEnergiKr, 'kr/år'),
          ],

          // 🔹 Efter optimering (hvis kanOptimeres)
          if (kanOptimeres) ...[
            const SizedBox(height: 12),
            const Text('Efter optimering', style: TextStyle(fontWeight: FontWeight.bold)),
            _infoLinje(Icons.local_fire_department, 'Nyt varmeforbrug', efterEnergiKWh, 'kWh/år'),
            _infoLinje(Icons.payments, 'Ny omkostning', efterEnergiKr, 'kr/år'),
            _infoLinje(Icons.speed, 'Ny virkningsgrad', nyVirkningsgrad, '%', decimals: 1),

            const SizedBox(height: 12),
            const Text('Besparelse', style: TextStyle(fontWeight: FontWeight.bold)),
            _infoLinje(Icons.savings, 'Energibesparelse', besparelseKWh, 'kWh/år'),
            _infoLinje(Icons.monetization_on, 'Økonomisk besparelse', besparelseKr, 'kr/år'),
            if (co2Besparelse > 0)
              _infoLinje(Icons.eco, 'CO₂-besparelse', co2Besparelse, 'kg/år'),
          ],

          // 🔹 Kommentar fra optimering (hvis den findes)
          if (varmeforbrugResultat.optimering?.kommentar != null) ...[
            const SizedBox(height: 8),
            Text(
              varmeforbrugResultat.optimering!.kommentar,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ],
      ),

      // Note under boksen vises kun hvis vi viser optimering
      if (kanOptimeres) ...[
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Der vises ikke en tilbagebetalingstid på varmebesparelsen, '
                'da renoveringsomkostningen for varmegenvinding kræver en mere '
                'dybdegående undersøgelse. Beregningen er udarbejdet for at give et '
                'indblik i det potentielle besparelsesniveau, som kan opnås ved '
                'optimering af varmeveksleren.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    ],
  );
}

Widget _infoKort(IconData? icon, String overskrift, List<Widget> children, {Widget? trailing}) {
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFF34E0A1), width: 2),
      borderRadius: BorderRadius.circular(13),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overskrift.isNotEmpty || icon != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF006390), size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  overskrift,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006390),
                    fontSize: 15,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        if (overskrift.isNotEmpty || icon != null) const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

/// 🔹 Samlet resultatkort: opsummering af besparelse + tilstandsvurdering
Widget _samletResultatKort(
    OekonomiResultat eco,
    VarmeforbrugResultat? varme,
    double elPris,
    String valgtTilstand, {
      bool erNytVentilationsanlaeg = false, // ✅ TILFØJ DENNE PARAMETER
    }) {
  // Ventilatorbesparelse
  final double elBesparelseVent = eco.aarsbesparelse > 0 && elPris > 0
      ? eco.aarsbesparelse / elPris
      : 0;
  final double krBesparelseVent = eco.aarsbesparelse;
  final double co2BesparelseVent = elBesparelseVent * 0.34; // 0,34 kg/kWh

  // Varmebesparelse
  // ✅ KRITISK FIX: Tjek om varmen kan optimeres før beregning
  final bool kanOptimeresVarme = varme?.optimering?.kanOptimeres ?? false;

  final double nuvEnergiKWh = varme?.varmeforbrugKWh.toDouble() ?? 0;
  // ✅ Hvis varmen ikke kan optimeres, sæt efter-værdi til samme som før-værdi (besparelse = 0)
  final double efterEnergiKWh = kanOptimeresVarme
      ? (varme?.optimering?.nytVarmeforbrugKWh?.toDouble() ?? nuvEnergiKWh)
      : nuvEnergiKWh;

  final double nuvEnergiKr = varme?.varmeOmkostning.toDouble() ?? 0;
  // ✅ Hvis varmen ikke kan optimeres, sæt efter-værdi til samme som før-værdi (besparelse = 0)
  final double efterEnergiKr = kanOptimeresVarme
      ? (varme?.optimering?.nytVarmeforbrugKr?.toDouble() ?? nuvEnergiKr)
      : nuvEnergiKr;

  final double varmeBesparelseKWh = (nuvEnergiKWh - efterEnergiKWh);
  final double varmeBesparelseKr = (nuvEnergiKr - efterEnergiKr);
  // CO₂ kun hvis der faktisk er en besparelse
  final double varmeBesparelseCo2 = (varmeBesparelseKWh > 0)
      ? varmeBesparelseKWh * 0.10
      : 0;

  // Totalsummer
  final double totalKWh = elBesparelseVent + varmeBesparelseKWh;
  final double totalKr = krBesparelseVent + varmeBesparelseKr;
  final double totalCo2 = co2BesparelseVent + varmeBesparelseCo2;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _infoKort(
        Icons.assessment,
        erNytVentilationsanlaeg
            ? 'Tilstandsvurdering'  // ✅ KUN tilstandsvurdering for nye anlæg
            : 'Største besparelsespotentiale og tilstandsvurdering',
        [
          // ✅ VIS KUN besparelse for STANDARD løsninger (IKKE nye ventilationsanlæg)
          if (!erNytVentilationsanlaeg) ...[
            const Text('Opsummering', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              '(Beregnet inkl. både ventilator- og varmeoptimering)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            _infoLinje(Icons.flash_on, 'Energibesparelse', totalKWh, 'kWh/år'),
            _infoLinje(Icons.payments, 'Økonomisk besparelse', totalKr, 'kr/år'),
            _infoLinje(Icons.public, 'CO₂-besparelse', totalCo2, 'kg/år'),
            const SizedBox(height: 12),
          ],

          // ✅ Tilstandsvurdering (VISES ALTID)
          const Text('Tilstandsvurdering', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Anlægget er ${_tekstForTilstand(valgtTilstand)}',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: getTilstandsfarve(valgtTilstand),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        _tilstandsKommentar(valgtTilstand),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
      ),
    ],
  );
}
String _tekstForTilstand(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return 'i god stand';
    case '2':
      return 'rimelig stand';
    case '3':
      return 'slidt kræver opmærksomhed';
    case '4':
      return 'kritisk bør optimeres';
    case '5':
      return 'meget kritisk akut behov';
    case '6':
      return 'ude af drift';
    default:
      return 'uden vurdering';
  }
}

Color getTilstandsfarve(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return Colors.green;
    case '2':
      return Colors.lightGreen;
    case '3':
      return Colors.orange;
    case '4':
      return Colors.deepOrange;
    case '5':
      return Colors.red;
    case '6':
      return Colors.black;
    default:
      return Colors.grey;
  }
}
String _tilstandsKommentar(String valgtTilstand) {
  switch (valgtTilstand) {
    case '1':
      return 'Da anlægget er i god stand, er det oplagt at gennemføre en energioptimering, '
          'da investeringen kan udnyttes fuldt ud og skabe størst mulig værdi.';
    case '2':
      return'Anlægget er i rimelig stand med mindre slitage registreret. Det kan fortsat fungere '
          'uden større problemer, men en energioptimering kan være fordelagtig for at reducere '
          'driftsomkostninger og forlænge levetiden.';
    case '3':
      return 'Anlægget er slidt og har en restlevetid på 1–3 år. Det bør vurderes, om en renovering '
          'kan forlænge levetiden, eller om en udskiftning er mere hensigtsmæssig. '
          'Ved begge løsninger bør energioptimering indgå som en naturlig del af indsatsen.';
    case '4':
      return 'Anlægget er i kritisk stand og bør udskiftes eller gennemgå en større renovering '
          'inden for det næste år. Det anbefales at planlægge indsatsen i god tid og samtidig '
          'inddrage energioptimering som en central del af løsningen.';
    case '5':
      return 'Anlægget er i meget kritisk stand og kræver en større indsats. '
          'Der bør planlægges omfattende renovering eller udskiftning, '
          'hvor energioptimering indgår som en del af løsningen.';
    case '6':
      return 'Anlægget er ikke længere funktionsdygtigt og skal udskiftes.'
          'I forbindelse med udskiftningen anbefales det at vælge en løsning med fokus på energioptimering.';
    default:
      return '';
  }
}
Widget _infoLinje(
    IconData icon,
    String label,
    num value,
    String enhed, {
      int decimals = 0,
    }) {
  final v = formatDK(value, decimals: decimals);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF34E0A1), size: 18),
        const SizedBox(width: 5),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(

                  text: '$v $enhed',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}



