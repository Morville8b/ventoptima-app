import 'filter_resultat.dart';
import 'package:flutter/material.dart';
import 'beregning_varmeforbrug.dart';

class AnlaegsdataWidget extends StatelessWidget {
  final TextEditingController anlaegsNavnController;
  final String valgtAnlaegstype;
  final void Function(String?) onAnlaegstypeChanged;
  final FilterValg? filterValg;

  const AnlaegsdataWidget({
    super.key,
    required this.anlaegsNavnController,
    required this.valgtAnlaegstype,
    required this.onAnlaegstypeChanged,
    this.filterValg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Anlægs nr./navn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(
          controller: anlaegsNavnController,
          decoration: const InputDecoration(labelText: 'Anlægs nr./navn'),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 24),
        const Text('Anlægstype',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          initialValue: valgtAnlaegstype,
          items: const [
            DropdownMenuItem(
                value: 'Ventilationsanlæg', child: Text('Ventilationsanlæg')),
            DropdownMenuItem(
                value: 'Indblæsningsanlæg', child: Text('Indblæsningsanlæg')),
            DropdownMenuItem(
                value: 'Udsugningsanlæg', child: Text('Udsugningsanlæg')),
          ],
          onChanged: onAnlaegstypeChanged,
          decoration: const InputDecoration(labelText: 'Vælg anlægstype'),
        ),
      ],
    );
  }
}

class AnlaegsData {
  final String anlaegsNavn;
  final String ventMaerkatNr;
  final String valgtAnlaegstype;
  double aarsbesparelse;
  double tilbagebetalingstid;
  final double luftInd;
  final double luftUd;
  final double trykInd;
  final double trykUd;
  final double kwInd;
  final double kwUd;
  final double? elOmkostningIndFoer;
  final double? elOmkostningUdFoer;
  final double hzInd;
  final double hzUd;
  final double elpris;
  final double varmepris;
  final double friskluftTemp;
  final double tempUd;
  final double tempIndEfterGenvinding;
  final double tempIndEfterVarmeflade;

  final double? tempIndEfterGenvindingEfter;
  final VarmeforbrugResultat? varmeResultat;
  final String? varmeKommentar;

  final double? varmeAarsbesparelse;
  final double? varmeBesparelseKWh;
  final double? varmeforbrugKWhFoer;
  final double? varmeOmkostningFoer;
  final double? varmeforbrugKWHEfter;
  final double? varmeOmkostningEfter;

  // ✅ Normale tryk-værdier
  final double? trykFoerInd;
  final double? trykEfterInd;
  final double? trykFoerUd;
  final double? trykEfterUd;

  // Maksimale tryk-værdier
  final double? trykFoerIndMax;
  final double? trykEfterIndMax;
  final double? trykFoerUdMax;
  final double? trykEfterUdMax;

  final double? luftIndMax;
  final double? luftUdMax;
  final double? kVaerdiInd;
  final double? kVaerdiUd;
  final double? maksLuftInd;
  final double? maksLuftUd;
  final double? maksEffektInd;
  final double? maksEffektUd;
  final double? effektMaaltInd;
  final double? effektMaaltUd;
  final double? trykDifferensInd;
  final double? trykDifferensUd;
  final double? trykGamleFiltreInd;
  final double? trykGamleFiltreUd;
  final int? antalHeleFiltreInd;
  final int? antalHalveFiltreInd;
  final int? antalHeleFiltreUd;
  final int? antalHalveFiltreUd;
  final double kammerBredde;
  final double kammerHoede;
  final double kammerLaengde;
  final String valgtTilstand;
  final String eksisterendeVarenummerInd;
  final String eksisterendeVarenummerUd;
  final bool erBeregnetInd;
  final bool erBeregnetUd;
  final double? remUdskiftningPris;
  final double omkostningFoer;
  final double omkostningEfter;
  final FilterResultat? filterResultat;
  final FilterValg? filterValg;
  final double? driftstimer;
  final double? virkningsgradInd;
  final double? virkningsgradUd;
  final double? filterKammerLaengdeInd;
  final double? filterKammerLaengdeUd;

  final List<Map<String, String>>? dokumentation;

