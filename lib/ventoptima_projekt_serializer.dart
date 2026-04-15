import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'anlaegs_data.dart';
import 'generel_projekt_info.dart';
import 'filter_resultat.dart';

// ─────────────────────────────────────────────
// SERIALISERING AF AnlaegsData
// ─────────────────────────────────────────────
Map<String, dynamic> anlaegsDataToJson(AnlaegsData d) => {
  'anlaegsNavn': d.anlaegsNavn,
  'ventMaerkatNr': d.ventMaerkatNr,
  'valgtAnlaegstype': d.valgtAnlaegstype,
  'aarsbesparelse': d.aarsbesparelse,
  'tilbagebetalingstid': d.tilbagebetalingstid,
  'luftInd': d.luftInd,
  'luftUd': d.luftUd,
  'trykInd': d.trykInd,
  'trykUd': d.trykUd,
  'kwInd': d.kwInd,
  'kwUd': d.kwUd,
  'hzInd': d.hzInd,
  'hzUd': d.hzUd,
  'elpris': d.elpris,
  'varmepris': d.varmepris,
  'trykFoerIndMax': d.trykFoerIndMax,
  'trykEfterIndMax': d.trykEfterIndMax,
  'trykFoerUdMax': d.trykFoerUdMax,
  'trykEfterUdMax': d.trykEfterUdMax,
  'luftIndMax': d.luftIndMax,
  'luftUdMax': d.luftUdMax,
  'kVaerdiInd': d.kVaerdiInd,
  'kVaerdiUd': d.kVaerdiUd,
  'maksLuftInd': d.maksLuftInd,
  'maksLuftUd': d.maksLuftUd,
  'maksEffektInd': d.maksEffektInd,
  'maksEffektUd': d.maksEffektUd,
  'effektMaaltInd': d.effektMaaltInd,
  'effektMaaltUd': d.effektMaaltUd,
  'trykDifferensInd': d.trykDifferensInd,
  'trykDifferensUd': d.trykDifferensUd,
  'trykGamleFiltreInd': d.trykGamleFiltreInd,
  'trykGamleFiltreUd': d.trykGamleFiltreUd,
  'antalHeleFiltreInd': d.antalHeleFiltreInd,
  'antalHalveFiltreInd': d.antalHalveFiltreInd,
  'antalHeleFiltreUd': d.antalHeleFiltreUd,
  'antalHalveFiltreUd': d.antalHalveFiltreUd,
  'kammerBredde': d.kammerBredde,
  'kammerHoede': d.kammerHoede,
  'kammerLaengde': d.kammerLaengde,
  'valgtTilstand': d.valgtTilstand,
  'erBeregnetInd': d.erBeregnetInd,
  'erBeregnetUd': d.erBeregnetUd,
  'erBeregnetUdFraKVaerdiInd': d.erBeregnetUdFraKVaerdiInd,
  'erBeregnetUdFraKVaerdiUd': d.erBeregnetUdFraKVaerdiUd,
  'erLuftmaengdeMaaeltIndtastetInd': d.erLuftmaengdeMaaeltIndtastetInd,
  'erLuftmaengdeMaaeltIndtastetUd': d.erLuftmaengdeMaaeltIndtastetUd,
  'remUdskiftningPris': d.remUdskiftningPris,
  'omkostningFoer': d.omkostningFoer,
  'omkostningEfter': d.omkostningEfter,
  'eksisterendeVarenummerInd': d.eksisterendeVarenummerInd,
  'eksisterendeVarenummerUd': d.eksisterendeVarenummerUd,
  'internKommentar': d.internKommentar,
  'recirkuleringProcent': d.recirkuleringProcent,
  'friskluftTemp': d.friskluftTemp,
  'tempUd': d.tempUd,
  'tempIndEfterGenvinding': d.tempIndEfterGenvinding,
  'tempIndEfterVarmeflade': d.tempIndEfterVarmeflade,
  'filterKammerLaengdeInd': d.filterKammerLaengdeInd,
  'filterKammerLaengdeUd': d.filterKammerLaengdeUd,
  'driftstimer': d.driftstimer,
  // FilterValg
  'filterValg': d.filterValg == null ? null : {
    'filterFoerInd': d.filterValg!.filterFoerInd,
    'filterFoerUd': d.filterValg!.filterFoerUd,
    'filterMaalIndMm': d.filterValg!.filterMaalIndMm,
    'filterMaalUdMm': d.filterValg!.filterMaalUdMm,
  },
};

