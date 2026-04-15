import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:ventoptima/services/app_sikkerhed.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ventoptima/ventoptima_projekt_serializer.dart';

Future<void> visSendRapportPopup(
    BuildContext context,
    dynamic projektInfo,
    dynamic kundePdfFil, // PDF bytes
    dynamic tekniskPdfFil, // PDF bytes
    ) async {
  final String valgtAfdeling = projektInfo.afdeling ?? '';
  String? valgtServiceleder;

  // 🔹 Afdelinger og serviceledere
  final Map<String, Map<String, String>> afdelinger = {
    'Aalborg': {
      'Henrik Wrængmose Christensen': 'henrik.wraengmose.christensen@bravida.dk',
      'Kasper Lynggaard Christensen': 'kasper.lynggaard@bravida.dk',
      'Johnny Hansen': 'j.hansen@bravida.dk',
      'Martin Jacobsen': 'morville1976@gmail.com',
    },
    'Randers': {
      'Svend Jeppesen': 'svend.jeppesen@bravida.dk',
    },
    'Aarhus': {
      'Louise de Fries Bjerrum': 'louise.bjerrum@bravida.dk',
      'Svend Jeppesen': 'svend.jeppesen@bravida.dk',
      'Peter S. D. Andersen': 'peter.s.d.andersen@bravida.dk',
      'Mathias Nørholm Nielsen': 'mathias.n.nielsen@bravida.dk',
    },
    'Holstebro': {
      'Lars Nielsen': 'la.nielsen@bravida.dk',
      'Silas Bonde-Petersen': 'silas.bonde-petersen@bravida.dk',
    },
    'Horsens': {
      'Jakob Pedersen': 'jakob.pedersen@bravida.dk',
    },
    'Kolding': {
      'Kasper Mac Donald': 'kasper.mac.donald@bravida.dk',
    },
    'Esbjerg': {
      'Jannik B. Sørensen': 'jannik.b.sorensen@bravida.dk',
      'Richard Skak Andreasen': 'richard.s.andreasen@bravida.dk',
      'Jean Gøbel Jacobsen': 'jean.g.jacobsen@bravida.dk',
    },
    'Odense': {
      'Martin Møller Hansen': 'martin.hansen@bravida.dk',
      'Søren Hornemann Jensen': 'soren.hornemann.jensen@bravida.dk',
      'Henrik Christensen': 'henrik.christensen@bravida.dk',
      'Kasper Mac Donald': 'kasper.mac.donald@bravida.dk',
    },
    'Brøndby': {
      'Jens Meyland': 'jens.meyland@bravida.dk',
      'Batric Lekic': 'batric.lekic@bravida.dk',
      'Ticho Sten Jensen': 'ticho.jensen@bravida.dk',
    },
  };

  const Color matchingGreen = Color(0xFF34E0A1);
  const Color matchingBlue = Color(0xFF006390);
  final valgteLedere = afdelinger[valgtAfdeling];

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final bool kanSendes =
              valgtServiceleder != null && valgtServiceleder!.isNotEmpty;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.25),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🟩 Grøn topbjælke
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF34E0A1), Color(0xFF2ACD8F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Send rapport til serviceleder',
                      style: TextStyle(
                        color: matchingBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Afdeling: $valgtAfdeling',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: matchingBlue,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Begge PDF-filer (kunde og teknisk) bliver vedhæftet automatisk.\n'
                              'Vælg serviceleder for den valgte afdeling:',
                          style: TextStyle(fontSize: 13.5, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),

                        if (valgteLedere != null)
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Serviceleder',
                              labelStyle: const TextStyle(color: matchingGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                BorderSide(color: matchingGreen, width: 1.5),
                              ),
                            ),
                            value: valgtServiceleder,
                            items: valgteLedere.keys.map((navn) {
                              return DropdownMenuItem(value: navn, child: Text(navn));
                            }).toList(),
                            onChanged: (val) => setState(() => valgtServiceleder = val),
                          ),

                        const SizedBox(height: 28),

                        // 🔹 Send-knap
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              kanSendes ? matchingGreen : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                              elevation: kanSendes ? 4 : 0,
                            ),
                            icon: const Icon(Icons.send),
                            label: Text(
                              kanSendes ? 'Send rapport' : 'Vælg serviceleder',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: !kanSendes
                                ? null
                                : () async {
                              final email = valgteLedere?[valgtServiceleder] ?? '';

                              // 🔍 Tjek for internet – gælder alle platforme
                              final connectivityResult = await Connectivity().checkConnectivity();
                              final hasInternet =
                                  connectivityResult != ConnectivityResult.none &&
                                      await _hasNetworkConnection();

                              if (!hasInternet) {
                                Navigator.pop(context);
                                _visOfflineDialog(
                                  context,
                                  email,
                                  valgtServiceleder!,
                                  projektInfo,
                                  kundePdfFil,
                                  tekniskPdfFil,
                                );
                                return;
                              }

                              // 📅 Beregn udløbsdato (30 dage)
                              final udloebsDato = DateTime.now().add(const Duration(days: 30));
                              final datoFormat = DateFormat('d. MMMM yyyy', 'da_DK');

                              await sendVentoptimaMail(
                                context: context,
                                to: email,
                                toName: valgtServiceleder!,
                                subject:
                                'VentOptima rapport – ${projektInfo.kundeNavn} – ${(projektInfo.alleAnlaeg.isNotEmpty ? projektInfo.alleAnlaeg.first.anlaegsNavn : "Ukendt anlæg")}',
                                body: '''
Hej $valgtServiceleder,
 
Jeg sender hermed kunde- og teknisk rapport for ${projektInfo.kundeNavn}, anlæg ${(projektInfo.alleAnlaeg.isNotEmpty ? projektInfo.alleAnlaeg.first.anlaegsNavn : "Ukendt anlæg")}.
 
Den tekniske rapport er kun til intern brug.
Kunderapporten kan anvendes som grundlag for den videre dialog med kunden.
 
═══════════════════════════════════════════════
📌 HUSK: Gem rapporterne lokalt
═══════════════════════════════════════════════
 
⚠️  Rapporterne slettes automatisk efter 30 dage
📅 Udløbsdato: ${datoFormat.format(udloebsDato)}
💾 Gem derfor PDF-filerne på din computer nu
 
═══════════════════════════════════════════════
 
Ved spørgsmål er du velkommen til at kontakte mig.
 
Venlig hilsen
${projektInfo.teknikerNavn}
Bravida – VentOptima
Tlf: ${projektInfo.telefon}
''',
                                kundePdfBytes: kundePdfFil,
                                tekniskPdfBytes: tekniskPdfFil,
                                projektInfo: projektInfo,
                              );

                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// 🔍 Simpelt netværkstjek (pinger Google DNS)
Future<bool> _hasNetworkConnection() async {
  try {
    final result = await InternetAddress.lookup('8.8.8.8');
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// 🧱 Offline dialog (ingen internet) - kun for Android
void _visOfflineDialog(
    BuildContext context,
    String to,
    String toName,
    dynamic projektInfo,
    dynamic kundePdfFil,
    dynamic tekniskPdfFil,
    ) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Ingen internetforbindelse'),
        content: const Text(
          'Der er ingen internetforbindelse lige nu.\n\n'
              'Mailen kunne ikke sendes. Du kan gemme den til senere afsendelse, når du igen har forbindelse.',
        ),
        actions: [
          TextButton(
            child: const Text('Annuller'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34E0A1)),
            child: const Text('Gem til senere'),
            onPressed: () async {
              await _gemMailTilSenere(
                  to, toName, projektInfo, kundePdfFil, tekniskPdfFil);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF34E0A1),
                  content: Text('Mail gemt til senere afsendelse ✅'),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

/// 💾 Gem mailen lokalt til senere afsendelse
Future<void> _gemMailTilSenere(
    String to,
    String toName,
    dynamic projektInfo,
    dynamic kundePdfFil,
    dynamic tekniskPdfFil,
    ) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/pending_mails');
  if (!folder.existsSync()) folder.createSync();

  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}_${projektInfo.kundeNavn}.json';
  final file = File('${folder.path}/$fileName');

  final data = {
    'to': to,
    'toName': toName,
    'kundeNavn': projektInfo.kundeNavn,
    'teknikerNavn': projektInfo.teknikerNavn,
    'anlaeg': projektInfo.alleAnlaeg.isNotEmpty
        ? projektInfo.alleAnlaeg.first.anlaegsNavn
        : 'Ukendt anlæg',
    'kundePdf': base64Encode(List<int>.from(kundePdfFil)),
    'tekniskPdf': base64Encode(List<int>.from(tekniskPdfFil)),
  };

  await file.writeAsString(jsonEncode(data));
}

/// 📧 Send mail - Platform-aware (Android: SMTP, Windows: Supabase)
Future<void> sendVentoptimaMail({
  required BuildContext context,
  required String to,
  required String toName,
  required String subject,
  required String body,
  required dynamic kundePdfBytes,
  required dynamic tekniskPdfBytes,
  required dynamic projektInfo,
}) async {
  // 🔍 Platform check
  if (Platform.isWindows) {
    // ✅ WINDOWS: Upload til Supabase og send via Edge Function
    await _sendViaSupabase(
      context: context,
      to: to,
      toName: toName,
      subject: subject,
      body: body,
      kundePdfBytes: kundePdfBytes,
      tekniskPdfBytes: tekniskPdfBytes,
      projektInfo: projektInfo,
    );
    return;
  }

  // ✅ ANDROID/IOS: Brug SMTP
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Afsender rapport...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006390),
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34E0A1)),
                backgroundColor: Color(0xFFE0F8EF),
                minHeight: 6,
              ),
              SizedBox(height: 16),
              Text(
                'Vent mens mailen sendes til servicelederen',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );

  File? tempKundeFil;
  File? tempTekniskFil;
  File? tempVentoptimaFil;

  try {
    // 🔐 SMTP indstillinger for Gmail
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      port: 587,
      username: 'ventoptimaenergy@gmail.com',
      password: 'szzc ygio dhuf gdte',
      ssl: false,
      allowInsecure: false,
    );

    // Hent afsenderinfo
    final bruger = await AppSikkerhed.hentBrugerInfo();
    final senderName = bruger['navn'] ?? projektInfo.teknikerNavn;

    // 📁 Gem PDF'er og .ventoptima fil som midlertidige filer
    final tempDir = await getTemporaryDirectory();

    tempKundeFil = File('${tempDir.path}/Kunde_Rapport.pdf');
    await tempKundeFil.writeAsBytes(List<int>.from(kundePdfBytes));

    tempTekniskFil = File('${tempDir.path}/Intern_Rapport.pdf');
    await tempTekniskFil.writeAsBytes(List<int>.from(tekniskPdfBytes));

    // 🆕 Gem .ventoptima projektfil midlertidigt
    tempVentoptimaFil = await gemVentoptimaFil(projektInfo);

    // Opret email besked med FileAttachment
    final message = Message()
      ..from = Address('ventoptimaenergy@gmail.com', senderName)
      ..recipients.add(Address(to, toName))
      ..subject = subject
      ..text = '''
$body
 
═══════════════════════════════════════════════
🔄 GENÅBN PROJEKT I VENTOPTIMA APPEN
═══════════════════════════════════════════════
 
Projektfilen er vedhæftet denne mail (.ventoptima).
 
Sådan gør du:
1. Gem .ventoptima filen på din enhed
2. Åbn VentOptima appen
3. Tryk "Åbn eksisterende projekt"
4. Vælg den gemte .ventoptima fil
 
═══════════════════════════════════════════════
'''
      ..attachments = [
        FileAttachment(tempKundeFil, contentType: 'application/pdf'),
        FileAttachment(tempTekniskFil, contentType: 'application/pdf'),
        FileAttachment(tempVentoptimaFil), // 🆕 .ventoptima fil
      ];

    // Send email
    final sendReport = await send(message, smtpServer);

    debugPrint('✅ Email sendt til $to');
    debugPrint('📧 Send report: ${sendReport.toString()}');

    Navigator.pop(context); // Luk loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF34E0A1),
        content: Text('Mail sendt til serviceleder ✅'),
        duration: Duration(seconds: 3),
      ),
    );

    // 🔹 Tjek for ventende mails og send dem automatisk
    await tjekOgSendVentendeMails(context);
  } on MailerException catch (e) {
    Navigator.pop(context);
    debugPrint('❌ Email fejl: ${e.toString()}');

    String fejlBesked = 'Kunne ikke sende mail';
    if (e.problems.isNotEmpty) {
      fejlBesked = e.problems.first.msg;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade400,
        content: Text(fejlBesked),
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    debugPrint('❌ Uventet fejl: ${e.toString()}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade400,
        content: Text('Kunne ikke sende mail: $e'),
        duration: const Duration(seconds: 4),
      ),
    );
  } finally {
    // 🗑️ Ryd op - slet midlertidige filer
    try {
      if (tempKundeFil != null && await tempKundeFil.exists()) {
        await tempKundeFil.delete();
      }
      if (tempTekniskFil != null && await tempTekniskFil.exists()) {
        await tempTekniskFil.delete();
      }
      if (tempVentoptimaFil != null && await tempVentoptimaFil.exists()) {
        await tempVentoptimaFil.delete(); // 🆕
      }
    } catch (e) {
      debugPrint('⚠️ Kunne ikke slette midlertidig fil: $e');
    }
  }
}

