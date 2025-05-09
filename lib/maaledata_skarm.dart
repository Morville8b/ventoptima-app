import 'package:flutter/material.dart';
import 'resultat_intern_skarm.dart';
import 'package:ventoptima/widgets/vis_dokumentation_dialog.dart';
import 'dokumentation_billede_skarm.dart';
import 'lav_hz_beregning.dart';
import 'anlaegs_data.dart';
import 'generel_projekt_info.dart';
import 'inddata_ventilator.dart';
import 'inddata_luftmaengde.dart';
import 'inddata_varmegenvindning.dart';
import 'ebmpapst.dart';
class MaaledataSkarm extends StatefulWidget {
    final GenerelProjektInfo projektInfo;

    const MaaledataSkarm({super.key, required this.projektInfo});

    @override
    State<MaaledataSkarm> createState() => _MaaledataSkarmState();
}

class _MaaledataSkarmState extends State<MaaledataSkarm> {
    bool _visKVaerdiBeregningInd = false;
    bool _visEffektBeregningInd = false;
    bool _visKVaerdiBeregningUd = false;
    bool _visEffektBeregningUd = false;
    bool _visVarmegenvinding = false;
    bool _beregnUdFraIndblaesning = true;
    bool _beregnetInd = false;
    String _valgtAnlaegstype = 'Ventilationsanlæg';

    double _samletTrykInd = 0;
    double _samletTrykUd = 0;

    // 👇 Tilføj disse to
    double _luftMaaltInd = 0;
    double _luftMaaltUd = 0;

    final TextEditingController _anlaegsNavnController = TextEditingController();
    final TextEditingController _ventMaerkatNrController = TextEditingController();
    final TextEditingController _tFriskController = TextEditingController();
    final TextEditingController _tIndController = TextEditingController();
    final TextEditingController _tAfkastController = TextEditingController();
    final TextEditingController _tUdController = TextEditingController();

    final TextEditingController _hzIndController = TextEditingController();
    final TextEditingController _hzUdController = TextEditingController();

    final TextEditingController _trykGamleFiltreInd = TextEditingController();
    final TextEditingController _antalFiltreInd = TextEditingController();
    final TextEditingController _trykFoerInd = TextEditingController();
    final TextEditingController _trykEfterIndController = TextEditingController();
    final TextEditingController _trykEfterInd = TextEditingController(); // Denne er korrekt tilføjet
    final TextEditingController _effektInd = TextEditingController();
    final TextEditingController _trykEfterUdController = TextEditingController();
    final TextEditingController _trykGamleFiltreUd = TextEditingController();
    final TextEditingController _antalFiltreUd = TextEditingController();
    final TextEditingController _trykFoerUd = TextEditingController();

    final TextEditingController _trykEfterUd = TextEditingController(); // Denne er korrekt tilføjet
    final TextEditingController _effektUd = TextEditingController();

    final TextEditingController _luftMaaltIndController = TextEditingController();
    final TextEditingController _kVaerdiIndController = TextEditingController();
    final TextEditingController _trykDifferensIndController = TextEditingController();
    final TextEditingController _maksLuftIndController = TextEditingController();
    final TextEditingController _maksEffektIndController = TextEditingController();
    final TextEditingController _effektMaaltIndController = TextEditingController();

    final TextEditingController _luftMaaltUdController = TextEditingController();
    final TextEditingController _kVaerdiUdController = TextEditingController();
    final TextEditingController _trykDifferensUdController = TextEditingController();
    final TextEditingController _maksLuftUdController = TextEditingController();
    final TextEditingController _maksEffektUdController = TextEditingController();
    final TextEditingController _effektMaaltUdController = TextEditingController();

    final Color _matchingGreen = Color(0xFF34E0A1);
    final Color _matchingBlue = Color(0xFF006390);

    void _visBilledeBeskrivelsePopup() async {
        final bool? vilFortsaette = await visDokumentationsDialog(context);

        final double driftstimer = widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) * widget.projektInfo.ugerPerAar;
        final EbmpapstResultat eksisterendeInd = findNaermesteVentilator(_samletTrykInd, _luftMaaltInd, driftstimer: driftstimer);
        final EbmpapstResultat eksisterendeUd = findNaermesteVentilator(_samletTrykUd, _luftMaaltUd, driftstimer: driftstimer);

