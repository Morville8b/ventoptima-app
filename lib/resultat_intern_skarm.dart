import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'generel_projekt_info.dart';
import 'ebmpapst.dart' as ebmpapst;
import 'novenco.dart' as novenco;
import 'ziehlabegg.dart' as ziehl;
import 'package:ventoptima/widgets/tilstand_popup.dart';
import 'maaledata_skarm.dart';
import 'anlaegs_data.dart';
import 'package:ventoptima/anlaegs_oversigt_skarm.dart';
import 'ventilator_samlet_beregning.dart';
import 'ventilator_oekonomi_kort.dart';
import 'package:ventoptima/beregning_varmeforbrug.dart';
import 'beregning_varmegenvinding_optimering.dart';
import 'filter_resultat_skarm.dart';
import 'filter_skarm.dart';
import 'dart:math';

// 🔹 NY: Enum til dialog-svar
enum DialogResultat {
  afslut,
  fortsaet,
  tilfoejEkstra,
}

// Hjælpefunktion til formatering af danske tal
String formatDK(double value, {int decimals = 0}) {
  if (value.isNaN || value.isInfinite) return 'Ikke beregnet';

  // Formatér tallet manuelt med punktum som tusindtalsseparator
  final absValue = value.abs();
  final wholePart = absValue.floor();
  final decimalPart = absValue - wholePart;

  // Konverter heltal til streng med punktum-separatorer
  String wholeStr = wholePart.toString();
  String formatted = '';
  int count = 0;

  for (int i = wholeStr.length - 1; i >= 0; i--) {
    if (count == 3) {
      formatted = '.$formatted';
      count = 0;
    }
    formatted = wholeStr[i] + formatted;
    count++;
  }

  // Tilføj decimaler hvis nødvendigt
  if (decimals > 0) {
    final decimalStr = (decimalPart * pow(10, decimals)).round().toString().padLeft(decimals, '0');
    formatted = '$formatted,$decimalStr';
  }

  // Tilføj minus hvis negativt
  return value < 0 ? '-$formatted' : formatted;
}