  final bool erBeregnetUdFraKVaerdiInd;
  final bool erBeregnetUdFraKVaerdiUd;
  final bool erLuftmaengdeMaaeltIndtastetInd;
  final bool erLuftmaengdeMaaeltIndtastetUd;
  final String? internKommentar;
  final double? recirkuleringProcent;
  final bool erFaerdigbehandlet;

  // ✅ NY: Varmegenvindingstype som tekst (fx 'Krydsveksler', 'Roterende veksler' osv.)
  final String? varmegenvindingsType;

  AnlaegsData({
    required this.anlaegsNavn,
    required this.ventMaerkatNr,
    required this.valgtAnlaegstype,
    required this.aarsbesparelse,
    required this.tilbagebetalingstid,
    required this.luftInd,
    required this.luftUd,
    required this.trykInd,
    required this.trykUd,
    required this.kwInd,
    required this.kwUd,
    this.elOmkostningIndFoer,
    this.elOmkostningUdFoer,
    required this.hzInd,
    required this.hzUd,
    required this.elpris,
    required this.varmepris,
    required this.eksisterendeVarenummerInd,
    required this.eksisterendeVarenummerUd,
    this.varmeResultat,
    this.varmeKommentar,
    this.varmeAarsbesparelse,
    this.varmeBesparelseKWh,
    this.varmeforbrugKWhFoer,
    this.varmeOmkostningFoer,
    this.varmeforbrugKWHEfter,
    this.varmeOmkostningEfter,
    this.trykFoerInd,
    this.trykEfterInd,
    this.trykFoerUd,
    this.trykEfterUd,
    this.trykFoerIndMax,
    this.trykEfterIndMax,
    this.trykFoerUdMax,
    this.trykEfterUdMax,
    this.luftIndMax,
    this.luftUdMax,
    this.kVaerdiInd,
    this.kVaerdiUd,
    this.maksLuftInd,
    this.maksLuftUd,
    this.maksEffektInd,
    this.maksEffektUd,
    this.effektMaaltInd,
    this.effektMaaltUd,
    this.trykDifferensInd,
    this.trykDifferensUd,
    this.trykGamleFiltreInd,
    this.trykGamleFiltreUd,
    this.antalHeleFiltreInd,
    this.antalHalveFiltreInd,
    this.antalHeleFiltreUd,
    this.antalHalveFiltreUd,
    required this.kammerBredde,
    required this.kammerHoede,
    required this.kammerLaengde,
    required this.valgtTilstand,
    required this.erBeregnetInd,
    required this.erBeregnetUd,
    this.remUdskiftningPris,
    required this.omkostningFoer,
    required this.omkostningEfter,
    this.friskluftTemp = 0,
    this.tempUd = 0,
    this.tempIndEfterGenvinding = 0,
    this.tempIndEfterVarmeflade = 0,
    this.tempIndEfterGenvindingEfter,
    this.dokumentation,
    this.filterResultat,
    this.filterValg,
    this.driftstimer,
    this.virkningsgradInd,
    this.virkningsgradUd,
    this.filterKammerLaengdeInd,
    this.filterKammerLaengdeUd,
    this.erBeregnetUdFraKVaerdiInd = false,
    this.erBeregnetUdFraKVaerdiUd = false,
    this.erLuftmaengdeMaaeltIndtastetInd = false,
    this.erLuftmaengdeMaaeltIndtastetUd = false,
    this.internKommentar,
    this.recirkuleringProcent,
    this.erFaerdigbehandlet = false,
    this.varmegenvindingsType,  // ✅ NY
  });

