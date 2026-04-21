import 'package:ventoptima/ebmpapst.dart' as ebmpapst;
import 'package:ventoptima/novenco.dart' as novenco;
import 'package:ventoptima/ziehlabegg.dart' as ziehlabegg;
import 'package:ventoptima/ebmpapst_priser.dart';
import 'package:ventoptima/ziehlabegg_priser.dart';
import 'package:ventoptima/afdelingsdata.dart' as afdelingsdata;
import 'package:ventoptima/beregning_varmeforbrug.dart';
import 'package:ventoptima/generel_projekt_info.dart';

abstract class BaseOekonomiResultat {
  String get varenummer;
  double get tilbagebetalingstid;
  double get aarsforbrugKWh;
  double get omkostning;
  double get effekt;
  double get tryk;
  double get luftmaengde;
  double get virkningsgrad;
  double get selvaerdi;
  double get pris;
}

class OekonomiResultat implements BaseOekonomiResultat {
  @override final String varenummer;
  @override final double tilbagebetalingstid;
  @override final double aarsforbrugKWh;
  @override final double omkostning;
  @override final double effekt;
  @override final double tryk;
  @override final double luftmaengde;
  @override final double virkningsgrad;
  @override final double selvaerdi;

  final String anlaegstype;
  final String anlaegsnavn;
  final double omkostningFoer;
  final double indPris;
  final double udPris;
  final double totalPris;
  final double aarsbesparelse;
  final double? varmeAarsbesparelse;
  final double? varmeBesparelseKWh;
  final double? varmeforbrugKWhFoer;
  final double? varmeOmkostningFoer;
  final double? varmeforbrugKWHEfter;
  final double? varmeOmkostningEfter;

  @override
  double get pris => totalPris;

  OekonomiResultat({
    required this.omkostningFoer,
    required this.varenummer,
    required this.tilbagebetalingstid,
    required this.aarsforbrugKWh,
    required this.omkostning,
    required this.effekt,
    required this.tryk,
    required this.luftmaengde,
    required this.virkningsgrad,
    required this.selvaerdi,
    required this.indPris,
    required this.udPris,
    required this.totalPris,
    required this.aarsbesparelse,
    required this.anlaegstype,
    required this.anlaegsnavn,
    this.varmeAarsbesparelse,
    this.varmeBesparelseKWh,
    this.varmeforbrugKWhFoer,
    this.varmeOmkostningFoer,
    this.varmeforbrugKWHEfter,
    this.varmeOmkostningEfter,
  });
}

class VentilatorOekonomiSamlet {
  final String anlaegstype;
  final String anlaegsnavn;
  final String fabrikant;
  final String logoPath;
  final String varenummerInd;
  final String varenummerUd;
  final bool sammeVentilatorVedMax;
  final String kommentarInd;
  final String kommentarUd;
  final BaseOekonomiResultat oekonomi;
  final BaseOekonomiResultat indNormal;
  final BaseOekonomiResultat indMax;
  final BaseOekonomiResultat udNormal;
  final BaseOekonomiResultat udMax;
  final double totalPris;
  final double? remUdskiftningPris;
  final double? varmeAarsbesparelse;
  final double? varmeBesparelseKWh;
  final double? varmeforbrugKWhFoer;
  final double? varmeOmkostningFoer;
  final double? varmeforbrugKWHEfter;
  final double? varmeOmkostningEfter;

  VentilatorOekonomiSamlet({
    required this.anlaegstype,
    required this.anlaegsnavn,
    required this.fabrikant,
    required this.logoPath,
    required this.varenummerInd,
    required this.varenummerUd,
    required this.sammeVentilatorVedMax,
    required this.kommentarInd,
    required this.kommentarUd,
    required this.oekonomi,
    required this.indNormal,
    required this.indMax,
    required this.udNormal,
    required this.udMax,
    required this.totalPris,
    this.remUdskiftningPris,
    this.varmeAarsbesparelse,
    this.varmeBesparelseKWh,
    this.varmeforbrugKWhFoer,
    this.varmeOmkostningFoer,
    this.varmeforbrugKWHEfter,
    this.varmeOmkostningEfter,
  });
}