// 🔹 Tjek om et ventilatorforslag er gyldigt (FLYTTET UD - skal ikke være inde i formatDK!)
bool erGyldigtVentilatorForslag(VentilatorOekonomiSamlet forslag) {
  final eco = forslag.oekonomi as OekonomiResultat;

  // Manuel indtastning er altid gyldig
  if (forslag.fabrikant == 'Special anlæg' ||
      forslag.fabrikant == 'Nyt Ventilationsanlæg') {
    return true;
  }

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

VentilatorOekonomiSamlet ebmpapst_beregnEbmpapstVentilatorer({
  required String afdeling,
  required double trykIndNormal,
  required double luftIndNormal,
  required double trykIndMax,
  required double luftIndMax,
  required double trykUdNormal,
  required double luftUdNormal,
  required double trykUdMax,
  required double luftUdMax,
  required double fradragRemtrukket,
  required int driftstimer,
  required double elpris,
  required double omkostningInd,
  required double omkostningUd,
  required String anlaegsNavn,
  required String anlaegstype,
  required GenerelProjektInfo projektInfo,
}) {
  final forslag = beregnAlleVentilatorer(
    fabrikant: 'Ebmpapst',
    afdeling: afdeling,
    trykIndNormal: trykIndNormal,
    luftIndNormal: luftIndNormal,
    trykIndMax: trykIndMax,
    luftIndMax: luftIndMax,
    trykUdNormal: trykUdNormal,
    luftUdNormal: luftUdNormal,
    trykUdMax: trykUdMax,
    luftUdMax: luftUdMax,
    fradragRemtrukket: fradragRemtrukket,
    driftstimer: driftstimer,
    elpris: elpris,
    omkostningInd: omkostningInd,
    omkostningUd: omkostningUd,
    anlaegsNavn: anlaegsNavn,
    anlaegstype: anlaegstype,
    projektInfo: projektInfo,
  );

  return forslag.firstWhere((e) => e.fabrikant == 'Ebmpapst');
}

VentilatorOekonomiSamlet novenco_beregnNovencoVentilatorer({
  required String afdeling,
  required double trykIndNormal,
  required double luftIndNormal,
  required double trykIndMax,
  required double luftIndMax,
  required double trykUdNormal,
  required double luftUdNormal,
  required double trykUdMax,
  required double luftUdMax,
  required double fradragRemtrukket,
  required int driftstimer,
  required double elpris,
  required double omkostningInd,
  required double omkostningUd,
  required String anlaegsNavn,
  required String anlaegstype,
  required GenerelProjektInfo projektInfo,
}) {
  final forslag = beregnAlleVentilatorer(
    fabrikant: 'Novenco',
    afdeling: afdeling,
    trykIndNormal: trykIndNormal,
    luftIndNormal: luftIndNormal,
    trykIndMax: trykIndMax,
    luftIndMax: luftIndMax,
    trykUdNormal: trykUdNormal,
    luftUdNormal: luftUdNormal,
    trykUdMax: trykUdMax,
    luftUdMax: luftUdMax,
    fradragRemtrukket: fradragRemtrukket,
    driftstimer: driftstimer,
    elpris: elpris,
    omkostningInd: omkostningInd,
    omkostningUd: omkostningUd,
    anlaegsNavn: anlaegsNavn,
    anlaegstype: anlaegstype,
    projektInfo: projektInfo,
  );

  return forslag.firstWhere((e) => e.fabrikant == 'Novenco');
}

VentilatorOekonomiSamlet ziehl_beregnZiehlVentilatorer({
  required String afdeling,
  required double trykIndNormal,
  required double luftIndNormal,
  required double trykIndMax,
  required double luftIndMax,
  required double trykUdNormal,
  required double luftUdNormal,
  required double trykUdMax,
  required double luftUdMax,
  required double fradragRemtrukket,
  required int driftstimer,
  required double elpris,
  required double omkostningInd,
  required double omkostningUd,
  required String anlaegsNavn,
  required String anlaegstype,
  required GenerelProjektInfo projektInfo,
}) {
  final forslag = beregnAlleVentilatorer(
    fabrikant: 'Ziehl-Abegg',
    afdeling: afdeling,
    trykIndNormal: trykIndNormal,
    luftIndNormal: luftIndNormal,
    trykIndMax: trykIndMax,
    luftIndMax: luftIndMax,
    trykUdNormal: trykUdNormal,
    luftUdNormal: luftUdNormal,
    trykUdMax: trykUdMax,
    luftUdMax: luftUdMax,
    fradragRemtrukket: fradragRemtrukket,
    driftstimer: driftstimer,
    elpris: elpris,
    omkostningInd: omkostningInd,
    omkostningUd: omkostningUd,
    anlaegsNavn: anlaegsNavn,
    anlaegstype: anlaegstype,
    projektInfo: projektInfo,
  );

  return forslag.firstWhere((e) => e.fabrikant == 'Ziehl-Abegg');
}

class ResultatInternSkarm extends StatelessWidget {
  final List<VentilatorOekonomiSamlet> forslag;
  final AnlaegsData anlaeg;
  final int index;
  final List<AnlaegsData> alleAnlaeg;
  final String anlaegsType;
  final double omkostningFoer;
  final double omkostningEfter;
  final String anlaegsNavn;
  final double kwInd;
  final double luftInd;
  final double statiskTrykInd;
  final double statiskTrykUd;
  final double kwUd;
  final double luftUd;
  final double hzInd;
  final double hzUd;
  final GenerelProjektInfo projektInfo;
  final bool erBeregnetInd;
  final bool erBeregnetUd;
  final String eksisterendeVarenummerInd;
  final String eksisterendeVarenummerUd;
  final double? trykFoerIndMax;
  final double? trykEfterIndMax;
  final double? trykFoerUdMax;
  final double? trykEfterUdMax;
  final double? luftIndMax;
  final double? luftUdMax;
  final double elpris;
  final double samletOmkostning;
  final double aarsbesparelse;
  final double tilbagebetalingstid;
  final double? remUdskiftningPris;
  final double? kammerBredde;
  final double? kammerHoede;
  final double? kammerLaengde;
  final String valgtTilstand;
  final String luftmaengdeLabelInd;
  final String luftmaengdeLabelUd;
  final bool erBeregnetUdFraKVaerdiInd;
  final bool erBeregnetUdFraKVaerdiUd;
  final bool erLuftmaengdeMaaeltIndtastetInd;
  final bool erLuftmaengdeMaaeltIndtastetUd;
  final Map<String, TextEditingController> driftstimer;
  final VarmeforbrugResultat? varmeforbrugResultat;
  final double? trykGamleFiltreInd;
  final double? trykGamleFiltreUd;
  final int? antalHeleFiltreInd;
  final int? antalHalveFiltreInd;
  final int? antalHeleFiltreUd;
  final int? antalHalveFiltreUd;
  final Map<String, dynamic>? manuelleData;
  final String? internKommentar;
  final double? recirkuleringProcent;

  const ResultatInternSkarm({
    super.key,
    required this.forslag,
    required this.index,
    required this.alleAnlaeg,
    required this.anlaeg,
    required this.anlaegsType,
    required this.omkostningFoer,
    required this.omkostningEfter,
    required this.anlaegsNavn,
    required this.kwInd,
    required this.luftInd,
    required this.statiskTrykInd,
    required this.statiskTrykUd,
    required this.kwUd,
    required this.luftUd,
    required this.hzInd,
    required this.hzUd,
    required this.projektInfo,
    required this.erBeregnetInd,
    required this.erBeregnetUd,
    required this.eksisterendeVarenummerInd,
    required this.eksisterendeVarenummerUd,
    required this.trykFoerIndMax,
    required this.trykEfterIndMax,
    required this.trykFoerUdMax,
    required this.trykEfterUdMax,
    required this.luftIndMax,
    required this.luftUdMax,
    required this.elpris,
    required this.samletOmkostning,
    required this.aarsbesparelse,
    required this.tilbagebetalingstid,
    required this.driftstimer,
    required this.kammerBredde,
    required this.kammerHoede,
    required this.kammerLaengde,
    required this.valgtTilstand,
    this.remUdskiftningPris,
    required this.luftmaengdeLabelInd,
    required this.luftmaengdeLabelUd,
    required this.erBeregnetUdFraKVaerdiInd,
    required this.erBeregnetUdFraKVaerdiUd,
    required this.erLuftmaengdeMaaeltIndtastetInd,
    required this.erLuftmaengdeMaaeltIndtastetUd,
    this.varmeforbrugResultat,
    this.trykGamleFiltreInd,
    this.trykGamleFiltreUd,
    this.antalHeleFiltreInd,
    this.antalHalveFiltreInd,
    this.antalHeleFiltreUd,
    this.antalHalveFiltreUd,
    this.manuelleData,
    this.internKommentar,
    this.recirkuleringProcent,
  });

  Widget advarselsBoks(String tekst, {bool fedTekst = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE44F02),
            Color(0xFF7E1800),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tekst,
              style: TextStyle(
                color: Colors.white,
                fontWeight: fedTekst ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget undertekstBoks(String tekst) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 32),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF7E1800),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tekst,
        style: const TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  double beregnElforbrug(double kw, double timer) => kw * timer;

  double beregnVirkningsgrad(double luftmaengde, double tryk, double kw) {
    if (kw == 0) return 0;
    return ((luftmaengde / 3600.0) * tryk) / (kw * 1000.0) * 100.0;
  }

  double beregnSEL(double kw, double luftmaengde) {
    if (kw == 0 || luftmaengde == 0) return 0;
    return kw / (luftmaengde / 3600.0) * 1000;
  }

  double beregnOmkostning(double kWh, double elpris) => kWh * elpris;

  String formatNumber(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 'Ikke beregnet';
    final formatter = NumberFormat('#,##0', 'da_DK');
    return formatter.format(value.round());
  }

  String formatDecimal(double value, int decimals) {
    if (value.isNaN || value.isInfinite || value < 0) return 'Ikke beregnet';
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'da_DK');
    return formatter.format(value);
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

  double beregnDriftstimer() {
    return projektInfo.driftTimerPrUge.fold(0.0, (sum, timer) => sum + timer) * projektInfo.ugerPerAar;
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 DEBUG: luftInd = $luftInd, statiskTrykInd = $statiskTrykInd, kwInd = $kwInd');
    print('🔧 DEBUG: luftUd = $luftUd, statiskTrykUd = $statiskTrykUd, kwUd = $kwUd');

    VarmeforbrugResultat? nytVarmeResultat;

// 🆕 TILFØJ DETTE:
    final bool erManuelIndtastning = manuelleData?['manuelIndtastning'] == true;
    final String? manuelType = manuelleData?['type'];

    if (erManuelIndtastning && manuelType == 'hele_anlaeg' && anlaegsType == 'Ventilationsanlæg') {
      final double virkningsgrad = manuelleData!['virkningsgrad'];
      final double nyLuftInd = manuelleData!['luftInd'];
      final double nyLuftUd = manuelleData!['luftUd'];

      print('🔥🔥🔥 DEBUG: Beregner nyt varmeresultat med virkningsgrad = $virkningsgrad%');

      final optimering = beregnOptimeretVarmegenvinding(
        anlaegsType: anlaegsType,
        typeVarmegenvinding: '',
        beregnetVirkningsgrad: varmeforbrugResultat?.maaltVirkningsgrad ?? 0,
        luftInd: nyLuftInd,
        luftUd: nyLuftUd,
        driftstimer: beregnDriftstimer(),
        friskluftTemp: varmeforbrugResultat?.friskluftTemp ?? 5.0,
        tempUd: varmeforbrugResultat?.tempUd ?? 22.0,
        tempIndEfterVarmeflade: varmeforbrugResultat?.tempIndEfterVarmeflade ?? 21.0,
        varmePris: projektInfo.varmePris,
        co2Faktor: 0.2,
        driftstype: projektInfo.driftstype,
        manuelVirkningsgrad: virkningsgrad,
        tempAfkast: varmeforbrugResultat?.tempAfkast,
      );

      nytVarmeResultat = VarmeforbrugResultat(
        varmeforbrugKWh: varmeforbrugResultat?.varmeforbrugKWh ?? 0,
        varmeOmkostning: varmeforbrugResultat?.varmeOmkostning ?? 0,
        co2Udledning: (varmeforbrugResultat?.varmeforbrugKWh ?? 0) / 1000.0 * 0.2,
        gennemsnitTemp: varmeforbrugResultat?.gennemsnitTemp ?? 0,
        maaltVirkningsgrad: varmeforbrugResultat?.maaltVirkningsgrad ?? 0,
        driftstype: projektInfo.driftstype,
        kommentar: 'Før-situation med gammelt anlæg',
        optimering: optimering,
        friskluftTemp: varmeforbrugResultat?.friskluftTemp,
        tempUd: varmeforbrugResultat?.tempUd,
        tempIndEfterVarmeflade: varmeforbrugResultat?.tempIndEfterVarmeflade,
        tempAfkast: varmeforbrugResultat?.tempAfkast,
      );

      print('🔥🔥🔥 DEBUG: Nyt resultat oprettet med virkningsgrad = ${optimering.nyVirkningsgrad}%');
      print('🔍 TJEK: varmeforbrugResultat?.friskluftTemp = ${varmeforbrugResultat?.friskluftTemp}');
      print('🔍 TJEK: varmeforbrugResultat?.tempUd = ${varmeforbrugResultat?.tempUd}');
      print('🔍 TJEK: varmeforbrugResultat?.tempIndEfterVarmeflade = ${varmeforbrugResultat?.tempIndEfterVarmeflade}');
      print('🎯 RESULTAT_INTERN_SKARM: virkningsgrad fra popup = $virkningsgrad');
      print('🎯 RESULTAT_INTERN_SKARM: virkningsgrad TYPE = ${virkningsgrad.runtimeType}');
    }

// 🆕 BRUG DET NYE RESULTAT I STEDET FOR DET GAMLE!
    final VarmeforbrugResultat? aktuelVarmeResultat = nytVarmeResultat ?? varmeforbrugResultat;

    final bool visEbmpapstKort = false;

    final double driftstimer = beregnDriftstimer();

    final double statiskTrykIndNormal = statiskTrykInd;
    final double statiskTrykUdNormal = statiskTrykUd;
    final double elforbrugInd = (anlaegsType == 'Udsugningsanlæg')
        ? 0 : beregnElforbrug(kwInd, driftstimer);
    final double elforbrugUd = (anlaegsType == 'Indblæsningsanlæg')
        ? 0 : beregnElforbrug(kwUd, driftstimer);
    final double virkningsgradInd = beregnVirkningsgrad(luftInd, statiskTrykIndNormal, kwInd);
    final double virkningsgradUd = beregnVirkningsgrad(luftUd, statiskTrykUdNormal, kwUd);
    final double selInd = beregnSEL(kwInd, luftInd);
    final double selUd = beregnSEL(kwUd, luftUd);
    final double omkostningInd = beregnOmkostning(elforbrugInd, projektInfo.elPris);
    final double omkostningUd = beregnOmkostning(elforbrugUd, projektInfo.elPris);
    final double samletFoerKWh = elforbrugInd + elforbrugUd;
    final double samletFoerKr = omkostningInd + omkostningUd;

    final double? statiskTrykMaxInd = (trykEfterIndMax != null && trykFoerIndMax != null)
        ? trykEfterIndMax! - trykFoerIndMax!
        : null;
    final double? statiskTrykMaxUd = (trykEfterUdMax != null && trykFoerUdMax != null)
        ? trykEfterUdMax! - trykFoerUdMax!
        : null;

    final String eksisterendeVarenummerInd = alleAnlaeg[index].ventMaerkatNr;
    final String eksisterendeVarenummerUd = alleAnlaeg[index].ventMaerkatNr;

    final afd = projektInfo.afdeling;

    final ebmpapst.EbmpapstResultat resultatInd =
    (anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
        luftInd > 0 &&
        statiskTrykIndNormal > 0
        ? ebmpapst.findNaermesteEbmpapstVentilator(
      statiskTrykIndNormal,
      luftInd,
      driftstimer: driftstimer,
      elpris: elpris,
      samletOmkostning: samletOmkostning,
      aarsbesparelse: aarsbesparelse,
    )
        : ebmpapst.EbmpapstResultat(
      tryk: 0,
      luftmaengde: 0,
      effekt: 0,
      aarsforbrugKWh: 0,
      omkostning: 0,
      varenummer: '',
      kommentar: '',
      virkningsgrad: 0.0,
      selvaerdi: 0.0,
      tilbagebetalingstid: 0,
      samletOmkostning: 0,
      aarsbesparelse: 0,
    );

    final ebmpapst.EbmpapstResultat resultatUd =
    (anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
        luftUd > 0 &&
        statiskTrykUdNormal > 0
        ? ebmpapst.findNaermesteEbmpapstVentilator(
      statiskTrykUdNormal,
      luftUd,
      driftstimer: driftstimer,
      elpris: elpris,
      samletOmkostning: samletOmkostning,
      aarsbesparelse: aarsbesparelse,
    )
        : ebmpapst.EbmpapstResultat(
      tryk: 0,
      luftmaengde: 0,
      effekt: 0,
      aarsforbrugKWh: 0,
      omkostning: 0,
      varenummer: '',
      kommentar: '',
      virkningsgrad: 0.0,
      selvaerdi: 0.0,
      tilbagebetalingstid: 0,
      samletOmkostning: 0,
      aarsbesparelse: 0,
    );

    final double samletEfterKWhEbmpapst =
        resultatInd.aarsforbrugKWh + resultatUd.aarsforbrugKWh;
    final double samletEfterKrEbmpapst =
        resultatInd.omkostning + resultatUd.omkostning;

    final novenco.NovencoResultat novencoInd =
    (anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
        luftInd > 0 &&
        statiskTrykIndNormal > 0
        ? novenco.findNaermesteNovencoVentilator(
      statiskTrykIndNormal,
      luftInd,
      driftstimer: driftstimer,
      elpris: elpris,
      samletOmkostning: samletOmkostning,
      aarsbesparelse: aarsbesparelse,
    )
        : novenco.NovencoResultat(
      tryk: 0,
      luftmaengde: 0,
      effekt: 0,
      aarsforbrugKWh: 0,
      omkostning: 0,
      varenummer: '',
      kommentar: '',
      virkningsgrad: 0.0,
      selvaerdi: 0.0,
      tilbagebetalingstid: 0,
      samletOmkostning: 0,
      aarsbesparelse: 0,
    );

    final novenco.NovencoResultat novencoUd =
    (anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
        luftUd > 0 &&
        statiskTrykUdNormal > 0
        ? novenco.findNaermesteNovencoVentilator(
      statiskTrykUdNormal,
      luftUd,
      driftstimer: driftstimer,
      elpris: elpris,
      samletOmkostning: samletOmkostning,
      aarsbesparelse: aarsbesparelse,
    )
        : novenco.NovencoResultat(
      tryk: 0,
      luftmaengde: 0,
      effekt: 0,
      aarsforbrugKWh: 0,
      omkostning: 0,
      varenummer: '',
      kommentar: '',
      virkningsgrad: 0.0,
      selvaerdi: 0.0,
      tilbagebetalingstid: 0,
      samletOmkostning: 0,
      aarsbesparelse: 0,
    );

    final double samletEfterKWhNovenco =
        novencoInd.aarsforbrugKWh + novencoUd.aarsforbrugKWh;
    final double samletEfterKrNovenco =
        novencoInd.omkostning + novencoUd.omkostning;

    final ziehl.ZiehlAbeggResultat ziehlInd =
    (anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
        luftInd > 0 &&
        statiskTrykIndNormal > 0
        ? ziehl.findNaermesteZiehlAbeggVentilator(
      statiskTrykIndNormal,
      luftInd,
      driftstimer: driftstimer,
      elpris: elpris,
      samletOmkostning: samletOmkostning,
      aarsbesparelse: aarsbesparelse,
    )
        : ziehl.ZiehlAbeggResultat(
      tryk: 0,
      luftmaengde: 0,
      effekt: 0,
      aarsforbrugKWh: 0,
      omkostning: 0,
      varenummer: '',
      kommentar: '',
      virkningsgrad: 0.0,
      selvaerdi: 0.0,
      tilbagebetalingstid: 0,
      samletOmkostning: 0,
      aarsbesparelse: 0,
    );

    final ziehl.ZiehlAbeggResultat ziehlUd =
    (anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') &&
        luftUd > 0 &&
        statiskTrykUdNormal > 0
        ? ziehl.findNaermesteZiehlAbeggVentilator(
      statiskTrykUdNormal,
      luftUd,
      driftstimer: driftstimer,
      elpris: elpris,
      samletOmkostning: samletOmkostning,
      aarsbesparelse: aarsbesparelse,
    )
        : ziehl.ZiehlAbeggResultat(
      tryk: 0,
      luftmaengde: 0,
      effekt: 0,
      aarsforbrugKWh: 0,
      omkostning: 0,
      varenummer: '',
      kommentar: '',
      virkningsgrad: 0.0,
      selvaerdi: 0.0,
      tilbagebetalingstid: 0,
      samletOmkostning: 0,
      aarsbesparelse: 0,
    );

    final double samletEfterKWhZiehl =
        ziehlInd.aarsforbrugKWh + ziehlUd.aarsforbrugKWh;
    final double samletEfterKrZiehl =
        ziehlInd.omkostning + ziehlUd.omkostning;

    final bool erBeregnetInd = this.erBeregnetInd;
    final bool erBeregnetUd = this.erBeregnetUd;

    final bool erLuftmaengdeMaaeltIndtastetInd = this.erLuftmaengdeMaaeltIndtastetInd;
    final bool erLuftmaengdeMaaeltIndtastetUd = this.erLuftmaengdeMaaeltIndtastetUd;

    final bool flagKVaerdiInd = erBeregnetUdFraKVaerdiInd;
    final bool flagKVaerdiUd = erBeregnetUdFraKVaerdiUd;

    final bool erLavHzInd = hzInd < 50;
    final bool erLavHzUd = hzUd < 50;

    final bool beregnetUdFraLavHzInd = erBeregnetInd && erLavHzInd;
    final bool beregnetUdFraLavHzUd = erBeregnetUd && erLavHzUd;

    final bool beregnetDesignInd = erBeregnetInd && !erLuftmaengdeMaaeltIndtastetInd && !flagKVaerdiInd;
    final bool beregnetDesignUd = erBeregnetUd && !erLuftmaengdeMaaeltIndtastetUd && !flagKVaerdiUd;

    final bool beregnetKVaerdiInd = flagKVaerdiInd && !erLuftmaengdeMaaeltIndtastetInd;
    final bool beregnetKVaerdiUd = flagKVaerdiUd && !erLuftmaengdeMaaeltIndtastetUd;

    final bool erBeregnetUdFraDesignData = beregnetDesignInd || beregnetDesignUd;
    final bool erBeregnetUdFraKVaerdi = beregnetKVaerdiInd || beregnetKVaerdiUd;
    final bool erBeregnetUdFraLavHz = beregnetUdFraLavHzInd || beregnetUdFraLavHzUd;
    final bool erBeregnetUdFraDesignEllerLavHz = erBeregnetUdFraDesignData || erBeregnetUdFraLavHz;

    final ziehl.ZiehlAbeggResultat resultatNormalInd = ziehlInd;
    final ziehl.ZiehlAbeggResultat resultatMaxInd = ziehlInd;
    final ziehl.ZiehlAbeggResultat resultatNormalUd = ziehlUd;
    final ziehl.ZiehlAbeggResultat resultatMaxUd = ziehlUd;

    final bool visIndblaesningNote = erBeregnetInd &&
        eksisterendeVarenummerInd.isNotEmpty &&
        resultatNormalInd.varenummer.isNotEmpty &&
        resultatNormalInd.varenummer != resultatMaxInd.varenummer;

    final bool visUdsugningNote = erBeregnetUd &&
        eksisterendeVarenummerUd.isNotEmpty &&
        resultatNormalUd.varenummer.isNotEmpty &&
        resultatNormalUd.varenummer != resultatMaxUd.varenummer;

    final bool erBeregnetUdFraDesignDataEllerLavHz = erBeregnetUdFraDesignData || erBeregnetUdFraLavHz;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Energi- og økonomiberegning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Image.asset('assets/images/star_logo.png', height: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF34E0A1),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                '$anlaegsType $anlaegsNavn',
                style: const TextStyle(
                  color: Color(0xFF006390),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (erBeregnetUdFraDesignData) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 12),
                child: Text(
                  '⚠ Tryk og luftmængde er baseret på designdata og kan afvige fra faktiske målinger. For præcis vurdering anbefales det at foretage målinger.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            if (hzInd < 50 && luftIndMax != null &&
                (anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg')) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠ Indblæsningsventilatorens maksimal luftmængde er beregnet ud fra lav frekvens (< 50 Hz). Resultater kan afvige fra faktiske forhold.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            if (hzUd < 50 && luftUdMax != null &&
                (anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg')) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠ Udsugningsventilatorens maksimal luftmængde er beregnet ud fra lav frekvens (< 50 Hz) . Resultater kan afvige fra faktiske forhold.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            if (erBeregnetUdFraKVaerdi) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠ Tryk og luftmængde er beregnet ud fra K-værdi. Kontroller at korrekt formel er brugt, da der kan være variationer.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'El-forbrug',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),

                    if ((anlaegsType == 'Indblæsningsanlæg' || anlaegsType == 'Ventilationsanlæg') && elforbrugInd > 0) ...[
                      const Text('Før optimering  Indblæsning', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (luftInd > 0) Text('Luftmængde: ${formatNumber(luftInd)} m³/h'),
                      if (statiskTrykIndNormal > 0) Text('Statisk tryk: ${formatNumber(statiskTrykIndNormal)} Pa'),
                      if (kwInd > 0) Text('Effekt: ${formatDecimal(kwInd, 2)} kW'),
                      if (hzInd > 0) Text('Frekvens: ${formatDecimal(hzInd, 1)} Hz'),
                      const SizedBox(height: 8),
                      Text('Elforbrug: ${formatNumber(elforbrugInd)} kWh/år'),
                      Text('Virkningsgrad: ${formatDecimal(virkningsgradInd, 1)} %'),
                      Text('SEL: ${formatNumber(selInd)} W/(m³/s)'),
                      Text('Omkostning: ${formatNumber(omkostningInd)} kr./år'),

                      if (luftIndMax != null && luftIndMax! > 0) ...[
                        const SizedBox(height: 12),
                        const Text('Ved maksimal drift:', style: TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                        Text('Luftmængde maks: ${formatNumber(luftIndMax!)} m³/h'),
                        if (statiskTrykMaxInd != null && statiskTrykMaxInd > 0)
                          Text('Statisk tryk maks: ${formatNumber(statiskTrykMaxInd)} Pa'),
                      ],
                      const SizedBox(height: 24),
                    ],

                    if ((anlaegsType == 'Udsugningsanlæg' || anlaegsType == 'Ventilationsanlæg') && elforbrugUd > 0) ...[
                      const Text('Før optimering  Udsugning', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (luftUd > 0) Text('Luftmængde: ${formatNumber(luftUd)} m³/h'),
                      if (statiskTrykUdNormal > 0) Text('Statisk tryk: ${formatNumber(statiskTrykUdNormal)} Pa'),
                      if (kwUd > 0) Text('Effekt: ${formatDecimal(kwUd, 2)} kW'),
                      if (hzUd > 0) Text('Frekvens: ${formatDecimal(hzUd, 1)} Hz'),
                      const SizedBox(height: 8),
                      Text('Elforbrug: ${formatNumber(elforbrugUd)} kWh/år'),
                      Text('Virkningsgrad: ${formatDecimal(virkningsgradUd, 1)} %'),
                      Text('SEL: ${formatNumber(selUd)} W/(m³/s)'),
                      Text('Omkostning: ${formatNumber(omkostningUd)} kr./år'),

                      if (luftUdMax != null && luftUdMax! > 0) ...[
                        const SizedBox(height: 12),
                        const Text('Ved maksimal drift:', style: TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                        Text('Luftmængde maks: ${formatNumber(luftUdMax!)} m³/h'),
                        if (statiskTrykMaxUd != null && statiskTrykMaxUd > 0)
                          Text('Statisk tryk maks: ${formatNumber(statiskTrykMaxUd)} Pa'),
                      ],
                      const SizedBox(height: 24),
                    ],

                    if ((elforbrugInd > 0 || elforbrugUd > 0)) ...[
                      const SizedBox(height: 12),
                      const Text('Samlet energiforbrug og driftsomkostning', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Samlet elforbrug: ${formatNumber(samletFoerKWh)} kWh/år'),
                      Text('Samlet omkostning: ${formatNumber(samletFoerKr)} kr./år'),
                    ],

                    const SizedBox(height: 12),

                    if (aktuelVarmeResultat != null &&
                        ((anlaegsType == 'Ventilationsanlæg' && aktuelVarmeResultat.harBeregning) ||
                            (anlaegsType == 'Indblæsningsanlæg' && (aktuelVarmeResultat.varmeforbrugKWh ?? 0) > 0) ||
                            (anlaegsType == 'Udsugningsanlæg' && (aktuelVarmeResultat.varmeforbrugKWh ?? 0) > 0))) ...[
                      const SizedBox(height: 16),

                      const Text(
                        'Varmeforbrug',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),

                      if (anlaegsType == 'Ventilationsanlæg') ...[
                        if (aktuelVarmeResultat.harBeregning) ...[
                          const Text('Før optimering', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Årsforbrug: ${formatNumber(aktuelVarmeResultat.varmeforbrugKWh)} kWh/år'),
                          Text('Årlig omkostning: ${formatNumber(aktuelVarmeResultat.varmeOmkostning)} kr./år'),
                          Text(
                            aktuelVarmeResultat.recirkuleringProcent != null
                                ? 'Recirkulering: ${formatDecimal(aktuelVarmeResultat.recirkuleringProcent!, 0)} %'
                                : 'Målt virkningsgrad: ${formatDecimal(aktuelVarmeResultat.maaltVirkningsgrad, 1)} %',
                          ),
                          if (aktuelVarmeResultat.recirkuleringProcent != null)
                            Text(
                              'Samlet virkningsgrad: ${formatDecimal(aktuelVarmeResultat.maaltVirkningsgrad, 1)} %',
                            ),
                          Text(
                            aktuelVarmeResultat.recirkuleringProcent != null
                                ? aktuelVarmeResultat.varmegenvindingVirkningsgrad != null
                                ? 'Temp. efter blanding + genvinding: ${formatDecimal(aktuelVarmeResultat.gennemsnitTemp, 1)} °C'
                                : 'Blandingstemperatur: ${formatDecimal(aktuelVarmeResultat.gennemsnitTemp, 1)} °C'
                                : 'Temp. efter varmegenvinding: ${formatDecimal(aktuelVarmeResultat.gennemsnitTemp, 1)} °C',
                          ),

                          if (aktuelVarmeResultat.recirkuleringProcent != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Dette er et specialanlæg med recirkulering. '
                                          'En vurdering af optimeringsmulighederne kræver '
                                          'en grundigere teknisk gennemgang af anlægget '
                                          'i samråd med en serviceleder.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (aktuelVarmeResultat.optimering?.kanOptimeres ?? false) ...[
                            const SizedBox(height: 12),
                            const Text('Efter optimering', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Nyt varmeforbrug: ${formatNumber(aktuelVarmeResultat.optimering!.nytVarmeforbrugKWh ?? 0)} kWh/år'),
                            Text('Ny omkostning: ${formatNumber(aktuelVarmeResultat.optimering!.nytVarmeforbrugKr ?? 0)} kr./år'),
                            Text('Ny virkningsgrad: ${formatDecimal(aktuelVarmeResultat.optimering!.nyVirkningsgrad, 1)} %'),
                          ],
                        ],

                        const SizedBox(height: 8),

                        Builder(
                          builder: (context) {
                            String kommentar;

                            if (!aktuelVarmeResultat.harBeregning) {
                              kommentar = "👉 Det har ikke været muligt at fastsætte varmeforbruget under service. "
                                  "En mulig årsag kan være, at udetemperaturen var over 10 °C under service.";
                            } else if (aktuelVarmeResultat.optimering != null &&
                                !(aktuelVarmeResultat.optimering!.kanOptimeres)) {
                              kommentar = "👉 Anlæggets varmegenvinding er allerede tæt på det forventede niveau "
                                  "og vurderes ikke at kunne optimeres yderligere.";
                            } else if (aktuelVarmeResultat.optimering?.kommentar != null &&
                                aktuelVarmeResultat.optimering!.kommentar.contains("Virkningsgrad oplyst af producenten")) {
                              kommentar = "👉 ${aktuelVarmeResultat.optimering!.kommentar}";
                            } else if (aktuelVarmeResultat.optimering?.korrigeretVirkningsgrad != null) {
                              kommentar = "👉 ${aktuelVarmeResultat.optimering!.kommentar}";
                            } else if (aktuelVarmeResultat.recirkuleringProcent != null) {
                            kommentar = aktuelVarmeResultat.kommentar ?? '';
                            } else {
                            kommentar = "👉 Standard virkningsgrad anvendt: "
                            "${formatDK(aktuelVarmeResultat.optimering?.valgtVirkningsgrad ?? 0, decimals: 1)} %";
                            }

                            return Text(
                              kommentar,
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            );
                          },
                        ),
                      ],

                      if (anlaegsType == 'Indblæsningsanlæg') ...[
                        if ((aktuelVarmeResultat.varmeforbrugKWh ?? 0) > 0) ...[
                          Text('Årsforbrug: ${formatNumber(aktuelVarmeResultat.varmeforbrugKWh)} kWh/år'),
                          Text('Årlig omkostning: ${formatNumber(aktuelVarmeResultat.varmeOmkostning)} kr./år'),
                          if (aktuelVarmeResultat.co2Udledning > 0)
                            Text('CO₂-udledning: ${formatDecimal(aktuelVarmeResultat.co2Udledning, 1)} ton/år'),
                        ],
                        if (aktuelVarmeResultat.kommentar != null &&
                            aktuelVarmeResultat.kommentar!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            aktuelVarmeResultat.kommentar!,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ],
                      ],

                      if (anlaegsType == 'Udsugningsanlæg') ...[
                        if ((aktuelVarmeResultat.varmeforbrugKWh ?? 0) > 0) ...[
                          Text('Årligt tab: ${formatNumber(aktuelVarmeResultat.varmeforbrugKWh)} kWh/år'),
                          Text('Årlig omkostning: ${formatNumber(aktuelVarmeResultat.varmeOmkostning)} kr./år'),
                          if (aktuelVarmeResultat.co2Udledning > 0)
                            Text('CO₂-udledning: ${formatDecimal(aktuelVarmeResultat.co2Udledning, 1)} ton/år'),
                        ],

                        if (aktuelVarmeResultat.kommentar != null &&
                            aktuelVarmeResultat.kommentar!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            aktuelVarmeResultat.kommentar!,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ],
                      ],

                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Tilstandsvurdering: ${getTilstandsbeskrivelse(valgtTilstand)}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: getTilstandsfarve(valgtTilstand),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF34E0A1),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Optimeringsforslag – Ventilatorsammenligning mellem producenter',
                    style: TextStyle(
                      color: Color(0xFF006390),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Builder(
                builder: (context) {
                  // 🆕 CHECK OM DER ER MANUEL INDTASTNING
                  final bool erManuelIndtastning = manuelleData?['manuelIndtastning'] == true;
                  final String? manuelType = manuelleData?['type'];

                  List<VentilatorOekonomiSamlet> alleResultater;

                  if (erManuelIndtastning) {
                    // ═══════════════════════════════════════════════════════════
                    // MANUEL INDTASTNING - kun ét resultat, ingen fabrikanter
                    // ═══════════════════════════════════════════════════════════

                    if (manuelType == 'ventilatorer') {
                      // VENTILATOR-UDSKIFTNING
                      final double prisInd = manuelleData!['prisInd'];
                      final double prisUd = manuelleData!['prisUd'];
                      final double nyEffektInd = manuelleData!['effektInd'];
                      final double nyEffektUd = manuelleData!['effektUd'];

                      final double nytElforbrugInd = beregnElforbrug(nyEffektInd / 1000, driftstimer);
                      final double nytElforbrugUd = beregnElforbrug(nyEffektUd / 1000, driftstimer);
                      final double nyOmkostningInd = beregnOmkostning(nytElforbrugInd, projektInfo.elPris);
                      final double nyOmkostningUd = beregnOmkostning(nytElforbrugUd, projektInfo.elPris);
                      final double nyVirkningsgradInd = beregnVirkningsgrad(luftInd, statiskTrykIndNormal, nyEffektInd / 1000);
                      final double nyVirkningsgradUd = beregnVirkningsgrad(luftUd, statiskTrykUdNormal, nyEffektUd / 1000);
                      final double nySELInd = beregnSEL(nyEffektInd / 1000, luftInd);
                      final double nySELUd = beregnSEL(nyEffektUd / 1000, luftUd);

                      final double aarsbesparelseEl = (omkostningInd + omkostningUd) - (nyOmkostningInd + nyOmkostningUd);
                      final double samletInvestering = (prisInd + prisUd - (remUdskiftningPris ?? 0)).clamp(0, double.infinity);
                      final double tilbagebetalingstid = aarsbesparelseEl > 0 ? samletInvestering / aarsbesparelseEl : 999;

                      final resultatIndManuel = ebmpapst.EbmpapstResultat(
                        tryk: statiskTrykIndNormal,
                        luftmaengde: luftInd,
                        effekt: nyEffektInd,
                        aarsforbrugKWh: nytElforbrugInd,
                        omkostning: nyOmkostningInd,
                        varenummer: 'Special anlæg - Indblæsning',
                        kommentar: 'Manuel pris og effekt. Tryk og luftmængde fra eksisterende anlæg.',
                        virkningsgrad: nyVirkningsgradInd,
                        selvaerdi: nySELInd,
                        tilbagebetalingstid: tilbagebetalingstid,
                        samletOmkostning: prisInd,
                        aarsbesparelse: aarsbesparelseEl,
                      );

                      final resultatUdManuel = ebmpapst.EbmpapstResultat(
                        tryk: statiskTrykUdNormal,
                        luftmaengde: luftUd,
                        effekt: nyEffektUd,
                        aarsforbrugKWh: nytElforbrugUd,
                        omkostning: nyOmkostningUd,
                        varenummer: 'Special anlæg - Udsugning',
                        kommentar: 'Manuel pris og effekt. Tryk og luftmængde fra eksisterende anlæg.',
                        virkningsgrad: nyVirkningsgradUd,
                        selvaerdi: nySELUd,
                        tilbagebetalingstid: tilbagebetalingstid,
                        samletOmkostning: prisUd,
                        aarsbesparelse: aarsbesparelseEl,
                      );

                      final manuelResultat = VentilatorOekonomiSamlet(
                        anlaegstype: anlaegsType,
                        anlaegsnavn: anlaegsNavn,
                        fabrikant: 'Special anlæg',
                        logoPath: 'assets/images/star_logo.png',
                        varenummerInd: 'Manuel - Indblæsning',
                        varenummerUd: 'Manuel - Udsugning',
                        sammeVentilatorVedMax: false,
                        kommentarInd: resultatIndManuel.kommentar,
                        kommentarUd: resultatUdManuel.kommentar,
                        oekonomi: OekonomiResultat(
                          anlaegstype: anlaegsType,
                          anlaegsnavn: anlaegsNavn,
                          omkostningFoer: omkostningInd + omkostningUd,
                          varenummer: 'Manuel',
                          tilbagebetalingstid: tilbagebetalingstid,
                          aarsforbrugKWh: nytElforbrugInd + nytElforbrugUd,
                          omkostning: nyOmkostningInd + nyOmkostningUd,
                          effekt: nyEffektInd + nyEffektUd,
                          tryk: (statiskTrykIndNormal + statiskTrykUdNormal) / 2,
                          luftmaengde: (luftInd + luftUd) / 2,
                          virkningsgrad: (nyVirkningsgradInd + nyVirkningsgradUd) / 2,
                          selvaerdi: (nySELInd + nySELUd) / 2,
                          indPris: prisInd,
                          udPris: prisUd,
                          totalPris: samletInvestering,
                          aarsbesparelse: aarsbesparelseEl,
                        ),
                        indNormal: resultatIndManuel,
                        indMax: resultatIndManuel,
                        udNormal: resultatUdManuel,
                        udMax: resultatUdManuel,
                        totalPris: samletInvestering,
                      );

                      alleResultater = [manuelResultat];

                    } else if (manuelType == 'hele_anlaeg') {
                      // HELT NYT ANLÆG
                      final double pris = manuelleData!['pris'];
                      final double virkningsgrad = manuelleData!['virkningsgrad'];
                      final double nyLuftInd = manuelleData!['luftInd'];
                      final double nyLuftUd = manuelleData!['luftUd'];
                      final double nyEffektInd = manuelleData!['effektInd'];
                      final double nyEffektUd = manuelleData!['effektUd'];
                      final double nyTrykInd = manuelleData!['trykEfterInd'] - manuelleData!['trykFoerInd'];
                      final double nyTrykUd = manuelleData!['trykEfterUd'] - manuelleData!['trykFoerUd'];

                      final double nytElforbrugInd = beregnElforbrug(nyEffektInd / 1000, driftstimer);
                      final double nytElforbrugUd = beregnElforbrug(nyEffektUd / 1000, driftstimer);
                      final double nyOmkostningInd = beregnOmkostning(nytElforbrugInd, projektInfo.elPris);
                      final double nyOmkostningUd = beregnOmkostning(nytElforbrugUd, projektInfo.elPris);
                      final double nyVirkningsgradInd = beregnVirkningsgrad(luftInd, statiskTrykIndNormal, nyEffektInd / 1000);
                      final double nyVirkningsgradUd = beregnVirkningsgrad(luftUd, statiskTrykUdNormal, nyEffektUd / 1000);
                      final double nySELInd = beregnSEL(nyEffektInd / 1000, nyLuftInd);
                      final double nySELUd = beregnSEL(nyEffektUd / 1000, nyLuftUd);

                      final double aarsbesparelseEl = (omkostningInd + omkostningUd) - (nyOmkostningInd + nyOmkostningUd);
                      final double samletInvestering = (pris - (remUdskiftningPris ?? 0)).clamp(0, double.infinity);

                      // ✅ TILFØJ VARMEBESPARELSE TIL SAMLET BESPARELSE (kun ved helt nyt anlæg)
                      final double varmebesparelse = nytVarmeResultat?.optimering?.besparelseKr ?? 0;
                      final double samletAarsbesparelse = aarsbesparelseEl + varmebesparelse;

                      final double tilbagebetalingstid = samletAarsbesparelse > 0
                          ? samletInvestering / samletAarsbesparelse
                          : 999;

                      print('💰 EL-besparelse: ${aarsbesparelseEl.toStringAsFixed(0)} kr./år');
                      print('🔥 Varmebesparelse: ${varmebesparelse.toStringAsFixed(0)} kr./år');
                      print('📊 SAMLET besparelse: ${samletAarsbesparelse.toStringAsFixed(0)} kr./år');
                      print('⏱️ Tilbagebetalingstid: ${tilbagebetalingstid.toStringAsFixed(1)} år');

                      final resultatIndManuel = ebmpapst.EbmpapstResultat(
                        tryk: nyTrykInd,
                        luftmaengde: nyLuftInd,
                        effekt: nyEffektInd,
                        aarsforbrugKWh: nytElforbrugInd,
                        omkostning: nyOmkostningInd,
                        varenummer: 'Nyt anlæg - Indblæsning',
                        kommentar: 'Helt nyt anlæg med manuel pris, virkningsgrad ${virkningsgrad.toStringAsFixed(1)}%, og alle nye specifikationer.',
                        virkningsgrad: nyVirkningsgradInd,
                        selvaerdi: nySELInd,
                        tilbagebetalingstid: tilbagebetalingstid,
                        samletOmkostning: pris / 2,
                        aarsbesparelse: aarsbesparelseEl,
                      );

                      final resultatUdManuel = ebmpapst.EbmpapstResultat(
                        tryk: nyTrykUd,
                        luftmaengde: nyLuftUd,
                        effekt: nyEffektUd,
                        aarsforbrugKWh: nytElforbrugUd,
                        omkostning: nyOmkostningUd,
                        varenummer: 'Nyt anlæg - Udsugning',
                        kommentar: 'Helt nyt anlæg med manuel pris, virkningsgrad ${virkningsgrad.toStringAsFixed(1)}%, og alle nye specifikationer.',
                        virkningsgrad: nyVirkningsgradUd,
                        selvaerdi: nySELUd,
                        tilbagebetalingstid: tilbagebetalingstid,
                        samletOmkostning: pris / 2,
                        aarsbesparelse: aarsbesparelseEl,
                      );

                      final manuelResultat = VentilatorOekonomiSamlet(
                        anlaegstype: anlaegsType,
                        anlaegsnavn: anlaegsNavn,
                        fabrikant: 'Nyt Ventilationsanlæg',
                        logoPath: 'assets/images/star_logo.png',
                        varenummerInd: '',
                        varenummerUd: '',
                        sammeVentilatorVedMax: false,
                        kommentarInd: resultatIndManuel.kommentar,
                        kommentarUd: resultatUdManuel.kommentar,
                        oekonomi: OekonomiResultat(
                          anlaegstype: anlaegsType,
                          anlaegsnavn: anlaegsNavn,
                          omkostningFoer: omkostningInd + omkostningUd,
                          varenummer: '',
                          tilbagebetalingstid: tilbagebetalingstid,
                          aarsforbrugKWh: nytElforbrugInd + nytElforbrugUd,
                          omkostning: nyOmkostningInd + nyOmkostningUd + (nytVarmeResultat?.optimering?.nytVarmeforbrugKr ?? 0),
                          effekt: nyEffektInd + nyEffektUd,
                          tryk: (nyTrykInd + nyTrykUd) / 2,
                          luftmaengde: (nyLuftInd + nyLuftUd) / 2,
                          virkningsgrad: (nyVirkningsgradInd + nyVirkningsgradUd) / 2,
                          selvaerdi: (nySELInd + nySELUd) / 2,
                          indPris: 0,
                          udPris: 0,
                          totalPris: samletInvestering,
                          aarsbesparelse: aarsbesparelseEl,
                          varmeAarsbesparelse: nytVarmeResultat?.optimering?.besparelseKr,
                          varmeBesparelseKWh: nytVarmeResultat?.optimering?.besparelseKWh,
                          varmeforbrugKWhFoer: nytVarmeResultat?.varmeforbrugKWh,
                          varmeOmkostningFoer: nytVarmeResultat?.varmeOmkostning,
                          varmeforbrugKWHEfter: nytVarmeResultat?.optimering?.nytVarmeforbrugKWh,
                          varmeOmkostningEfter: nytVarmeResultat?.optimering?.nytVarmeforbrugKr,
                        ),
                        indNormal: resultatIndManuel,
                        indMax: resultatIndManuel,
                        udNormal: resultatUdManuel,
                        udMax: resultatUdManuel,
                        totalPris: samletInvestering,
                      );

                      alleResultater = [manuelResultat];

                    } else {
                      throw Exception('Ukendt manuel type: $manuelType');
                    }

                  } else {
                    // NORMAL DATABASE-LOOKUP - 3 fabrikanter
                    final ebmResult = ebmpapst_beregnEbmpapstVentilatorer(
                      afdeling: afd,
                      trykIndNormal: statiskTrykIndNormal,
                      luftIndNormal: luftInd,
                      trykIndMax: statiskTrykMaxInd ?? 0,
                      luftIndMax: luftIndMax ?? 0,
                      trykUdNormal: statiskTrykUdNormal,
                      luftUdNormal: luftUd,
                      trykUdMax: statiskTrykMaxUd ?? 0,
                      luftUdMax: luftUdMax ?? 0,
                      fradragRemtrukket: remUdskiftningPris ?? 0,
                      driftstimer: driftstimer.toInt(),
                      elpris: elpris,
                      omkostningInd: omkostningInd,
                      omkostningUd: omkostningUd,
                      anlaegsNavn: anlaegsNavn,
                      anlaegstype: anlaegsType,
                      projektInfo: projektInfo,
                    );

                    final novResult = novenco_beregnNovencoVentilatorer(
                      afdeling: afd,
                      trykIndNormal: statiskTrykIndNormal,
                      luftIndNormal: luftInd,
                      trykIndMax: statiskTrykMaxInd ?? 0,
                      luftIndMax: luftIndMax ?? 0,
                      trykUdNormal: statiskTrykUdNormal,
                      luftUdNormal: luftUd,
                      trykUdMax: statiskTrykMaxUd ?? 0,
                      luftUdMax: luftUdMax ?? 0,
                      fradragRemtrukket: remUdskiftningPris ?? 0,
                      driftstimer: driftstimer.toInt(),
                      elpris: elpris,
                      omkostningInd: omkostningInd,
                      omkostningUd: omkostningUd,
                      anlaegsNavn: anlaegsNavn,
                      anlaegstype: anlaegsType,
                      projektInfo: projektInfo,
                    );

                    final ziehlResult = ziehl_beregnZiehlVentilatorer(
                      afdeling: afd,
                      trykIndNormal: statiskTrykIndNormal,
                      luftIndNormal: luftInd,
                      trykIndMax: statiskTrykMaxInd ?? 0,
                      luftIndMax: luftIndMax ?? 0,
                      trykUdNormal: statiskTrykUdNormal,
                      luftUdNormal: luftUd,
                      trykUdMax: statiskTrykMaxUd ?? 0,
                      luftUdMax: luftUdMax ?? 0,
                      fradragRemtrukket: remUdskiftningPris ?? 0,
                      driftstimer: driftstimer.toInt(),
                      elpris: elpris,
                      omkostningInd: omkostningInd,
                      omkostningUd: omkostningUd,
                      anlaegsNavn: anlaegsNavn,
                      anlaegstype: anlaegsType,
                      projektInfo: projektInfo,
                    );

                    alleResultater = [ebmResult, novResult, ziehlResult];
                  }

                  final gyldigeResultater = alleResultater.where(erGyldigtVentilatorForslag).toList();

                  // 🟢 SORTER EFTER TILBAGEBETALINGSTID (korteste først = bedste tilbud først)
                  gyldigeResultater.sort((a, b) {
                    final tbtA = (a.oekonomi as OekonomiResultat).tilbagebetalingstid;
                    final tbtB = (b.oekonomi as OekonomiResultat).tilbagebetalingstid;
                    return tbtA.compareTo(tbtB);
                  });

                  final antalGyldige = gyldigeResultater.length;

                  // Find manglende fabrikanter
                  final alleFabrikanter = ['Ebmpapst', 'Novenco', 'Ziehl-Abegg'];
                  final gyldigeFabrikanter = gyldigeResultater.map((f) => f.fabrikant).toSet();
                  final manglenedFabrikanter = alleFabrikanter.where((f) => !gyldigeFabrikanter.contains(f)).toList();

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Hvis manuel indtastning OG gyldige - vis info boks
                        if (erManuelIndtastning && antalGyldige > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'SKRÆDDERSYET LØSNING',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Dette anlæg kræver en specialløsning, da der ikke findes standardprodukter der matcher behovet.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  manuelType == 'ventilatorer'
                                      ? '✓ Udskiftning af ventilatorer med manuel pris og effekt'
                                      : '✓ Helt nyt anlæg med alle specifikationer indtastet manuelt',
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Hvis 0 matches OG IKKE manuel - vis specialanlæg besked
                        if (!erManuelIndtastning && antalGyldige == 0) ...[
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
                                Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.orange, size: 28),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'SPECIALANLÆG',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Dette anlæg ligger uden for standardløsningerne fra vores leverandører.',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 12),
                                const Text('Årsag:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('• Luftmængde: ${formatNumber(luftInd > 0 ? luftInd : luftUd)} m³/h'),
                                Text('• Tryk: ${formatNumber(statiskTrykIndNormal > 0 ? statiskTrykIndNormal : statiskTrykUdNormal)} Pa'),
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
                        ] else ...[
                          // Vis gyldige kort
                          ...gyldigeResultater.map((resultat) {
                            // 🆕 Specialhåndtering af manuel indtastning - BRAVIDA LOGO
                            final String logoAsset = erManuelIndtastning
                                ? 'assets/images/star_logo.png'
                                : resultat.fabrikant == 'Ebmpapst'
                                ? 'assets/images/ebmpapst_trans_2.png'
                                : resultat.fabrikant == 'Novenco'
                                ? 'assets/images/novenco.png'
                                : 'assets/images/ziehlabegg.png';

                            final double logoHeight = erManuelIndtastning
                                ? 40
                                : resultat.fabrikant == 'Ebmpapst'
                                ? 120
                                : resultat.fabrikant == 'Novenco'
                                ? 130
                                : 200;

                            final double logoWidth = erManuelIndtastning
                                ? 40
                                : resultat.fabrikant == 'Ebmpapst'
                                ? 100
                                : resultat.fabrikant == 'Novenco'
                                ? 110
                                : 160;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: VentilatorOekonomiKort(
                                resultat: resultat,
                                logoAsset: logoAsset,
                                producentNavn:  '',
                                logoHeight: logoHeight,
                                logoWidth: logoWidth,
                                resultatInd: resultat.indNormal,
                                resultatUd: resultat.udNormal,
                                resultatMaxInd: resultat.indMax,
                                resultatMaxUd: resultat.udMax,
                                samletAarsforbrugKWh: resultat.indNormal.aarsforbrugKWh + resultat.udNormal.aarsforbrugKWh,
                                samletOmkostning: resultat.indNormal.omkostning + resultat.udNormal.omkostning,
                                anlaegsType: resultat.anlaegstype,
                              ),
                            );
                          }),

                          // Note hvis 1-2 fabrikanter mangler
                          if (antalGyldige < 3 && !erManuelIndtastning) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
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
                        ],

                        if (kammerHoede != null && kammerLaengde != null && kammerBredde != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Opmåling af ventilatorkammer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Image.asset(
                            'assets/images/opmaaling_af_ventilatorkammer.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text('Højde: ${kammerHoede!.toStringAsFixed(0)} mm'),
                          Text('Længde: ${kammerLaengde!.toStringAsFixed(0)} mm'),
                          Text('Bredde: ${kammerBredde!.toStringAsFixed(0)} mm'),
                        ],
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              // 🔹 NY LOGIK: Hvis ingen gyldige forslag (SPECIALANLÆG), gem kun før-data og hop videre
                              if (antalGyldige == 0) {
                                // Gem før-situationen
                                final nytAnlaeg = anlaeg.copyWith(
                                  anlaegsNavn: anlaegsNavn,
                                  ventMaerkatNr: eksisterendeVarenummerInd,
                                  valgtAnlaegstype: anlaegsType,
                                  luftInd: luftInd,
                                  luftUd: luftUd,
                                  trykInd: statiskTrykInd,
                                  trykUd: statiskTrykUd,
                                  kwInd: kwInd,
                                  kwUd: kwUd,
                                  hzInd: hzInd,
                                  hzUd: hzUd,
                                  elpris: projektInfo.elPris,
                                  varmepris: projektInfo.varmePris,
                                  elOmkostningIndFoer: omkostningInd,
                                  elOmkostningUdFoer: omkostningUd,
                                  omkostningFoer: omkostningInd + omkostningUd,
                                  remUdskiftningPris: remUdskiftningPris,
                                  varmeResultat: varmeforbrugResultat,
                                  varmeforbrugKWhFoer: varmeforbrugResultat?.varmeforbrugKWh,
                                  varmeOmkostningFoer: varmeforbrugResultat?.varmeOmkostning,
                                  varmeAarsbesparelse: varmeforbrugResultat?.optimering?.besparelseKr,
                                  varmeBesparelseKWh: varmeforbrugResultat?.optimering?.besparelseKWh,
                                  varmeforbrugKWHEfter: varmeforbrugResultat?.optimering?.nytVarmeforbrugKWh,
                                  varmeOmkostningEfter: varmeforbrugResultat?.optimering?.nytVarmeforbrugKr,
                                  kammerBredde: kammerBredde ?? 0,
                                  kammerHoede: kammerHoede ?? 0,
                                  kammerLaengde: kammerLaengde ?? 0,
                                  valgtTilstand: valgtTilstand,
                                  erBeregnetInd: erBeregnetInd,
                                  erBeregnetUd: erBeregnetUd,
                                  dokumentation: anlaeg.dokumentation,
                                  antalHeleFiltreInd: anlaeg.antalHeleFiltreInd,
                                  antalHalveFiltreInd: anlaeg.antalHalveFiltreInd,
                                  antalHeleFiltreUd: anlaeg.antalHeleFiltreUd,
                                  antalHalveFiltreUd: anlaeg.antalHalveFiltreUd,
                                  trykGamleFiltreInd: anlaeg.trykGamleFiltreInd,
                                  trykGamleFiltreUd: anlaeg.trykGamleFiltreUd,
                                  filterValg: anlaeg.filterValg,
                                  filterResultat: anlaeg.filterResultat,
                                  driftstimer: driftstimer,
                                  virkningsgradInd: virkningsgradInd,
                                  virkningsgradUd: virkningsgradUd,
                                  erBeregnetUdFraKVaerdiInd: erBeregnetUdFraKVaerdiInd,
                                  erBeregnetUdFraKVaerdiUd: erBeregnetUdFraKVaerdiUd,
                                  erLuftmaengdeMaaeltIndtastetInd: this.erLuftmaengdeMaaeltIndtastetInd,
                                  erLuftmaengdeMaaeltIndtastetUd: this.erLuftmaengdeMaaeltIndtastetUd,
                                  internKommentar: internKommentar,
                                );

                                // Opdater anlæg i listen
                                if (index < projektInfo.alleAnlaeg.length) {
                                  projektInfo.alleAnlaeg[index] = nytAnlaeg;
                                } else {
                                  projektInfo.alleAnlaeg.add(nytAnlaeg);
                                }

                                final nyeAlleAnlaeg = List<AnlaegsData>.from(alleAnlaeg);
                                if (index < nyeAlleAnlaeg.length) {
                                  nyeAlleAnlaeg[index] = nytAnlaeg;
                                } else {
                                  nyeAlleAnlaeg.add(nytAnlaeg);
                                }

                                // Tilføj til forslag-listen
                                final opdateretForslag = List<VentilatorOekonomiSamlet>.from(forslag);
                                opdateretForslag.removeWhere((f) => f.anlaegsnavn == anlaegsNavn);

                                // Opret dummy forslag
                                final ebmResult = ebmpapst_beregnEbmpapstVentilatorer(
                                  afdeling: afd,
                                  trykIndNormal: statiskTrykIndNormal,
                                  luftIndNormal: luftInd,
                                  trykIndMax: statiskTrykMaxInd ?? 0,
                                  luftIndMax: luftIndMax ?? 0,
                                  trykUdNormal: statiskTrykUdNormal,
                                  luftUdNormal: luftUd,
                                  trykUdMax: statiskTrykMaxUd ?? 0,
                                  luftUdMax: luftUdMax ?? 0,
                                  fradragRemtrukket: remUdskiftningPris ?? 0,
                                  driftstimer: driftstimer.toInt(),
                                  elpris: elpris,
                                  omkostningInd: omkostningInd,
                                  omkostningUd: omkostningUd,
                                  anlaegsNavn: anlaegsNavn,
                                  anlaegstype: anlaegsType,
                                  projektInfo: projektInfo,
                                );

                                final dummyForslag = VentilatorOekonomiSamlet(
                                  anlaegstype: anlaegsType,
                                  anlaegsnavn: anlaegsNavn,
                                  fabrikant: 'Ingen',
                                  logoPath: '',
                                  varenummerInd: '',
                                  varenummerUd: '',
                                  sammeVentilatorVedMax: false,
                                  kommentarInd: '',
                                  kommentarUd: '',
                                  oekonomi: OekonomiResultat(
                                    anlaegstype: anlaegsType,
                                    anlaegsnavn: anlaegsNavn,
                                    omkostningFoer: omkostningInd + omkostningUd,
                                    varenummer: '',
                                    tilbagebetalingstid: double.infinity,
                                    aarsforbrugKWh: 0,
                                    omkostning: omkostningInd + omkostningUd,
                                    effekt: 0,
                                    tryk: 0,
                                    luftmaengde: 0,
                                    virkningsgrad: 0,
                                    selvaerdi: 0,
                                    indPris: 0,
                                    udPris: 0,
                                    totalPris: 0,
                                    aarsbesparelse: 0,
                                  ),
                                  indNormal: ebmResult.indNormal,
                                  indMax: ebmResult.indMax,
                                  udNormal: ebmResult.udNormal,
                                  udMax: ebmResult.udMax,
                                  totalPris: 0,
                                );
                                opdateretForslag.add(dummyForslag);

                                // Check filtre
                                final bool harFiltre = (antalHeleFiltreInd ?? 0) > 0 ||
                                    (antalHalveFiltreInd ?? 0) > 0 ||
                                    (antalHeleFiltreUd ?? 0) > 0 ||
                                    (antalHalveFiltreUd ?? 0) > 0;

                                final int naesteIndex = projektInfo.index + 1;
                                final bool erSidsteAnlaeg = naesteIndex >= projektInfo.alleAnlaeg.length;

                                if (harFiltre) {
                                  if (erSidsteAnlaeg) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FilterResultatSkarm(
                                          anlaeg: nytAnlaeg,
                                          projektInfo: projektInfo,
                                          antalHeleFiltreInd: antalHeleFiltreInd ?? 0,
                                          antalHalveFiltreInd: antalHalveFiltreInd ?? 0,
                                          antalHeleFiltreUd: antalHeleFiltreUd ?? 0,
                                          antalHalveFiltreUd: antalHalveFiltreUd ?? 0,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FilterSkarm(
                                          alleAnlaeg: nyeAlleAnlaeg,
                                          index: index,
                                          anlaeg: nytAnlaeg,
                                          projektInfo: projektInfo,
                                          antalHeleFiltreInd: antalHeleFiltreInd ?? 0,
                                          antalHalveFiltreInd: antalHalveFiltreInd ?? 0,
                                          antalHeleFiltreUd: antalHeleFiltreUd ?? 0,
                                          antalHalveFiltreUd: antalHalveFiltreUd ?? 0,
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                // Ingen filtre - vis dialog
                                final resultat = await visVilDuFortsatteDialog(context, erSidsteAnlaeg: erSidsteAnlaeg);

                                if (resultat == DialogResultat.afslut) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AnlaegsOversigtSkarm(
                                        alleForslag: opdateretForslag,
                                        elPris: projektInfo.elPris,
                                        varmePris: projektInfo.varmePris,
                                        projektInfo: projektInfo,
                                      ),
                                    ),
                                  );
                                } else if (resultat == DialogResultat.fortsaet) {
                                  if (!erSidsteAnlaeg) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MaaledataSkarm(
                                          forslag: opdateretForslag,
                                          projektInfo: projektInfo.copyWithIndex(naesteIndex),
                                          index: naesteIndex,
                                          alleAnlaeg: nyeAlleAnlaeg,
                                          driftstimer: this.driftstimer,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AnlaegsOversigtSkarm(
                                          alleForslag: opdateretForslag,
                                          elPris: projektInfo.elPris,
                                          varmePris: projektInfo.varmePris,
                                          projektInfo: projektInfo,
                                        ),
                                      ),
                                    );
                                  }
                                } else if (resultat == DialogResultat.tilfoejEkstra) {
                                  final nytEkstraAnlaeg = AnlaegsData.empty();
                                  projektInfo.alleAnlaeg.add(nytEkstraAnlaeg);
                                  nyeAlleAnlaeg.add(nytEkstraAnlaeg);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaaledataSkarm(
                                        forslag: opdateretForslag,
                                        projektInfo: projektInfo.copyWithIndex(projektInfo.alleAnlaeg.length - 1),
                                        index: projektInfo.alleAnlaeg.length - 1,
                                        alleAnlaeg: nyeAlleAnlaeg,
                                        driftstimer: this.driftstimer,
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              // ✅✅✅ HER ER RETTELSEN - BRUG alleResultater I STEDET FOR AT GENBEREGNE ✅✅✅
                              final opdateretForslag = List<VentilatorOekonomiSamlet>.from(forslag);
                              opdateretForslag.removeWhere((f) => f.anlaegsnavn == anlaegsNavn);
                              opdateretForslag.addAll(alleResultater);  // ✅ BRUG alleResultater FRA BUILDER!

                              final double samletFoerKr = omkostningInd + omkostningUd;

                              final samletEfterKrListe = [
                                samletEfterKrEbmpapst,
                                samletEfterKrNovenco,
                                samletEfterKrZiehl,
                              ].where((v) => v > 0).toList();

                              final double samletEfterKrMin = samletEfterKrListe.isNotEmpty
                                  ? samletEfterKrListe.reduce((a, b) => a < b ? a : b)
                                  : 0.0;

                              final nytAnlaeg = anlaeg.copyWith(
                                anlaegsNavn: anlaegsNavn,
                                ventMaerkatNr: eksisterendeVarenummerInd,
                                valgtAnlaegstype: anlaegsType,
                                aarsbesparelse: aarsbesparelse,
                                tilbagebetalingstid: tilbagebetalingstid,
                                luftInd: luftInd,
                                luftUd: luftUd,
                                trykInd: statiskTrykInd,
                                trykUd: statiskTrykUd,
                                kwInd: kwInd,
                                kwUd: kwUd,
                                hzInd: hzInd,
                                hzUd: hzUd,
                                elpris: projektInfo.elPris,
                                varmepris: projektInfo.varmePris,
                                elOmkostningIndFoer: omkostningInd,
                                elOmkostningUdFoer: omkostningUd,
                                omkostningFoer: samletFoerKr,
                                omkostningEfter: samletEfterKrMin,
                                remUdskiftningPris: remUdskiftningPris,
                                eksisterendeVarenummerInd: eksisterendeVarenummerInd,
                                eksisterendeVarenummerUd: eksisterendeVarenummerUd,
                                varmeResultat: nytVarmeResultat ?? varmeforbrugResultat,
                                varmeAarsbesparelse: (nytVarmeResultat ?? varmeforbrugResultat)?.optimering?.besparelseKr,
                                varmeBesparelseKWh: (nytVarmeResultat ?? varmeforbrugResultat)?.optimering?.besparelseKWh,
                                varmeforbrugKWhFoer: (nytVarmeResultat ?? varmeforbrugResultat)?.varmeforbrugKWh,
                                varmeOmkostningFoer: (nytVarmeResultat ?? varmeforbrugResultat)?.varmeOmkostning,
                                varmeforbrugKWHEfter: (nytVarmeResultat ?? varmeforbrugResultat)?.optimering?.nytVarmeforbrugKWh,
                                varmeOmkostningEfter: (nytVarmeResultat ?? varmeforbrugResultat)?.optimering?.nytVarmeforbrugKr,
                                trykFoerIndMax: trykFoerIndMax,
                                trykEfterIndMax: trykEfterIndMax,
                                trykFoerUdMax: trykFoerUdMax,
                                trykEfterUdMax: trykEfterUdMax,
                                luftIndMax: luftIndMax,
                                luftUdMax: luftUdMax,
                                kammerBredde: kammerBredde ?? 0,
                                kammerHoede: kammerHoede ?? 0,
                                kammerLaengde: kammerLaengde ?? 0,
                                valgtTilstand: valgtTilstand,
                                erBeregnetInd: erBeregnetInd,
                                erBeregnetUd: erBeregnetUd,
                                dokumentation: anlaeg.dokumentation,
                                antalHeleFiltreInd: anlaeg.antalHeleFiltreInd,
                                antalHalveFiltreInd: anlaeg.antalHalveFiltreInd,
                                antalHeleFiltreUd: anlaeg.antalHeleFiltreUd,
                                antalHalveFiltreUd: anlaeg.antalHalveFiltreUd,
                                trykGamleFiltreInd: anlaeg.trykGamleFiltreInd,
                                trykGamleFiltreUd: anlaeg.trykGamleFiltreUd,
                                filterValg: anlaeg.filterValg,
                                filterResultat: anlaeg.filterResultat,
                                driftstimer: driftstimer,
                                virkningsgradInd: virkningsgradInd,
                                virkningsgradUd: virkningsgradUd,
                                erBeregnetUdFraKVaerdiInd: erBeregnetUdFraKVaerdiInd,
                                erBeregnetUdFraKVaerdiUd: erBeregnetUdFraKVaerdiUd,
                                erLuftmaengdeMaaeltIndtastetInd: this.erLuftmaengdeMaaeltIndtastetInd,
                                erLuftmaengdeMaaeltIndtastetUd: this.erLuftmaengdeMaaeltIndtastetUd,
                                internKommentar: internKommentar,
                              );

                              if (index < projektInfo.alleAnlaeg.length) {
                                projektInfo.alleAnlaeg[index] = nytAnlaeg;
                              } else {
                                projektInfo.alleAnlaeg.add(nytAnlaeg);
                              }

                              final nyeAlleAnlaeg = List<AnlaegsData>.from(alleAnlaeg);
                              if (index < nyeAlleAnlaeg.length) {
                                nyeAlleAnlaeg[index] = nytAnlaeg;
                              } else {
                                nyeAlleAnlaeg.add(nytAnlaeg);
                              }

                              final bool harFiltre = (antalHeleFiltreInd ?? 0) > 0 ||
                                  (antalHalveFiltreInd ?? 0) > 0 ||
                                  (antalHeleFiltreUd ?? 0) > 0 ||
                                  (antalHalveFiltreUd ?? 0) > 0;

                              final int naesteIndex = projektInfo.index + 1;
                              final bool erSidsteAnlaeg = naesteIndex >= projektInfo.alleAnlaeg.length;

                              if (harFiltre) {
                                if (erSidsteAnlaeg) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterResultatSkarm(
                                        anlaeg: nytAnlaeg,
                                        projektInfo: projektInfo,
                                        antalHeleFiltreInd: antalHeleFiltreInd ?? 0,
                                        antalHalveFiltreInd: antalHalveFiltreInd ?? 0,
                                        antalHeleFiltreUd: antalHeleFiltreUd ?? 0,
                                        antalHalveFiltreUd: antalHalveFiltreUd ?? 0,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterSkarm(
                                        alleAnlaeg: nyeAlleAnlaeg,
                                        index: index,
                                        anlaeg: nytAnlaeg,
                                        projektInfo: projektInfo,
                                        antalHeleFiltreInd: antalHeleFiltreInd ?? 0,
                                        antalHalveFiltreInd: antalHalveFiltreInd ?? 0,
                                        antalHeleFiltreUd: antalHeleFiltreUd ?? 0,
                                        antalHalveFiltreUd: antalHalveFiltreUd ?? 0,
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              final resultat = await visVilDuFortsatteDialog(context, erSidsteAnlaeg: erSidsteAnlaeg);

                              if (resultat == DialogResultat.afslut) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AnlaegsOversigtSkarm(
                                      alleForslag: opdateretForslag,
                                      elPris: projektInfo.elPris,
                                      varmePris: projektInfo.varmePris,
                                      projektInfo: projektInfo,
                                    ),
                                  ),
                                );
                              } else if (resultat == DialogResultat.fortsaet) {
                                if (!erSidsteAnlaeg) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaaledataSkarm(
                                        forslag: opdateretForslag,
                                        projektInfo: projektInfo.copyWithIndex(naesteIndex),
                                        index: naesteIndex,
                                        alleAnlaeg: nyeAlleAnlaeg,
                                        driftstimer: this.driftstimer,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AnlaegsOversigtSkarm(
                                        alleForslag: opdateretForslag,
                                        elPris: projektInfo.elPris,
                                        varmePris: projektInfo.varmePris,
                                        projektInfo: projektInfo,
                                      ),
                                    ),
                                  );
                                }
                              } else if (resultat == DialogResultat.tilfoejEkstra) {
                                final nytEkstraAnlaeg = AnlaegsData.empty();

                                projektInfo.alleAnlaeg.add(nytEkstraAnlaeg);
                                nyeAlleAnlaeg.add(nytEkstraAnlaeg);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MaaledataSkarm(
                                      forslag: opdateretForslag,
                                      projektInfo: projektInfo.copyWithIndex(projektInfo.alleAnlaeg.length - 1),
                                      index: projektInfo.alleAnlaeg.length - 1,
                                      alleAnlaeg: nyeAlleAnlaeg,
                                      driftstimer: this.driftstimer,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34E0A1),
                              foregroundColor: const Color(0xFF006390),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: Text(
                              (projektInfo.index + 1) < projektInfo.alleAnlaeg.length
                                  ? 'Gem og fortsæt med næste anlæg'
                                  : 'Gem og afslut',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DialogResultat?> visVilDuFortsatteDialog(BuildContext context, {required bool erSidsteAnlaeg}) async {
  const Color primaryGreen = Color(0xFF34E0A1);
  const Color primaryBlue = Color(0xFF006390);

  return await showDialog<DialogResultat>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Text(
            'Hvad vil du gøre nu?',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Text(
            erSidsteAnlaeg
                ? 'Du har gennemført alle anlæg. Vil du afslutte eller tilføje flere anlæg?'
                : 'Vælg hvad du vil gøre efter dette anlæg:',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Afslut',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(DialogResultat.afslut),
          ),
          if (!erSidsteAnlaeg)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Næste anlæg',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(DialogResultat.fortsaet),
            ),
          if (erSidsteAnlaeg)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Ekstra anlæg',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              onPressed: () => Navigator.of(dialogContext).pop(DialogResultat.tilfoejEkstra),
            ),
        ],
      );
    },
  );
}

