import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ventoptima/generel_projekt_info.dart';
import 'package:intl/intl.dart';
import 'package:ventoptima/ventilator_samlet_beregning.dart';
import 'package:ventoptima/services/app_sikkerhed.dart';
import 'rapport_anlaegsoversigt.dart';
import 'rapport_besparelseforslag.dart';
import 'rapport_dokumentation.dart';
import 'rapport_filterresultat.dart';
import 'package:ventoptima/anlaegs_data.dart';

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

class RapportPdfGenerator {
  static Future<pw.Document> generateRapport({
    required GenerelProjektInfo projektInfo,
    required List<VentilatorOekonomiSamlet> alleForslag,
    required double elPris,
    required double varmePris,
  }) async {
    final pdf = pw.Document();

    const PdfColor primaryBlue = PdfColor.fromInt(0xFF006390);
    const PdfColor primaryGreen = PdfColor.fromInt(0xFF34E0A1);

    final datoFormat = DateFormat('d. MMMM yyyy', 'da_DK');
    final formateretDato = datoFormat.format(DateTime.now());

    // 🔒 Hent watermark info
    final watermarkInfo = await AppSikkerhed.hentWatermarkInfo();

    // Load Bravida logo
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/bravida_logo_rgb_pos.png')
        .then((data) => data.buffer.asUint8List());
    final bravidaLogo = pw.MemoryImage(logoBytes);

    // Load alle leverandør-logoer
    final Map<String, pw.MemoryImage> leverandorLogoer = {};

    final Uint8List zieglerBytes = await rootBundle
        .load('assets/images/ziehlabegg.png')
        .then((data) => data.buffer.asUint8List());
    leverandorLogoer['assets/images/ziehlabegg.png'] = pw.MemoryImage(zieglerBytes);

    final Uint8List novencoBytes = await rootBundle
        .load('assets/images/novenco.png')
        .then((data) => data.buffer.asUint8List());
    leverandorLogoer['assets/images/novenco.png'] = pw.MemoryImage(novencoBytes);

    final Uint8List ebmBytes = await rootBundle
        .load('assets/images/ebmpapst.png')
        .then((data) => data.buffer.asUint8List());
    leverandorLogoer['assets/images/ebmpapst.png'] = pw.MemoryImage(ebmBytes);

    // Forside billede
    final Uint8List forsideBilledeBytes = await rootBundle
        .load('assets/images/lunger.png')
        .then((data) => data.buffer.asUint8List());
    final forsideBillede = pw.MemoryImage(forsideBilledeBytes);

    // Beregn samlet besparelse (kun gyldige forslag)
    double samletBesparelse = 0;
    for (var anlaeg in projektInfo.alleAnlaeg) {
      final forslagForAnlaeg = alleForslag.where((f) => f.anlaegsnavn == anlaeg.anlaegsNavn).toList();
      final gyldigeForslagForAnlaeg = forslagForAnlaeg.where(erGyldigtVentilatorForslag).toList();

      if (gyldigeForslagForAnlaeg.isNotEmpty) {
        final bedsteForslag = gyldigeForslagForAnlaeg.reduce((a, b) =>
        (a.oekonomi as OekonomiResultat).aarsbesparelse >
            (b.oekonomi as OekonomiResultat).aarsbesparelse ? a : b);
        samletBesparelse += (bedsteForslag.oekonomi as OekonomiResultat).aarsbesparelse;
      }
      samletBesparelse += anlaeg.varmeAarsbesparelse ?? 0;
    }

    final fmtBesparelse = NumberFormat('#,##0', 'da_DK');

    // ════════════════════════════════════════════════════════════════
    // 1. FORSIDE
    // ════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Image(bravidaLogo, height: 40),
                    pw.SizedBox(height: 4),
                  ],
                ),
              ),
              pw.Container(width: double.infinity, height: 2, color: primaryGreen),
              pw.SizedBox(height: 80),
              pw.Text("Ventilationsoptimering", textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 30),
              pw.Text(projektInfo.adresse, textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.normal, color: PdfColors.black)),
              pw.SizedBox(height: 40),
              pw.Text("Kunne du tænke dig at spare", textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 16, color: PdfColor.fromInt(0xFF006390), fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
              pw.Text("${fmtBesparelse.format(samletBesparelse)} kr. årligt?", textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
              pw.SizedBox(height: 50),
              pw.Image(forsideBillede, height: 250, fit: pw.BoxFit.contain),
              pw.Spacer(),
              pw.Text("Et sundt indeklima begynder med et grønt valg", textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 12, color: primaryGreen, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
              _buildWatermark(watermarkInfo),
            ],
          );
        },
      ),
    );

    // ════════════════════════════════════════════════════════════════
    // 2. PROJEKTINFORMATION
    // ════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(bravidaLogo, primaryGreen),
              pw.SizedBox(height: 20),
              _buildSection("Projektinformation",
                  "Tekniker: ${projektInfo.teknikerNavn}\n"
                      "Telefon: ${projektInfo.telefon}\n"
                      "E-mail: ${projektInfo.email}\n"
                      "Afdeling: ${projektInfo.afdeling}\n\n"
                      "Elpris: ${projektInfo.elPris.toStringAsFixed(2)} DKK/kWh\n"
                      "Varmepris: ${projektInfo.varmePris.toStringAsFixed(2)} DKK/kWh\n\n"
                      "Driftstimer pr. uge:\n"
                      "Mandag: ${projektInfo.driftTimerPrUge[0]} timer\n"
                      "Tirsdag: ${projektInfo.driftTimerPrUge[1]} timer\n"
                      "Onsdag: ${projektInfo.driftTimerPrUge[2]} timer\n"
                      "Torsdag: ${projektInfo.driftTimerPrUge[3]} timer\n"
                      "Fredag: ${projektInfo.driftTimerPrUge[4]} timer\n"
                      "Lørdag: ${projektInfo.driftTimerPrUge[5]} timer\n"
                      "Søndag: ${projektInfo.driftTimerPrUge[6]} timer\n\n"
                      "Uger pr. år: ${projektInfo.ugerPerAar}\n"
                      "Driftstype: ${projektInfo.driftstype.name}"),
              pw.Spacer(),
              _buildWatermark(watermarkInfo),
            ],
          ),
        ),
      ),
    );

    // ════════════════════════════════════════════════════════════════
    // 3. AFRAPPORTERING (KORT: KUN INDLEDNING + KONKLUSION + BILAG)
    // ════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Afrapportering',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: primaryBlue)),
                  pw.Image(bravidaLogo, height: 30),
                ],
              ),
              pw.Container(width: double.infinity, height: 1, color: primaryGreen),
              pw.SizedBox(height: 10),
              pw.Text('Gennemgang af ventilationsanlæg med fokus på drift og energieffektivitet',
                  style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 20),

              _buildSection("",
                  "Kunde: ${projektInfo.kundeNavn}\n"
                      "Adresse: ${projektInfo.adresse}\n"
                      "Postnr. og By: ${projektInfo.postnrBy}\n"
                      "Kontaktperson: ${projektInfo.att}\n\n"
                      "Rapport udført af:\n"
                      "Tekniker: ${projektInfo.teknikerNavn}\n"
                      "Telefon: ${projektInfo.telefon}\n"
                      "E-mail: ${projektInfo.email}\n"
                      "Dato: $formateretDato"),

              _buildSection("1. Indledning",
                  "Denne rapport er udarbejdet på baggrund af et øjebliksbillede af ventilationsanlæggets drift. "
                      "Formålet er at give et overblik over anlæggets tilstand, energiforbrug og effektivitet samt at identificere muligheder for optimering.\n\n"
                      "Det er vigtigt at understrege, at rapportens beregninger og vurderinger er baseret på de målinger, der blev udført ved gennemgangen. "
                      "Resultaterne er derfor estimater og ikke en garanti. For at opnå et mere præcist billede anbefales det at supplere med logning over en længere periode."),

              _buildSection("2. Konklusion og anbefalinger",
                  "De præsenterede beregninger viser et betydeligt potentiale for energibesparelse. "
                      "Resultaterne er baseret på målingerne foretaget ved gennemgangen og giver et estimat for de mulige forbedringer.\n\n"
                      "For at opnå de største gevinster anbefales det at:\n\n"
                      "Følge de kortsigtede tiltag for hurtige forbedringer\n"
                      "Planlægge langsigtede investeringer i mere effektive ventilatorer og varmegenvinding\n"
                      "Gennemføre regelmæssige eftersyn og logninger for at dokumentere og fastholde energibesparelser\n\n"
                      "Ved at gennemføre anbefalingerne kan anlæggets driftsomkostninger reduceres, energieffektiviteten forbedres, "
                      "og levetiden forlænges, samtidig med at der sikres et bedre indeklima for bygningens brugere."),

              _buildSection("Bilag",
                  "Samlet besparelsespotentiale\n"
                      "Ventilatoroptimering (før/efter + scenarier)\n"
                      "Varmeoptimering\n"
                      "Filteroptimering\n"
                      "Tekniske detaljer og kontrol\n\n"
                      "Bilag 2: Filterspecifikationer (Camfil Hi-Flo)\n"
                      "Produktbeskrivelse og dokumentation fra filterleverandør."),
              pw.Spacer(),
              _buildWatermark(watermarkInfo),
            ],
          ),
        ),
      ),
    );

    // ════════════════════════════════════════════════════════════════
    // 4. BEREGNINGER (Anlægsoversigt + Besparelsesforslag + Filter + Dokumentation)
    // ════════════════════════════════════════════════════════════════

    // 4A. Anlægsoversigt
    final oversigtSider = RapportAnlaegsOversigt.build(
      alleForslag,
      projektInfo,
      elPris,
      varmePris,
      bravidaLogo,
    );
    for (var side in oversigtSider) {
      pdf.addPage(side);
    }

    // 4B. Besparelsesforslag, Filterresultat og Dokumentation for hvert anlæg
    final Map<String, List<VentilatorOekonomiSamlet>> grupperet = {};
    for (var v in alleForslag) {
      grupperet.putIfAbsent(v.anlaegsnavn, () => []).add(v);
    }

    final sorteredeAnlaeg = grupperet.entries.toList()
      ..sort((a, b) {
        final aMin = a.value.map((v) => (v.oekonomi as OekonomiResultat).tilbagebetalingstid).reduce((a, b) => a < b ? a : b);
        final bMin = b.value.map((v) => (v.oekonomi as OekonomiResultat).tilbagebetalingstid).reduce((a, b) => a < b ? a : b);
        return aMin.compareTo(bMin);
      });

    final double driftstimer = projektInfo.driftTimerPrUge.reduce((a, b) => a + b) * projektInfo.ugerPerAar;

    for (var entry in sorteredeAnlaeg) {
      final anlaegsNavn = entry.key;
      final forslagForAnlaeg = entry.value;
      final anlaeg = projektInfo.alleAnlaeg.firstWhere(
            (a) => a.anlaegsNavn == anlaegsNavn,
        orElse: () => AnlaegsData.empty(),
      );

      final double elforbrugIndAar = anlaeg.kwInd * driftstimer;
      final double elforbrugUdAar = anlaeg.kwUd * driftstimer;
      final double samletFoerKWh = elforbrugIndAar + elforbrugUdAar;
      final double samletFoerKr = (anlaeg.elOmkostningIndFoer ?? 0) + (anlaeg.elOmkostningUdFoer ?? 0);

      // Besparelsesforslag (vis altid, selv ved 0 matches)
      if (forslagForAnlaeg.isNotEmpty && (elforbrugIndAar > 0 || elforbrugUdAar > 0)) {
        // Filtrer gyldige forslag
        final gyldigeForslagForAnlaeg = forslagForAnlaeg.where(erGyldigtVentilatorForslag).toList();

        final besparelsesSider = RapportBesparelsesforslag.build(
          alleForslag: forslagForAnlaeg,  // Send alle forslag - rapport_besparelseforslag.dart håndterer filtrering
          projektInfo: projektInfo,
          anlaegsNavn: anlaegsNavn,
          elPris: elPris,
          varmePris: varmePris,
          logo: bravidaLogo,
          leverandorLogoer: leverandorLogoer,
          anlaegsType: anlaeg.valgtAnlaegstype,
          elforbrugInd: elforbrugIndAar,
          omkostningInd: anlaeg.elOmkostningIndFoer ?? 0,
          elforbrugUd: elforbrugUdAar,
          omkostningUd: anlaeg.elOmkostningUdFoer ?? 0,
          samletFoerKWh: samletFoerKWh,
          samletFoerKr: samletFoerKr,
          valgtTilstand: anlaeg.valgtTilstand,
          varmeforbrugResultat: anlaeg.varmeResultat,
        );
        for (var side in besparelsesSider) {
          pdf.addPage(side);
        }
      }

      // Filterresultat
      final bool harFilterData = anlaeg.filterValg != null &&
          ((anlaeg.antalHeleFiltreInd ?? 0) > 0 ||
              (anlaeg.antalHalveFiltreInd ?? 0) > 0 ||
              (anlaeg.antalHeleFiltreUd ?? 0) > 0 ||
              (anlaeg.antalHalveFiltreUd ?? 0) > 0);

      if (harFilterData) {
        final filterSider = await RapportFilter.genererFilterSider(
          anlaeg,
          projektInfo,
          pw.Font.helvetica(),
          pw.Font.helveticaBold(),
        );
        for (var side in filterSider) {
          pdf.addPage(pw.Page(build: (context) => side));
        }
      }

      // Dokumentation
      if (anlaeg.dokumentation != null && anlaeg.dokumentation!.isNotEmpty) {
        final dokumentationsSider = RapportDokumentation.build(
          anlaeg: anlaeg,
          logo: bravidaLogo,
        );
        for (var side in dokumentationsSider) {
          pdf.addPage(side);
        }
      }
    }

    // ════════════════════════════════════════════════════════════════
    // 5. METODEBESKRIVELSE (Problemets omfang, Datagrundlag, Filterkontrol, Foranstaltninger)
    // ════════════════════════════════════════════════════════════════

    // 5A. Problemets omfang + Datagrundlag
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(bravidaLogo, primaryGreen),
              pw.SizedBox(height: 20),
              _buildSection("3. Problemets omfang",
                  "Ved gennemgangen af ventilationsanlægget er der identificeret forhold, som kan have indflydelse på energieffektivitet, driftssikkerhed og komfort. "
                      "Typiske udfordringer kan være:\n\n"
                      "Forhøjet energiforbrug i ventilatorer\n"
                      "Ineffektive eller tilstoppede filtre\n"
                      "Utilstrækkelig varmegenvinding\n"
                      "Mangelfuld regulering eller styring"),

              _buildSection("4. Datagrundlag",
                  "Rapporten er udarbejdet på baggrund af:\n\n"
                      "Luftmængde og trykmålinger\n"
                      "El og effektmålinger på ventilatorer\n"
                      "Temperaturmålinger før og efter varmegenvinding\n"
                      "Kontrol af filtre og filtertryk\n"
                      "Sammenligning med producentdata og gældende standarder"),
              pw.Spacer(),
              _buildWatermark(watermarkInfo),
            ],
          ),
        ),
      ),
    );

    // 5B. Filterkontrol
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(bravidaLogo, primaryGreen),
              pw.SizedBox(height: 20),
              _buildSection("5. Filterkontrol og optimering",
                  "Ved serviceopstart er filternes tryktab blevet kontrolleret for at vurdere, om serviceintervallet er passende. "
                      "Der er en øvre grænse for tilsmudsningsgraden i et filter, og overskrides denne, øges både energiforbruget og risikoen for nedsat luftkvalitet.\n\n"
                      "Det er ligeledes vurderet, om antallet af filtre er tilpasset den målte luftmængde. "
                      "Hvis lufthastigheden over filtrene overstiger de anbefalede grænseværdier (typisk 2-3 m/s afhængigt af filtertype), kan følgende problemer opstå:\n\n"
                      "Øget tryktab: Ventilatoren bruger mere energi, hvilket øger driftsomkostningerne.\n"
                      "Støjproblemer: Højere hastighed skaber turbulens og støj i anlæg og kanaler.\n"
                      "Risiko for filterskader: Filtermaterialet kan presses sammen eller gå i stykker.\n"
                      "Nedsat filtereffektivitet: Partikler når at passere gennem filteret.\n"
                      "Øget slitage: Filtrene slides hurtigere og skal skiftes oftere.\n\n"
                      "Når filterets maksimale sluttryktab overskrides, kan ventilationsanlægget miste evnen til at levere den nødvendige luftmængde, "
                      "ventilatoren kan blive overbelastet, og der kan opstå risiko for, at ufiltreret luft trænger udenom filteret via utætheder.\n\n"
                      "Løsningen er at udskifte filtre, inden sluttryktabet nås. Derfor anbefales det at anvende trykdifferensmålere, der kan advare i tide. "
                      "Dette sikrer både et sundt indeklima, lavere energiforbrug og længere levetid for anlægget."),
              pw.Spacer(),
              _buildWatermark(watermarkInfo),
            ],
          ),
        ),
      ),
    );

    // 5C. Foranstaltninger
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(bravidaLogo, primaryGreen),
              pw.SizedBox(height: 20),
              _buildSection("6. Foranstaltninger",
                  "6.1 Kortsigtede foranstaltninger\n\n"
                      "Udskiftning af filtre efter behov\n"
                      "Rengøring af varmevekslere og ventilationskomponenter\n"
                      "Justering af driftsparametre (tryk, luftmængde, frekvensstyring)\n"
                      "Gennemgang af CTS indstillinger\n\n"
                      "6.2 Langsigtede foranstaltninger\n\n"
                      "Udskiftning af ventilatorer til energieffektive EC-modeller\n"
                      "Implementering af behovsstyret ventilation (CO2, temperatur eller tidsstyring)\n"
                      "Optimering af varmegenvinding\n"
                      "Løbende vedligeholdelse for at sikre stabile driftsforhold"),
              pw.Spacer(),
              _buildWatermark(watermarkInfo),
            ],
          ),
        ),
      ),
    );

    // ════════════════════════════════════════════════════════════════
    // 6. CAMFIL-SIDE (SIDST!)
    // ════════════════════════════════════════════════════════════════
    final Uint8List camfilImage = await rootBundle
        .load('assets/images/camfill.png')
        .then((data) => data.buffer.asUint8List());
    final camfil = pw.MemoryImage(camfilImage);

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(camfil, fit: pw.BoxFit.contain),
                ),
              ),
              _buildWatermark(watermarkInfo),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ════════════════════════════════════════════════════════════════
  // HELPER FUNKTIONER
  // ════════════════════════════════════════════════════════════════

  static pw.Widget _buildHeader(pw.MemoryImage logo, PdfColor greenColor) {
    return pw.Column(
      children: [
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Image(logo, height: 30),
        ),
        pw.SizedBox(height: 4),
        pw.Container(width: double.infinity, height: 1, color: greenColor),
      ],
    );
  }

  static pw.Widget _buildSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF006390),
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Text(content, style: const pw.TextStyle(fontSize: 12, height: 1.5)),
        pw.SizedBox(height: 16),
      ],
    );
  }

  // 🔒 Watermark widget
  static pw.Widget _buildWatermark(String watermarkInfo) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 5, bottom: 5),
      child: pw.Text(
        watermarkInfo,
        style: pw.TextStyle(
          fontSize: 6,
          color: PdfColors.grey400,
        ),
        textAlign: pw.TextAlign.right,
      ),
    );
  }
}