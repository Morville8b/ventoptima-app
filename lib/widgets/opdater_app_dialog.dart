import 'dart:io' show Platform, exit;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpdaterAppDialog extends StatefulWidget {
  const OpdaterAppDialog({Key? key}) : super(key: key);

  @override
  State<OpdaterAppDialog> createState() => _OpdaterAppDialogState();
}

class _OpdaterAppDialogState extends State<OpdaterAppDialog> {
  bool _downloader = false;
  double _downloadProgress = 0.0;

  Future<void> _opdaterApp() async {
    if (Platform.isAndroid) {
      // Android: Åbn Google Play
      final url = Uri.parse(
        'https://play.google.com/store/apps/details?id=dk.ventoptima.app',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isWindows) {
      // Windows: Download og installer MSIX
      await _downloadOgInstallerWindows();
    }
  }

  Future<void> _downloadOgInstallerWindows() async {
    setState(() {
      _downloader = true;
      _downloadProgress = 0.0;
    });

    try {
      // Hent download URL fra Supabase
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_version')
          .select('windows_download_url')
          .eq('id', 1)
          .single();

      final downloadUrl = response['windows_download_url'] as String?;

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception('Download URL ikke fundet');
      }

      // Gem i Downloads mappen
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Kunne ikke finde Downloads mappe');
      }

      final filePath = '${downloadsDir.path}\\VentOptima-Update.msix';

      // Download filen med progress
      await Dio().download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Åbn filen (Windows vil spørge om installation)
      final fileUri = Uri.file(filePath);
      await launchUrl(fileUri);

      // Luk appen så brugeren kan installere
      exit(0);
    } catch (e) {
      setState(() {
        _downloader = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Kan ikke lukkes
      child: AlertDialog(
        title: const Text(
          'Opdatering tilgængelig',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: _downloader
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Downloader opdatering...'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF34E0A1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        )
            : const Text(
          'Der er en ny version af VentOptima tilgængelig. '
              'Opdater nu for at få de nyeste funktioner og fejlrettelser.',
        ),
        actions: _downloader
            ? []
            : [
          ElevatedButton.icon(
            icon: const Icon(Icons.system_update),
            label: Text(
              Platform.isWindows ? 'Download opdatering' : 'Opdater nu',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34E0A1),
              foregroundColor: Colors.white,
            ),
            onPressed: _opdaterApp,
          ),
        ],
      ),
    );
  }
}