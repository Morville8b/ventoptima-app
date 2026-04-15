import 'anlaegs_data.dart';

/// Enum til at styre driftstype korrekt
enum Driftstype { doegn, dag, nat }

/// Enum til at styre valg af varmegenvindingstype
enum VarmegenvindingType {
  krydsveksler,
  dobbeltKrydsveksler,
  roterendeVeksler,
  modstroemsVeksler,
  vaeskekobletVeksler,
  blandekammer,
}

class GenerelProjektInfo {
  final String kundeNavn;
  final String adresse;
  final String postnrBy;
  final String att;
  final String teknikerNavn;
  final String telefon;
  final String email;
  final String afdeling;
  final int antalAnlaeg;
  final double elPris;
  final double varmePris;
  final List<double> driftTimerPrUge;
  final int ugerPerAar;
  final Driftstype driftstype;
  final int index;
  final List<AnlaegsData> alleAnlaeg;

  /// ➕ Type af varmegenvinding
  final VarmegenvindingType varmegenvindingsType;

  /// ➕ Dato for rapport
  final DateTime rapportDato;

  /// ➕ Nye felter til Supabase-logning
  final String? montorNavn;   // Navnet på montøren
  final String? montorEmail;  // Montørens e-mail
  final String? rapportId;    // Unikt ID for rapport

  GenerelProjektInfo({
    required this.kundeNavn,
    required this.adresse,
    required this.postnrBy,
    required this.att,
    required this.teknikerNavn,
    required this.telefon,
    required this.email,
    required this.afdeling,
    required this.antalAnlaeg,
    required this.elPris,
    required this.varmePris,
    required this.driftTimerPrUge,
    required this.ugerPerAar,
    required this.driftstype,
    required this.index,
    required this.alleAnlaeg,
    required this.varmegenvindingsType,
    required this.rapportDato,
    this.montorNavn,
    this.montorEmail,
    this.rapportId,
  });

  /// Kopi med nyt index
  GenerelProjektInfo copyWithIndex(int newIndex) {
    return GenerelProjektInfo(
      kundeNavn: kundeNavn,
      adresse: adresse,
      postnrBy: postnrBy,
      att: att,
      teknikerNavn: teknikerNavn,
      telefon: telefon,
      email: email,
      afdeling: afdeling,
      antalAnlaeg: antalAnlaeg,
      elPris: elPris,
      varmePris: varmePris,
      driftTimerPrUge: driftTimerPrUge,
      ugerPerAar: ugerPerAar,
      driftstype: driftstype,
      index: newIndex,
      alleAnlaeg: alleAnlaeg,
      varmegenvindingsType: varmegenvindingsType,
      rapportDato: rapportDato,
      montorNavn: montorNavn,
      montorEmail: montorEmail,
      rapportId: rapportId,
    );
  }

  /// Generel copyWith metode
  GenerelProjektInfo copyWith({
    String? kundeNavn,
    String? adresse,
    String? postnrBy,
    String? att,
    String? teknikerNavn,
    String? telefon,
    String? email,
    String? afdeling,
    int? antalAnlaeg,
    double? elPris,
    double? varmePris,
    List<double>? driftTimerPrUge,
    int? ugerPerAar,
    Driftstype? driftstype,
    int? index,
    List<AnlaegsData>? alleAnlaeg,
    VarmegenvindingType? varmegenvindingsType,
    DateTime? rapportDato,
    String? montorNavn,
    String? montorEmail,
    String? rapportId,
  }) {
    return GenerelProjektInfo(
      kundeNavn: kundeNavn ?? this.kundeNavn,
      adresse: adresse ?? this.adresse,
      postnrBy: postnrBy ?? this.postnrBy,
      att: att ?? this.att,
      teknikerNavn: teknikerNavn ?? this.teknikerNavn,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      afdeling: afdeling ?? this.afdeling,
      antalAnlaeg: antalAnlaeg ?? this.antalAnlaeg,
      elPris: elPris ?? this.elPris,
      varmePris: varmePris ?? this.varmePris,
      driftTimerPrUge: driftTimerPrUge ?? this.driftTimerPrUge,
      ugerPerAar: ugerPerAar ?? this.ugerPerAar,
      driftstype: driftstype ?? this.driftstype,
      index: index ?? this.index,
      alleAnlaeg: alleAnlaeg ?? this.alleAnlaeg,
      varmegenvindingsType: varmegenvindingsType ?? this.varmegenvindingsType,
      rapportDato: rapportDato ?? this.rapportDato,
      montorNavn: montorNavn ?? this.montorNavn,
      montorEmail: montorEmail ?? this.montorEmail,
      rapportId: rapportId ?? this.rapportId,
    );
  }
}