/// 🪟 WINDOWS: Upload til Supabase og send via Edge Function
Future<void> _sendViaSupabase({
  required BuildContext context,
  required String to,
  required String toName,
  required String subject,
  required String body,
  required dynamic kundePdfBytes,
  required dynamic tekniskPdfBytes,
  required dynamic projektInfo,
}) async {
  // Vis loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sender rapport...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006390),
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34E0A1)),
                backgroundColor: Color(0xFFE0F8EF),
                minHeight: 6,
              ),
              SizedBox(height: 16),
              Text(
                'Uploader rapporter og sender email...',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    final supabase = Supabase.instance.client;

    // Generer unikke filnavne
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final kundeNavn = projektInfo.kundeNavn.replaceAll(RegExp(r'[^\w\s-]'), '');
    final kundePath = '$timestamp/${kundeNavn}_kunde.pdf';
    final tekniskPath = '$timestamp/${kundeNavn}_teknisk.pdf';
    final ventoptimaPath = '$timestamp/${kundeNavn}.ventoptima';

    debugPrint('📤 Uploader PDF-filer til Supabase...');

    // Upload kunde-PDF
    await supabase.storage
        .from('ventoptima-rapporter')
        .uploadBinary(kundePath, Uint8List.fromList(List<int>.from(kundePdfBytes)));

    // Upload teknisk-PDF
    await supabase.storage
        .from('ventoptima-rapporter')
        .uploadBinary(tekniskPath, Uint8List.fromList(List<int>.from(tekniskPdfBytes)));

    // Upload .ventoptima projektfil
    final ventoptimaFil = await gemVentoptimaFil(projektInfo);
    final ventoptimaBytes = await ventoptimaFil.readAsBytes();
    await supabase.storage
        .from('ventoptima-rapporter')
        .uploadBinary(ventoptimaPath, ventoptimaBytes);
    await ventoptimaFil.delete();

    debugPrint('✅ PDF-filer og projektfil uploadet til Supabase');
    debugPrint('📧 Kalder Edge Function...');

    // Kald Edge Function
    final response = await supabase.functions.invoke(
      'send-ventoptima-email',
      body: {
        'to': to,
        'toName': toName,
        'subject': subject,
        'body': body,
        'kundePdfPath': kundePath,
        'tekniskPdfPath': tekniskPath,
        'ventoptimaPath': ventoptimaPath,
      },
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.status != 200) {
      throw Exception('Edge Function fejl: ${response.data}');
    }

    debugPrint('✅ Email sendt via Edge Function til $to');

    Navigator.pop(context); // Luk loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF34E0A1),
        content: Text('Rapport sendt til serviceleder ✅'),
        duration: Duration(seconds: 3),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    debugPrint('❌ Fejl ved Supabase afsendelse: $e');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text('Kunne ikke sende rapport: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

/// 📨 Automatisk tjek og afsendelse af mails gemt offline (kun Android)
Future<void> tjekOgSendVentendeMails(BuildContext context) async {
  // Kun relevant for Android/iOS
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final connectivityResult = await Connectivity().checkConnectivity();
  final hasInternet = connectivityResult != ConnectivityResult.none &&
      await _hasNetworkConnection();

  if (!hasInternet) return; // stadig offline, vent til næste gang

  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/pending_mails');
  if (!folder.existsSync()) return;

  final files =
  folder.listSync().where((f) => f.path.endsWith('.json')).toList();

  if (files.isEmpty) return;

  // SMTP setup
  final smtpServer = SmtpServer(
    'smtp.gmail.com',
    port: 587,
    username: 'ventoptimaenergy@gmail.com',
    password: 'szzc ygio dhuf gdte',
    ssl: false,
    allowInsecure: false,
  );

  for (final file in files) {
    File? tempKundeFil;
    File? tempTekniskFil;

    try {
      final content = await File(file.path).readAsString();
      final data = jsonDecode(content);

      final to = data['to'];
      final toName = data['toName'];
      final kundeNavn = data['kundeNavn'];
      final teknikerNavn = data['teknikerNavn'];
      final anlaeg = data['anlaeg'];
      final kundePdf = base64Decode(data['kundePdf']);
      final tekniskPdf = base64Decode(data['tekniskPdf']);

      // 📁 Gem PDF'er som midlertidige filer
      final tempDir = await getTemporaryDirectory();

      tempKundeFil = File('${tempDir.path}/Kunde_Rapport_pending.pdf');
      await tempKundeFil.writeAsBytes(kundePdf);

      tempTekniskFil = File('${tempDir.path}/Intern_Rapport_pending.pdf');
      await tempTekniskFil.writeAsBytes(tekniskPdf);

      // 📅 Beregn udløbsdato (30 dage)
      final udloebsDato = DateTime.now().add(const Duration(days: 30));
      final datoFormat = DateFormat('d. MMMM yyyy', 'da_DK');

      final message = Message()
        ..from = Address('ventoptimaenergy@gmail.com', 'VentOptima')
        ..recipients.add(Address(to, toName))
        ..subject = 'VentOptima rapport – $kundeNavn – $anlaeg'
        ..text = '''
Hej $toName,
 
Hermed automatisk afsendt rapport for $kundeNavn, anlæg: $anlaeg.
 
Denne rapport blev gemt tidligere pga. manglende internetforbindelse og er nu sendt automatisk.
 
═══════════════════════════════════════════════
📌 HUSK: Gem rapporterne lokalt
═══════════════════════════════════════════════
 
⚠️  Rapporterne slettes automatisk efter 30 dage
📅 Udløbsdato: ${datoFormat.format(udloebsDato)}
💾 Gem derfor PDF-filerne på din computer nu
 
═══════════════════════════════════════════════
 
Venlig hilsen  
$teknikerNavn
Bravida VentOptima
'''
        ..attachments = [
          FileAttachment(tempKundeFil, contentType: 'application/pdf'),
          FileAttachment(tempTekniskFil, contentType: 'application/pdf'),
        ];

      await send(message, smtpServer);

      await File(file.path).delete();
      debugPrint('📤 Offline mail sendt: $kundeNavn');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF34E0A1),
          content: Text('Mail for $kundeNavn sendt automatisk ✅'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 🗑️ Ryd op efter succesfuld afsendelse
      try {
        if (tempKundeFil != null && await tempKundeFil.exists()) {
          await tempKundeFil.delete();
        }
        if (tempTekniskFil != null && await tempTekniskFil.exists()) {
          await tempTekniskFil.delete();
        }
      } catch (e) {
        debugPrint('⚠️ Kunne ikke slette midlertidig fil: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Fejl ved automatisk mailafsendelse: $e');

      // 🗑️ Ryd op selv ved fejl
      try {
        if (tempKundeFil != null && await tempKundeFil.exists()) {
          await tempKundeFil.delete();
        }
        if (tempTekniskFil != null && await tempTekniskFil.exists()) {
          await tempTekniskFil.delete();
        }
      } catch (e) {
        debugPrint('⚠️ Kunne ikke slette midlertidig fil: $e');
      }
    }
  }
}

/// Formater dato til filnavn
String _formatDato() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
}