  AnlaegsData copyWith({
    String? anlaegsNavn,
    String? ventMaerkatNr,
    String? valgtAnlaegstype,
    double? aarsbesparelse,
    double? tilbagebetalingstid,
    double? luftInd,
    double? luftUd,
    double? trykInd,
    double? trykUd,
    double? kwInd,
    double? kwUd,
    double? elOmkostningIndFoer,
    double? elOmkostningUdFoer,
    double? hzInd,
    double? hzUd,
    double? elpris,
    double? varmepris,
    VarmeforbrugResultat? varmeResultat,
    double? varmeAarsbesparelse,
    double? varmeBesparelseKWh,
    double? varmeforbrugKWhFoer,
    double? varmeOmkostningFoer,
    double? varmeforbrugKWHEfter,
    double? varmeOmkostningEfter,
    double? trykFoerInd,
    double? trykEfterInd,
    double? trykFoerUd,
    double? trykEfterUd,
    double? trykFoerIndMax,
    double? trykEfterIndMax,
    double? trykFoerUdMax,
    double? trykEfterUdMax,
    double? luftIndMax,
    double? luftUdMax,
    double? kVaerdiInd,
    double? kVaerdiUd,
    double? maksLuftInd,
    double? maksLuftUd,
    double? maksEffektInd,
    double? maksEffektUd,
    double? effektMaaltInd,
    double? effektMaaltUd,
    double? trykDifferensInd,
    double? trykDifferensUd,
    double? trykGamleFiltreInd,
    double? trykGamleFiltreUd,
    int? antalHeleFiltreInd,
    int? antalHalveFiltreInd,
    int? antalHeleFiltreUd,
    int? antalHalveFiltreUd,
    double? kammerBredde,
    double? kammerHoede,
    double? kammerLaengde,
    String? valgtTilstand,
    bool? erBeregnetInd,
    bool? erBeregnetUd,
    double? remUdskiftningPris,
    double? omkostningFoer,
    double? omkostningEfter,
    String? eksisterendeVarenummerInd,
    String? eksisterendeVarenummerUd,
    double? tempIndEfterGenvindingEfter,
    List<Map<String, String>>? dokumentation,
    FilterResultat? filterResultat,
    FilterValg? filterValg,
    double? driftstimer,
    double? virkningsgradInd,
    double? virkningsgradUd,
    double? filterKammerLaengdeInd,
    double? filterKammerLaengdeUd,
    bool? erBeregnetUdFraKVaerdiInd,
    bool? erBeregnetUdFraKVaerdiUd,
    bool? erLuftmaengdeMaaeltIndtastetInd,
    bool? erLuftmaengdeMaaeltIndtastetUd,
    String? internKommentar,
    double? recirkuleringProcent,
    double? friskluftTemp,
    double? tempIndEfterGenvinding,
    double? tempIndEfterVarmeflade,
    double? tempUd,
    bool? erFaerdigbehandlet,
    String? varmegenvindingsType,  // ✅ NY
  }) {
    return AnlaegsData(
      anlaegsNavn: anlaegsNavn ?? this.anlaegsNavn,
      ventMaerkatNr: ventMaerkatNr ?? this.ventMaerkatNr,
      valgtAnlaegstype: valgtAnlaegstype ?? this.valgtAnlaegstype,
      aarsbesparelse: aarsbesparelse ?? this.aarsbesparelse,
      tilbagebetalingstid: tilbagebetalingstid ?? this.tilbagebetalingstid,
      luftInd: luftInd ?? this.luftInd,
      luftUd: luftUd ?? this.luftUd,
      trykInd: trykInd ?? this.trykInd,
      trykUd: trykUd ?? this.trykUd,
      kwInd: kwInd ?? this.kwInd,
      kwUd: kwUd ?? this.kwUd,
      elOmkostningIndFoer: elOmkostningIndFoer ?? this.elOmkostningIndFoer,
      elOmkostningUdFoer: elOmkostningUdFoer ?? this.elOmkostningUdFoer,
      hzInd: hzInd ?? this.hzInd,
      hzUd: hzUd ?? this.hzUd,
      elpris: elpris ?? this.elpris,
      varmepris: varmepris ?? this.varmepris,
      varmeResultat: varmeResultat ?? this.varmeResultat,
      varmeAarsbesparelse: varmeAarsbesparelse ?? this.varmeAarsbesparelse,
      varmeBesparelseKWh: varmeBesparelseKWh ?? this.varmeBesparelseKWh,
      varmeforbrugKWhFoer: varmeforbrugKWhFoer ?? this.varmeforbrugKWhFoer,
      varmeOmkostningFoer: varmeOmkostningFoer ?? this.varmeOmkostningFoer,
      varmeforbrugKWHEfter: varmeforbrugKWHEfter ?? this.varmeforbrugKWHEfter,
      varmeOmkostningEfter: varmeOmkostningEfter ?? this.varmeOmkostningEfter,
      trykFoerInd: trykFoerInd ?? this.trykFoerInd,
      trykEfterInd: trykEfterInd ?? this.trykEfterInd,
      trykFoerUd: trykFoerUd ?? this.trykFoerUd,
      trykEfterUd: trykEfterUd ?? this.trykEfterUd,
      trykFoerIndMax: trykFoerIndMax ?? this.trykFoerIndMax,
      trykEfterIndMax: trykEfterIndMax ?? this.trykEfterIndMax,
      trykFoerUdMax: trykFoerUdMax ?? this.trykFoerUdMax,
      trykEfterUdMax: trykEfterUdMax ?? this.trykEfterUdMax,
      luftIndMax: luftIndMax ?? this.luftIndMax,
      luftUdMax: luftUdMax ?? this.luftUdMax,
      kVaerdiInd: kVaerdiInd ?? this.kVaerdiInd,
      kVaerdiUd: kVaerdiUd ?? this.kVaerdiUd,
      maksLuftInd: maksLuftInd ?? this.maksLuftInd,
      maksLuftUd: maksLuftUd ?? this.maksLuftUd,
      maksEffektInd: maksEffektInd ?? this.maksEffektInd,
      maksEffektUd: maksEffektUd ?? this.maksEffektUd,
      effektMaaltInd: effektMaaltInd ?? this.effektMaaltInd,
      effektMaaltUd: effektMaaltUd ?? this.effektMaaltUd,
      trykDifferensInd: trykDifferensInd ?? this.trykDifferensInd,
      trykDifferensUd: trykDifferensUd ?? this.trykDifferensUd,
      trykGamleFiltreInd: trykGamleFiltreInd ?? this.trykGamleFiltreInd,
      trykGamleFiltreUd: trykGamleFiltreUd ?? this.trykGamleFiltreUd,
      antalHeleFiltreInd: antalHeleFiltreInd ?? this.antalHeleFiltreInd,
      antalHalveFiltreInd: antalHalveFiltreInd ?? this.antalHalveFiltreInd,
      antalHeleFiltreUd: antalHeleFiltreUd ?? this.antalHeleFiltreUd,
      antalHalveFiltreUd: antalHalveFiltreUd ?? this.antalHalveFiltreUd,
      kammerBredde: kammerBredde ?? this.kammerBredde,
      kammerHoede: kammerHoede ?? this.kammerHoede,
      kammerLaengde: kammerLaengde ?? this.kammerLaengde,
      valgtTilstand: valgtTilstand ?? this.valgtTilstand,
      erBeregnetInd: erBeregnetInd ?? this.erBeregnetInd,
      erBeregnetUd: erBeregnetUd ?? this.erBeregnetUd,
      remUdskiftningPris: remUdskiftningPris ?? this.remUdskiftningPris,
      omkostningFoer: omkostningFoer ?? this.omkostningFoer,
      omkostningEfter: omkostningEfter ?? this.omkostningEfter,
      eksisterendeVarenummerInd: eksisterendeVarenummerInd ?? this.eksisterendeVarenummerInd,
      eksisterendeVarenummerUd: eksisterendeVarenummerUd ?? this.eksisterendeVarenummerUd,
      tempIndEfterGenvindingEfter: tempIndEfterGenvindingEfter ?? this.tempIndEfterGenvindingEfter,
      dokumentation: dokumentation ?? this.dokumentation,
      filterResultat: filterResultat ?? this.filterResultat,
      filterValg: filterValg ?? this.filterValg,
      driftstimer: driftstimer ?? this.driftstimer,
      virkningsgradInd: virkningsgradInd ?? this.virkningsgradInd,
      virkningsgradUd: virkningsgradUd ?? this.virkningsgradUd,
      filterKammerLaengdeInd: filterKammerLaengdeInd ?? this.filterKammerLaengdeInd,
      filterKammerLaengdeUd: filterKammerLaengdeUd ?? this.filterKammerLaengdeUd,
      erBeregnetUdFraKVaerdiInd: erBeregnetUdFraKVaerdiInd ?? this.erBeregnetUdFraKVaerdiInd,
      erBeregnetUdFraKVaerdiUd: erBeregnetUdFraKVaerdiUd ?? this.erBeregnetUdFraKVaerdiUd,
      erLuftmaengdeMaaeltIndtastetInd: erLuftmaengdeMaaeltIndtastetInd ?? this.erLuftmaengdeMaaeltIndtastetInd,
      erLuftmaengdeMaaeltIndtastetUd: erLuftmaengdeMaaeltIndtastetUd ?? this.erLuftmaengdeMaaeltIndtastetUd,
      internKommentar: internKommentar ?? this.internKommentar,
      recirkuleringProcent: recirkuleringProcent ?? this.recirkuleringProcent,
      friskluftTemp: friskluftTemp ?? this.friskluftTemp,
      tempIndEfterGenvinding: tempIndEfterGenvinding ?? this.tempIndEfterGenvinding,
      tempIndEfterVarmeflade: tempIndEfterVarmeflade ?? this.tempIndEfterVarmeflade,
      tempUd: tempUd ?? this.tempUd,
      erFaerdigbehandlet: erFaerdigbehandlet ?? this.erFaerdigbehandlet,
      varmegenvindingsType: varmegenvindingsType ?? this.varmegenvindingsType,  // ✅ NY
    );
  }

