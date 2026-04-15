import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker {
  static const storage = FlutterSecureStorage();
  static final supabase = Supabase.instance.client;

  /// Tjek om der er en ny version tilgængelig
  static Future<bool> erNyVersionTilgaengelig() async {
    try {
      // Hent nuværende version fra appen
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      // Hent seneste version fra Supabase
      final response = await supabase
          .from('app_version')
          .select('version_code')
          .eq('id', 1)
          .single();

      final latestVersionCode = response['version_code'] as int;

      print('📱 Nuværende version: $currentVersionCode');
      print('☁️ Seneste version: $latestVersionCode');

      return latestVersionCode > currentVersionCode;
    } catch (e) {
      print('⚠️ Fejl ved version-tjek: $e');
      return false;
    }
  }

  /// Tjek om vi skal tjekke version (én gang om dagen)
  static Future<bool> skalTjekkeVersion() async {
    final sidsteTjek = await storage.read(key: 'sidste_version_tjek');

    if (sidsteTjek == null) {
      return true;
    }

    final sidsteTjekDato = DateTime.parse(sidsteTjek);
    final dageSiden = DateTime.now().difference(sidsteTjekDato).inHours;

    return dageSiden >= 24;
  }

  /// Opdater sidste tjek-tidspunkt
  static Future<void> opdaterSidsteTjek() async {
    await storage.write(
      key: 'sidste_version_tjek',
      value: DateTime.now().toIso8601String(),
    );
  }
}