AnlaegsData anlaegsDataFromJson(Map<String, dynamic> j) => AnlaegsData(
  anlaegsNavn: j['anlaegsNavn'] ?? '',
  ventMaerkatNr: j['ventMaerkatNr'] ?? '',
  valgtAnlaegstype: j['valgtAnlaegstype'] ?? 'Ventilationsanlæg',
  aarsbesparelse: (j['aarsbesparelse'] ?? 0).toDouble(),
  tilbagebetalingstid: (j['tilbagebetalingstid'] ?? 0).toDouble(),
  luftInd: (j['luftInd'] ?? 0).toDouble(),
  luftUd: (j['luftUd'] ?? 0).toDouble(),
  trykInd: (j['trykInd'] ?? 0).toDouble(),
  trykUd: (j['trykUd'] ?? 0).toDouble(),
  kwInd: (j['kwInd'] ?? 0).toDouble(),
  kwUd: (j['kwUd'] ?? 0).toDouble(),
  hzInd: (j['hzInd'] ?? 0).toDouble(),
  hzUd: (j['hzUd'] ?? 0).toDouble(),
  elpris: (j['elpris'] ?? 0).toDouble(),
  varmepris: (j['varmepris'] ?? 0).toDouble(),
  trykFoerIndMax: j['trykFoerIndMax']?.toDouble(),
  trykEfterIndMax: j['trykEfterIndMax']?.toDouble(),
  trykFoerUdMax: j['trykFoerUdMax']?.toDouble(),
  trykEfterUdMax: j['trykEfterUdMax']?.toDouble(),
  luftIndMax: j['luftIndMax']?.toDouble(),
  luftUdMax: j['luftUdMax']?.toDouble(),
  kVaerdiInd: j['kVaerdiInd']?.toDouble(),
  kVaerdiUd: j['kVaerdiUd']?.toDouble(),
  maksLuftInd: j['maksLuftInd']?.toDouble(),
  maksLuftUd: j['maksLuftUd']?.toDouble(),
  maksEffektInd: j['maksEffektInd']?.toDouble(),
  maksEffektUd: j['maksEffektUd']?.toDouble(),
  effektMaaltInd: j['effektMaaltInd']?.toDouble(),
  effektMaaltUd: j['effektMaaltUd']?.toDouble(),
  trykDifferensInd: j['trykDifferensInd']?.toDouble(),
  trykDifferensUd: j['trykDifferensUd']?.toDouble(),
  trykGamleFiltreInd: j['trykGamleFiltreInd']?.toDouble(),
  trykGamleFiltreUd: j['trykGamleFiltreUd']?.toDouble(),
  antalHeleFiltreInd: j['antalHeleFiltreInd'],
  antalHalveFiltreInd: j['antalHalveFiltreInd'],
  antalHeleFiltreUd: j['antalHeleFiltreUd'],
  antalHalveFiltreUd: j['antalHalveFiltreUd'],
  kammerBredde: (j['kammerBredde'] ?? 0).toDouble(),
  kammerHoede: (j['kammerHoede'] ?? 0).toDouble(),
  kammerLaengde: (j['kammerLaengde'] ?? 0).toDouble(),
  valgtTilstand: j['valgtTilstand'] ?? '1',
  erBeregnetInd: j['erBeregnetInd'] ?? false,
  erBeregnetUd: j['erBeregnetUd'] ?? false,
  erBeregnetUdFraKVaerdiInd: j['erBeregnetUdFraKVaerdiInd'] ?? false,
  erBeregnetUdFraKVaerdiUd: j['erBeregnetUdFraKVaerdiUd'] ?? false,
  erLuftmaengdeMaaeltIndtastetInd: j['erLuftmaengdeMaaeltIndtastetInd'] ?? false,
  erLuftmaengdeMaaeltIndtastetUd: j['erLuftmaengdeMaaeltIndtastetUd'] ?? false,
  remUdskiftningPris: j['remUdskiftningPris']?.toDouble(),
  omkostningFoer: (j['omkostningFoer'] ?? 0).toDouble(),
  omkostningEfter: (j['omkostningEfter'] ?? 0).toDouble(),
  eksisterendeVarenummerInd: j['eksisterendeVarenummerInd'] ?? '',
  eksisterendeVarenummerUd: j['eksisterendeVarenummerUd'] ?? '',
  internKommentar: j['internKommentar'],
  recirkuleringProcent: j['recirkuleringProcent']?.toDouble(),
  friskluftTemp: (j['friskluftTemp'] ?? 0).toDouble(),
  tempUd: (j['tempUd'] ?? 0).toDouble(),
  tempIndEfterGenvinding: (j['tempIndEfterGenvinding'] ?? 0).toDouble(),
  tempIndEfterVarmeflade: (j['tempIndEfterVarmeflade'] ?? 0).toDouble(),
  filterKammerLaengdeInd: j['filterKammerLaengdeInd']?.toDouble(),
  filterKammerLaengdeUd: j['filterKammerLaengdeUd']?.toDouble(),
  driftstimer: j['driftstimer']?.toDouble(),
  filterValg: j['filterValg'] == null ? null : FilterValg(
    filterFoerInd: j['filterValg']['filterFoerInd'],
    filterFoerUd: j['filterValg']['filterFoerUd'],
    filterEfterInd: null,
    filterEfterUd: null,
    filterMaalIndMm: j['filterValg']['filterMaalIndMm']?.toDouble(),
    filterMaalUdMm: j['filterValg']['filterMaalUdMm']?.toDouble(),
  ),
);

