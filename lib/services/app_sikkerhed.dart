import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class AppSikkerhed {
  static final DateTime UDLOEB = DateTime(2026, 6, 30);
  static const int DAGE_MELLEM_VALIDERING = 7;

  static const storage = FlutterSecureStorage(iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock));
  static final supabase = Supabase.instance.client;

  static bool erUdloebet() {
    return DateTime.now().isAfter(UDLOEB);
  }

  // ═══════════════════════════════════════════════════════════
  // SUPABASE AUTH MED OFFLINE SUPPORT
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fuldeNavn,
    required String medarbejderNr,
    required String telefon,
    required String afdeling,
  }) async {
    try {
      if (!email.endsWith('@bravida.dk')) {
        return {
          'success': false,
          'message': 'Kun Bravida e-mails (@bravida.dk) er tilladt'
        };
      }

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fuldeNavn,
          'medarbejder_nr': medarbejderNr,
          'telefon': telefon,
          'afdeling': afdeling,
        },
      );

      if (response.user != null) {
        try {
          await storage.write(key: 'bruger_navn', value: fuldeNavn);
          await storage.write(key: 'medarbejder_nr', value: medarbejderNr);
          await storage.write(key: 'bruger_email', value: email);
          await storage.write(key: 'bruger_telefon', value: telefon);
          await storage.write(key: 'bruger_afdeling', value: afdeling);
          await _opdaterSidsteValidering();
        } catch (e) {
          debugPrint('Storage write fejlede: $e');
        }

        return {
          'success': true,
          'message': 'Tjek din email for at bekræfte din konto'
        };
      } else {
        return {
          'success': false,
          'message': 'Kunne ikke oprette bruger'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Fejl: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData = response.user!.userMetadata;
        try {
          await storage.write(key: 'bruger_navn', value: userData?['full_name']);
          await storage.write(key: 'medarbejder_nr', value: userData?['medarbejder_nr']);
          await storage.write(key: 'bruger_email', value: email);
          await storage.write(key: 'bruger_telefon', value: userData?['telefon']);
          await storage.write(key: 'bruger_afdeling', value: userData?['afdeling']);
          await _opdaterSidsteValidering();
        } catch (e) {
          debugPrint('Storage write fejlede: $e');
        }

        return {'success': true, 'message': 'Login succesfuldt'};
      } else {
        return {'success': false, 'message': 'Login fejlede'};
      }
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        return {
          'success': false,
          'message': 'Du skal bekræfte din email først. Tjek din indbakke.'
        };
      }
      return {
        'success': false,
        'message': 'Forkert email eller password'
      };
    } catch (e) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        return {
          'success': true,
          'message': 'Login succesfuldt (offline mode)',
          'offline': true
        };
      }

      return {
        'success': false,
        'message': 'Ingen internetforbindelse. Log ind online første gang.'
      };
    }
  }

  static Future<bool> erLoggetInd() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    if (user.emailConfirmedAt == null) {
      return false;
    }

    try {
      final session = supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        try {
          await _opdaterSidsteValidering();
        } catch (e) {
          debugPrint('Opdater validering fejlede: $e');
        }
        return true;
      }
    } catch (e) {
      final sidsteValidering = await _hentSidsteValidering();
      if (sidsteValidering != null) {
        final dageSiden = DateTime.now().difference(sidsteValidering).inDays;
        if (dageSiden <= DAGE_MELLEM_VALIDERING) {
          return true;
        }
      }
    }

    return false;
  }

  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('SignOut fejlede: $e');
    }
    try {
      await storage.deleteAll();
    } catch (e) {
      debugPrint('Storage deleteAll fejlede: $e');
    }
  }

  static Future<bool> skalGenvalideres() async {
    final sidsteValidering = await _hentSidsteValidering();
    if (sidsteValidering == null) return true;

    final dageSiden = DateTime.now().difference(sidsteValidering).inDays;
    return dageSiden > DAGE_MELLEM_VALIDERING;
  }

  // ═══════════════════════════════════════════════════════════
  // BRUGER INFO
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, String?>> hentBrugerInfo() async {
    try {
      await supabase.auth.refreshSession();
    } catch (e) {
      debugPrint('Session refresh fejlede (muligvis offline): $e');
    }

    final user = supabase.auth.currentUser;

    if (user != null && user.userMetadata != null) {
      try {
        await storage.write(key: 'bruger_navn', value: user.userMetadata?['full_name']);
        await storage.write(key: 'bruger_email', value: user.email);
        await storage.write(key: 'bruger_telefon', value: user.userMetadata?['telefon']);
        await storage.write(key: 'bruger_afdeling', value: user.userMetadata?['afdeling']);
      } catch (e) {
        debugPrint('Storage write fejlede: $e');
      }

      return {
        'navn': user.userMetadata?['full_name'],
        'medarbejderNr': user.userMetadata?['medarbejder_nr'],
        'email': user.email,
        'telefon': user.userMetadata?['telefon'],
        'afdeling': user.userMetadata?['afdeling'],
      };
    }

    try {
      return {
        'navn': await storage.read(key: 'bruger_navn'),
        'medarbejderNr': await storage.read(key: 'medarbejder_nr'),
        'email': await storage.read(key: 'bruger_email'),
        'telefon': await storage.read(key: 'bruger_telefon'),
        'afdeling': await storage.read(key: 'bruger_afdeling'),
      };
    } catch (e) {
      debugPrint('Storage read fejlede: $e');
      return {
        'navn': null,
        'medarbejderNr': null,
        'email': null,
        'telefon': null,
        'afdeling': null,
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WATERMARK
  // ═══════════════════════════════════════════════════════════

  static Future<String> hentEnhedInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return 'Android: ${info.model} (${info.id.substring(0, 8)})';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return 'iOS: ${info.model} (${info.identifierForVendor?.substring(0, 8) ?? "N/A"})';
    }
    return 'Ukendt enhed';
  }

  static Future<String> hentWatermarkInfo() async {
    final bruger = await hentBrugerInfo();
    final dato = DateTime.now();
    return 'Genereret af: ${bruger['navn'] ?? 'Ukendt'} | ${dato.day}/${dato.month}/${dato.year}';
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPER FUNKTIONER
  // ═══════════════════════════════════════════════════════════

  static Future<void> _opdaterSidsteValidering() async {
    try {
      await storage.write(
        key: 'sidste_validering',
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Opdater validering fejlede: $e');
    }
  }

  static Future<DateTime?> _hentSidsteValidering() async {
    try {
      final dateStr = await storage.read(key: 'sidste_validering');
      if (dateStr != null) {
        return DateTime.parse(dateStr);
      }
      return null;
    } catch (e) {
      debugPrint('Hent validering fejlede: $e');
      return null;
    }
  }
}