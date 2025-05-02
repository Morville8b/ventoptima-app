import 'package:flutter/material.dart';

import 'package:ventoptima/widgets/vis_dokumentation_dialog.dart';

import 'anlaegs_data.dart';
import 'generel_projekt_info.dart';
import 'indberetning_skarm.dart';
import 'inddata_ventilator.dart';
import 'inddata_luftmaengde.dart';
import 'inddata_varmegenvindning.dart';


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

        String _valgtAnlaegstype = 'Ventilationsanlæg';

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
        final TextEditingController _trykEfterInd = TextEditingController();
        final TextEditingController _effektInd = TextEditingController();

        final TextEditingController _trykGamleFiltreUd = TextEditingController();
        final TextEditingController _antalFiltreUd = TextEditingController();
        final TextEditingController _trykFoerUd = TextEditingController();
        final TextEditingController _trykEfterUd = TextEditingController();
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

        // Grøn farve, der matcher logoet
        final Color _matchingGreen = Color(0xFF34E0A1); // Farven HEX #34E0A1

        // Blå farve
        final Color _matchingBlue = Color(0xFF006390); // Farven HEX #006390

        void _visBilledeBeskrivelsePopup() async {
            final bool? vilFortsaette = await visDokumentationsDialog(context);

            if (vilFortsaette == true) {
            Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => IndberetningSkarm(
            onGemOgNaeste: () => Navigator.pop(context),
            projektInfo: widget.projektInfo,
            ),
            ),
            );
            }
        }

        @override
        Widget build(BuildContext context) {
        final double hzInd = double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0;
        final double hzUd = double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0;

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
        ),
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
        hzInd: hzInd,
        hzUd: hzUd,
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
        // Funktion til tilbage navigation
        Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
        backgroundColor: _matchingGreen, // Grøn farve til knapbaggrund
        ),
        child: Text(
        'Tilbage',
        style: TextStyle(
        color: _matchingBlue, // Blå farve til teksten
        ),
        ),
        ),
        const SizedBox(width: 16), // Plads mellem knapperne
        ElevatedButton(
        onPressed: _visBilledeBeskrivelsePopup,
        style: ElevatedButton.styleFrom(
        backgroundColor: _matchingGreen, // Grøn farve til knapbaggrund
        ),
        child: Text(
        'Næste',
        style: TextStyle(
        color: _matchingBlue, // Blå farve til teksten
        ),
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







































































































































































