  factory AnlaegsData.empty() {
    return AnlaegsData(
      anlaegsNavn: '',
      ventMaerkatNr: '',
      valgtAnlaegstype: '',
      aarsbesparelse: 0,
      tilbagebetalingstid: 0,
      luftInd: 0,
      luftUd: 0,
      trykInd: 0,
      trykUd: 0,
      kwInd: 0,
      kwUd: 0,
      elOmkostningIndFoer: 0,
      elOmkostningUdFoer: 0,
      hzInd: 0,
      hzUd: 0,
      elpris: 0,
      varmepris: 0,
      eksisterendeVarenummerInd: '',
      eksisterendeVarenummerUd: '',
      varmeResultat: null,
      varmeAarsbesparelse: 0,
      varmeBesparelseKWh: 0,
      varmeforbrugKWhFoer: 0,
      varmeOmkostningFoer: 0,
      varmeforbrugKWHEfter: 0,
      varmeOmkostningEfter: 0,
      trykFoerInd: null,
      trykEfterInd: null,
      trykFoerUd: null,
      trykEfterUd: null,
      trykFoerIndMax: null,
      trykEfterIndMax: null,
      trykFoerUdMax: null,
      trykEfterUdMax: null,
      luftIndMax: null,
      luftUdMax: null,
      kVaerdiInd: null,
      kVaerdiUd: null,
      maksLuftInd: null,
      maksLuftUd: null,
      maksEffektInd: null,
      maksEffektUd: null,
      effektMaaltInd: null,
      effektMaaltUd: null,
      trykDifferensInd: null,
      trykDifferensUd: null,
      trykGamleFiltreInd: null,
      trykGamleFiltreUd: null,
      antalHeleFiltreInd: null,
      antalHalveFiltreInd: null,
      antalHeleFiltreUd: null,
      antalHalveFiltreUd: null,
      kammerBredde: 0,
      kammerHoede: 0,
      kammerLaengde: 0,
      valgtTilstand: '',
      erBeregnetInd: false,
      erBeregnetUd: false,
      remUdskiftningPris: null,
      omkostningFoer: 0,
      omkostningEfter: 0,
      tempIndEfterGenvindingEfter: 0,
      dokumentation: [],
      filterResultat: null,
      filterValg: null,
      driftstimer: 0,
      virkningsgradInd: 0,
      virkningsgradUd: 0,
      filterKammerLaengdeInd: 0,
      filterKammerLaengdeUd: 0,
      erBeregnetUdFraKVaerdiInd: false,
      erBeregnetUdFraKVaerdiUd: false,
      erLuftmaengdeMaaeltIndtastetInd: false,
      erLuftmaengdeMaaeltIndtastetUd: false,
      internKommentar: null,
      recirkuleringProcent: null,
      erFaerdigbehandlet: false,
      varmegenvindingsType: null,  // ✅ NY
    );
  }
}