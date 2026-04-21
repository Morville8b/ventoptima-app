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
import 'package:ventoptima/widgets/vis_virkningsgrad_advarsel.dart';
import 'package:ventoptima/widgets/kammeropmaaling.dart';
import 'package:ventoptima/widgets/tilstand_popup.dart';
// eller hvad filnavnet hedder
import 'ebmpapst.dart' as ebmpapst;
import 'package:ventoptima/ventilator_samlet_beregning.dart';
import 'beregning_varmeforbrug.dart';
import 'filter_resultat.dart';

enum VarmegenvindingType {
    krydsveksler,
    dobbeltKrydsveksler,
    roterendeVeksler,
    modstroemsVeksler,
    vaeskekobletVeksler,
    blandekammer,
    recirkulering,
}

// 🔽 Funktion til at vise enum-navne i UI
String _visNavn(VarmegenvindingType type) {
    switch (type) {
        case VarmegenvindingType.krydsveksler:
            return 'Krydsveksler';
        case VarmegenvindingType.dobbeltKrydsveksler:
            return 'Dobbelt krydsveksler';
        case VarmegenvindingType.roterendeVeksler:
            return 'Roterende veksler';
        case VarmegenvindingType.modstroemsVeksler:
            return 'Modstrømsveksler';
        case VarmegenvindingType.vaeskekobletVeksler:
            return 'Væskekoblet veksler';
        case VarmegenvindingType.blandekammer:
            return 'Blandekammer';
        case VarmegenvindingType.recirkulering:
            return 'Recirkulering';
    }
}

class MaaledataSkarm extends StatefulWidget {
    final GenerelProjektInfo projektInfo;
    final int index;
    final List<AnlaegsData> alleAnlaeg; // ← denne MANGLEDE
    final Map<String, TextEditingController> driftstimer;
    final List<VentilatorOekonomiSamlet> forslag;


    final double? aarsbesparelse;
    final double? tilbagebetalingstid;
    final String? eksisterendeVarenummerInd;
    final String? eksisterendeVarenummerUd;
    const MaaledataSkarm({
        super.key,
        required this.forslag,
        required this.projektInfo,
        required this.index,
        required this.alleAnlaeg,
        required this.driftstimer,
        this.aarsbesparelse,
        this.tilbagebetalingstid,
        this.eksisterendeVarenummerInd,
        this.eksisterendeVarenummerUd,
    });

    @override
    State<MaaledataSkarm> createState() => _MaaledataSkarmState();
}

class _MaaledataSkarmState extends State<MaaledataSkarm> {
    final GlobalKey<BeregnVedLavHzWidgetState> lavHzKey = GlobalKey<BeregnVedLavHzWidgetState>();
    double remUdskiftningPris = 0;

    final FocusNode _dummyFocus = FocusNode();

    @override
    void dispose() {
        _dummyFocus.dispose();
        super.dispose();
    }

    VarmegenvindingType? _valgtVarmegenvindingstype = VarmegenvindingType.krydsveksler;

    // 🔽 Her indsætter du de to metoder:
    double _beregnAarsbesparelse() {
        final kwInd = double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0;
        final kwUd = double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0;
        final elpris = widget.projektInfo.elPris;
        final timer = widget.driftstimer.values
            .map((t) => int.tryParse(t.text) ?? 0)
            .reduce((a, b) => a + b);

        final besparelseKwh = (kwInd - kwUd) * timer;
        return besparelseKwh * elpris;
    }

    // ✅ TILFØJ DENNE METODE HER
    Future<void> _fjernFokusKomplet() async {
        // Skjul tastatur
        FocusScope.of(context).unfocus();
        // Flyt fokus til et tomt node
        FocusScope.of(context).requestFocus(FocusNode());
        // Vent på at tastaturet lukker
        await Future.delayed(const Duration(milliseconds: 150));
    }


