import 'generel_projekt_info.dart';
import 'beregning_varmegenvinding_optimering.dart';

class VarmeforbrugResultat {
  final double varmeforbrugKWh;
  final double varmeOmkostning;
  final double co2Udledning;
  final double gennemsnitTemp;
  final double maaltVirkningsgrad;
  final Driftstype driftstype;
  final String? kommentar;
  final OptimeretVarmegenvindingResultat? optimering;
  final double? friskluftTemp;
  final double? tempUd;
  final double? tempIndEfterVarmeflade;
  final double? tempIndEfterGenvinding;
  final double? tempAfkast;
  final double? recirkuleringProcent;
  final double? varmegenvindingVirkningsgrad;
  final String? varmegenvindingsType;

  const VarmeforbrugResultat({
    required this.varmeforbrugKWh,
    required this.varmeOmkostning,
    required this.co2Udledning,
    required this.gennemsnitTemp,
    required this.maaltVirkningsgrad,
    required this.driftstype,
    this.kommentar,
    this.optimering,
    this.friskluftTemp,
    this.tempUd,
    this.tempIndEfterVarmeflade,
    this.tempIndEfterGenvinding,
    this.tempAfkast,
    this.recirkuleringProcent,
    this.varmegenvindingVirkningsgrad,
    this.varmegenvindingsType,
  });

  bool get harBeregning => varmeforbrugKWh > 0;
}