// ─────────────────────────────────────────────
// SERIALISERING AF GenerelProjektInfo
// ─────────────────────────────────────────────
Map<String, dynamic> projektInfoToJson(GenerelProjektInfo p) => {
  'version': 1, // til fremtidig kompatibilitet
  'kundeNavn': p.kundeNavn,
  'adresse': p.adresse,
  'postnrBy': p.postnrBy,
  'att': p.att,
  'teknikerNavn': p.teknikerNavn,
  'telefon': p.telefon,
  'email': p.email,
  'afdeling': p.afdeling,
  'antalAnlaeg': p.antalAnlaeg,
  'elPris': p.elPris,
  'varmePris': p.varmePris,
  'driftTimerPrUge': p.driftTimerPrUge,
  'ugerPerAar': p.ugerPerAar,
  'driftstype': p.driftstype.index,
  'index': p.index,
  'varmegenvindingsType': p.varmegenvindingsType.index,
  'rapportDato': p.rapportDato.toIso8601String(),
  'montorNavn': p.montorNavn,
  'montorEmail': p.montorEmail,
  'rapportId': p.rapportId,
  'alleAnlaeg': p.alleAnlaeg.map(anlaegsDataToJson).toList(),
};

GenerelProjektInfo projektInfoFromJson(Map<String, dynamic> j) {
  final anlaegListe = (j['alleAnlaeg'] as List)
      .map((a) => anlaegsDataFromJson(a as Map<String, dynamic>))
      .toList();

  return GenerelProjektInfo(
    kundeNavn: j['kundeNavn'] ?? '',
    adresse: j['adresse'] ?? '',
    postnrBy: j['postnrBy'] ?? '',
    att: j['att'] ?? '',
    teknikerNavn: j['teknikerNavn'] ?? '',
    telefon: j['telefon'] ?? '',
    email: j['email'] ?? '',
    afdeling: j['afdeling'] ?? '',
    antalAnlaeg: j['antalAnlaeg'] ?? 1,
    elPris: (j['elPris'] ?? 0).toDouble(),
    varmePris: (j['varmePris'] ?? 0).toDouble(),
    driftTimerPrUge: (j['driftTimerPrUge'] as List).map((e) => (e as num).toDouble()).toList(),
    ugerPerAar: j['ugerPerAar'] ?? 52,
    driftstype: Driftstype.values[j['driftstype'] ?? 0],
    index: j['index'] ?? 0,
    alleAnlaeg: anlaegListe,
    varmegenvindingsType: VarmegenvindingType.values[j['varmegenvindingsType'] ?? 0],
    rapportDato: DateTime.parse(j['rapportDato']),
    montorNavn: j['montorNavn'],
    montorEmail: j['montorEmail'],
    rapportId: j['rapportId'],
  );
}

// ─────────────────────────────────────────────
// GEM OG INDLÆS .ventoptima FIL
// ─────────────────────────────────────────────

/// Gemmer projektet som en .ventoptima fil og returnerer filstien
Future<File> gemVentoptimaFil(GenerelProjektInfo projektInfo) async {
  final dir = await getTemporaryDirectory();
  final sikkerNavn = projektInfo.kundeNavn
      .replaceAll(RegExp(r'[^\w\æøåÆØÅ ]'), '')
      .replaceAll(' ', '_');
  final filNavn = '${sikkerNavn}_${DateTime.now().millisecondsSinceEpoch}.ventoptima';
  final fil = File('${dir.path}/$filNavn');

  final json = jsonEncode(projektInfoToJson(projektInfo));
  await fil.writeAsString(json);
  return fil;
}

/// Indlæser et projekt fra en .ventoptima fil
Future<GenerelProjektInfo> indlaesVentoptimaFil(String filSti) async {
  final fil = File(filSti);
  final json = await fil.readAsString();
  final data = jsonDecode(json) as Map<String, dynamic>;
  return projektInfoFromJson(data);
}