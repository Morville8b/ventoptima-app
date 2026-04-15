import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Generel funktion til logning af hændelser i Supabase
  static Future<void> logAftryk({
    required String haendelseType,             // fx 'App åbnet'
    String? afsenderNavn,
    String? afdeling,
    String? afsenderEmail,
    String? modtagerEmail,
    String? rapportId,
    String? status,                            // fx 'OK'
  }) async {
    try {
      await _client.from('aftryk').insert({
        'dato': DateTime.now().toIso8601String(),
        'afsender_navn': afsenderNavn ?? 'Ukendt',
        'afdeling': afdeling ?? 'Ukendt',
        'afsender_email': afsenderEmail ?? 'ukendt@bravida.dk',
        'modtager_email': modtagerEmail ?? '',
        'haendelse_type': haendelseType,
        'rapport_id': rapportId ?? '',
        'status': status ?? 'OK',
      });
      print('✅ Logget: $haendelseType');
    } catch (e) {
      print('⚠️ Fejl ved logning til Supabase: $e');
    }
  }

  // 🔹 Foruddefinerede log-typer
  static Future<void> logAppAabnet(String navn, String afdeling, String email) =>
      logAftryk(
        haendelseType: 'App åbnet',
        afsenderNavn: navn,
        afdeling: afdeling,
        afsenderEmail: email,
      );

  static Future<void> logRapportGenereret(
      String navn, String afdeling, String email, String rapportId) =>
      logAftryk(
        haendelseType: 'Rapport genereret',
        afsenderNavn: navn,
        afdeling: afdeling,
        afsenderEmail: email,
        rapportId: rapportId,
      );

  static Future<void> logRapportSendt(
      String navn, String afdeling, String email, String modtager, String rapportId) =>
      logAftryk(
        haendelseType: 'Rapport sendt',
        afsenderNavn: navn,
        afdeling: afdeling,
        afsenderEmail: email,
        modtagerEmail: modtager,
        rapportId: rapportId,
      );

  static Future<void> logRapportAabnetAfModtager(
      String modtager, String rapportId) =>
      logAftryk(
        haendelseType: 'Rapport åbnet af modtager',
        afsenderNavn: 'Serviceleder',
        afsenderEmail: modtager,
        rapportId: rapportId,
      );

  static Future<void> logRapportPrintet(
      String modtager, String rapportId) =>
      logAftryk(
        haendelseType: 'Rapport printet',
        afsenderNavn: 'Serviceleder',
        afsenderEmail: modtager,
        rapportId: rapportId,
      );
}