VarmeforbrugResultat beregnVarmeforbrugOgVirkningsgrad({
  required String anlaegsType,
  required double luftInd,
  double? luftUd,
  required double driftstimer,
  required double friskluftTemp,
  required double tempUd,
  required double tempIndEfterGenvinding,
  required double tempIndEfterVarmeflade,
  required double varmePris,
  required Driftstype driftstype,
  double co2Faktor = 0.2,
  String? varmegenvindingsType,
  double? tempAfkast,
  double? recirkuleringProcent,
  double? varmegenvindingVirkningsgrad,
  String? kombineretVarmegenvindingsType,
}) {
  double referenceTemp;
  switch (driftstype) {
    case Driftstype.doegn: referenceTemp = 8.9; break;
    case Driftstype.dag:   referenceTemp = 12.0; break;
    case Driftstype.nat:   referenceTemp = 5.9; break;
  }

  // 1️⃣ Indblæsningsanlæg
  if (anlaegsType == "Indblæsningsanlæg") {
    if (tempIndEfterVarmeflade > referenceTemp) {
      double deltaT = (tempIndEfterVarmeflade - referenceTemp).clamp(0, double.infinity);
      double varmeforbrug = (luftInd * 1.2 * 1.006 * deltaT * driftstimer) / 3600.0;
      double varmeOmkostning = varmeforbrug * varmePris;
      double co2 = varmeforbrug * co2Faktor;

      return VarmeforbrugResultat(
        varmeforbrugKWh: varmeforbrug,
        varmeOmkostning: varmeOmkostning,
        co2Udledning: co2,
        gennemsnitTemp: tempIndEfterVarmeflade,
        maaltVirkningsgrad: 0,
        driftstype: driftstype,
        kommentar: "Da dette er et indblæsningsanlæg uden varmegenvinding, "
            "opstår der et højt varmeforbrug. Den opvarmede luft vil typisk blive "
            "suget ud af et separat udsugningsanlæg uden genvinding.",
        optimering: null,
        friskluftTemp: friskluftTemp,
        tempUd: tempUd,
        tempIndEfterVarmeflade: tempIndEfterVarmeflade,
        tempIndEfterGenvinding: tempIndEfterGenvinding,  // ✅
        tempAfkast: tempAfkast,
        recirkuleringProcent: recirkuleringProcent,
        varmegenvindingVirkningsgrad: varmegenvindingVirkningsgrad,
        varmegenvindingsType: varmegenvindingsType,  // ✅
      );
    } else {
      return VarmeforbrugResultat(
        varmeforbrugKWh: 0,
        varmeOmkostning: 0,
        co2Udledning: 0,
        gennemsnitTemp: 0,
        maaltVirkningsgrad: 0,
        driftstype: driftstype,
        kommentar: "Indblæsningsluften er ikke registreret som opvarmet, derfor ingen varmeberegning.",
        optimering: null,
        friskluftTemp: friskluftTemp,
        tempUd: tempUd,
        tempIndEfterVarmeflade: tempIndEfterVarmeflade,
        tempIndEfterGenvinding: tempIndEfterGenvinding,  // ✅
        tempAfkast: tempAfkast,
        recirkuleringProcent: recirkuleringProcent,
        varmegenvindingVirkningsgrad: varmegenvindingVirkningsgrad,
        varmegenvindingsType: varmegenvindingsType,  // ✅
      );
    }
  }

  // 2️⃣ Udsugningsanlæg
  if (anlaegsType == "Udsugningsanlæg") {
    if (tempUd > referenceTemp && luftUd != null) {
      double deltaUd = (tempUd - referenceTemp).clamp(0, double.infinity);
      double tabtVarme = (luftUd * 1.2 * 1.006 * deltaUd * driftstimer) / 3600.0;
      double tabtVarmeKr = tabtVarme * varmePris;
      double co2 = tabtVarme * co2Faktor;

      return VarmeforbrugResultat(
        varmeforbrugKWh: tabtVarme,
        varmeOmkostning: tabtVarmeKr,
        co2Udledning: co2,
        gennemsnitTemp: tempUd,
        maaltVirkningsgrad: 0,
        driftstype: driftstype,
        kommentar: "Da dette er et udsugningsanlæg uden varmegenvinding, "
            "blæses den opvarmede indeluft direkte ud i det fri. Varmeenergien går tabt, "
            "men kunne være genvundet med et ventilationsanlæg med varmeveksler.",
        optimering: null,
        friskluftTemp: friskluftTemp,
        tempUd: tempUd,
        tempIndEfterVarmeflade: tempIndEfterVarmeflade,
        tempIndEfterGenvinding: tempIndEfterGenvinding,  // ✅
        tempAfkast: tempAfkast,
        recirkuleringProcent: recirkuleringProcent,
        varmegenvindingVirkningsgrad: varmegenvindingVirkningsgrad,
        varmegenvindingsType: varmegenvindingsType,  // ✅
      );
    } else {
      return VarmeforbrugResultat(
        varmeforbrugKWh: 0,
        varmeOmkostning: 0,
        co2Udledning: 0,
        gennemsnitTemp: 0,
        maaltVirkningsgrad: 0,
        driftstype: driftstype,
        kommentar: "Udsugningsluften er ikke registreret som opvarmet, derfor ingen varmeberegning.",
        optimering: null,
        friskluftTemp: friskluftTemp,
        tempUd: tempUd,
        tempIndEfterVarmeflade: tempIndEfterVarmeflade,
        tempIndEfterGenvinding: tempIndEfterGenvinding,  // ✅
        tempAfkast: tempAfkast,
        recirkuleringProcent: recirkuleringProcent,
        varmegenvindingVirkningsgrad: varmegenvindingVirkningsgrad,
        varmegenvindingsType: varmegenvindingsType,  // ✅
      );
    }
  }

  // ✅ RECIRKULERING
  if (varmegenvindingsType?.toLowerCase().trim() == "recirkulering" &&
      recirkuleringProcent != null &&
      recirkuleringProcent > 0 &&
      anlaegsType == "Ventilationsanlæg") {

    final double deltaTFoer = (tempIndEfterVarmeflade - friskluftTemp).clamp(0, double.infinity);
    final double varmeforbrugFoer = (luftInd * 1.2 * 1.006 * deltaTFoer * driftstimer) / 3600.0;
    final double tBland = friskluftTemp + (recirkuleringProcent / 100) * (tempUd - friskluftTemp);

    double beregnetKombineretEta = 0;
    if (varmegenvindingVirkningsgrad != null && varmegenvindingVirkningsgrad > 0) {
      beregnetKombineretEta = varmegenvindingVirkningsgrad;
    } else if (kombineretVarmegenvindingsType != null && (tempUd - tBland).abs() > 0.001) {
      beregnetKombineretEta = ((tempIndEfterGenvinding - tBland) / (tempUd - tBland)) * 100;
      beregnetKombineretEta = beregnetKombineretEta.clamp(0, 100);
    }

    final double tEfterGenvinding = beregnetKombineretEta > 0
        ? tBland + (beregnetKombineretEta / 100) * (tempUd - tBland)
        : tBland;

    final double deltaTEfter = (tempIndEfterVarmeflade - tEfterGenvinding).clamp(0, double.infinity);
    final double varmeforbrugEfter = (luftInd * 1.2 * 1.006 * deltaTEfter * driftstimer) / 3600.0;
    final double besparelseKWh = varmeforbrugFoer - varmeforbrugEfter;
    final double besparelseKr = besparelseKWh * varmePris;
    final bool harKombineretGenvinding = kombineretVarmegenvindingsType != null && beregnetKombineretEta > 0;

    final String tempTekst = harKombineretGenvinding
        ? "Blandingstemperatur ${tBland.toStringAsFixed(1)} °C, efter varmegenvinding ${tEfterGenvinding.toStringAsFixed(1)} °C."
        : "Blandingstemperatur ${tBland.toStringAsFixed(1)} °C.";

    final double samletVirkningsgrad = (tempUd - friskluftTemp).abs() > 0.001
        ? ((tEfterGenvinding - friskluftTemp) / (tempUd - friskluftTemp)) * 100
        : recirkuleringProcent;

    final String co2Advarsel = recirkuleringProcent > 80
        ? "\n\nOBS: Recirkulering over 80 % frarådes i rum med personer, da der er risiko for for høj CO₂-belastning i indeklimaet."
        : "\n\nBemærk: Ved recirkulering i rum med personer anbefales det ikke at overstige 80 % af hensyn til CO₂-niveauet i indeklimaet.";

    return VarmeforbrugResultat(
      varmeforbrugKWh: varmeforbrugEfter,
      varmeOmkostning: varmeforbrugEfter * varmePris,
      co2Udledning: (varmeforbrugEfter / 1000.0) * co2Faktor,
      gennemsnitTemp: tEfterGenvinding,
      maaltVirkningsgrad: samletVirkningsgrad,
      driftstype: driftstype,
      kommentar: "Anlægget har recirkulering ${recirkuleringProcent.toStringAsFixed(0)} % "
          "${harKombineretGenvinding ? 'samt $kombineretVarmegenvindingsType med en målt virkningsgrad på ${beregnetKombineretEta.toStringAsFixed(0)} %. ' : ''}"
          "Den samlede varmegevinst svarer til en virkningsgrad på ${samletVirkningsgrad.toStringAsFixed(1)} %. "
          "$tempTekst$co2Advarsel",
      optimering: OptimeretVarmegenvindingResultat(
        kanOptimeres: besparelseKWh > 0,
        valgtVirkningsgrad: samletVirkningsgrad,
        standardVirkningsgrad: samletVirkningsgrad,
        korrigeretVirkningsgrad: null,
        nyVirkningsgrad: samletVirkningsgrad,
        nytVarmeforbrugKWh: varmeforbrugEfter,
        nytVarmeforbrugKr: varmeforbrugEfter * varmePris,
        besparelseKWh: besparelseKWh,
        besparelseKr: besparelseKr,
        co2Besparelse: besparelseKWh * co2Faktor,
        minGraense: 0,
        kommentar: "Anlægget har recirkulering ${recirkuleringProcent.toStringAsFixed(0)} % "
            "${harKombineretGenvinding ? 'samt $kombineretVarmegenvindingsType med en målt virkningsgrad på ${beregnetKombineretEta.toStringAsFixed(0)} %. ' : ''}"
            "Den samlede varmegevinst svarer til en virkningsgrad på ${samletVirkningsgrad.toStringAsFixed(1)} %. "
            "$tempTekst$co2Advarsel",
      ),
      friskluftTemp: friskluftTemp,
      tempUd: tempUd,
      tempIndEfterVarmeflade: tempIndEfterVarmeflade,
      tempIndEfterGenvinding: tempIndEfterGenvinding,  // ✅
      tempAfkast: tempAfkast,
      recirkuleringProcent: recirkuleringProcent,
      varmegenvindingVirkningsgrad: varmegenvindingVirkningsgrad,
      varmegenvindingsType: varmegenvindingsType,  // ✅
    );
  }

  // 3️⃣ Ventilationsanlæg (med varmegenvinding)
  final double effektivFriskluftTemp = friskluftTemp;

  double maaltVirkningsgrad = 0;
  if (tempAfkast != null && (tempAfkast - effektivFriskluftTemp).abs() > 0.0001) {
    maaltVirkningsgrad =
        ((tempIndEfterGenvinding - effektivFriskluftTemp) / (tempAfkast - effektivFriskluftTemp)) * 100;
  } else if ((tempUd - effektivFriskluftTemp).abs() > 0.0001) {
    maaltVirkningsgrad =
        ((tempIndEfterGenvinding - effektivFriskluftTemp) / (tempUd - effektivFriskluftTemp)) * 100;
  }

  double tempEfterVarmegenvinding =
      ((maaltVirkningsgrad / 100) * (tempUd - referenceTemp)) + referenceTemp;
  double deltaT = (tempIndEfterVarmeflade - tempEfterVarmegenvinding).clamp(0, double.infinity);
  double varmeforbrugKWh = (luftInd * 1.2 * 1.006 * deltaT * driftstimer) / 3600.0;

  return VarmeforbrugResultat(
    varmeforbrugKWh: varmeforbrugKWh,
    varmeOmkostning: varmeforbrugKWh * varmePris,
    co2Udledning: (varmeforbrugKWh / 1000.0) * co2Faktor,
    gennemsnitTemp: tempEfterVarmegenvinding,
    maaltVirkningsgrad: maaltVirkningsgrad,
    driftstype: driftstype,
    kommentar: "Varmeforbrug beregnet ud fra målt virkningsgrad. Resultatet bruges som grundlag for evt. optimering.",
    optimering: beregnOptimeretVarmegenvinding(
      anlaegsType: anlaegsType,
      typeVarmegenvinding: varmegenvindingsType ?? "",
      beregnetVirkningsgrad: maaltVirkningsgrad,
      luftInd: luftInd,
      luftUd: luftUd,
      driftstimer: driftstimer,
      friskluftTemp: effektivFriskluftTemp,
      tempUd: tempUd,
      tempIndEfterVarmeflade: tempIndEfterVarmeflade,
      varmePris: varmePris,
      co2Faktor: co2Faktor,
      driftstype: driftstype,
      tempAfkast: tempAfkast,
    ),
    friskluftTemp: friskluftTemp,
    tempUd: tempUd,
    tempIndEfterVarmeflade: tempIndEfterVarmeflade,
    tempIndEfterGenvinding: tempIndEfterGenvinding,  // ✅
    tempAfkast: tempAfkast,
    recirkuleringProcent: recirkuleringProcent,
    varmegenvindingVirkningsgrad: varmegenvindingVirkningsgrad,
    varmegenvindingsType: varmegenvindingsType,  // ✅
  );
}














































