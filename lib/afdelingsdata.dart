// lib/afdelingsdata.dart

class AfdelingsData {
  final double timeloen;
  final double montagetimer;
  final double daekningProcent;
  final double materialePris;

  AfdelingsData({
    required this.timeloen,
    required this.montagetimer,
    required this.daekningProcent,
    required this.materialePris,
  });
}

final Map<String, AfdelingsData> afdelingsData = {
  'Aalborg': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Randers': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Aarhus': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Holstebro': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Horsens': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Kolding': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Esbjerg': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Odense': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
  'Brøndby': AfdelingsData(timeloen: 680.0, montagetimer: 7.5, daekningProcent: 30.0, materialePris: 2500.0),
};

// Funktioner til at hente data ud fra afdelingsnavn
double hentMontagetimer(String? afdeling) =>
    afdelingsData[afdeling]?.montagetimer ?? 0.0;

double hentTimeloen(String? afdeling) =>
    afdelingsData[afdeling]?.timeloen ?? 0.0;

double hentMaterialePris(String? afdeling) =>
    afdelingsData[afdeling]?.materialePris ?? 0.0;

double hentDaekningProcent(String? afdeling) =>
    afdelingsData[afdeling]?.daekningProcent ?? 0.0;