import 'dart:math';
import 'package:intl/intl.dart';
import 'generel_projekt_info.dart';

String formatDK(num value) {
  final f = NumberFormat.decimalPattern('da_DK')
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 0;
  return f.format(value);
}

class OptimeretVarmegenvindingResultat {
  final bool kanOptimeres;
  final double valgtVirkningsgrad;
  final double standardVirkningsgrad;
  final double? korrigeretVirkningsgrad;
  final double nyVirkningsgrad;
  final double? nytVarmeforbrugKWh;
  final double? nytVarmeforbrugKr;
  final double? besparelseKWh;
  final double? besparelseKr;
  final double? co2Besparelse;
  final double minGraense;
  final String kommentar;
  final double? virkningsgradFoer;

  OptimeretVarmegenvindingResultat({
    required this.kanOptimeres,
    required this.valgtVirkningsgrad,
    required this.standardVirkningsgrad,
    required this.korrigeretVirkningsgrad,
    required this.nyVirkningsgrad,
    required this.nytVarmeforbrugKWh,
    required this.nytVarmeforbrugKr,
    required this.besparelseKWh,
    required this.besparelseKr,
    required this.co2Besparelse,
    required this.minGraense,
    required this.kommentar,
    this.virkningsgradFoer,
  });
}

OptimeretVarmegenvindingResultat beregnOptimeretVarmegenvinding({
  required String anlaegsType,
  required String typeVarmegenvinding,
  required double beregnetVirkningsgrad,
  required double luftInd,
  required double driftstimer,
  required double friskluftTemp,
  required double tempUd,
  required double tempIndEfterVarmeflade,
  required double varmePris,
  required double co2Faktor,
  required Driftstype driftstype,
  double? luftUd,
  double? tempAfkast,
  bool erUdsugningsluftOpvarmet = false,
  double? manuelVirkningsgrad,
  double? recirkuleringProcent,
}) {
  print('═══════════════════════════════════════');
  print('🔥 FUNKTION KALDT!');
  print('manuelVirkningsgrad = $manuelVirkningsgrad');
  print('recirkuleringProcent = $recirkuleringProcent');
  print('anlaegsType = $anlaegsType');
  print('friskluftTemp = $friskluftTemp');
  print('tempUd = $tempUd');
  print('tempIndEfterVarmeflade = $tempIndEfterVarmeflade');
  print('luftInd = $luftInd');
  print('═══════════════════════════════════════');

  double referenceTemp;
  switch (driftstype) {
    case Driftstype.doegn: referenceTemp = 8.9; break;
    case Driftstype.dag: referenceTemp = 12.0; break;
    case Driftstype.nat: referenceTemp = 5.6; break;
  }

  // ✅ HÅNDTER MANUEL VIRKNINGSGRAD ALLERFØRST
  if (manuelVirkningsgrad != null && anlaegsType == "Ventilationsanlæg") {
    if (manuelVirkningsgrad < 1) {
      manuelVirkningsgrad = manuelVirkningsgrad * 100;
    }

    double virkningsgradFoer = beregnetVirkningsgrad;
    if (tempAfkast != null && (tempAfkast - friskluftTemp).abs() > 0.0001) {
      virkningsgradFoer = ((tempIndEfterVarmeflade - friskluftTemp) / (tempAfkast - friskluftTemp)) * 100;
    }

    double tempEfterFoer = ((virkningsgradFoer / 100) * (tempUd - referenceTemp)) + referenceTemp;
    double deltaTFoer = (tempIndEfterVarmeflade - tempEfterFoer).clamp(0, double.infinity);
    double varmeforbrugFoer = (luftInd * 1.2 * 1.006 * deltaTFoer * driftstimer) / 3600.0;
    double varmeforbrugKrFoer = varmeforbrugFoer * varmePris;

    double tempEfterEfter = ((manuelVirkningsgrad / 100) * (tempUd - referenceTemp)) + referenceTemp;
    double deltaTEfter = (tempIndEfterVarmeflade - tempEfterEfter).clamp(0, double.infinity);
    double nytVarmeforbrugKWh = (luftInd * 1.2 * 1.006 * deltaTEfter * driftstimer) / 3600.0;
    double nytVarmeforbrugKr = nytVarmeforbrugKWh * varmePris;

    double besparelseKWh = varmeforbrugFoer - nytVarmeforbrugKWh;
    double besparelseKr = varmeforbrugKrFoer - nytVarmeforbrugKr;
    double co2Besparelse = besparelseKWh * co2Faktor;

    return OptimeretVarmegenvindingResultat(
      kanOptimeres: true,
      valgtVirkningsgrad: manuelVirkningsgrad,
      standardVirkningsgrad: manuelVirkningsgrad,
      korrigeretVirkningsgrad: null,
      nyVirkningsgrad: manuelVirkningsgrad,
      nytVarmeforbrugKWh: nytVarmeforbrugKWh,
      nytVarmeforbrugKr: nytVarmeforbrugKr,
      besparelseKWh: besparelseKWh,
      besparelseKr: besparelseKr,
      co2Besparelse: co2Besparelse,
      minGraense: 0,
      kommentar: "Virkningsgrad oplyst af producenten: ${manuelVirkningsgrad.toStringAsFixed(1)} %",
    );
  }

  // ✅ HÅNDTER RECIRKULERING
  // friskluftTemp er allerede justeret i beregning_varmeforbrug.dart
  // Her beregner vi den ækvivalente virkningsgrad recirkulering giver
  if (typeVarmegenvinding.toLowerCase().trim() == "recirkulering" &&
      recirkuleringProcent != null &&
      recirkuleringProcent > 0 &&
      anlaegsType == "Ventilationsanlæg") {

    // Effektiv frisklufttemp med recirkulering
    final double effektivFriskluft = friskluftTemp; // allerede justeret ved kald

    // Ækvivalent virkningsgrad: hvad svarer recirkulering til?
    final double aekviVirkningsgrad = recirkuleringProcent.clamp(0, 95);

    // FØR-situation (uden recirkulering, brug original friskluftTemp)
    // friskluftTemp her er allerede den justerede, så vi beregner direkte
    double virkningsgradFoer = beregnetVirkningsgrad;
    double tempEfterFoer = ((virkningsgradFoer / 100) * (tempUd - referenceTemp)) + referenceTemp;
    double deltaTFoer = (tempIndEfterVarmeflade - tempEfterFoer).clamp(0, double.infinity);
    double varmeforbrugFoer = (luftInd * 1.2 * 1.006 * deltaTFoer * driftstimer) / 3600.0;
    double varmeforbrugKrFoer = varmeforbrugFoer * varmePris;

    // EFTER-situation (med recirkulering — friskluftTemp allerede justeret)
    double tempEfterEfter = ((aekviVirkningsgrad / 100) * (tempUd - referenceTemp)) + referenceTemp;
    double deltaTEfter = (tempIndEfterVarmeflade - tempEfterEfter).clamp(0, double.infinity);
    double nytVarmeforbrugKWh = (luftInd * 1.2 * 1.006 * deltaTEfter * driftstimer) / 3600.0;
    double nytVarmeforbrugKr = nytVarmeforbrugKWh * varmePris;

    double besparelseKWh = varmeforbrugFoer - nytVarmeforbrugKWh;
    double besparelseKr = varmeforbrugKrFoer - nytVarmeforbrugKr;
    double co2Besparelse = besparelseKWh * co2Faktor;

    return OptimeretVarmegenvindingResultat(
      kanOptimeres: besparelseKWh > 0,
      valgtVirkningsgrad: aekviVirkningsgrad,
      standardVirkningsgrad: aekviVirkningsgrad,
      korrigeretVirkningsgrad: null,
      nyVirkningsgrad: aekviVirkningsgrad,
      nytVarmeforbrugKWh: nytVarmeforbrugKWh,
      nytVarmeforbrugKr: nytVarmeforbrugKr,
      besparelseKWh: besparelseKWh,
      besparelseKr: besparelseKr,
      co2Besparelse: co2Besparelse,
      minGraense: 0,
      kommentar: "Recirkulering på ${recirkuleringProcent.toStringAsFixed(0)} % reducerer varmebehovet "
          "ved at tilbageføre opvarmet luft til indblæsningen.",
    );
  }

  // ------------------------
  // Ingen temperaturer indtastet
  // ------------------------
  if (friskluftTemp == 0 && tempUd == 0 && tempIndEfterVarmeflade == 0) {
    return OptimeretVarmegenvindingResultat(
      kanOptimeres: false,
      valgtVirkningsgrad: 0,
      standardVirkningsgrad: 0,
      korrigeretVirkningsgrad: null,
      nyVirkningsgrad: 0,
      nytVarmeforbrugKWh: null,
      nytVarmeforbrugKr: null,
      besparelseKWh: null,
      besparelseKr: null,
      co2Besparelse: null,
      minGraense: 0,
      kommentar: "Det har ikke været muligt at fastsætte varmeforbruget under service. "
          "En mulig årsag kan være, at udetemperaturen var over 10 °C under service.",
    );
  }

  // ------------------------
  // 1️⃣ Indblæsningsanlæg
  // ------------------------
  if (anlaegsType == "Indblæsningsanlæg" && tempIndEfterVarmeflade > referenceTemp) {
    double deltaT = (tempIndEfterVarmeflade - referenceTemp).clamp(0, double.infinity);
    double varmeforbrug = (luftInd * 1.2 * 1.006 * deltaT * driftstimer) / 3600.0;
    double co2 = varmeforbrug * co2Faktor;

    return OptimeretVarmegenvindingResultat(
      kanOptimeres: false,
      valgtVirkningsgrad: 0,
      standardVirkningsgrad: 0,
      korrigeretVirkningsgrad: null,
      nyVirkningsgrad: 0,
      nytVarmeforbrugKWh: null,
      nytVarmeforbrugKr: null,
      besparelseKWh: null,
      besparelseKr: null,
      co2Besparelse: co2,
      minGraense: 0,
      kommentar: "Da dette er et indblæsningsanlæg uden varmegenvinding, opstår der et højt varmeforbrug. "
          "Den opvarmede luft vil typisk blive suget ud af et separat udsugningsanlæg uden genvinding.",
    );
  }

  // ------------------------
  // 2️⃣ Udsugningsanlæg
  // ------------------------
  if (anlaegsType == "Udsugningsanlæg" && tempUd > 0) {
    double deltaUd = (tempUd - referenceTemp).clamp(0, double.infinity);
    double tabtVarme = (luftUd! * 1.2 * 1.006 * deltaUd * driftstimer) / 3600.0;
    double co2 = tabtVarme * co2Faktor;

    return OptimeretVarmegenvindingResultat(
      kanOptimeres: false,
      valgtVirkningsgrad: 0,
      standardVirkningsgrad: 0,
      korrigeretVirkningsgrad: null,
      nyVirkningsgrad: 0,
      nytVarmeforbrugKWh: null,
      nytVarmeforbrugKr: null,
      besparelseKWh: null,
      besparelseKr: null,
      co2Besparelse: co2,
      minGraense: 0,
      kommentar: "Udsugningsluften er registreret som opvarmet og varmere end reference-temperaturen "
          "(${referenceTemp.toStringAsFixed(1)} °C). Da anlægget ikke har varmegenvinding, tabes energien direkte.",
    );
  }

  // ------------------------
  // 3️⃣ Ventilationsanlæg (med varmegenvinding)
  // ------------------------
  double valgtVirkningsgrad;
  double minGraense;

  switch (typeVarmegenvinding.toLowerCase().trim()) {
    case "krydsveksler": valgtVirkningsgrad = 74; minGraense = 40; break;
    case "dobbelt krydsveksler": valgtVirkningsgrad = 80; minGraense = 60; break;
    case "roterende veksler": valgtVirkningsgrad = 83; minGraense = 60; break;
    case "modstrømsveksler": valgtVirkningsgrad = 80; minGraense = 30; break;
    case "væskekoblet veksler": valgtVirkningsgrad = 50; minGraense = 30; break;
    case "blandekammer": valgtVirkningsgrad = 80; minGraense = 60; break;
    case "recirkulering": valgtVirkningsgrad = 0; minGraense = 0; break;
    case "ingen": valgtVirkningsgrad = 0; minGraense = 0; break;
    default: valgtVirkningsgrad = beregnetVirkningsgrad; minGraense = 50;
  }

  double standardVirkningsgrad = valgtVirkningsgrad;

  double virkningsgradFoer = beregnetVirkningsgrad;
  if (tempAfkast != null && (tempAfkast - friskluftTemp).abs() > 0.0001) {
    virkningsgradFoer =
        ((tempIndEfterVarmeflade - friskluftTemp) / (tempAfkast - friskluftTemp)) * 100;
  }

  double tempEfterFoer = ((virkningsgradFoer / 100) * (tempUd - referenceTemp)) + referenceTemp;
  double deltaTFoer = (tempIndEfterVarmeflade - tempEfterFoer).clamp(0, double.infinity);
  double varmeforbrugFoer = (luftInd * 1.2 * 1.006 * deltaTFoer * driftstimer) / 3600.0;
  double varmeforbrugKrFoer = varmeforbrugFoer * varmePris;

  double? korrigeretVirkningsgrad;

  if (luftInd > 0 && luftUd != null && luftUd > 0 && (luftInd - luftUd).abs() > 0.0001) {
    double K = luftUd / luftInd;
    if (K > 1.0) {
      korrigeretVirkningsgrad = (valgtVirkningsgrad * K).clamp(0, 92);
    } else {
      int rounded = (valgtVirkningsgrad ~/ 10) * 10;
      if (rounded < 30) rounded = 30;
      if (rounded > 90) rounded = 90;
      switch (rounded) {
        case 30: korrigeretVirkningsgrad = 13.031 * log(K) + 30.209; break;
        case 40: korrigeretVirkningsgrad = 17.186 * log(K) + 39.823; break;
        case 50: korrigeretVirkningsgrad = 22.028 * log(K) + 50.023; break;
        case 60: korrigeretVirkningsgrad = 26.912 * log(K) + 59.509; break;
        case 70: korrigeretVirkningsgrad = -19.086 * pow(K, 2) + 75.114 * K + 13.243; break;
        case 80: korrigeretVirkningsgrad = -26.438 * pow(K, 2) + 96.096 * K + 9.5714; break;
        case 90: korrigeretVirkningsgrad = -40.152 * pow(K, 2) + 130.84 * K + 2.8286; break;
        default: korrigeretVirkningsgrad = valgtVirkningsgrad * K; break;
      }
    }
  }

  double nyVirkningsgrad = (korrigeretVirkningsgrad ?? valgtVirkningsgrad).clamp(0, 100);

  double tempEfterEfter = ((nyVirkningsgrad / 100) * (tempUd - referenceTemp)) + referenceTemp;
  double deltaTEfter = (tempIndEfterVarmeflade - tempEfterEfter).clamp(0, double.infinity);
  double nytVarmeforbrugKWh = (luftInd * 1.2 * 1.006 * deltaTEfter * driftstimer) / 3600.0;
  double nytVarmeforbrugKr = nytVarmeforbrugKWh * varmePris;

  double tempEfterStandard = ((standardVirkningsgrad / 100) * (tempUd - referenceTemp)) + referenceTemp;
  double deltaTStandard = (tempIndEfterVarmeflade - tempEfterStandard).clamp(0, double.infinity);
  double varmeforbrugVedPerfektBalance = (luftInd * 1.2 * 1.006 * deltaTStandard * driftstimer) / 3600.0;

  double ekstraVarmeforbrug = nytVarmeforbrugKWh - varmeforbrugVedPerfektBalance;
  double ekstraVarmeforbrugKr = ekstraVarmeforbrug * varmePris;

  double besparelseKWh = varmeforbrugFoer - nytVarmeforbrugKWh;
  double besparelseKr = varmeforbrugKrFoer - nytVarmeforbrugKr;
  double co2Besparelse = besparelseKWh * co2Faktor;

  String kommentar = "";

  bool erRecirkulation =
      typeVarmegenvinding.toLowerCase().trim() == "recirkulering";

  if (luftUd != null && (luftInd - luftUd).abs() > 0.0001) {
    if (erRecirkulation) {
      // 🔄 RECIRKULATION → brug IKKE virkningsgrad
      if (luftInd > luftUd) {
        kommentar =
        "Ubalance i luftmængder ved recirkulation (større indblæsning end udsugning) "
            "kan medføre øget varmebehov.";
      } else {
        kommentar =
        "Ubalance i luftmængder ved recirkulation (større udsugning end indblæsning) "
            "kan påvirke varmeforbruget og medføre tab af opvarmet luft.";
      }
    } else {
      // 🔁 VARMEGENVINDING (rotor/plade)
      if (luftInd > luftUd) {
        kommentar =
        "Virkningsgrad faldet fra ${standardVirkningsgrad.toStringAsFixed(0)} % "
            "til ${nyVirkningsgrad.toStringAsFixed(0)} % pga. større indblæsning end udsugning. "
            "Dette medfører et ekstra varmeforbrug på ca. ${ekstraVarmeforbrug.abs().toStringAsFixed(0)} kWh/år "
            "(${ekstraVarmeforbrugKr.abs().toStringAsFixed(0)} kr./år).";
      } else {
        double besparelseUbalance =
            varmeforbrugVedPerfektBalance - nytVarmeforbrugKWh;
        double besparelseUbalanceKr = besparelseUbalance * varmePris;
        double ekstraUdsugning = luftUd - luftInd;

        if (besparelseUbalance > 0) {
          kommentar =
          "Virkningsgrad steget fra ${standardVirkningsgrad.toStringAsFixed(0)} % "
              "til ${nyVirkningsgrad.toStringAsFixed(0)} % pga. større udsugning end indblæsning. "
              "Dette giver en yderligere besparelse på ca. ${besparelseUbalance.toStringAsFixed(0)} kWh/år "
              "(${besparelseUbalanceKr.toStringAsFixed(0)} kr./år). "
              "OBS: Den ekstra udsugning på ${ekstraUdsugning.toStringAsFixed(0)} m³/h fjerner opvarmet luft.";
        } else {
          kommentar =
          "Virkningsgrad faldet fra ${standardVirkningsgrad.toStringAsFixed(0)} % "
              "til ${nyVirkningsgrad.toStringAsFixed(0)} % pga. større udsugning end indblæsning. "
              "Dette medfører et ekstra varmeforbrug på ca. ${besparelseUbalance.abs().toStringAsFixed(0)} kWh/år "
              "(${besparelseUbalanceKr.abs().toStringAsFixed(0)} kr./år).";
        }
      }
    }
  } else {
    if (erRecirkulation) {
      kommentar =
      "Recirkulering på ${recirkuleringProcent?.toStringAsFixed(0) ?? '?'} % "
          "giver en blandingstemperatur, men der er ingen ændring i luftbalance i forhold til nuværende drift.";
    } else if (manuelVirkningsgrad != null) {
      kommentar =
      "Virkningsgrad oplyst af producenten: ${valgtVirkningsgrad.toStringAsFixed(0)} %.";
    } else {
      kommentar =
      "Standard virkningsgrad anvendt: ${valgtVirkningsgrad.toStringAsFixed(0)} %.";
    }
  }
  return OptimeretVarmegenvindingResultat(
    kanOptimeres: nyVirkningsgrad > virkningsgradFoer,
    valgtVirkningsgrad: valgtVirkningsgrad,
    standardVirkningsgrad: standardVirkningsgrad,
    korrigeretVirkningsgrad: korrigeretVirkningsgrad,
    nyVirkningsgrad: nyVirkningsgrad, // ✅ FIX
    nytVarmeforbrugKWh: nytVarmeforbrugKWh,
    nytVarmeforbrugKr: nytVarmeforbrugKr,
    besparelseKWh: besparelseKWh,
    besparelseKr: besparelseKr,
    co2Besparelse: co2Besparelse,
    minGraense: minGraense,
    kommentar: kommentar,
    virkningsgradFoer: virkningsgradFoer,
  );
}
