    Widget _dropdownVarmegenvindingType() {
        return DropdownButtonFormField<VarmegenvindingType>(
            initialValue: _valgtVarmegenvindingstype,
            decoration: const InputDecoration(
                labelText: 'Vælg varmegenvindingstype',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: VarmegenvindingType.values.map((type) {
                return DropdownMenuItem(
                    value: type,
                    child: Text(_visNavn(type)),
                );
            }).toList(),
            onChanged: (val) => setState(() => _valgtVarmegenvindingstype = val),
        );
    }


    double _beregnTilbagebetalingstid(double besparelse) {
        return (besparelse > 0) ? (remUdskiftningPris / besparelse) : double.infinity;
    }

    Future<FilterValg?> visFilterPopup({
        required BuildContext context,
        required AnlaegsData anlaeg,
        required GenerelProjektInfo projektInfo,
        required List<AnlaegsData> alleAnlaeg,
        required int index,
    }) async {
        String? valgtFilterFoerInd;
        String? valgtFilterFoerUd;

        final TextEditingController filterMaalIndController = TextEditingController();
        final TextEditingController filterMaalUdController = TextEditingController();

        final List<String> filterTyper = [
            "Basic-Flo M5 G 1050 592 x 592 x 520",
            "Basic-Flo M5 G 1050 592 x 592 x 600",
            "Basic-Flo F7 G 2570 592 x 592 x 520",
            "Basic-Flo F7 G 2570 592 x 592 x 600",
            "Hiflo XLS M5 592 x 592 x 520",
            "Hiflo XLS M5 592 x 592 x 640",
            "Hiflo XLS F7 592 x 592 x 520",
            "Hiflo XLS F7 592 x 592 x 640",
        ];

        return await Navigator.of(context).push(
            PageRouteBuilder<FilterValg>(
                opaque: false,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                pageBuilder: (context, animation, secondaryAnimation) {
                    return SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(0, -1),
                            end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                        )),
                        child: Align(
                            alignment: Alignment.topCenter,
                            child: Material(
                                color: Colors.transparent,
                                child: Container(
                                    margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 60), // ✅ Tilføjet bottom margin
                                    constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height * 0.85
                                            - MediaQuery.of(context).viewInsets.bottom, // ✅ TRÆK TASTATURHØJDE FRA
                                        maxWidth: 500,
                                    ),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                            ),
                                        ],
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            // Header (fast)
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFF34E0A1),
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                child: const Row(
                                                    children: [
                                                        Icon(Icons.filter_alt, color: Color(0xFF006390)), // ✅ Tilføjet ikon
                                                        SizedBox(width: 8),
                                                        Text(
                                                            "Filtervalg",
                                                            style: TextStyle(
                                                                color: Color(0xFF006390),
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 18,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),

                                            // Content (scrollbar)
                                            Expanded( // ✅ Ændret fra Flexible
                                                child: SingleChildScrollView(
                                                    padding: const EdgeInsets.all(20),
                                                    child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start, // ✅ Tilføjet
                                                        children: [
                                                            // Illustrationsbillede
                                                            Container(
                                                                padding: const EdgeInsets.all(8),
                                                                decoration: BoxDecoration(
                                                                    border: Border.all(color: const Color(0xFF34E0A1), width: 2),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Column(
                                                                    children: [
                                                                        const Text(
                                                                            'Målepunkt for filterkammer',
                                                                            style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 14,
                                                                                color: Color(0xFF006390),
                                                                            ),
                                                                        ),
                                                                        const SizedBox(height: 8),
                                                                        Image.asset(
                                                                            'assets/images/filterkammer.png',
                                                                            height: 150,
                                                                            fit: BoxFit.contain,
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                            const SizedBox(height: 20),

                                                            // INDBLÆSNING
                                                            const Text(
                                                                'INDBLÆSNING',
                                                                style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 15,
                                                                    color: Color(0xFF006390),
                                                                ),
                                                            ),
                                                            const SizedBox(height: 12),

                                                            TextFormField(
                                                                controller: filterMaalIndController,
                                                                keyboardType: TextInputType.text,
                                                                decoration: const InputDecoration(
                                                                    labelText: 'Filterkammer mål indblæsning (mm)',
                                                                    hintText: 'Indtast længde i millimeter',
                                                                    border: OutlineInputBorder(),
                                                                    prefixIcon: Icon(Icons.straighten, color: Color(0xFF34E0A1)),
                                                                ),
                                                            ),
                                                            const SizedBox(height: 12),

                                                            DropdownButtonFormField<String>(
                                                                isExpanded: true,
                                                                decoration: const InputDecoration(
                                                                    labelText: "Gammelt filter (indblæsning)",
                                                                    border: OutlineInputBorder(),
                                                                ),
                                                                initialValue: valgtFilterFoerInd,
                                                                items: filterTyper.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                                                                onChanged: (val) => valgtFilterFoerInd = val,
                                                            ),
                                                            const SizedBox(height: 24),

                                                            // UDSUGNING
                                                            const Text(
                                                                'UDSUGNING',
                                                                style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 15,
                                                                    color: Color(0xFF006390),
                                                                ),
                                                            ),
                                                            const SizedBox(height: 12),

                                                            TextFormField(
                                                                controller: filterMaalUdController,
                                                                keyboardType: TextInputType.text,
                                                                decoration: const InputDecoration(
                                                                    labelText: 'Filterkammer mål udsugning (mm)',
                                                                    hintText: 'Indtast længde i millimeter',
                                                                    border: OutlineInputBorder(),
                                                                    prefixIcon: Icon(Icons.straighten, color: Color(0xFF34E0A1)),
                                                                ),
                                                            ),
                                                            const SizedBox(height: 12),

                                                            DropdownButtonFormField<String>(
                                                                isExpanded: true,
                                                                decoration: const InputDecoration(
                                                                    labelText: "Gammelt filter (udsugning)",
                                                                    border: OutlineInputBorder(),
                                                                ),
                                                                initialValue: valgtFilterFoerUd,
                                                                items: filterTyper.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                                                                onChanged: (val) => valgtFilterFoerUd = val,
                                                            ),
                                                            const SizedBox(height: 20), // ✅ Ekstra padding i bunden
                                                        ],
                                                    ),
                                                ),
                                            ),

                                            // Actions (fast i bunden)
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                    color: Colors.grey[50], // ✅ Let grå baggrund
                                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                                ),
                                                child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                        Expanded(
                                                            child: OutlinedButton(
                                                                onPressed: () => Navigator.pop(context, null),
                                                                style: OutlinedButton.styleFrom(
                                                                    foregroundColor: const Color(0xFF006390),
                                                                    side: const BorderSide(color: Color(0xFF34E0A1), width: 2),
                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                ),
                                                                child: const Text("Spring over"),
                                                            ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                            child: ElevatedButton(
                                                                onPressed: () {
                                                                    final filterValg = FilterValg(
                                                                        filterFoerInd: valgtFilterFoerInd,
                                                                        filterEfterInd: null,
                                                                        filterFoerUd: valgtFilterFoerUd,
                                                                        filterEfterUd: null,
                                                                        filterMaalIndMm: double.tryParse(filterMaalIndController.text.replaceAll(',', '.')),
                                                                        filterMaalUdMm: double.tryParse(filterMaalUdController.text.replaceAll(',', '.')),
                                                                    );

                                                                    Navigator.pop(context, filterValg);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                    backgroundColor: const Color(0xFF34E0A1),
                                                                    foregroundColor: const Color(0xFF006390),
                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                    elevation: 0,
                                                                ),
                                                                child: const Text("Fortsæt", style: TextStyle(fontWeight: FontWeight.bold)),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    );
                },
                transitionDuration: const Duration(milliseconds: 400),
            ),
        );
    }

    // 🟢 Her indsætter vi funktionen:
    Future<double?> visRemtrukketPopup(BuildContext context, double luftmaengde) async {
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 50));

        const Color matchingGreen = Color(0xFF34E0A1);
        const Color matchingBlue = Color(0xFF006390);

        // 🔹 Første popup: Er det remtrukne ventilatorer?
        final svarRemtrukket = await Navigator.of(context).push<bool>(
            PageRouteBuilder(
                opaque: false,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                pageBuilder: (context, animation, secondaryAnimation) {
                    return SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(0, -1),
                            end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                        )),
                        child: Center(
                            child: Material(
                                color: Colors.transparent,
                                child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                            ),
                                        ],
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                    color: matchingGreen.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.settings,
                                                    size: 40,
                                                    color: matchingBlue,
                                                ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                                'Er det remtrukne ventilatorer?',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: matchingBlue,
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                                'Vælg om ventilatorerne er remtrukne. Dette har betydning for vurdering af efterfølgende komponenter.',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey[700],
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                                children: [
                                                    Expanded(
                                                        child: OutlinedButton(
                                                            onPressed: () => Navigator.pop(context, false),
                                                            style: OutlinedButton.styleFrom(
                                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                                side: const BorderSide(color: matchingGreen, width: 2),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                ),
                                                            ),
                                                            child: const Text(
                                                                'Nej',
                                                                style: TextStyle(
                                                                    color: matchingBlue,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                        child: ElevatedButton(
                                                            onPressed: () => Navigator.pop(context, true),
                                                            style: ElevatedButton.styleFrom(
                                                                backgroundColor: matchingGreen,
                                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                ),
                                                                elevation: 0,
                                                            ),
                                                            child: const Text(
                                                                'Ja',
                                                                style: TextStyle(
                                                                    color: matchingBlue,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    );
                },
                transitionDuration: const Duration(milliseconds: 400),
            ),
        );

        if (svarRemtrukket != true) return null;

        // 🔹 Anden popup: Skal der skiftes rem og remskiver?
        final svarUdskiftning = await Navigator.of(context).push<bool>(
            PageRouteBuilder(
                opaque: false,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                pageBuilder: (context, animation, secondaryAnimation) {
                    return SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(0, -1),
                            end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                        )),
                        child: Center(
                            child: Material(
                                color: Colors.transparent,
                                child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                            ),
                                        ],
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                    color: matchingGreen.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.build,
                                                    size: 40,
                                                    color: matchingBlue,
                                                ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                                'Udskiftning',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: matchingBlue,
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                                'Skal der skiftes rem + remskiver på ventilatoren?',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey[700],
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                                children: [
                                                    Expanded(
                                                        child: OutlinedButton(
                                                            onPressed: () => Navigator.pop(context, false),
                                                            style: OutlinedButton.styleFrom(
                                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                                side: const BorderSide(color: matchingGreen, width: 2),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                ),
                                                            ),
                                                            child: const Text(
                                                                'Nej',
                                                                style: TextStyle(
                                                                    color: matchingBlue,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                        child: ElevatedButton(
                                                            onPressed: () => Navigator.pop(context, true),
                                                            style: ElevatedButton.styleFrom(
                                                                backgroundColor: matchingGreen,
                                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                ),
                                                                elevation: 0,
                                                            ),
                                                            child: const Text(
                                                                'Ja',
                                                                style: TextStyle(
                                                                    color: matchingBlue,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    );
                },
                transitionDuration: const Duration(milliseconds: 400),
            ),
        );

        if (svarUdskiftning != true) return null;

        // 🔹 Beregn rem-pris baseret på luftmængde
        final luftmaengder = [5000, 10000, 15000, 20000, 25000, 30000];
        final priser = [4000, 6500, 8000, 8000, 8500, 8500];

        for (int i = 0; i < luftmaengder.length; i++) {
            if (luftmaengde <= luftmaengder[i]) return priser[i].toDouble();
        }

        return priser.last.toDouble();
    }

    // 🟢 POPUP 1: Spørg om manuel prisindtastning
    Future<bool?> visPrisIndtastningValg(BuildContext context) async {
        const Color matchingGreen = Color(0xFF34E0A1);
        const Color matchingBlue  = Color(0xFF006390);

        return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                icon: const Icon(Icons.edit, color: matchingBlue, size: 50),
                title: const Text(
                    'Prisindtastning',
                    style: TextStyle(color: matchingBlue, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                ),
                content: const Text(
                    'Vil du selv indtaste pris og data for det nye anlæg, eller skal programmet finde det automatisk?',
                    textAlign: TextAlign.center,
                ),

                actionsAlignment: MainAxisAlignment.center,
                actions: [
                    Row(
                        children: [
                            // ✅ NEJ (grøn baggrund) - VENSTRE SIDE
                            Expanded(
                                child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: matchingGreen,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                    ),
                                    child: const Text(
                                        'Brug standard løsning',
                                        style: TextStyle(
                                            color: matchingBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ),

                            const SizedBox(width: 12),

                            // ✅ JA (outline) - HØJRE SIDE
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: const BorderSide(color: matchingGreen, width: 2),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                    ),
                                    child: const Text(
                                        'Ønsker selv at indtaste pris',
                                        style: TextStyle(
                                            color: matchingBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        );
    }


// 🟢 POPUP 2: Vælg udskiftningstype
    Future<String?> visUdskiftningstype(BuildContext context) async {
        const Color matchingGreen = Color(0xFF34E0A1);
        const Color matchingBlue  = Color(0xFF006390);

        return await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                icon: const Icon(Icons.compare_arrows, color: matchingBlue, size: 50),
                title: const Text(
                    'Udskiftningstype',
                    style: TextStyle(
                        color: matchingBlue,
                        fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                ),
                content: const Text(
                    'Vælg om der skal udskiftes kun ventilatorer eller hele anlægget:',
                    textAlign: TextAlign.center,
                ),

                actionsAlignment: MainAxisAlignment.center,
                actions: [
                    Column(
                        children: [
                            // ➤ Øverste knap (grøn baggrund)
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context, 'ventilatorer'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: matchingGreen,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                    ),
                                    child: const Text(
                                        'Udskiftning af ventilatorer',
                                        style: TextStyle(
                                            color: matchingBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ),

                            const SizedBox(height: 12),

                            // ➤ Nederste knap (hvid med grøn outline)
                            SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context, 'hele_anlaeg'),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: const BorderSide(
                                            color: matchingGreen,
                                            width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                    ),
                                    child: const Text(
                                        'Udskiftning af hele anlæg',
                                        style: TextStyle(
                                            color: matchingBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        );
    }

// 🟢 POPUP 3: Indtast data - forskellige felter afhængig af type
    Future<Map<String, dynamic>?> visNytAnlaegData(BuildContext context, String udskiftningstype, {required String anlaegstype}) async {
        const Color localGreen = Color(0xFF34E0A1);
        const Color localBlue = Color(0xFF006390);

        final prisController = TextEditingController();
        final prisIndController = TextEditingController(); // Separat pris indblæsning
        final prisUdController = TextEditingController(); // Separat pris udsugning
        final virkningsgradController = TextEditingController();
        final effektIndController = TextEditingController();
        final effektUdController = TextEditingController();

        // Kun ved hele anlæg
        final trykFoerIndController = TextEditingController();
        final trykEfterIndController = TextEditingController();
        final luftIndController = TextEditingController();
        final trykFoerUdController = TextEditingController();
        final trykEfterUdController = TextEditingController();
        final luftUdController = TextEditingController();

        return await Navigator.of(context).push(
            PageRouteBuilder<Map<String, dynamic>>(
                opaque: false,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                pageBuilder: (context, animation, secondaryAnimation) {
                    return SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(0, -1),
                            end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                        )),
                        child: Align(
                            alignment: Alignment.topCenter,
                            child: Material(
                                color: Colors.transparent,
                                child: AnimatedContainer(  // ✅ ÆNDRET: Container → AnimatedContainer
                                    duration: const Duration(milliseconds: 300),  // ✅ TILFØJET
                                    margin: EdgeInsets.only(  // ✅ ÆNDRET: fjernet "const"
                                        top: 60,
                                        left: 16,
                                        right: 16,
                                        bottom: 60 + MediaQuery.of(context).viewInsets.bottom,  // ✅ ÆNDRET
                                    ),
                                    constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                                        maxWidth: 500,
                                    ),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                            ),
                                        ],
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            // Header
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: const BoxDecoration(
                                                    color: localGreen,
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                child: Row(
                                                    children: [
                                                        const Icon(Icons.edit_note, color: localBlue, size: 28),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                            child: Text(
                                                                udskiftningstype == 'ventilatorer'
                                                                    ? 'Data for nye ventilatorer'
                                                                    : 'Data for nyt anlæg',
                                                                style: const TextStyle(
                                                                    color: localBlue,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 18,
                                                                ),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),

                                            // Content (scrollable)
                                            Expanded(
                                                child: SingleChildScrollView(
                                                    padding: const EdgeInsets.all(20),
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            // Info text
                                                            Container(
                                                                padding: const EdgeInsets.all(12),
                                                                decoration: BoxDecoration(
                                                                    color: Colors.blue.shade50,
                                                                    borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Row(
                                                                    children: [
                                                                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                                                        const SizedBox(width: 8),
                                                                        Expanded(
                                                                            child: Text(
                                                                                udskiftningstype == 'ventilatorer'
                                                                                    ? 'Tryk og luftmængder bruges fra før-situationen'
                                                                                    : 'Indtast alle data for det nye anlæg',
                                                                                style: TextStyle(
                                                                                    fontSize: 13,
                                                                                    color: Colors.blue.shade700,
                                                                                ),
                                                                            ),
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                            const SizedBox(height: 20),

                                                            // 🔹 Pris - forskellig for ventilatorer vs hele anlæg
                                                            if (udskiftningstype == 'hele_anlaeg') ...[
                                                                TextField(
                                                                    controller: prisController,
                                                                    keyboardType: TextInputType.text,
                                                                    decoration: const InputDecoration(
                                                                        labelText: 'Pris (DKK)',
                                                                        hintText: 'Samlet pris for hele anlægget',
                                                                        border: OutlineInputBorder(),
                                                                        prefixIcon: Icon(Icons.attach_money, color: localGreen),
                                                                    ),
                                                                ),
                                                                const SizedBox(height: 16),
                                                                TextField(
                                                                    controller: virkningsgradController,
                                                                    keyboardType: TextInputType.text,
                                                                    decoration: const InputDecoration(
                                                                        labelText: 'Virkningsgrad varmegenvinding (%)',
                                                                        hintText: 'Fx 75',
                                                                        border: OutlineInputBorder(),
                                                                        prefixIcon: Icon(Icons.thermostat, color: localGreen),
                                                                    ),
                                                                ),
                                                            ],

                                                            // ═══════════════════════════════════════
                                                            // INDBLÆSNING - kun ved Indblæsnings- eller Ventilationsanlæg
                                                            // ═══════════════════════════════════════
                                                            if (anlaegstype == 'Indblæsningsanlæg' || anlaegstype == 'Ventilationsanlæg') ...[
                                                                const SizedBox(height: 24),
                                                                const Text(
                                                                    'INDBLÆSNING',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 15,
                                                                        color: localBlue,
                                                                    ),
                                                                ),
                                                                const SizedBox(height: 12),

                                                                // Pris indblæsning (kun ventilatorer)
                                                                if (udskiftningstype == 'ventilatorer') ...[
                                                                    TextField(
                                                                        controller: prisIndController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Pris indblæsningsventilator (DKK)',
                                                                            hintText: 'Indtast pris',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.attach_money, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                ],

                                                                // Tryk (kun hele anlæg)
                                                                if (udskiftningstype == 'hele_anlaeg') ...[
                                                                    TextField(
                                                                        controller: trykFoerIndController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Tryk før ventilator (Pa)',
                                                                            hintText: 'Negativ værdi (fx -150)',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.arrow_downward, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                    TextField(
                                                                        controller: trykEfterIndController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Tryk efter ventilator (Pa)',
                                                                            hintText: 'Positiv værdi (fx 300)',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.arrow_upward, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                    TextField(
                                                                        controller: luftIndController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Luftmængde (m³/h)',
                                                                            hintText: 'Fx 5000',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.air, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                ],

                                                                // Effekt indblæsning
                                                                TextField(
                                                                    controller: effektIndController,
                                                                    keyboardType: TextInputType.text,
                                                                    decoration: const InputDecoration(
                                                                        labelText: 'Effekt indblæsning (kW)',
                                                                        hintText: 'Fx 2.5',
                                                                        border: OutlineInputBorder(),
                                                                        prefixIcon: Icon(Icons.flash_on, color: localGreen),
                                                                    ),
                                                                ),
                                                            ],

                                                            // ═══════════════════════════════════════
                                                            // UDSUGNING - kun ved Udsugnings- eller Ventilationsanlæg
                                                            // ═══════════════════════════════════════
                                                            if (anlaegstype == 'Udsugningsanlæg' || anlaegstype == 'Ventilationsanlæg') ...[
                                                                const SizedBox(height: 24),
                                                                const Text(
                                                                    'UDSUGNING',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 15,
                                                                        color: localBlue,
                                                                    ),
                                                                ),
                                                                const SizedBox(height: 12),

                                                                // Pris udsugning (kun ventilatorer)
                                                                if (udskiftningstype == 'ventilatorer') ...[
                                                                    TextField(
                                                                        controller: prisUdController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Pris udsugningsventilator (DKK)',
                                                                            hintText: 'Indtast pris',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.attach_money, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                ],

                                                                // Tryk (kun hele anlæg)
                                                                if (udskiftningstype == 'hele_anlaeg') ...[
                                                                    TextField(
                                                                        controller: trykFoerUdController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Tryk før ventilator (Pa)',
                                                                            hintText: 'Negativ værdi (fx -150)',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.arrow_downward, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                    TextField(
                                                                        controller: trykEfterUdController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Tryk efter ventilator (Pa)',
                                                                            hintText: 'Positiv værdi (fx 300)',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.arrow_upward, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                    TextField(
                                                                        controller: luftUdController,
                                                                        keyboardType: TextInputType.text,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Luftmængde (m³/h)',
                                                                            hintText: 'Fx 5000',
                                                                            border: OutlineInputBorder(),
                                                                            prefixIcon: Icon(Icons.air, color: localGreen),
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                ],

                                                                // Effekt udsugning
                                                                TextField(
                                                                    controller: effektUdController,
                                                                    keyboardType: TextInputType.text,
                                                                    decoration: const InputDecoration(
                                                                        labelText: 'Effekt udsugning (kW)',
                                                                        hintText: 'Fx 2.5',
                                                                        border: OutlineInputBorder(),
                                                                        prefixIcon: Icon(Icons.flash_on, color: localGreen),
                                                                    ),
                                                                ),
                                                            ],
                                                            const SizedBox(height: 20),
                                                        ],
                                                    ),
                                                ),
                                            ),

                                            // Actions
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                                ),
                                                child: Row(
                                                    children: [
                                                        Expanded(
                                                            child: OutlinedButton(
                                                                onPressed: () => Navigator.pop(context, null),
                                                                style: OutlinedButton.styleFrom(
                                                                    foregroundColor: localBlue,
                                                                    side: const BorderSide(color: localGreen, width: 2),
                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                ),
                                                                child: const Text('Annuller'),
                                                            ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                            child: ElevatedButton(
                                                                onPressed: () {
                                                                    // ✅ VALIDERING AF NEGATIVT TRYK (kun for hele anlæg)
                                                                    if (udskiftningstype == 'hele_anlaeg') {
                                                                        final double trykFoerInd = double.tryParse(
                                                                            trykFoerIndController.text.replaceAll(',', '.')
                                                                        ) ?? 0;
                                                                        final double trykFoerUd = double.tryParse(
                                                                            trykFoerUdController.text.replaceAll(',', '.')
                                                                        ) ?? 0;

                                                                        if (trykFoerInd > 0) {
                                                                            showDialog(
                                                                                context: context,
                                                                                builder: (ctx) => AlertDialog(
                                                                                    shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(16),
                                                                                    ),
                                                                                    titlePadding: EdgeInsets.zero,
                                                                                    title: Container(
                                                                                        padding: const EdgeInsets.all(16),
                                                                                        decoration: const BoxDecoration(
                                                                                            color: Color(0xFF34E0A1),
                                                                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                                                        ),
                                                                                        child: Row(
                                                                                            children: [
                                                                                                const Icon(Icons.warning, color: Color(0xFF006390), size: 28),
                                                                                                const SizedBox(width: 12),
                                                                                                const Expanded(
                                                                                                    child: Text(
                                                                                                        'Fejl i indtastning',
                                                                                                        style: TextStyle(
                                                                                                            color: Color(0xFF006390),
                                                                                                            fontWeight: FontWeight.bold,
                                                                                                            fontSize: 18,
                                                                                                        ),
                                                                                                    ),
                                                                                                ),
                                                                                            ],
                                                                                        ),
                                                                                    ),
                                                                                    content: const Padding(
                                                                                        padding: EdgeInsets.all(16),
                                                                                        child: Text(
                                                                                            'Tryk før indblæsningsventilator skal være NEGATIVT (sugetryk).\n\n'
                                                                                                'Eksempel: -150 Pa\n\n'
                                                                                                'Tjek venligst din indtastning.',
                                                                                            style: TextStyle(fontSize: 15),
                                                                                        ),
                                                                                    ),
                                                                                    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                                                                    actions: [
                                                                                        SizedBox(
                                                                                            width: double.infinity,
                                                                                            child: ElevatedButton(
                                                                                                onPressed: () => Navigator.pop(ctx),
                                                                                                style: ElevatedButton.styleFrom(
                                                                                                    backgroundColor: const Color(0xFF34E0A1),
                                                                                                    foregroundColor: const Color(0xFF006390),
                                                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                        borderRadius: BorderRadius.circular(8),
                                                                                                    ),
                                                                                                    elevation: 0,
                                                                                                ),
                                                                                                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                            ),
                                                                                        ),
                                                                                    ],
                                                                                ),
                                                                            );
                                                                            return;
                                                                        }

                                                                        if (trykFoerUd > 0) {
                                                                            showDialog(
                                                                                context: context,
                                                                                builder: (ctx) => AlertDialog(
                                                                                    shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(16),
                                                                                    ),
                                                                                    titlePadding: EdgeInsets.zero,
                                                                                    title: Container(
                                                                                        padding: const EdgeInsets.all(16),
                                                                                        decoration: const BoxDecoration(
                                                                                            color: Color(0xFF34E0A1),
                                                                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                                                        ),
                                                                                        child: Row(
                                                                                            children: [
                                                                                                const Icon(Icons.warning, color: Color(0xFF006390), size: 28),
                                                                                                const SizedBox(width: 12),
                                                                                                const Expanded(
                                                                                                    child: Text(
                                                                                                        'Fejl i indtastning',
                                                                                                        style: TextStyle(
                                                                                                            color: Color(0xFF006390),
                                                                                                            fontWeight: FontWeight.bold,
                                                                                                            fontSize: 18,
                                                                                                        ),
                                                                                                    ),
                                                                                                ),
                                                                                            ],
                                                                                        ),
                                                                                    ),
                                                                                    content: const Padding(
                                                                                        padding: EdgeInsets.all(16),
                                                                                        child: Text(
                                                                                            'Tryk før udsugningsventilator skal være NEGATIVT (sugetryk).\n\n'
                                                                                                'Eksempel: -150 Pa\n\n'
                                                                                                'Tjek venligst din indtastning.',
                                                                                            style: TextStyle(fontSize: 15),
                                                                                        ),
                                                                                    ),
                                                                                    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                                                                    actions: [
                                                                                        SizedBox(
                                                                                            width: double.infinity,
                                                                                            child: ElevatedButton(
                                                                                                onPressed: () => Navigator.pop(ctx),
                                                                                                style: ElevatedButton.styleFrom(
                                                                                                    backgroundColor: const Color(0xFF34E0A1),
                                                                                                    foregroundColor: const Color(0xFF006390),
                                                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                                    shape: RoundedRectangleBorder(
                                                                                                        borderRadius: BorderRadius.circular(8),
                                                                                                    ),
                                                                                                    elevation: 0,
                                                                                                ),
                                                                                                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                            ),
                                                                                        ),
                                                                                    ],
                                                                                ),
                                                                            );
                                                                            return;
                                                                        }
                                                                    }

                                                                    // Returner data
                                                                    if (udskiftningstype == 'ventilatorer') {
                                                                        final bool harInd = anlaegstype == 'Indblæsningsanlæg' || anlaegstype == 'Ventilationsanlæg';
                                                                        final bool harUd = anlaegstype == 'Udsugningsanlæg' || anlaegstype == 'Ventilationsanlæg';

                                                                        Navigator.pop(context, {
                                                                            'prisInd': harInd ? (double.tryParse(prisIndController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'prisUd': harUd ? (double.tryParse(prisUdController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'effektInd': harInd ? (double.tryParse(effektIndController.text.replaceAll(',', '.')) ?? 0.0) * 1000 : 0.0,
                                                                            'effektUd': harUd ? (double.tryParse(effektUdController.text.replaceAll(',', '.')) ?? 0.0) * 1000 : 0.0,
                                                                            'type': udskiftningstype,
                                                                            'manuelIndtastning': true,
                                                                        });
                                                                    } else {
                                                                        final bool harInd = anlaegstype == 'Indblæsningsanlæg' || anlaegstype == 'Ventilationsanlæg';
                                                                        final bool harUd = anlaegstype == 'Udsugningsanlæg' || anlaegstype == 'Ventilationsanlæg';

                                                                        Navigator.pop(context, {
                                                                            'pris': double.tryParse(prisController.text.replaceAll(',', '.')) ?? 0.0,
                                                                            'virkningsgrad': double.tryParse(virkningsgradController.text.replaceAll(',', '.')) ?? 0.0,
                                                                            'trykFoerInd': harInd ? (double.tryParse(trykFoerIndController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'trykEfterInd': harInd ? (double.tryParse(trykEfterIndController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'luftInd': harInd ? (double.tryParse(luftIndController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'effektInd': harInd ? (double.tryParse(effektIndController.text.replaceAll(',', '.')) ?? 0.0) * 1000 : 0.0,
                                                                            'trykFoerUd': harUd ? (double.tryParse(trykFoerUdController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'trykEfterUd': harUd ? (double.tryParse(trykEfterUdController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'luftUd': harUd ? (double.tryParse(luftUdController.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                                                                            'effektUd': harUd ? (double.tryParse(effektUdController.text.replaceAll(',', '.')) ?? 0.0) * 1000 : 0.0,
                                                                            'type': udskiftningstype,
                                                                            'manuelIndtastning': true,
                                                                        });
                                                                    }
                                                                },

                                                                style: ElevatedButton.styleFrom(
                                                                    backgroundColor: localGreen,
                                                                    foregroundColor: localBlue,
                                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                    elevation: 0,
                                                                ),
                                                                child: const Text('Gem', style: TextStyle(fontWeight: FontWeight.bold)),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    );
                },
                transitionDuration: const Duration(milliseconds: 400),
            ),
        );
    }
    // ✅ NY FUNKTION: VIS INTERN KOMMENTAR DIALOG
    Future<String?> visInternKommentarDialog(BuildContext context) async {
        const Color matchingGreen = Color(0xFF34E0A1);
        const Color matchingBlue = Color(0xFF006390);

        final kommentarController = TextEditingController();

        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 100));

        return await Navigator.of(context).push(
            PageRouteBuilder<String>(
                opaque: false,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                pageBuilder: (context, animation, secondaryAnimation) {
                    return SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(0, -1),
                            end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                        )),
                        child: Center(
                            child: Material(
                                color: Colors.transparent,
                                child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                            ),
                                        ],
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            // Ikon
                                            Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                    color: matchingGreen.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.note_add,
                                                    size: 40,
                                                    color: matchingBlue,
                                                ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Titel
                                            const Text(
                                                'Intern kommentar',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: matchingBlue,
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),

                                            // Undertekst
                                            Text(
                                                'Tilføj interne noter til rapporten.\nVises kun i intern PDF.',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 20),

                                            // Tekstfelt
                                            TextField(
                                                controller: kommentarController,
                                                maxLines: 5,
                                                maxLength: 500,
                                                autofocus: false,
                                                decoration: InputDecoration(
                                                    hintText: 'Skriv dine interne noter her...',
                                                    border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: const BorderSide(color: matchingGreen),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: const BorderSide(color: matchingGreen, width: 2),
                                                    ),
                                                    contentPadding: const EdgeInsets.all(14),
                                                ),
                                                textCapitalization: TextCapitalization.sentences,
                                            ),
                                            const SizedBox(height: 20),

                                            // Knapper
                                            Row(
                                                children: [
                                                    Expanded(
                                                        child: OutlinedButton(
                                                            onPressed: () => Navigator.pop(context, null),
                                                            style: OutlinedButton.styleFrom(
                                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                                side: const BorderSide(color: matchingGreen, width: 2),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                ),
                                                            ),
                                                            child: const Text(
                                                                'Spring over',
                                                                style: TextStyle(
                                                                    color: matchingBlue,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                        child: ElevatedButton(
                                                            onPressed: () {
                                                                final kommentar = kommentarController.text.trim();
                                                                Navigator.pop(context, kommentar.isNotEmpty ? kommentar : null);
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                                backgroundColor: matchingGreen,
                                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                ),
                                                                elevation: 0,
                                                            ),
                                                            child: const Text(
                                                                'Gem',
                                                                style: TextStyle(
                                                                    color: matchingBlue,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    );
                },
                transitionDuration: const Duration(milliseconds: 400),
            ),
        );
    }

    // 🟡 Her fortsætter dine variabler og controllere som før
    bool brugBeregningInd = true;

    bool _visKVaerdiBeregningInd = false;
    bool _visEffektBeregningInd = false;
    bool _visKVaerdiBeregningUd = false;
    bool _visEffektBeregningUd = false;
    bool _visVarmegenvinding = false;
    bool _beregnUdFraIndblaesning = true;
    final bool _beregnetInd = false;
    String _valgtAnlaegstype = 'Ventilationsanlæg';

    double? luftUdMax, trykFoerUdMax, trykEfterUdMax;
    double? luftIndMax, trykFoerIndMax, trykEfterIndMax;
    double? luftIndManuel, trykFoerIndManuel, trykEfterIndManuel;

    double _samletTrykInd = 0;
    double _samletTrykUd = 0;

    double _kammerBredde = 0;
    double _kammerHoede = 0;
    double _kammerLaengde= 0;

    double _luftMaaltInd = 0;
    double _luftMaaltUd = 0;

    String valgtTilstand = '1';

    final TextEditingController _anlaegsNavnController = TextEditingController();
    final TextEditingController _ventMaerkatNrController = TextEditingController();
    final TextEditingController _elPrisController = TextEditingController();
    final TextEditingController _tFriskController = TextEditingController();
    final TextEditingController _tIndEfterGenvindingController = TextEditingController();
    final TextEditingController _tIndEfterVarmefladeController = TextEditingController();
    final TextEditingController _tAfkastController = TextEditingController();
    final TextEditingController _tUdController = TextEditingController();

    final TextEditingController _hzIndController = TextEditingController();
    final TextEditingController _hzUdController = TextEditingController();
    final TextEditingController _maxHzIndController = TextEditingController(text: '50');
    final TextEditingController _maxHzUdController = TextEditingController(text: '50');

    final TextEditingController _trykGamleFiltreInd = TextEditingController();

// 👇 Indblæsning: hele + halve filtre
    final TextEditingController _antalHeleFiltreInd = TextEditingController();
    final TextEditingController _antalHalveFiltreInd = TextEditingController();

    final TextEditingController _trykFoerInd = TextEditingController();
    final TextEditingController _trykEfterIndController = TextEditingController();
    final TextEditingController _trykEfterInd = TextEditingController(); // Denne er korrekt tilføjet
    final TextEditingController _effektInd = TextEditingController();

    final TextEditingController _trykEfterUdController = TextEditingController();
    final TextEditingController _trykGamleFiltreUd = TextEditingController();

// 👇 Udsugning: hele + halve filtre
    final TextEditingController _antalHeleFiltreUd = TextEditingController();
    final TextEditingController _antalHalveFiltreUd = TextEditingController();

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
    final TextEditingController _kwIndController = TextEditingController();
    final TextEditingController _kwUdController = TextEditingController();
    final TextEditingController _kammerBreddeController = TextEditingController();
    final TextEditingController _kammerHoedeController = TextEditingController();
    final TextEditingController _kammerLaengdeController = TextEditingController();
    final TextEditingController _filterKammerLaengdeIndController = TextEditingController();
    final TextEditingController _filterKammerLaengdeUdController = TextEditingController();
    final TextEditingController _varmeforbrugController = TextEditingController();
    final TextEditingController _virkningsgradController = TextEditingController();
    final TextEditingController _recirkuleringProcentController = TextEditingController();
    final TextEditingController _recirkuleringVarmegenvindingController = TextEditingController();
    bool _kombinerMedVarmegenvinding = false;
    VarmegenvindingType? _kombineretVarmegenvindingstype = VarmegenvindingType.krydsveksler;
    final TextEditingController _kVaerdiController = TextEditingController();
    final TextEditingController _udeTempController = TextEditingController();
    final TextEditingController _kommentarController = TextEditingController();


    final Color _matchingGreen = Color(0xFF34E0A1);
    final Color _matchingBlue = Color(0xFF006390);





    void _visBilledeBeskrivelsePopup() async {

        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 100));

        final bool vilFortsaette = await visDokumentationsDialog(context, valgtTilstand);
        final double? remUdskiftningPris = await visRemtrukketPopup(context, _luftMaaltInd);

        final double elpris = widget.projektInfo.elPris;
        final double driftstimer =
            widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) *
                widget.projektInfo.ugerPerAar;

        final double? kVaerdiInd =
        double.tryParse(_kVaerdiIndController.text.replaceAll(',', '.'));
        final double? kVaerdiUd =
        double.tryParse(_kVaerdiUdController.text.replaceAll(',', '.'));

        final bool erBeregnetInd =
            _visKVaerdiBeregningInd ||
                _visEffektBeregningInd ||
                (kVaerdiInd != null && kVaerdiInd > 0);

        final bool erBeregnetUd =
            _visKVaerdiBeregningUd ||
                _visEffektBeregningUd ||
                (kVaerdiUd != null && kVaerdiUd > 0);

        final double hzInd = double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0;
        final double hzUd = double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0;

        final double trykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
        final double trykEfterInd = double.tryParse(_trykEfterIndController.text.replaceAll(',', '.')) ?? 0;
        final double trykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;
        final double trykEfterUd = double.tryParse(_trykEfterUdController.text.replaceAll(',', '.')) ?? 0;

        final double samletTrykInd = trykEfterInd - trykFoerInd;
        final double samletTrykUd = trykEfterUd - trykFoerUd;


        lavHzKey.currentState?.beregnInd();
        lavHzKey.currentState?.beregnUd();

        final maxDataInd = lavHzKey.currentState?.hentMaxDataInd();
        final maxDataUd = lavHzKey.currentState?.hentMaxDataUd();


// Effektdata (kW)
        final kwInd = double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0;
        final kwUd = double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0;


// Beregn elforbrug før optimering
        final elforbrugFoer = (kwInd + kwUd) * driftstimer;

// Brug realistiske nye effektværdier (fx fra ventilatorvalg)
        final effektEfterInd = 0.85; // eksempel: 850 W → 0.85 kW
        final effektEfterUd = 0.90; // eksempel: 900 W → 0.90 kW
        final elforbrugEfter = (effektEfterInd + effektEfterUd) * driftstimer;

// Beregn årlig besparelse
        final beregnetBesparelse = (elforbrugFoer - elforbrugEfter) * widget.projektInfo.elPris;

// Tilbagebetalingstid
        final beregnetTilbTid = (beregnetBesparelse > 0)
            ? ((remUdskiftningPris ?? 0) / beregnetBesparelse)
            : double.infinity;

// Beregn varmeforbrug og virkningsgrad (før/efter)
        final varmeResultat = beregnVarmeforbrugOgVirkningsgrad(
            anlaegsType: _valgtAnlaegstype,
            luftInd: _luftMaaltInd,
            luftUd: _luftMaaltUd,
            friskluftTemp: double.tryParse(_tFriskController.text.replaceAll(',', '.')) ?? double.nan,
            tempIndEfterGenvinding: double.tryParse(_tIndEfterGenvindingController.text.replaceAll(',', '.')) ?? 0,
            tempIndEfterVarmeflade: double.tryParse(_tIndEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0,
            tempUd: double.tryParse(_tUdController.text.replaceAll(',', '.')) ?? 0,
            tempAfkast: double.tryParse(_tAfkastController.text.replaceAll(',', '.')),
            driftstype: widget.projektInfo.driftstype,
            driftstimer: driftstimer,
            varmePris: widget.projektInfo.varmePris ?? 0.0,
            // 🔥 vigtig ændring:
          varmegenvindingsType: _valgtAnlaegstype == 'Ventilationsanlæg'
              ? _visNavn(_valgtVarmegenvindingstype ?? VarmegenvindingType.krydsveksler)
              : "ingen",
            recirkuleringProcent: _valgtVarmegenvindingstype == VarmegenvindingType.recirkulering
                ? double.tryParse(_recirkuleringProcentController.text.replaceAll(',', '.'))
                : null,
            varmegenvindingVirkningsgrad: null,
            kombineretVarmegenvindingsType: _kombinerMedVarmegenvinding && _kombineretVarmegenvindingstype != null
                ? _visNavn(_kombineretVarmegenvindingstype!)
                : null,
        );

// --- Opdater controllers (visning) ---
        _varmeforbrugController.text =
            varmeResultat.varmeforbrugKWh.toStringAsFixed(0);

        _virkningsgradController.text =
            varmeResultat.maaltVirkningsgrad.toStringAsFixed(1);

// 🟢 K-værdi visning (vises hvis der er indtastet for indblæsning eller udsugning)
        if (_kVaerdiIndController.text.isNotEmpty &&
            double.tryParse(_kVaerdiIndController.text.replaceAll(',', '.')) != null &&
            double.parse(_kVaerdiIndController.text.replaceAll(',', '.')) > 0) {
            _kVaerdiController.text = _kVaerdiIndController.text;
        } else if (_kVaerdiUdController.text.isNotEmpty &&
            double.tryParse(_kVaerdiUdController.text.replaceAll(',', '.')) != null &&
            double.parse(_kVaerdiUdController.text.replaceAll(',', '.')) > 0) {
            _kVaerdiController.text = _kVaerdiUdController.text;
        } else {
            _kVaerdiController.text = '';
        }

        _udeTempController.text =
            varmeResultat.gennemsnitTemp.toStringAsFixed(1);

        _kommentarController.text =
            varmeResultat.kommentar ?? "";


// --- Gem hele varmeResultat i AnlaegsData ---
        final opdateretData = widget.alleAnlaeg[widget.index].copyWith(
            varmeResultat: varmeResultat, // ✅ gem hele objektet

        );

// Opdater listen så data ryger med videre
        widget.alleAnlaeg[widget.index] = opdateretData;

// Beregn el-omkostninger
        final beregnetOmkostningFoer = kwInd * elpris * driftstimer / 1000;
        final beregnetOmkostningEfter = kwUd * elpris * driftstimer / 1000;

// Opret nyt anlæg

        final double? kVaerdiIndVisning =
        double.tryParse(_kVaerdiIndController.text.replaceAll(',', '.'));
        final double? kVaerdiUdVisning =
        double.tryParse(_kVaerdiUdController.text.replaceAll(',', '.'));

        final bool harKVaerdiInd = (kVaerdiIndVisning != null && kVaerdiIndVisning > 0);
        final bool harKVaerdiUd = (kVaerdiUdVisning != null && kVaerdiUdVisning > 0);

// 🔹 Opdater K-værdi-visning
        if (harKVaerdiInd) {
            _kVaerdiController.text = kVaerdiIndVisning.toStringAsFixed(2);
        } else if (harKVaerdiUd) {
            _kVaerdiController.text = kVaerdiUdVisning.toStringAsFixed(2);
        } else {
            _kVaerdiController.text = '';
        }

        final nytAnlaeg = AnlaegsData(
            anlaegsNavn: _anlaegsNavnController.text.isNotEmpty
                ? _anlaegsNavnController.text
                : 'Ukendt anlæg',
            ventMaerkatNr: _ventMaerkatNrController.text,
            valgtAnlaegstype: _valgtAnlaegstype,
            aarsbesparelse: beregnetBesparelse,
            tilbagebetalingstid: beregnetTilbTid,
            luftInd: _luftMaaltInd,
            luftUd: _luftMaaltUd,
            trykInd: _samletTrykInd,
            trykUd: _samletTrykUd,
            kwInd: kwInd,
            kwUd: kwUd,
            hzInd: double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0,
            hzUd: double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0,
            elpris: elpris,
            varmepris: widget.projektInfo.varmePris ?? 0.0,

            trykFoerIndMax: trykFoerIndMax,
            trykEfterIndMax: trykEfterIndMax,
            trykFoerUdMax: trykFoerUdMax,
            trykEfterUdMax: trykEfterUdMax,
            luftIndMax: luftIndMax,
            luftUdMax: luftUdMax,

            // ✅ brug de korrekte værdier fra ovenfor
            kVaerdiInd: kVaerdiIndVisning,
            kVaerdiUd: kVaerdiUdVisning,

            maksLuftInd: double.tryParse(_maksLuftIndController.text.replaceAll(',', '.')),
            maksLuftUd: double.tryParse(_maksLuftUdController.text.replaceAll(',', '.')),
            maksEffektInd: double.tryParse(_maksEffektIndController.text.replaceAll(',', '.')),
            maksEffektUd: double.tryParse(_maksEffektUdController.text.replaceAll(',', '.')),
            effektMaaltInd: double.tryParse(_effektMaaltIndController.text.replaceAll(',', '.')),
            effektMaaltUd: double.tryParse(_effektMaaltUdController.text.replaceAll(',', '.')),
            trykDifferensInd: double.tryParse(_trykDifferensIndController.text.replaceAll(',', '.')),
            trykDifferensUd: double.tryParse(_trykDifferensUdController.text.replaceAll(',', '.')),
            antalHeleFiltreInd: int.tryParse(_antalHeleFiltreInd.text) ?? 0,
            antalHalveFiltreInd: int.tryParse(_antalHalveFiltreInd.text) ?? 0,
            antalHeleFiltreUd: int.tryParse(_antalHeleFiltreUd.text) ?? 0,
            antalHalveFiltreUd: int.tryParse(_antalHalveFiltreUd.text) ?? 0,
            trykGamleFiltreInd:
            double.tryParse(_trykGamleFiltreInd.text.replaceAll(',', '.')) ?? 0,
            trykGamleFiltreUd:
            double.tryParse(_trykGamleFiltreUd.text.replaceAll(',', '.')) ?? 0,

            // 🟢 Manglende overførsel
            filterValg: widget.alleAnlaeg[widget.index].filterValg,
            filterResultat: widget.alleAnlaeg[widget.index].filterResultat,

            kammerBredde: _kammerBredde,
            kammerHoede: _kammerHoede,
            kammerLaengde: _kammerLaengde,
            filterKammerLaengdeInd: double.tryParse(
                _filterKammerLaengdeIndController.text.replaceAll(',', '.')),
            filterKammerLaengdeUd: double.tryParse(
                _filterKammerLaengdeUdController.text.replaceAll(',', '.')),

            valgtTilstand: valgtTilstand,

            // ✅ Her sættes alle beregnings-flags korrekt
            erBeregnetInd:
            _visKVaerdiBeregningInd || _visEffektBeregningInd || harKVaerdiInd,
            erBeregnetUd:
            _visKVaerdiBeregningUd || _visEffektBeregningUd || harKVaerdiUd,

            erBeregnetUdFraKVaerdiInd:
            _visKVaerdiBeregningInd || harKVaerdiInd,
            erBeregnetUdFraKVaerdiUd:
            _visKVaerdiBeregningUd || harKVaerdiUd,

            erLuftmaengdeMaaeltIndtastetInd:
            !_visKVaerdiBeregningInd && !_visEffektBeregningInd && !harKVaerdiInd,
            erLuftmaengdeMaaeltIndtastetUd:
            !_visKVaerdiBeregningUd && !_visEffektBeregningUd && !harKVaerdiUd,

            remUdskiftningPris: remUdskiftningPris,
            omkostningFoer: beregnetOmkostningFoer,
            omkostningEfter: beregnetOmkostningEfter,
            eksisterendeVarenummerInd: '',
            eksisterendeVarenummerUd: '',
            varmeResultat: varmeResultat,
        );

// ✅ Opdater eller tilføj i listen
        // 1) Opdater eller tilføj i listen
        if (widget.index < widget.alleAnlaeg.length) {
            widget.alleAnlaeg[widget.index] = nytAnlaeg;
        } else {
            widget.alleAnlaeg.add(nytAnlaeg);
        }

// 2) Beregn besparelse og tilbagebetalingstid
        final double beregnetAarsbesparelse = beregnetOmkostningFoer - beregnetOmkostningEfter;
        final double beregnetTilbagebetalingstid = beregnetAarsbesparelse == 0
            ? 0
            : (remUdskiftningPris ?? 0) / beregnetAarsbesparelse;

// 3) Beregn samlet omkostning, og sørg for ikke-negativ
        double beregnetSamletOmkostning = beregnetOmkostningFoer + beregnetOmkostningEfter - (remUdskiftningPris ?? 0);
        if (beregnetSamletOmkostning < 0) beregnetSamletOmkostning = 0;

// 4) Lav listen af VentilatorOekonomiSamlet:
        final List<VentilatorOekonomiSamlet> forslag = beregnAlleVentilatorer(
            fabrikant: 'Ebmpapst',  // eller hvad du nu sender ind
            afdeling: widget.projektInfo.afdeling,
            trykIndNormal: samletTrykInd,
            luftIndNormal: _luftMaaltInd,
            trykIndMax: trykFoerIndMax ?? 0,
            luftIndMax: luftIndMax ?? 0,
            trykUdNormal: samletTrykUd,
            luftUdNormal: _luftMaaltUd,
            trykUdMax: trykFoerUdMax ?? 0,
            luftUdMax: luftUdMax ?? 0,
            omkostningInd: beregnetOmkostningFoer,
            omkostningUd: beregnetOmkostningEfter,
            fradragRemtrukket: remUdskiftningPris ?? 0,
            driftstimer: widget.driftstimer.values
                .map((c) => int.tryParse(c.text) ?? 0)
                .fold(0, (sum, v) => sum + v),
            elpris: elpris,
            anlaegsNavn: _anlaegsNavnController.text,
            anlaegstype: _valgtAnlaegstype,          // fx "Ventilationsanlæg"
            projektInfo: widget.projektInfo,
        );

        final double samledeDriftstimer =
            widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) *
                widget.projektInfo.ugerPerAar;

        // ✅ Definer recirkuleringProcent lokalt i denne funktion
        final double? recirkuleringProcent =
        _valgtVarmegenvindingstype == VarmegenvindingType.recirkulering
            ? double.tryParse(_recirkuleringProcentController.text.replaceAll(',', '.'))
            : null;

// 5) Navigér og giv både 'alleAnlaeg' og 'forslag'
        // ➕ Beregn varmeforbrug og virkningsgrad inden navigation
        final varmeforbrugResultat = beregnVarmeforbrugOgVirkningsgrad(
            anlaegsType: _valgtAnlaegstype,
            luftInd: _luftMaaltInd,
            luftUd: _luftMaaltUd,
            driftstimer: samledeDriftstimer.toDouble(),
            friskluftTemp: double.tryParse(_tFriskController.text.replaceAll(',', '.')) ?? 0,
            tempUd: double.tryParse(_tUdController.text.replaceAll(',', '.')) ?? 0,
            tempIndEfterGenvinding: double.tryParse(_tIndEfterGenvindingController.text.replaceAll(',', '.')) ?? 0,
            tempIndEfterVarmeflade: double.tryParse(_tIndEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0,
            varmePris: widget.projektInfo.varmePris,
            driftstype: widget.projektInfo.driftstype,
            tempAfkast: double.tryParse(_tAfkastController.text.replaceAll(',', '.')),
            varmegenvindingsType: _valgtAnlaegstype == 'Ventilationsanlæg'
                ? _visNavn(_valgtVarmegenvindingstype ?? VarmegenvindingType.krydsveksler)
                : null,
            recirkuleringProcent: recirkuleringProcent,
            varmegenvindingVirkningsgrad: null,
            kombineretVarmegenvindingsType: _kombinerMedVarmegenvinding && _kombineretVarmegenvindingstype != null
                ? _visNavn(_kombineretVarmegenvindingstype!)
                : null,
        );

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ResultatInternSkarm(
                    index: widget.index,
                    alleAnlaeg: widget.alleAnlaeg,
                    anlaeg: widget.alleAnlaeg[widget.index],
                    forslag: forslag,
                    anlaegsType: _valgtAnlaegstype,
                    anlaegsNavn: _anlaegsNavnController.text,
                    kwInd: kwInd,
                    luftInd: _luftMaaltInd,
                    statiskTrykInd: samletTrykInd,
                    kwUd: kwUd,
                    luftUd: _luftMaaltUd,
                    statiskTrykUd: samletTrykUd,
                    hzInd: hzInd,
                    hzUd: hzUd,
                    projektInfo: widget.projektInfo,

                    erBeregnetInd: _visKVaerdiBeregningInd || _visEffektBeregningInd,
                    erBeregnetUd: _visKVaerdiBeregningUd || _visEffektBeregningUd,

                    erBeregnetUdFraKVaerdiInd: _visKVaerdiBeregningInd,
                    erBeregnetUdFraKVaerdiUd: _visKVaerdiBeregningUd,

                    trykFoerIndMax: trykFoerIndMax,
                    trykEfterIndMax: trykEfterIndMax,
                    luftIndMax: luftIndMax,
                    trykFoerUdMax: trykFoerUdMax,
                    trykEfterUdMax: trykEfterUdMax,
                    luftUdMax: luftUdMax,
                    remUdskiftningPris: remUdskiftningPris,
                    omkostningFoer: beregnetOmkostningFoer,
                    omkostningEfter: beregnetOmkostningEfter,
                    elpris: elpris,
                    kammerBredde: _kammerBredde,
                    kammerHoede: _kammerHoede,
                    kammerLaengde: _kammerLaengde,
                    valgtTilstand: valgtTilstand,

                    erLuftmaengdeMaaeltIndtastetInd: !_visKVaerdiBeregningInd && !_visEffektBeregningInd,
                    erLuftmaengdeMaaeltIndtastetUd: !_visKVaerdiBeregningUd && !_visEffektBeregningUd,

                    luftmaengdeLabelInd: (_visKVaerdiBeregningInd || _visEffektBeregningInd)
                        ? 'Beregnet luftmængde (m³/h)'
                        : 'Målt luftmængde (m³/h)',
                    luftmaengdeLabelUd: (_visKVaerdiBeregningUd || _visEffektBeregningUd)
                        ? 'Beregnet luftmængde (m³/h)'
                        : 'Målt luftmængde (m³/h)',

                    driftstimer: widget.driftstimer,
                    aarsbesparelse: beregnetAarsbesparelse,
                    tilbagebetalingstid: beregnetTilbagebetalingstid,
                    samletOmkostning: beregnetSamletOmkostning,
                    eksisterendeVarenummerInd: 'ukendt',
                    eksisterendeVarenummerUd: 'ukendt',

                    // ✅ nu er variablen defineret
                    varmeforbrugResultat: varmeforbrugResultat,
                ),
            ),
        );
    }

    String _formatDouble(double? value) {
        if (value == null || value == 0) return '';
        if (value == value.roundToDouble()) return value.toInt().toString();
        return value.toString();
    }

    @override
    void initState() {
        super.initState();

        print('InitState for anlæg index=${widget.index}');
        print('Antal anlæg i liste: ${widget.alleAnlaeg.length}');

        if (widget.index < widget.alleAnlaeg.length) {
            final data = widget.alleAnlaeg[widget.index];

            print('Indlæser data for anlæg: ${data.anlaegsNavn}');
            print('LuftInd: ${data.luftInd}, LuftUd: ${data.luftUd}');
            print('TrykInd: ${data.trykInd}, TrykUd: ${data.trykUd}');
            print('kwInd: ${data.kwInd}, kwUd: ${data.kwUd}');

            if (widget.index < widget.alleAnlaeg.length) {
                final data = widget.alleAnlaeg[widget.index];

                _anlaegsNavnController.text = data.anlaegsNavn;
                _ventMaerkatNrController.text = data.ventMaerkatNr;

                const gyldigeAnlaegstyper = ['Ventilationsanlæg', 'Indblæsningsanlæg', 'Udsugningsanlæg'];
                if (gyldigeAnlaegstyper.contains(data.valgtAnlaegstype)) {
                    _valgtAnlaegstype = data.valgtAnlaegstype;
                } else {
                    _valgtAnlaegstype = 'Ventilationsanlæg';
                }
            }

            _luftMaaltInd = data.luftInd;
            _luftMaaltUd = data.luftUd;

            _samletTrykInd = data.trykInd;
            _samletTrykUd = data.trykUd;

            _effektInd.text = _formatDouble(data.kwInd);
            _effektUd.text = _formatDouble(data.kwUd);

            _hzIndController.text = _formatDouble(data.hzInd);
            _hzUdController.text = _formatDouble(data.hzUd);

            _elPrisController.text = data.elpris.toString();

            _trykFoerInd.text = _formatDouble(data.trykFoerInd ?? data.trykFoerIndMax);
            _trykEfterInd.text = _formatDouble(data.trykEfterInd ?? data.trykEfterIndMax);
            _trykFoerUd.text = _formatDouble(data.trykFoerUd ?? data.trykFoerUdMax);
            _trykEfterUd.text = _formatDouble(data.trykEfterUd ?? data.trykEfterUdMax);

            _kVaerdiIndController.text = _formatDouble(data.kVaerdiInd);
            _kVaerdiUdController.text = _formatDouble(data.kVaerdiUd);

            _maksLuftIndController.text = _formatDouble(data.maksLuftInd);
            _maksLuftUdController.text = _formatDouble(data.maksLuftUd);

            _maksEffektIndController.text = _formatDouble(data.maksEffektInd);
            _maksEffektUdController.text = _formatDouble(data.maksEffektUd);

            _effektMaaltIndController.text = _formatDouble(data.effektMaaltInd);
            _effektMaaltUdController.text = _formatDouble(data.effektMaaltUd);

            _trykDifferensIndController.text = _formatDouble(data.trykDifferensInd);
            _trykDifferensUdController.text = _formatDouble(data.trykDifferensUd);

            _trykGamleFiltreInd.text = _formatDouble(data.trykGamleFiltreInd);
            _trykGamleFiltreUd.text = _formatDouble(data.trykGamleFiltreUd);

            _antalHeleFiltreInd.text = data.antalHeleFiltreInd?.toString() ?? '';
            _antalHalveFiltreInd.text = data.antalHalveFiltreInd?.toString() ?? '';
            _antalHeleFiltreUd.text = data.antalHeleFiltreUd?.toString() ?? '';
            _antalHalveFiltreUd.text = data.antalHalveFiltreUd?.toString() ?? '';

            _kammerBredde = data.kammerBredde;
            _kammerHoede = data.kammerHoede;
            _kammerLaengde = data.kammerLaengde;

            valgtTilstand = data.valgtTilstand;

            _visKVaerdiBeregningInd = data.erBeregnetUdFraKVaerdiInd;
            _visKVaerdiBeregningUd = data.erBeregnetUdFraKVaerdiUd;

            _luftMaaltIndController.text = _formatDouble(data.luftInd);
            _luftMaaltUdController.text = _formatDouble(data.luftUd);

            _tFriskController.text = _formatDouble(data.friskluftTemp);
            _tIndEfterGenvindingController.text = _formatDouble(data.tempIndEfterGenvinding);
            _tIndEfterVarmefladeController.text = _formatDouble(data.tempIndEfterVarmeflade);
            _tUdController.text = _formatDouble(data.tempUd);

            _visVarmegenvinding = (data.friskluftTemp != 0 || data.tempUd != 0 || data.tempIndEfterGenvinding != 0);

            // ✅ Genindlæs varmegenvindingstype
            if (data.varmegenvindingsType != null) {
                _valgtVarmegenvindingstype = VarmegenvindingType.values.firstWhere(
                        (t) => _visNavn(t) == data.varmegenvindingsType,
                    orElse: () => VarmegenvindingType.krydsveksler,
                );
            }
        }

        _hzIndController.addListener(() {
            setState(() {}); // Genopbyg UI når indblæsnings-Hz ændres
        });

        _hzUdController.addListener(() {
            setState(() {}); // Genopbyg UI når udsugnings-Hz ændres
        });

        _effektInd.addListener(() {
            final value = double.tryParse(_effektInd.text.replaceAll(',', '.'));
            if (value != null && value >= 100) {
                _tjekEffektEnhed(_effektInd, 'Effekt indblæsning');
            }
        });

        _effektUd.addListener(() {
            final value = double.tryParse(_effektUd.text.replaceAll(',', '.'));
            if (value != null && value >= 100) {
                _tjekEffektEnhed(_effektUd, 'Effekt udsugning');
            }
        });
    }

    void _tjekEffektEnhed(TextEditingController controller, String label) {
        final value = double.tryParse(controller.text.replaceAll(',', '.'));
        if (value != null && value >= 100) {
            showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    titlePadding: EdgeInsets.zero,
                    title: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                            color: Color(0xFF34E0A1),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                            children: [
                                const Icon(Icons.warning, color: Color(0xFF006390), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(
                                        'Tjek enhed – $label',
                                        style: const TextStyle(
                                            color: Color(0xFF006390),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    content: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                            'Du har indtastet ${controller.text} – husk at effekten skal angives i kW og ikke i W.\n\n'
                                'Eksempel: 1.500 W skal indtastes som 1,5 kW.',
                            style: const TextStyle(fontSize: 15),
                        ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    actions: [
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34E0A1),
                                    foregroundColor: const Color(0xFF006390),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                ),
                                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ),
                    ],
                ),
            );
        }
    }

    void _hentLavHzData() {
        final maxInd = lavHzKey.currentState?.hentMaxDataInd();
        final maxUd = lavHzKey.currentState?.hentMaxDataUd();

        luftIndMax = maxInd?['luft'];
        trykFoerIndMax = maxInd?['trykFoer'];
        trykEfterIndMax = maxInd?['trykEfter'];

        luftUdMax = maxUd?['luft'];
        trykFoerUdMax = maxUd?['trykFoer'];
        trykEfterUdMax = maxUd?['trykEfter'];
    }

    bool _trykErPositivt() {
        final trykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
        final trykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;
        return trykFoerInd > 0 || trykFoerUd > 0;
    }
    @override
    Widget build(BuildContext context) {
        final double? hzInd = double.tryParse(_hzIndController.text.replaceAll(',', '.'));
        final double? hzUd = double.tryParse(_hzUdController.text.replaceAll(',', '.'));

        return Scaffold(
            body: Stack(
                children: [
                    // ✅ USYNLIG FOCUS-FANGER - TILFØJET HER FØRST
                    Positioned(
                        left: -100,
                        top: -100,
                        child: SizedBox(
                            width: 1,
                            height: 1,
                            child: Focus(
                                focusNode: _dummyFocus,
                                child: Container(),
                            ),
                        ),
                    ),

                    // DIT NORMALE INDHOLD FORTSÆTTER HER
                    SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const SizedBox(height: 100),

                                // Her vises anlægsnummer og antal anlæg
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                        'Anlæg ${widget.projektInfo.index + 1} af ${widget.projektInfo.alleAnlaeg.length}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                ),

                                _sektionTitel('STAMDATA'),
                                AnlaegsdataWidget(
                                    anlaegsNavnController: _anlaegsNavnController,
                                    valgtAnlaegstype: _valgtAnlaegstype,
                                    onAnlaegstypeChanged: (val) => setState(() => _valgtAnlaegstype = val!),
                                ),
                                const Divider(height: 32),
                                _sektionTitel('VENTILATORER'),
                                VentilatorVisning(
                                    anlaegstype: _valgtAnlaegstype,
                                    trykGamleFiltreIndController: _trykGamleFiltreInd,
                                    trykFoerIndController: _trykFoerInd,
                                    trykEfterIndController: _trykEfterInd,
                                    hzIndController: _hzIndController,
                                    effektIndController: _effektInd,
                                    trykGamleFiltreUdController: _trykGamleFiltreUd,
                                    trykFoerUdController: _trykFoerUd,
                                    trykEfterUdController: _trykEfterUd,
                                    hzUdController: _hzUdController,
                                    effektUdController: _effektUd,
                                    onSamletTrykIndChanged: (val) => _samletTrykInd = val,
                                    onSamletTrykUdChanged: (val) => _samletTrykUd = val,
                                    antalHeleFiltreIndController: _antalHeleFiltreInd,
                                    antalHalveFiltreIndController: _antalHalveFiltreInd,
                                    antalHeleFiltreUdController: _antalHeleFiltreUd,
                                    antalHalveFiltreUdController: _antalHalveFiltreUd,
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

                                BeregnVedLavHzWidget(
                                    anlaegsType: _valgtAnlaegstype,
                                    key: lavHzKey,
                                    hzInd: hzInd ?? 0,
                                    hzUd: hzUd ?? 0,
                                    luftInd: _luftMaaltInd,
                                    luftUd: _luftMaaltUd,
                                    statiskTrykInd: _samletTrykInd,
                                    statiskTrykUd: _samletTrykUd ?? 0.0,
                                    maaltLuftmaengdeIndController: _luftMaaltIndController,
                                    maaltLuftmaengdeUdController: _luftMaaltUdController,
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

                                    value: _visVarmegenvinding,
                                    onChanged: (val) => setState(() => _visVarmegenvinding = val),
                                    activeThumbColor: _matchingGreen, // Farven HEX #34E0A1
                                    inactiveTrackColor: _matchingGreen, // Farven HEX #34E0A1
                                ),
                                if (_visVarmegenvinding) ...[
                                    VarmegenvindingSektion(
                                        anlaegstype: _valgtAnlaegstype,
                                        visVarmegenvinding: _visVarmegenvinding,
                                        beregnUdFraIndblaesning: _beregnUdFraIndblaesning,
                                        visBeregningsMetode: _valgtAnlaegstype == 'Ventilationsanlæg',
                                        onMethodChanged: (val) => setState(() => _beregnUdFraIndblaesning = val),
                                        tFriskController: _tFriskController,
                                        tIndEfterGenvindingController: _tIndEfterGenvindingController,
                                        tIndEfterVarmefladeController: _tIndEfterVarmefladeController,
                                        tUdController: _tUdController,
                                        tAfkastController: _tAfkastController,
                                        hzInd: hzInd ?? 0,
                                        hzUd: hzUd ?? 0,

                                        onVisPopupInd: () {},  // 🔹 tom funktion (ingen knapfunktion)
                                        onVisPopupUd: () {},   // 🔹 tom funktion (ingen knapfunktion)

                                    ),
                                    const SizedBox(height: 12),

                                    // 👇 Kun vis dropdown når det er et ventilationsanlæg
                                  if (_valgtAnlaegstype == 'Ventilationsanlæg') ...[
                                    _dropdownVarmegenvindingType(),
                                            if (_valgtVarmegenvindingstype == VarmegenvindingType.recirkulering) ...[
                                            const SizedBox(height: 12),
                                            TextField(
                                            controller: _recirkuleringProcentController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                            labelText: 'Recirkulering (%)',
                                            hintText: 'Fx 30',
                                            border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: _matchingGreen, width: 2),
                                            ),
                                            prefixIcon: Icon(Icons.recycling, color: _matchingGreen),
                                            suffixText: '%',
                                            ),
                                            ),
                                            const SizedBox(height: 12),
                                            SwitchListTile(
                                            title: const Text('Kombinér med varmegenvinding?'),
                                            subtitle: const Text('Anlægget har både recirkulering og varmeveksler'),
                                            value: _kombinerMedVarmegenvinding,
                                            onChanged: (val) => setState(() => _kombinerMedVarmegenvinding = val),
                                            activeThumbColor: _matchingGreen,
                                            ),
                                            if (_kombinerMedVarmegenvinding) ...[
                                            const SizedBox(height: 12),
                                            DropdownButtonFormField<VarmegenvindingType>(
                                            initialValue: _kombineretVarmegenvindingstype,
                                            decoration: InputDecoration(
                                            labelText: 'Varmegenvindingstype',
                                            border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: _matchingGreen, width: 2),
                                            ),
                                            prefixIcon: Icon(Icons.thermostat, color: _matchingGreen),
                                            ),
                                            items: [
                                            VarmegenvindingType.krydsveksler,
                                            VarmegenvindingType.dobbeltKrydsveksler,
                                            VarmegenvindingType.roterendeVeksler,
                                            VarmegenvindingType.modstroemsVeksler,
                                            VarmegenvindingType.vaeskekobletVeksler,
                                            VarmegenvindingType.blandekammer,
                                            ].map((type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(_visNavn(type)),
                                            )).toList(),
                                            onChanged: (val) => setState(() => _kombineretVarmegenvindingstype = val),

                                      ),
                                    ],
                                  ],
                                ],
                                ],
                                const SizedBox(height: 32),
                                // To knapper: Tilbage og Næste
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        ElevatedButton(
                                            onPressed: () {
                                                widget.alleAnlaeg[widget.index] = widget.alleAnlaeg[widget.index].copyWith(
                                                    anlaegsNavn: _anlaegsNavnController.text,
                                                    ventMaerkatNr: _ventMaerkatNrController.text,
                                                    valgtAnlaegstype: _valgtAnlaegstype,
                                                    luftInd: double.tryParse(_luftMaaltIndController.text.replaceAll(',', '.')) ?? _luftMaaltInd,
                                                    luftUd: double.tryParse(_luftMaaltUdController.text.replaceAll(',', '.')) ?? _luftMaaltUd,
                                                    trykInd: _samletTrykInd,
                                                    trykUd: _samletTrykUd,
                                                    kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                                                    kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                                                    hzInd: double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0,
                                                    hzUd: double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0,
                                                    trykFoerIndMax: double.tryParse(_trykFoerInd.text.replaceAll(',', '.')),
                                                    trykEfterIndMax: double.tryParse(_trykEfterInd.text.replaceAll(',', '.')),
                                                    trykFoerUdMax: double.tryParse(_trykFoerUd.text.replaceAll(',', '.')),
                                                    trykEfterUdMax: double.tryParse(_trykEfterUd.text.replaceAll(',', '.')),
                                                    trykFoerInd: double.tryParse(_trykFoerInd.text.replaceAll(',', '.')),
                                                    trykEfterInd: double.tryParse(_trykEfterInd.text.replaceAll(',', '.')),
                                                    trykFoerUd: double.tryParse(_trykFoerUd.text.replaceAll(',', '.')),
                                                    trykEfterUd: double.tryParse(_trykEfterUd.text.replaceAll(',', '.')),
                                                    kVaerdiInd: double.tryParse(_kVaerdiIndController.text.replaceAll(',', '.')),
                                                    kVaerdiUd: double.tryParse(_kVaerdiUdController.text.replaceAll(',', '.')),
                                                    maksLuftInd: double.tryParse(_maksLuftIndController.text.replaceAll(',', '.')),
                                                    maksLuftUd: double.tryParse(_maksLuftUdController.text.replaceAll(',', '.')),
                                                    maksEffektInd: double.tryParse(_maksEffektIndController.text.replaceAll(',', '.')),
                                                    maksEffektUd: double.tryParse(_maksEffektUdController.text.replaceAll(',', '.')),
                                                    effektMaaltInd: double.tryParse(_effektMaaltIndController.text.replaceAll(',', '.')),
                                                    effektMaaltUd: double.tryParse(_effektMaaltUdController.text.replaceAll(',', '.')),
                                                    trykDifferensInd: double.tryParse(_trykDifferensIndController.text.replaceAll(',', '.')),
                                                    trykDifferensUd: double.tryParse(_trykDifferensUdController.text.replaceAll(',', '.')),
                                                    trykGamleFiltreInd: double.tryParse(_trykGamleFiltreInd.text.replaceAll(',', '.')),
                                                    trykGamleFiltreUd: double.tryParse(_trykGamleFiltreUd.text.replaceAll(',', '.')),
                                                    antalHeleFiltreInd: int.tryParse(_antalHeleFiltreInd.text) ?? 0,
                                                    antalHalveFiltreInd: int.tryParse(_antalHalveFiltreInd.text) ?? 0,
                                                    antalHeleFiltreUd: int.tryParse(_antalHeleFiltreUd.text) ?? 0,
                                                    antalHalveFiltreUd: int.tryParse(_antalHalveFiltreUd.text) ?? 0,
                                                    kammerBredde: _kammerBredde,
                                                    kammerHoede: _kammerHoede,
                                                    kammerLaengde: _kammerLaengde,
                                                    valgtTilstand: valgtTilstand,
                                                    erBeregnetUdFraKVaerdiInd: _visKVaerdiBeregningInd,
                                                    erBeregnetUdFraKVaerdiUd: _visKVaerdiBeregningUd,
                                                    erBeregnetInd: _visKVaerdiBeregningInd || _visEffektBeregningInd,
                                                    erBeregnetUd: _visKVaerdiBeregningUd || _visEffektBeregningUd,
                                                    erLuftmaengdeMaaeltIndtastetInd: !_visKVaerdiBeregningInd && !_visEffektBeregningInd,
                                                    erLuftmaengdeMaaeltIndtastetUd: !_visKVaerdiBeregningUd && !_visEffektBeregningUd,
                                                    friskluftTemp: double.tryParse(_tFriskController.text.replaceAll(',', '.')) ?? 0,
                                                    tempIndEfterGenvinding: double.tryParse(_tIndEfterGenvindingController.text.replaceAll(',', '.')) ?? 0,
                                                    tempIndEfterVarmeflade: double.tryParse(_tIndEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0,
                                                    tempUd: double.tryParse(_tUdController.text.replaceAll(',', '.')) ?? 0,
                                                    varmegenvindingsType: _valgtAnlaegstype == 'Ventilationsanlæg'
                                                        ? _visNavn(_valgtVarmegenvindingstype ?? VarmegenvindingType.krydsveksler)
                                                        : null,
                                                );
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
                                                // 💾 Gem nuværende data inden vi fortsætter
                                                widget.alleAnlaeg[widget.index] = widget.alleAnlaeg[widget.index].copyWith(
                                                    anlaegsNavn: _anlaegsNavnController.text,
                                                    ventMaerkatNr: _ventMaerkatNrController.text,
                                                    valgtAnlaegstype: _valgtAnlaegstype,
                                                    luftInd: double.tryParse(_luftMaaltIndController.text.replaceAll(',', '.')) ?? _luftMaaltInd,
                                                    luftUd: double.tryParse(_luftMaaltUdController.text.replaceAll(',', '.')) ?? _luftMaaltUd,
                                                    trykInd: _samletTrykInd,
                                                    trykUd: _samletTrykUd,
                                                    kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                                                    kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                                                    hzInd: double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0,
                                                    hzUd: double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0,
                                                    trykFoerIndMax: double.tryParse(_trykFoerInd.text.replaceAll(',', '.')),
                                                    trykEfterIndMax: double.tryParse(_trykEfterInd.text.replaceAll(',', '.')),
                                                    trykFoerUdMax: double.tryParse(_trykFoerUd.text.replaceAll(',', '.')),
                                                    trykEfterUdMax: double.tryParse(_trykEfterUd.text.replaceAll(',', '.')),
                                                    trykFoerInd: double.tryParse(_trykFoerInd.text.replaceAll(',', '.')),
                                                    trykEfterInd: double.tryParse(_trykEfterInd.text.replaceAll(',', '.')),
                                                    trykFoerUd: double.tryParse(_trykFoerUd.text.replaceAll(',', '.')),
                                                    trykEfterUd: double.tryParse(_trykEfterUd.text.replaceAll(',', '.')),
                                                    kVaerdiInd: double.tryParse(_kVaerdiIndController.text.replaceAll(',', '.')),
                                                    kVaerdiUd: double.tryParse(_kVaerdiUdController.text.replaceAll(',', '.')),
                                                    maksLuftInd: double.tryParse(_maksLuftIndController.text.replaceAll(',', '.')),
                                                    maksLuftUd: double.tryParse(_maksLuftUdController.text.replaceAll(',', '.')),
                                                    maksEffektInd: double.tryParse(_maksEffektIndController.text.replaceAll(',', '.')),
                                                    maksEffektUd: double.tryParse(_maksEffektUdController.text.replaceAll(',', '.')),
                                                    effektMaaltInd: double.tryParse(_effektMaaltIndController.text.replaceAll(',', '.')),
                                                    effektMaaltUd: double.tryParse(_effektMaaltUdController.text.replaceAll(',', '.')),
                                                    trykDifferensInd: double.tryParse(_trykDifferensIndController.text.replaceAll(',', '.')),
                                                    trykDifferensUd: double.tryParse(_trykDifferensUdController.text.replaceAll(',', '.')),
                                                    trykGamleFiltreInd: double.tryParse(_trykGamleFiltreInd.text.replaceAll(',', '.')),
                                                    trykGamleFiltreUd: double.tryParse(_trykGamleFiltreUd.text.replaceAll(',', '.')),
                                                    antalHeleFiltreInd: int.tryParse(_antalHeleFiltreInd.text) ?? 0,
                                                    antalHalveFiltreInd: int.tryParse(_antalHalveFiltreInd.text) ?? 0,
                                                    antalHeleFiltreUd: int.tryParse(_antalHeleFiltreUd.text) ?? 0,
                                                    antalHalveFiltreUd: int.tryParse(_antalHalveFiltreUd.text) ?? 0,
                                                    kammerBredde: _kammerBredde,
                                                    kammerHoede: _kammerHoede,
                                                    kammerLaengde: _kammerLaengde,
                                                    valgtTilstand: valgtTilstand,
                                                    erBeregnetUdFraKVaerdiInd: _visKVaerdiBeregningInd,
                                                    erBeregnetUdFraKVaerdiUd: _visKVaerdiBeregningUd,
                                                    erBeregnetInd: _visKVaerdiBeregningInd || _visEffektBeregningInd,
                                                    erBeregnetUd: _visKVaerdiBeregningUd || _visEffektBeregningUd,
                                                    erLuftmaengdeMaaeltIndtastetInd: !_visKVaerdiBeregningInd && !_visEffektBeregningInd,
                                                    erLuftmaengdeMaaeltIndtastetUd: !_visKVaerdiBeregningUd && !_visEffektBeregningUd,
                                                    friskluftTemp: double.tryParse(_tFriskController.text.replaceAll(',', '.')) ?? 0,
                                                    tempIndEfterGenvinding: double.tryParse(_tIndEfterGenvindingController.text.replaceAll(',', '.')) ?? 0,
                                                    tempIndEfterVarmeflade: double.tryParse(_tIndEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0,
                                                    tempUd: double.tryParse(_tUdController.text.replaceAll(',', '.')) ?? 0,
                                                    varmegenvindingsType: _valgtAnlaegstype == 'Ventilationsanlæg'
                                                        ? _visNavn(_valgtVarmegenvindingstype ?? VarmegenvindingType.krydsveksler)
                                                        : null,
                                                );

                                                // 🔧 Hvis luftmængde mangler, prøv at hente den manuelt fra inputfelterne
                                                _luftMaaltInd = double.tryParse(_luftMaaltIndController.text.replaceAll(',', '.')) ?? _luftMaaltInd;
                                                _luftMaaltUd = double.tryParse(_luftMaaltUdController.text.replaceAll(',', '.')) ?? _luftMaaltUd;

                                                // ✅ Spring popups over hvis anlægget allerede er færdigbehandlet
                                                final bool erAlleredeGennemgaaet = widget.alleAnlaeg[widget.index].erFaerdigbehandlet;

                                                if (erAlleredeGennemgaaet) {
                                                    final double elpris = widget.projektInfo.elPris;
                                                    final int samledeDriftstimer = widget.driftstimer.values
                                                        .map((controller) => int.tryParse(controller.text) ?? 0)
                                                        .fold(0, (sum, val) => sum + val) * widget.projektInfo.ugerPerAar;
                                                    final double kwInd = double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0;
                                                    final double kwUd = double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0;
                                                    final double hzInd = double.tryParse(_hzIndController.text.replaceAll(',', '.')) ?? 0;
                                                    final double hzUd = double.tryParse(_hzUdController.text.replaceAll(',', '.')) ?? 0;
                                                    final double beregnetOmkostningFoer = kwInd * elpris * samledeDriftstimer / 1000;
                                                    final double beregnetOmkostningEfter = kwUd * elpris * samledeDriftstimer / 1000;
                                                    final double beregnetAarsbesparelse = beregnetOmkostningFoer - beregnetOmkostningEfter;
                                                    final double beregnetTilbagebetalingstid = beregnetAarsbesparelse == 0
                                                        ? 0
                                                        : (widget.alleAnlaeg[widget.index].remUdskiftningPris ?? 0) / beregnetAarsbesparelse;
                                                    final double beregnetSamletOmkostning =
                                                        beregnetOmkostningEfter + (widget.alleAnlaeg[widget.index].remUdskiftningPris ?? 0);
                                                    final double? recirkuleringProcent =
                                                    _valgtVarmegenvindingstype == VarmegenvindingType.recirkulering
                                                        ? double.tryParse(_recirkuleringProcentController.text.replaceAll(',', '.'))
                                                        : null;
                                                    final varmeforbrugResultat = beregnVarmeforbrugOgVirkningsgrad(
                                                        anlaegsType: _valgtAnlaegstype,
                                                        luftInd: _luftMaaltInd,
                                                        luftUd: _luftMaaltUd,
                                                        driftstimer: samledeDriftstimer.toDouble(),
                                                        friskluftTemp: double.tryParse(_tFriskController.text.replaceAll(',', '.')) ?? 0,
                                                        tempUd: double.tryParse(_tUdController.text.replaceAll(',', '.')) ?? 0,
                                                        tempIndEfterGenvinding: double.tryParse(_tIndEfterGenvindingController.text.replaceAll(',', '.')) ?? 0,
                                                        tempIndEfterVarmeflade: double.tryParse(_tIndEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0,
                                                        varmePris: widget.projektInfo.varmePris,
                                                        driftstype: widget.projektInfo.driftstype,
                                                        tempAfkast: double.tryParse(_tAfkastController.text.replaceAll(',', '.')),
                                                        varmegenvindingsType: _valgtAnlaegstype == 'Ventilationsanlæg'
                                                            ? _visNavn(_valgtVarmegenvindingstype ?? VarmegenvindingType.krydsveksler)
                                                            : null,
                                                        recirkuleringProcent: recirkuleringProcent,
                                                        varmegenvindingVirkningsgrad: null,
                                                        kombineretVarmegenvindingsType: _kombinerMedVarmegenvinding && _kombineretVarmegenvindingstype != null
                                                            ? _visNavn(_kombineretVarmegenvindingstype!)
                                                            : null,
                                                    );
                                                    final List<VentilatorOekonomiSamlet> forslag = beregnAlleVentilatorer(
                                                        fabrikant: 'Ebmpapst',
                                                        afdeling: widget.projektInfo.afdeling,
                                                        trykIndNormal: _samletTrykInd,
                                                        luftIndNormal: _luftMaaltInd,
                                                        trykIndMax: trykFoerIndMax ?? 0,
                                                        luftIndMax: luftIndMax ?? 0,
                                                        trykUdNormal: _samletTrykUd,
                                                        luftUdNormal: _luftMaaltUd,
                                                        trykUdMax: trykFoerUdMax ?? 0,
                                                        luftUdMax: luftUdMax ?? 0,
                                                        omkostningInd: beregnetOmkostningFoer,
                                                        omkostningUd: beregnetOmkostningEfter,
                                                        fradragRemtrukket: widget.alleAnlaeg[widget.index].remUdskiftningPris ?? 0,
                                                        driftstimer: widget.driftstimer.values
                                                            .map((c) => int.tryParse(c.text) ?? 0)
                                                            .fold(0, (sum, v) => sum + v),
                                                        elpris: elpris,
                                                        anlaegsNavn: _anlaegsNavnController.text,
                                                        anlaegstype: _valgtAnlaegstype,
                                                        projektInfo: widget.projektInfo,
                                                    );
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => ResultatInternSkarm(
                                                                forslag: widget.forslag,
                                                                anlaeg: widget.alleAnlaeg[widget.index],
                                                                anlaegsType: _valgtAnlaegstype,
                                                                index: widget.index,
                                                                alleAnlaeg: widget.alleAnlaeg,
                                                                anlaegsNavn: _anlaegsNavnController.text,
                                                                kwInd: kwInd,
                                                                luftInd: _luftMaaltInd,
                                                                statiskTrykInd: _samletTrykInd,
                                                                kwUd: kwUd,
                                                                luftUd: _luftMaaltUd,
                                                                statiskTrykUd: _samletTrykUd,
                                                                hzInd: hzInd,
                                                                hzUd: hzUd,
                                                                projektInfo: widget.projektInfo,
                                                                erBeregnetInd: _visKVaerdiBeregningInd || _visEffektBeregningInd,
                                                                erBeregnetUd: _visKVaerdiBeregningUd || _visEffektBeregningUd,
                                                                erBeregnetUdFraKVaerdiInd: _visKVaerdiBeregningInd,
                                                                erBeregnetUdFraKVaerdiUd: _visKVaerdiBeregningUd,
                                                                trykFoerIndMax: trykFoerIndMax,
                                                                trykEfterIndMax: trykEfterIndMax,
                                                                trykFoerUdMax: trykFoerUdMax,
                                                                trykEfterUdMax: trykEfterUdMax,
                                                                luftIndMax: luftIndMax,
                                                                luftUdMax: luftUdMax,
                                                                remUdskiftningPris: widget.alleAnlaeg[widget.index].remUdskiftningPris,
                                                                elpris: elpris,
                                                                omkostningFoer: beregnetOmkostningFoer,
                                                                omkostningEfter: beregnetOmkostningEfter,
                                                                kammerBredde: widget.alleAnlaeg[widget.index].kammerBredde,
                                                                kammerHoede: widget.alleAnlaeg[widget.index].kammerHoede,
                                                                kammerLaengde: widget.alleAnlaeg[widget.index].kammerLaengde,
                                                                valgtTilstand: widget.alleAnlaeg[widget.index].valgtTilstand,
                                                                erLuftmaengdeMaaeltIndtastetInd: !_visKVaerdiBeregningInd && !_visEffektBeregningInd,
                                                                erLuftmaengdeMaaeltIndtastetUd: !_visKVaerdiBeregningUd && !_visEffektBeregningUd,
                                                                luftmaengdeLabelInd: (_visKVaerdiBeregningInd || _visEffektBeregningInd) ? 'Beregnet luftmængde (m³/h)' : 'Målt luftmængde (m³/h)',
                                                                luftmaengdeLabelUd: (_visKVaerdiBeregningUd || _visEffektBeregningUd) ? 'Beregnet luftmængde (m³/h)' : 'Målt luftmængde (m³/h)',
                                                                driftstimer: widget.driftstimer,
                                                                eksisterendeVarenummerInd: 'ukendt',
                                                                eksisterendeVarenummerUd: 'ukendt',
                                                                aarsbesparelse: beregnetAarsbesparelse,
                                                                tilbagebetalingstid: beregnetTilbagebetalingstid,
                                                                samletOmkostning: beregnetSamletOmkostning,
                                                                varmeforbrugResultat: varmeforbrugResultat,
                                                                recirkuleringProcent: recirkuleringProcent,
                                                                manuelleData: null,
                                                                internKommentar: widget.alleAnlaeg[widget.index].internKommentar,
                                                            ),
                                                        ),
                                                    );
                                                    return; // ← STOP HER
                                                }


                                                // ✅ Hent værdier fra lavHz-widget via nøgle
                                                final maxInd = lavHzKey.currentState?.hentMaxDataInd();
                                                final maxUd = lavHzKey.currentState?.hentMaxDataUd();

                                                luftIndMax = maxInd?['luft'];
                                                trykFoerIndMax = maxInd?['trykFoer'];
                                                trykEfterIndMax = maxInd?['trykEfter'];

                                                luftUdMax = maxUd?['luft'];
                                                trykFoerUdMax = maxUd?['trykFoer'];
                                                trykEfterUdMax = maxUd?['trykEfter'];

                                                // Beregn driftstimer (dette forbliver uændret)
                                                final double elpris = widget.projektInfo.elPris;
                                                final double driftstimer = widget.projektInfo.driftTimerPrUge.fold(0.0, (sum, t) => sum + t) * widget.projektInfo.ugerPerAar;

                                                final EbmpapstResultat eksisterendeInd = ebmpapst.findNaermesteEbmpapstVentilator(
                                                    _samletTrykInd,
                                                    _luftMaaltInd,
                                                    driftstimer: driftstimer,
                                                    elpris: elpris,
                                                    samletOmkostning: 0,
                                                    aarsbesparelse: 0,
                                                );

                                                final EbmpapstResultat eksisterendeUd = ebmpapst.findNaermesteEbmpapstVentilator(
                                                    _samletTrykUd,
                                                    _luftMaaltUd,
                                                    driftstimer: driftstimer,
                                                    elpris: elpris,
                                                    samletOmkostning: 0,
                                                    aarsbesparelse: 0,
                                                );

                                                final double luftInd = double.tryParse(_luftMaaltIndController.text.replaceAll(',', '.')) ?? 0;
                                                final double kwInd = double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0;

                                                final double luftUd = double.tryParse(_luftMaaltUdController.text.replaceAll(',', '.')) ?? 0;
                                                final double kwUd = double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0;

                                                final double virkningsgradIndFoer = ((luftInd / 3600) * _samletTrykInd) / (kwInd * 1000) * 100;
                                                final double virkningsgradUdFoer = ((luftUd / 3600) * _samletTrykUd) / (kwUd * 1000) * 100;

                                                print('🔧 DEBUG: virkningsgradIndFoer = $virkningsgradIndFoer, virkningsgradUdFoer = $virkningsgradUdFoer');

                                                final bool indHoj = virkningsgradIndFoer.isFinite && virkningsgradIndFoer > 70;
                                                final bool udHoj = virkningsgradUdFoer.isFinite && virkningsgradUdFoer > 70;

                                                if (indHoj || udHoj) {
                                                    print('⚠️ Popup skal vises nu');
                                                    final bool fortsaet = await visVirkningsgradAdvarsel(
                                                        context,
                                                        indblaesningHoj: indHoj,
                                                        udsugningHoj: udHoj,
                                                    );
                                                    if (!fortsaet) return;
                                                }

                                                final bool erBeregnetInd = _visKVaerdiBeregningInd || _visEffektBeregningInd;
                                                final bool erBeregnetUd = _visKVaerdiBeregningUd || _visEffektBeregningUd;

                                                final double trykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
                                                final double trykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;

                                                if (trykFoerInd > 0) {
                                                    await showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                            title: const Text('Advarsel'),
                                                            content: const Text('Du har angivet et positivt tryk før indblæsningsventilatoren. Tjek målingen.'),
                                                            actions: [
                                                                TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text('OK'),
                                                                ),
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
                                                                TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text('OK'),
                                                                ),
                                                            ],
                                                        ),
                                                    );
                                                }

                                                // ➕ Beregn korrekt fasit tryk (tryk før og tryk efter som absolutværdi)
                                                final double beregnetTrykFoerInd = double.tryParse(_trykFoerInd.text.replaceAll(',', '.')) ?? 0;
                                                final double beregnetTrykEfterInd = double.tryParse(_trykEfterIndController.text.replaceAll(',', '.')) ?? 0;
                                                final double beregnetTrykFoerUd = double.tryParse(_trykFoerUd.text.replaceAll(',', '.')) ?? 0;
                                                final double beregnetTrykEfterUd = double.tryParse(_trykEfterUdController.text.replaceAll(',', '.')) ?? 0;

                                                final double statiskTrykMagInd = beregnetTrykFoerInd.abs() + beregnetTrykEfterInd.abs();
                                                final double statiskTrykMagUd = beregnetTrykFoerUd.abs() + beregnetTrykEfterUd.abs();

// 🔹 Hent antal filtre fra inputfelterne
                                                final int antalHeleFiltreIndVal = int.tryParse(_antalHeleFiltreInd.text) ?? 0;
                                                final int antalHalveFiltreIndVal = int.tryParse(_antalHalveFiltreInd.text) ?? 0;
                                                final int antalHeleFiltreUdVal = int.tryParse(_antalHeleFiltreUd.text) ?? 0;
                                                final int antalHalveFiltreUdVal = int.tryParse(_antalHalveFiltreUd.text) ?? 0;

// 🟦 DEBUG
                                                print('🟦 Hele Ind=$antalHeleFiltreIndVal, Halve Ind=$antalHalveFiltreIndVal');
                                                print('🟦 Hele Ud=$antalHeleFiltreUdVal, Halve Ud=$antalHalveFiltreUdVal');

// 🔹 Beregn totaler hvis du har brug for det
                                                final double totalFiltreInd = antalHeleFiltreIndVal + 0.5 * antalHalveFiltreIndVal;
                                                final double totalFiltreUd = antalHeleFiltreUdVal + 0.5 * antalHalveFiltreUdVal;
                                                final double totalFiltre = totalFiltreInd + totalFiltreUd;

                                                print('🟩 DEBUG: total filtre (omregnet)=$totalFiltre');

// 🔹 Gem alle fire værdier i AnlaegsData
                                                widget.alleAnlaeg[widget.index] = widget.alleAnlaeg[widget.index].copyWith(
                                                    antalHeleFiltreInd: antalHeleFiltreIndVal,
                                                    antalHalveFiltreInd: antalHalveFiltreIndVal,
                                                    antalHeleFiltreUd: antalHeleFiltreUdVal,
                                                    antalHalveFiltreUd: antalHalveFiltreUdVal,
                                                    trykGamleFiltreInd: double.tryParse(_trykGamleFiltreInd.text.replaceAll(',', '.')),
                                                    trykGamleFiltreUd: double.tryParse(_trykGamleFiltreUd.text.replaceAll(',', '.')),
                                                    filterKammerLaengdeInd: double.tryParse(_filterKammerLaengdeIndController.text.replaceAll(',', '.')),
                                                    filterKammerLaengdeUd: double.tryParse(_filterKammerLaengdeUdController.text.replaceAll(',', '.')),

                                                );

// 1️⃣ Vis filter-popup kun hvis der er mindst ét filter
                                                if (totalFiltre > 0) {
                                                    final FilterValg? valgtFilter = await visFilterPopup(
                                                        context: context,
                                                        anlaeg: widget.alleAnlaeg[widget.index],
                                                        projektInfo: widget.projektInfo,
                                                        alleAnlaeg: widget.alleAnlaeg,
                                                        index: widget.index,
                                                    );

                                                    if (valgtFilter != null) {
                                                        widget.alleAnlaeg[widget.index] = widget.alleAnlaeg[widget.index].copyWith(
                                                            filterValg: valgtFilter,
                                                            antalHeleFiltreInd: antalHeleFiltreIndVal,
                                                            antalHalveFiltreInd: antalHalveFiltreIndVal,
                                                            antalHeleFiltreUd: antalHeleFiltreUdVal,
                                                            antalHalveFiltreUd: antalHalveFiltreUdVal,
                                                            trykGamleFiltreInd: double.tryParse(_trykGamleFiltreInd.text.replaceAll(',', '.')),
                                                            trykGamleFiltreUd: double.tryParse(_trykGamleFiltreUd.text.replaceAll(',', '.')),
                                                            filterKammerLaengdeInd: double.tryParse(_filterKammerLaengdeIndController.text.replaceAll(',', '.')),
                                                            filterKammerLaengdeUd: double.tryParse(_filterKammerLaengdeUdController.text.replaceAll(',', '.')),
                                                        );


                                                    }
                                                }


                                                // 1️⃣ Luk tastaturet helt før popup
                                                await _fjernFokusKomplet(); // ← sørger for at tastaturet skjules korrekt

// 2️⃣ Vis popup til remudskiftning
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                final double? remUdskiftningPris = await visRemtrukketPopup(context, _luftMaaltInd);

// 3️⃣ Vis popup til opmåling af kammer
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                final kammerResultat = await visKammerOpmalingPopup(context);
                                                if (kammerResultat != null) {
                                                    _kammerBredde = kammerResultat.bredde;
                                                    _kammerHoede = kammerResultat.hoejde;
                                                    _kammerLaengde = kammerResultat.laengde;
                                                }

// 4️⃣ Vis popup til tilstandsvurdering
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                final valgt = await visTilstandsvurderingPopup(context);
                                                if (valgt == null) return;

                                                setState(() {
                                                    valgtTilstand = valgt;
                                                });

                                                // 5️⃣ Vis popup til intern kommentar (NY!)
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                final String? internKommentar = await visInternKommentarDialog(context);
// Fortsætter også hvis null (bruger springer over)

                                                                // ⬆️⬆️⬆️ NY KODE SLUTTER HER ⬆️⬆️⬆️

// 🔹 Samlede driftstimer
                                                final int samledeDriftstimer = widget.driftstimer.values
                                                    .map((controller) => int.tryParse(controller.text) ?? 0)
                                                    .fold(0, (sum, val) => sum + val) * widget.projektInfo.ugerPerAar;


// 🔹 Beregning el-omkostning
                                                final double beregnetOmkostningFoer =
                                                    kwInd * elpris * samledeDriftstimer / 1000;
                                                final double beregnetOmkostningEfter =
                                                    kwUd * elpris * samledeDriftstimer / 1000;

// 🔹 Beregnet årlig besparelse og tilbagebetalingstid
                                                final double beregnetAarsbesparelse =
                                                    beregnetOmkostningFoer - beregnetOmkostningEfter;
                                                final double beregnetTilbagebetalingstid =
                                                beregnetAarsbesparelse == 0
                                                    ? 0
                                                    : (remUdskiftningPris ?? 0) / beregnetAarsbesparelse;

                                                final double beregnetSamletOmkostning =
                                                    beregnetOmkostningEfter + (remUdskiftningPris ?? 0);

                                                final double? recirkuleringProcent =
                                                _valgtVarmegenvindingstype == VarmegenvindingType.recirkulering
                                                    ? double.tryParse(_recirkuleringProcentController.text.replaceAll(',', '.'))
                                                    : null;

// 🔹 Beregn varmeforbrug og virkningsgrad (fælles resultat)
                                                final varmeforbrugResultat = beregnVarmeforbrugOgVirkningsgrad(
                                                    anlaegsType: _valgtAnlaegstype,
                                                    luftInd: _luftMaaltInd,
                                                    luftUd: _luftMaaltUd,
                                                    driftstimer: samledeDriftstimer.toDouble(),
                                                    friskluftTemp: double.tryParse(_tFriskController.text.replaceAll(',', '.')) ?? 0,
                                                    tempUd: double.tryParse(_tUdController.text.replaceAll(',', '.')) ?? 0,
                                                    tempIndEfterGenvinding: double.tryParse(_tIndEfterGenvindingController.text.replaceAll(',', '.')) ?? 0,
                                                    tempIndEfterVarmeflade: double.tryParse(_tIndEfterVarmefladeController.text.replaceAll(',', '.')) ?? 0,
                                                    varmePris: widget.projektInfo.varmePris,
                                                    driftstype: widget.projektInfo.driftstype,
                                                    tempAfkast: double.tryParse(_tAfkastController.text.replaceAll(',', '.')),
                                                    varmegenvindingsType: _valgtAnlaegstype == 'Ventilationsanlæg'
                                                        ? _visNavn(_valgtVarmegenvindingstype ?? VarmegenvindingType.krydsveksler)
                                                        : null,
                                                    recirkuleringProcent: recirkuleringProcent,
                                                    varmegenvindingVirkningsgrad: null,
                                                    kombineretVarmegenvindingsType: _kombinerMedVarmegenvinding && _kombineretVarmegenvindingstype != null
                                                        ? _visNavn(_kombineretVarmegenvindingstype!)
                                                        : null,
                                                );

                                                // 🔹 Skal brugeren tilføje billeder?
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                final bool vilTilfoejeBilleder =
                                                await visDokumentationsDialog(context, valgtTilstand);

                                                if (vilTilfoejeBilleder == true) {
                                                    final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => DokumentationBilledeSkarm(
                                                                index: widget.index,
                                                                alleAnlaeg: widget.alleAnlaeg,
                                                                anlaegsNavn: _anlaegsNavnController.text,
                                                                anlaegsType: _valgtAnlaegstype,
                                                                logoPath: 'assets/images/ebmpapst.png',
                                                                projektInfo: widget.projektInfo,
                                                                kwInd: double.tryParse(_effektInd.text.replaceAll(',', '.')) ?? 0,
                                                                luftInd: _luftMaaltInd,
                                                                trykInd: _samletTrykInd,
                                                                kwUd: double.tryParse(_effektUd.text.replaceAll(',', '.')) ?? 0,
                                                                luftUd: _luftMaaltUd,
                                                                trykUd: _samletTrykUd,
                                                                hzInd: hzInd ?? 0,
                                                                hzUd: hzUd ?? 0,
                                                                erBeregnetInd: erBeregnetInd,
                                                                erBeregnetUd: erBeregnetUd,
                                                                trykFoerIndMax: trykFoerIndMax,
                                                                trykEfterIndMax: trykEfterIndMax,
                                                                trykFoerUdMax: trykFoerUdMax,
                                                                trykEfterUdMax: trykEfterUdMax,
                                                                luftIndMax: luftIndMax,
                                                                luftUdMax: luftUdMax,
                                                                elpris: elpris,
                                                                kammerBredde: _kammerBredde,
                                                                kammerHoede: _kammerHoede,
                                                                kammerLaengde: _kammerLaengde,
                                                                valgtTilstand: valgtTilstand,
                                                                remUdskiftningPris: remUdskiftningPris,
                                                                driftstimer: widget.driftstimer,
                                                                omkostningFoer: beregnetOmkostningFoer,
                                                                omkostningEfter: beregnetOmkostningEfter,
                                                                eksisterendeVarenummerInd: 'ukendt',
                                                                eksisterendeVarenummerUd: 'ukendt',
                                                                samletOmkostning: beregnetSamletOmkostning,
                                                                varmeforbrugResultat: varmeforbrugResultat,


                                                            ),
                                                        ),
                                                    );

                                                    if (result != null && result is Map && result["status"] == "completed") {
                                                        final List<AnlaegsData> opdateretAlleAnlaeg = List<AnlaegsData>.from(result["alleAnlaeg"]);
                                                        final int opdateretIndex = result["opdateretIndex"] as int;

                                                        setState(() {
                                                            widget.alleAnlaeg..clear()..addAll(opdateretAlleAnlaeg);
                                                        });

                                                        // 🆕 EFTER BILLEDER - Spørg om pris
                                                        await Future.delayed(const Duration(milliseconds: 100));
                                                        final bool? vilIndtasteSelvPris = await visPrisIndtastningValg(context);

                                                        Map<String, dynamic>? manuelleData;
                                                        if (vilIndtasteSelvPris == true) {
                                                            await Future.delayed(const Duration(milliseconds: 100));
                                                            final String? udskiftningstype = await visUdskiftningstype(context);

                                                            if (udskiftningstype != null) {
                                                                await Future.delayed(const Duration(milliseconds: 100));
                                                                manuelleData = await visNytAnlaegData(context, udskiftningstype, anlaegstype: _valgtAnlaegstype);
                                                            }
                                                        }

                                                        widget.alleAnlaeg[widget.index] = widget.alleAnlaeg[widget.index].copyWith(
                                                            erFaerdigbehandlet: true,
                                                        );

                                                        // GÅ til ResultatInternSkarm
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) => ResultatInternSkarm(
                                                                    forslag: widget.forslag,
                                                                    anlaeg: widget.alleAnlaeg[opdateretIndex],
                                                                    anlaegsType: _valgtAnlaegstype,
                                                                    index: opdateretIndex,
                                                                    alleAnlaeg: widget.alleAnlaeg,
                                                                    anlaegsNavn: _anlaegsNavnController.text,
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
                                                                    trykFoerIndMax: trykFoerIndMax,
                                                                    trykEfterIndMax: trykEfterIndMax,
                                                                    trykFoerUdMax: trykFoerUdMax,
                                                                    trykEfterUdMax: trykEfterUdMax,
                                                                    luftIndMax: luftIndMax,
                                                                    luftUdMax: luftUdMax,
                                                                    remUdskiftningPris: remUdskiftningPris,
                                                                    elpris: elpris,
                                                                    omkostningFoer: beregnetOmkostningFoer,
                                                                    omkostningEfter: beregnetOmkostningEfter,
                                                                    kammerBredde: _kammerBredde,
                                                                    kammerHoede: _kammerHoede,
                                                                    kammerLaengde: _kammerLaengde,
                                                                    valgtTilstand: valgtTilstand,
                                                                    erBeregnetUdFraKVaerdiInd: _visKVaerdiBeregningInd,
                                                                    erBeregnetUdFraKVaerdiUd: _visKVaerdiBeregningUd,
                                                                    erLuftmaengdeMaaeltIndtastetInd: !_visKVaerdiBeregningInd && !_visEffektBeregningInd,
                                                                    erLuftmaengdeMaaeltIndtastetUd: !_visKVaerdiBeregningUd && !_visEffektBeregningUd,
                                                                    luftmaengdeLabelInd: (_visKVaerdiBeregningInd || _visEffektBeregningInd) ? 'Beregnet luftmængde (m³/h)' : 'Målt luftmængde (m³/h)',
                                                                    luftmaengdeLabelUd: (_visKVaerdiBeregningUd || _visEffektBeregningUd) ? 'Beregnet luftmængde (m³/h)' : 'Målt luftmængde (m³/h)',
                                                                    driftstimer: widget.driftstimer,
                                                                    eksisterendeVarenummerInd: 'ukendt',
                                                                    eksisterendeVarenummerUd: 'ukendt',
                                                                    aarsbesparelse: beregnetAarsbesparelse,
                                                                    tilbagebetalingstid: beregnetTilbagebetalingstid,
                                                                    samletOmkostning: beregnetSamletOmkostning,
                                                                    varmeforbrugResultat: varmeforbrugResultat,
                                                                    recirkuleringProcent: recirkuleringProcent,
                                                                    manuelleData: manuelleData,
                                                                    internKommentar: internKommentar,
                                                                ),
                                                            ),
                                                        );
                                                    }
                                                } else {
                                                    // 🆕 INGEN BILLEDER - Spørg om pris
                                                    await Future.delayed(const Duration(milliseconds: 100));
                                                    final bool? vilIndtasteSelvPris = await visPrisIndtastningValg(context);

                                                    Map<String, dynamic>? manuelleData;
                                                    if (vilIndtasteSelvPris == true) {
                                                        await Future.delayed(const Duration(milliseconds: 100));
                                                        final String? udskiftningstype = await visUdskiftningstype(context);

                                                        if (udskiftningstype != null) {
                                                            await Future.delayed(const Duration(milliseconds: 100));
                                                            manuelleData = await visNytAnlaegData(context, udskiftningstype, anlaegstype: _valgtAnlaegstype);
                                                        }
                                                    }
                                                    widget.alleAnlaeg[widget.index] = widget.alleAnlaeg[widget.index].copyWith(
                                                        erFaerdigbehandlet: true,
                                                    );

                                                    // GÅ til ResultatInternSkarm
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => ResultatInternSkarm(
                                                                forslag: widget.forslag,
                                                                anlaeg: widget.alleAnlaeg[widget.index],
                                                                anlaegsType: _valgtAnlaegstype,
                                                                index: widget.index,
                                                                alleAnlaeg: widget.alleAnlaeg,
                                                                anlaegsNavn: _anlaegsNavnController.text,
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
                                                                trykFoerIndMax: trykFoerIndMax,
                                                                trykEfterIndMax: trykEfterIndMax,
                                                                trykFoerUdMax: trykFoerUdMax,
                                                                trykEfterUdMax: trykEfterUdMax,
                                                                luftIndMax: luftIndMax,
                                                                luftUdMax: luftUdMax,
                                                                remUdskiftningPris: remUdskiftningPris,
                                                                elpris: elpris,
                                                                omkostningFoer: beregnetOmkostningFoer,
                                                                omkostningEfter: beregnetOmkostningEfter,
                                                                kammerBredde: _kammerBredde,
                                                                kammerHoede: _kammerHoede,
                                                                kammerLaengde: _kammerLaengde,
                                                                valgtTilstand: valgtTilstand,
                                                                erBeregnetUdFraKVaerdiInd: _visKVaerdiBeregningInd,
                                                                erBeregnetUdFraKVaerdiUd: _visKVaerdiBeregningUd,
                                                                erLuftmaengdeMaaeltIndtastetInd: !_visKVaerdiBeregningInd && !_visEffektBeregningInd,
                                                                erLuftmaengdeMaaeltIndtastetUd: !_visKVaerdiBeregningUd && !_visEffektBeregningUd,
                                                                luftmaengdeLabelInd: (_visKVaerdiBeregningInd || _visEffektBeregningInd) ? 'Beregnet luftmængde (m³/h)' : 'Målt luftmængde (m³/h)',
                                                                luftmaengdeLabelUd: (_visKVaerdiBeregningUd || _visEffektBeregningUd) ? 'Beregnet luftmængde (m³/h)' : 'Målt luftmængde (m³/h)',
                                                                driftstimer: widget.driftstimer,
                                                                eksisterendeVarenummerInd: 'ukendt',
                                                                eksisterendeVarenummerUd: 'ukendt',
                                                                aarsbesparelse: beregnetAarsbesparelse,
                                                                tilbagebetalingstid: beregnetTilbagebetalingstid,
                                                                samletOmkostning: beregnetSamletOmkostning,
                                                                varmeforbrugResultat: varmeforbrugResultat,
                                                                recirkuleringProcent: recirkuleringProcent,
                                                                manuelleData: manuelleData,
                                                                internKommentar: internKommentar,
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































































