List<VentilatorOekonomiSamlet> beregnAlleVentilatorer({
  required String anlaegsNavn,
  required String anlaegstype,
  required String fabrikant,
  required String afdeling,
  required double trykIndNormal,
  required double luftIndNormal,
  required double trykIndMax,
  required double luftIndMax,
  required double trykUdNormal,
  required double luftUdNormal,
  required double trykUdMax,
  required double luftUdMax,
  required double omkostningInd,
  required double omkostningUd,
  required double fradragRemtrukket,
  required int driftstimer,
  required double elpris,
  required GenerelProjektInfo projektInfo,
}) {
  final List<VentilatorOekonomiSamlet> resultater = [];

  void tilfoej({
    required String fabrikant,
    required String logoPath,
    required BaseOekonomiResultat indNormal,
    required BaseOekonomiResultat indMax,
    required BaseOekonomiResultat udNormal,
    required BaseOekonomiResultat udMax,
  }) {

    final sammeInd = indNormal.varenummer == indMax.varenummer;
    final sammeUd = udNormal.varenummer == udMax.varenummer;

    final afdelingsInfo = afdelingsdata.afdelingsData[afdeling]!;
    final double materialePris = afdelingsInfo.materialePris;
    final double daekning = afdelingsInfo.daekningProcent / 100;
    final double timer = afdelingsInfo.montagetimer;
    final double timeloen = afdelingsInfo.timeloen;

    // Pris for indblæsning
    // Pris for indblæsning
    double indPris = 0.0;
    if (fabrikant == 'Ebmpapst') {
      final double ventilatorPrisInd =
          ebmpapstPriser[indNormal.varenummer]?.toDouble() ?? 0.0;

      indPris = indNormal.varenummer.isEmpty
          ? 0
          : ((ventilatorPrisInd + materialePris) * (1 + daekning)) +
          (timer * timeloen);

    } else if (fabrikant == 'Ziehl-Abegg') {
      // Brug den korrekte funktion, som håndterer 2x osv.
      final ziehlOekonomi = beregnZiehlOekonomi(
        afdeling: afdeling,
        varenummerInd: indNormal.varenummer,
        varenummerUd: udNormal.varenummer,
        omkostningInd: omkostningInd,
        omkostningUd: omkostningUd,
        fradragRemtrukket: fradragRemtrukket,
      );
      indPris = ziehlOekonomi.indPris;

    } else {
      // Novenco eller andre
      indPris = indNormal.varenummer.isEmpty
          ? 0
          : ((indNormal.pris + materialePris) * (1 + daekning)) +
          (timer * timeloen);
    }

// Pris for udsugning
    double udPris = 0.0;
    if (fabrikant == 'Ebmpapst') {
      final double ventilatorPrisUd =
          ebmpapstPriser[udNormal.varenummer]?.toDouble() ?? 0.0;

      udPris = udNormal.varenummer.isEmpty
          ? 0
          : ((ventilatorPrisUd + materialePris) * (1 + daekning)) +
          (timer * timeloen);

    } else if (fabrikant == 'Ziehl-Abegg') {
      // Brug den korrekte funktion, som håndterer 2x osv.
      final ziehlOekonomi = beregnZiehlOekonomi(
        afdeling: afdeling,
        varenummerInd: indNormal.varenummer,
        varenummerUd: udNormal.varenummer,
        omkostningInd: omkostningInd,
        omkostningUd: omkostningUd,
        fradragRemtrukket: fradragRemtrukket,
      );
      udPris = ziehlOekonomi.udPris;

    } else {
      udPris = udNormal.varenummer.isEmpty
          ? 0
          : ((udNormal.pris + materialePris) * (1 + daekning)) +
          (timer * timeloen);
    }

    // ✅ Beregn totalPris afhængigt af anlægstype
    double totalPris;
    if (anlaegstype == 'Indblæsningsanlæg') {
      totalPris = (indPris - fradragRemtrukket).clamp(0, double.infinity);
    } else if (anlaegstype == 'Udsugningsanlæg') {
      totalPris = (udPris - fradragRemtrukket).clamp(0, double.infinity);
    } else {
      // Ventilationsanlæg = begge dele
      totalPris = (indPris + udPris - fradragRemtrukket).clamp(0, double.infinity);
    }

    final double samletFoer = omkostningInd + omkostningUd;
    final double samletEfter = indNormal.omkostning + udNormal.omkostning;
    final double aarsbesparelse = samletFoer - samletEfter;

    final double tilbagebetalingstid =
    aarsbesparelse > 0 ? totalPris / aarsbesparelse : double.infinity;

    final oekonomi = OekonomiResultat(
      anlaegstype: anlaegstype,
      anlaegsnavn: anlaegsNavn,
      omkostningFoer: samletFoer,
      varenummer: indNormal.varenummer.isNotEmpty
          ? indNormal.varenummer
          : udNormal.varenummer, // tag det varenummer der faktisk findes
      tilbagebetalingstid: tilbagebetalingstid,
      aarsforbrugKWh: 0,
      omkostning: samletEfter,
      effekt: 0,
      tryk: 0,
      luftmaengde: 0,
      virkningsgrad: 0,
      selvaerdi: 0,
      indPris: indPris,
      udPris: udPris,
      totalPris: totalPris,
      aarsbesparelse: aarsbesparelse,
    );

    final anlaeg = projektInfo.alleAnlaeg[projektInfo.index];

    final varmeResultat = beregnVarmeforbrugOgVirkningsgrad(
      anlaegsType: anlaeg.valgtAnlaegstype,
      luftInd: luftIndNormal,
      luftUd: luftUdNormal,
      driftstimer: driftstimer.toDouble(),
      friskluftTemp: anlaeg.friskluftTemp,
      tempUd: anlaeg.tempUd,
      tempIndEfterGenvinding: anlaeg.tempIndEfterGenvinding,
      tempIndEfterVarmeflade: anlaeg.tempIndEfterVarmeflade,
      varmePris: projektInfo.varmePris,
      driftstype: projektInfo.driftstype,
      varmegenvindingsType: projektInfo.varmegenvindingsType.name,
    );

    resultater.add(VentilatorOekonomiSamlet(
      anlaegstype: anlaegstype,
      anlaegsnavn: anlaegsNavn,
      fabrikant: fabrikant,
      logoPath: logoPath,
      varenummerInd: indNormal.varenummer,
      varenummerUd: udNormal.varenummer,
      sammeVentilatorVedMax: sammeInd && sammeUd,
      kommentarInd: indNormal.varenummer.isEmpty
          ? ''
          : (sammeInd
          ? '✅ Ventilator er identisk ved nominel og maks. drift'
          : '⚠️ Ventilator ved maks. drift er ikke identisk med nominel'),
      kommentarUd: udNormal.varenummer.isEmpty
          ? ''
          : (sammeUd
          ? '✅ Ventilator er identisk ved nominel og maks. drift'
          : '⚠️ Ventilator ved maks. drift er ikke identisk med nominel'),
      oekonomi: oekonomi,
      indNormal: indNormal,
      indMax: indMax,
      udNormal: udNormal,
      udMax: udMax,
      totalPris: totalPris,
      remUdskiftningPris: fradragRemtrukket,
      varmeAarsbesparelse: varmeResultat.optimering?.besparelseKr,
      varmeBesparelseKWh: varmeResultat.optimering?.besparelseKWh,
      varmeforbrugKWhFoer: varmeResultat.varmeforbrugKWh,
      varmeOmkostningFoer: varmeResultat.varmeOmkostning,
      varmeforbrugKWHEfter: varmeResultat.optimering?.nytVarmeforbrugKWh,
      varmeOmkostningEfter: varmeResultat.optimering?.nytVarmeforbrugKr,
    ));
  }

  // Tilføj alle tre fabrikanter
  tilfoej(
    fabrikant: 'Ebmpapst',
    logoPath: 'assets/images/ebmpapst.png',
    indNormal: ebmpapst.findNaermesteEbmpapstVentilator(
        trykIndNormal, luftIndNormal,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    indMax: ebmpapst.findNaermesteEbmpapstVentilator(
        trykIndMax, luftIndMax,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    udNormal: ebmpapst.findNaermesteEbmpapstVentilator(
        trykUdNormal, luftUdNormal,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    udMax: ebmpapst.findNaermesteEbmpapstVentilator(
        trykUdMax, luftUdMax,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
  );

  tilfoej(
    fabrikant: 'Novenco',
    logoPath: 'assets/images/novenco.png',
    indNormal: novenco.findNaermesteNovencoVentilator(
        trykIndNormal, luftIndNormal,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    indMax: novenco.findNaermesteNovencoVentilator(
        trykIndMax, luftIndMax,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    udNormal: novenco.findNaermesteNovencoVentilator(
        trykUdNormal, luftUdNormal,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    udMax: novenco.findNaermesteNovencoVentilator(
        trykUdMax, luftUdMax,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
  );

  tilfoej(
    fabrikant: 'Ziehl-Abegg',
    logoPath: 'assets/images/ziehlabegg.png',
    indNormal: ziehlabegg.findNaermesteZiehlAbeggVentilator(
        trykIndNormal, luftIndNormal,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    indMax: ziehlabegg.findNaermesteZiehlAbeggVentilator(
        trykIndMax, luftIndMax,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    udNormal: ziehlabegg.findNaermesteZiehlAbeggVentilator(
        trykUdNormal, luftUdNormal,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
    udMax: ziehlabegg.findNaermesteZiehlAbeggVentilator(
        trykUdMax, luftUdMax,
        driftstimer: driftstimer.toDouble(), elpris: elpris, samletOmkostning: 0, aarsbesparelse: 0),
  );

  return resultater;
}