        final bool erBeregnetInd = _visKVaerdiBeregningInd || _visEffektBeregningInd;
        final bool erBeregnetUd = _visKVaerdiBeregningUd || _visEffektBeregningUd;

        final double hzInd = double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0;
        final double hzUd = double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0;

        final double trykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
        final double trykEfterInd = double.tryParse(_trykEfterIndController.text.replaceAll(',', '.')) ?? 0;
        final double trykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;
        final double trykEfterUd = double.tryParse(_trykEfterUdController.text.replaceAll(',', '.')) ?? 0;

        final double samletTrykInd = trykFoerInd.abs() + trykEfterInd.abs();
        final double samletTrykUd = trykFoerUd.abs() + trykEfterUd.abs();

        if (vilFortsaette == true) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DokumentationBilledeSkarm(
                        anlaegsNavn: _anlaegsNavnController.text,
                        logoPath: 'assets/images/ebmpapst.png',
                        projektInfo: widget.projektInfo,
                        kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                        luftInd: _luftMaaltInd,
                        trykInd: samletTrykInd,
                        kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                        luftUd: _luftMaaltUd,
                        trykUd: samletTrykUd,

                        // 👇 Disse 6 manglede og skal tilføjes:
                        hzInd: hzInd ?? 0,
                        hzUd: hzUd ?? 0,
                        erBeregnetInd: erBeregnetInd,
                        erBeregnetUd: erBeregnetUd,
                        eksisterendeVarenummerInd: eksisterendeInd.varenummer,
                        eksisterendeVarenummerUd: eksisterendeUd.varenummer,
                    ),
                ),
            );
        } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ResultatInternSkarm(
                        anlagsNavn: _anlaegsNavnController.text,
                        kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                        luftInd: _luftMaaltInd,
                        statiskTrykInd: samletTrykInd,
                        kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                        luftUd: _luftMaaltUd,
                        statiskTrykUd: samletTrykUd,
                        hzInd: hzInd,
                        hzUd: hzUd,
                        projektInfo: widget.projektInfo,
                        erBeregnetInd: erBeregnetInd,
                        erBeregnetUd: erBeregnetUd,
                        eksisterendeVarenummerInd: eksisterendeInd.varenummer,
                        eksisterendeVarenummerUd: eksisterendeUd.varenummer,
                        trykFoerIndMax: trykFoerInd,
                        trykEfterIndMax: trykEfterInd,
                        trykFoerUdMax: trykFoerUd,
                        trykEfterUdMax: trykEfterUd,
                    ),
                ),
            );
        }
    }
    @override
    void initState() {
        super.initState();

        _hzIndController.addListener(() {
            setState(() {}); // Genopbyg skærmen når indblæsnings-Hz ændres
        });

        _hzUdController.addListener(() {
            setState(() {}); // Genopbyg skærmen når udsugnings-Hz ændres
        });
    }

    @override
    Widget build(BuildContext context) {
        // Tillad null hvis feltet er tomt
        final double? hzInd = double.tryParse(_hzIndController.text.replaceAll(',', '.'));
        final double? hzUd = double.tryParse(_hzUdController.text.replaceAll(',', '.'));

        final lavHzWidget = BeregnVedLavHzWidget(
            hzInd: hzInd ?? 0,
            hzUd: hzUd ?? 0,
            onBeregnResultatInd: (luft, tryk, {required bool erDesignData}) {
                setState(() {
                    _luftMaaltInd = luft;
                    _samletTrykInd = tryk;
                    _trykDifferensIndController.text = tryk.toStringAsFixed(0);
                    _visKVaerdiBeregningInd = erDesignData;
                    _visEffektBeregningInd = false;
                    print('✅ Gemt luftInd: $_luftMaaltInd, tryk: $_samletTrykInd');
                });
            },
            onBeregnResultatUd: (luft, tryk, {required bool erDesignData}) {
                setState(() {
                    _luftMaaltUd = luft;
                    _luftMaaltUdController.text = luft.toStringAsFixed(0); // 👈 denne linje skal med
                    _samletTrykUd = tryk;
                    _trykDifferensUdController.text = tryk.toStringAsFixed(0);
                    _visKVaerdiBeregningUd = erDesignData;
                    _visEffektBeregningUd = false;
                    print('✅ Gemt luftUd: $_luftMaaltUd, tryk: $_samletTrykUd');
                });
            },
        );

        return Scaffold(
            body: Stack(
                children: [
                    SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const SizedBox(height: 100),
                                _sektionTitel('STAMDATA'),
                                AnlaegsdataWidget(
                                    anlaegsNavnController: _anlaegsNavnController,
                                    ventMaerkatNrController: _ventMaerkatNrController,
                                    valgtAnlaegstype: _valgtAnlaegstype,
                                    onAnlaegstypeChanged: (val) => setState(() => _valgtAnlaegstype = val!),
                                ),
                                const Divider(height: 32),
                                _sektionTitel('VENTILATORER'),
                                VentilatorVisning(
                                    anlaegstype: _valgtAnlaegstype,
                                    trykGamleFiltreIndController: _trykGamleFiltreInd,
                                    antalFiltreIndController: _antalFiltreInd,
                                    trykFoerIndController: _trykFoerInd,
                                    trykEfterIndController: _trykEfterInd,
                                    hzIndController: _hzIndController,
                                    effektIndController: _effektInd,
                                    trykGamleFiltreUdController: _trykGamleFiltreUd,
                                    antalFiltreUdController: _antalFiltreUd,
                                    trykFoerUdController: _trykFoerUd,
                                    trykEfterUdController: _trykEfterUd,
                                    hzUdController: _hzUdController,
                                    effektUdController: _effektUd,
                                    onSamletTrykIndChanged: (val) => _samletTrykInd = val,
                                    onSamletTrykUdChanged: (val) => _samletTrykUd = val,
                                ),

                                // ✅ Her vises lav frekvens-widget, hvis relevant
                                lavHzWidget,

                                const Divider(height: 32),
                                _sektionTitel('LUFTMÆNGDE'),
                                LuftmaengdeVisning(
                                    anlaegstype: _valgtAnlaegstype,
                                    maaltLuftmaengdeIndController: _luftMaaltIndController,
                                    luftmaengdeKVaerdiIndController: _kVaerdiIndController,
                                    trykDifferensIndController: _trykDifferensIndController,
                                    maksLuftIndController: _maksLuftIndController,
                                    maksEffektIndController: _maksEffektIndController,
                                    effektMaaltIndController: _effektMaaltIndController,
                                    maaltLuftmaengdeUdController: _luftMaaltUdController,
                                    luftmaengdeKVaerdiUdController: _kVaerdiUdController,
                                    trykDifferensUdController: _trykDifferensUdController,
                                    maksLuftUdController: _maksLuftUdController,
                                    maksEffektUdController: _maksEffektUdController,
                                    effektMaaltUdController: _effektMaaltUdController,
                                    visKVaerdiBeregningInd: _visKVaerdiBeregningInd,
                                    visEffektBeregningInd: _visEffektBeregningInd,
                                    visKVaerdiBeregningUd: _visKVaerdiBeregningUd,
                                    visEffektBeregningUd: _visEffektBeregningUd,
                                    onSkiftKVaerdiInd: () => setState(() {
                                        _visKVaerdiBeregningInd = !_visKVaerdiBeregningInd;
                                        if (_visKVaerdiBeregningInd) _visEffektBeregningInd = false;
                                    }),
                                    onSkiftEffektInd: () => setState(() {
                                        _visEffektBeregningInd = !_visEffektBeregningInd;
                                        if (_visEffektBeregningInd) _visKVaerdiBeregningInd = false;
                                    }),
                                    onSkiftKVaerdiUd: () => setState(() {
                                        _visKVaerdiBeregningUd = !_visKVaerdiBeregningUd;
                                        if (_visKVaerdiBeregningUd) _visEffektBeregningUd = false;
                                    }),
                                    onSkiftEffektUd: () => setState(() {
                                        _visEffektBeregningUd = !_visEffektBeregningUd;
                                        if (_visEffektBeregningUd) _visKVaerdiBeregningUd = false;
                                    }),
                                ),

                                const Divider(height: 32),
        _sektionTitel('VARMEGENVINDING'),
        SwitchListTile(
        title: Text(
        _valgtAnlaegstype == 'Ventilationsanlæg'
        ? 'Kan der regnes på varmegenvinding?'
            : _valgtAnlaegstype == 'Indblæsningsanlæg'
        ? 'Er indblæsningsluften opvarmet?'
            : 'Er udsugningsluften opvarmet?',
        ),
        subtitle: const Text('Vælg om beregning skal vises'),
        value: _visVarmegenvinding,
        onChanged: (val) => setState(() => _visVarmegenvinding = val),
        activeColor: _matchingGreen, // Farven HEX #34E0A1
        inactiveTrackColor: _matchingGreen, // Farven HEX #34E0A1
        ),
        if (_visVarmegenvinding)
            VarmegenvindingSektion(
                anlaegstype: _valgtAnlaegstype,
                visVarmegenvinding: _visVarmegenvinding,
                beregnUdFraIndblaesning: _beregnUdFraIndblaesning,
                visBeregningsMetode: _valgtAnlaegstype == 'Ventilationsanlæg',
                onMethodChanged: (val) => setState(() => _beregnUdFraIndblaesning = val),
                tFriskController: _tFriskController,
                tIndController: _tIndController,
                tUdController: _tUdController,
                tAfkastController: _tAfkastController,
                hzInd: hzInd ?? 0,
                hzUd: hzUd ?? 0,
                onVisPopupInd: () {},
                onVisPopupUd: () {},
            ),

                                const SizedBox(height: 32),
        // To knapper: Tilbage og Næste
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    ElevatedButton(
                        onPressed: () {
                            Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _matchingGreen,
                        ),
                        child: Text(
                            'Tilbage',
                            style: TextStyle(color: _matchingBlue),
                        ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                        onPressed: () async {
                            // 🔧 Hvis luftmængde mangler, prøv at hente den manuelt fra inputfelterne
                            if (_luftMaaltInd == 0.0) {
                                _luftMaaltInd = double.tryParse(_luftMaaltIndController.text.replaceAll(',', '.')) ?? 0.0;
                            }
                            if (_luftMaaltUd == 0.0) {
                                _luftMaaltUd = double.tryParse(_luftMaaltUdController.text.replaceAll(',', '.')) ?? 0.0;
                            }

                            // Beregn driftstimer (dette forbliver uændret)
                            final double driftstimer = widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) * widget.projektInfo.ugerPerAar;
                            final EbmpapstResultat eksisterendeInd = findNaermesteVentilator(_samletTrykInd, _luftMaaltInd, driftstimer: driftstimer);
                            final EbmpapstResultat eksisterendeUd = findNaermesteVentilator(_samletTrykUd, _luftMaaltUd, driftstimer: driftstimer);
                            final bool erBeregnetInd = _visKVaerdiBeregningInd || _visEffektBeregningInd;
                            final bool erBeregnetUd = _visKVaerdiBeregningUd || _visEffektBeregningUd;

                            // 🔔 Advarsler ved positivt tryk før ventilator
                            final double trykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
                            final double trykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;

                            // Tjek for positivt tryk før ventilatorerne
                            if (trykFoerInd > 0) {
                                await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                        title: const Text('Advarsel'),
                                        content: const Text('Du har angivet et positivt tryk før indblæsningsventilatoren. Tjek målingen.'),
                                        actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                                        ],
                                    ),
                                );
                            }

                            if (trykFoerUd > 0) {
                                await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                        title: const Text('Advarsel'),
                                        content: const Text('Du har angivet et positivt tryk før udsugningsventilatoren. Tjek målingen.'),
                                        actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                                        ],
                                    ),
                                );
                            }

                            /// ➕ Beregn korrekt fasit tryk (tryk før og tryk efter som absolutværdi)
                            final double beregnetTrykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
                            final double beregnetTrykEfterInd = double.tryParse(_trykEfterIndController.text.replaceAll(',', '.')) ?? 0;
                            final double beregnetTrykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;
                            final double beregnetTrykEfterUd = double.tryParse(_trykEfterUdController.text.replaceAll(',', '.')) ?? 0;

                            final double statiskTrykMagInd = beregnetTrykFoerInd.abs() + beregnetTrykEfterInd.abs();
                            final double statiskTrykMagUd = beregnetTrykFoerUd.abs() + beregnetTrykEfterUd.abs();
                            final Widget destinationSkarm = ResultatInternSkarm(
                                anlagsNavn: _anlaegsNavnController.text,
                                kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                                luftInd: _luftMaaltInd,
                                statiskTrykInd: _samletTrykInd,
                                kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                                luftUd: _luftMaaltUd,
                                statiskTrykUd: _samletTrykUd,
                                hzInd: hzInd ?? 0,
                                hzUd: hzUd ?? 0,
                                projektInfo: widget.projektInfo,
                                erBeregnetInd: erBeregnetInd,
                                erBeregnetUd: erBeregnetUd,
                                eksisterendeVarenummerInd: eksisterendeInd.varenummer,
                                eksisterendeVarenummerUd: eksisterendeUd.varenummer,
                                trykFoerIndMax: beregnetTrykFoerInd,
                                trykEfterIndMax: beregnetTrykEfterInd,
                                trykFoerUdMax: beregnetTrykFoerUd,
                                trykEfterUdMax: beregnetTrykEfterUd,
                            );
                            final bool? vilTilfoejeBilleder = await visDokumentationsDialog(context);
                            if (vilTilfoejeBilleder == true) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DokumentationBilledeSkarm(
                                            anlaegsNavn: _anlaegsNavnController.text,
                                            logoPath: 'assets/images/ebmpapst.png',
                                            projektInfo: widget.projektInfo,
                                            kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                                            luftInd: _luftMaaltInd,
                                            trykInd: statiskTrykMagInd,
                                            kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                                            luftUd: _luftMaaltUd,
                                            trykUd: statiskTrykMagUd,

                                            // 🟢 Tilføj disse felter også:
                                            hzInd: hzInd ?? 0,
                                            hzUd: hzUd ?? 0,
                                            erBeregnetInd: erBeregnetInd,
                                            erBeregnetUd: erBeregnetUd,
                                            eksisterendeVarenummerInd: eksisterendeInd.varenummer,
                                            eksisterendeVarenummerUd: eksisterendeUd.varenummer,
                                        ),
                                    ),
                                );
                            }else {
                                final double driftstimer = widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) * widget.projektInfo.ugerPerAar;
                                final EbmpapstResultat eksisterendeInd = findNaermesteVentilator(_samletTrykInd, _luftMaaltInd, driftstimer: driftstimer);
                                final EbmpapstResultat eksisterendeUd = findNaermesteVentilator(_samletTrykUd, _luftMaaltUd, driftstimer: driftstimer);
                                final bool erBeregnetInd = _visKVaerdiBeregningInd || _visEffektBeregningInd;
                                final bool erBeregnetUd = _visKVaerdiBeregningUd || _visEffektBeregningUd;

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ResultatInternSkarm(
                                            anlagsNavn: _anlaegsNavnController.text,
                                            kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                                            luftInd: _luftMaaltInd,
                                            statiskTrykInd: _samletTrykInd,
                                            kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                                            luftUd: _luftMaaltUd,
                                            statiskTrykUd: _samletTrykUd,
                                            hzInd: hzInd ?? 0, // ← tilføj dette
                                            hzUd: hzUd ?? 0,   // ← og dette
                                            projektInfo: widget.projektInfo,
                                            erBeregnetInd: erBeregnetInd,
                                            erBeregnetUd: erBeregnetUd,
                                            eksisterendeVarenummerInd: eksisterendeInd.varenummer,
                                            eksisterendeVarenummerUd: eksisterendeUd.varenummer,
                                        ),
                                    ),
                                );
                            }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _matchingGreen,
                        ),
                        child: Text(
                            'Næste',
                            style: TextStyle(color: _matchingBlue),
                        ),
                    ),
                ],
            ),
        ],
        ),
        ),
        Container(
        height: 90,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
        clipBehavior: Clip.none,
        children: [
        Align(
        alignment: Alignment.centerLeft,
        child: Text(
        'Måledata',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        ),
        Positioned(
        top: 44,
        right: 0,
        child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: Image.asset(
        'assets/images/star_logo.png',
        height: 45,
        ),
        ),
        ),
        ],
        ),
        ),
        ],
        ),
        );
        }

        // Sektionstitel med blå tekst
        Widget _sektionTitel(String tekst) {
        return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: _matchingGreen, // Grøn farve
      child: Text(
        tekst,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _matchingBlue, // Inaktiv farve
        ),
      ),
    );
  }
}







































































































































































































