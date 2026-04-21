import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class VersionChecker {
  static const storage = FlutterSecureStorage(iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock));
  static final supabase = Supabase.instance.client;

  /// Tjek om der er en ny version tilgængelig
  static Future<bool> erNyVersionTilgaengelig() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      final response = await supabase
          .from('app_version')
          .select('version_code')
          .eq('id', 1)
          .single();

      final latestVersionCode = response['version_code'] as int;

      debugPrint('📱 Nuværende version: $currentVersionCode');
      debugPrint('☁️ Seneste version: $latestVersionCode');

      return latestVersionCode > currentVersionCode;
    } catch (e) {
      debugPrint('⚠️ Fejl ved version-tjek: $e');
      return false;
    }
  }

  /// Tjek om vi skal tjekke version (én gang om dagen)
  static Future<bool> skalTjekkeVersion() async {
    try {
      final sidsteTjek = await storage.read(key: 'sidste_version_tjek');

      if (sidsteTjek == null) {
        return true;
      }

      final sidsteTjekDato = DateTime.parse(sidsteTjek);
      final dageSiden = DateTime.now().difference(sidsteTjekDato).inHours;

      return dageSiden >= 24;
    } catch (e) {
      debugPrint('⚠️ Fejl ved version-tjek storage: $e');
      return true;
    }
  }

  /// Opdater sidste tjek-tidspunkt
  static Future<void> opdaterSidsteTjek() async {
    try {
      await storage.write(
        key: 'sidste_version_tjek',
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('⚠️ Fejl ved opdatering af tjek-tidspunkt: $e');
    }
  }
}