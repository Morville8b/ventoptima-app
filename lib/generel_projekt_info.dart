// lib/generel_projekt_info.dart
class GenerelProjektInfo {
  final String kundeNavn;
  final String adresse;
  final String postnrBy;
  final String att;
  final String teknikerNavn;
  final String telefon;
  final String email;
  final int antalAnlaeg;
  final double elPris;
  final double varmePris;
  final List<double> driftTimerPrUge;
  final int ugerPerAar;
  final String driftperiode;

  GenerelProjektInfo({
    required this.kundeNavn,
    required this.adresse,
    required this.postnrBy,
    required this.att,
    required this.teknikerNavn,
    required this.telefon,
    required this.email,
    required this.antalAnlaeg,
    required this.elPris,
    required this.varmePris,
    required this.driftTimerPrUge,
    required this.ugerPerAar,
    required this.driftperiode,
  });
}