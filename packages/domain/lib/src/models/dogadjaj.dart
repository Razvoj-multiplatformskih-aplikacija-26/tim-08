import '../states/stanje_dogadjaja.dart';
import 'id_types.dart';

class Dogadjaj {
  final DogadjajId id;
  final KorisnikId hostId;

  final String naziv;
  final StanjeDogadjaja stanje;
  final int kapacitet;
  final double hostReputacija;
  final String opis;

  const Dogadjaj({
    required this.id,
    required this.hostId,
    required this.naziv,
    required this.stanje,
    required this.kapacitet,
    required this.hostReputacija,
    required this.opis,
  });

  Dogadjaj copyWith({
    DogadjajId? id,
    KorisnikId? hostId,
    String? naziv,
    StanjeDogadjaja? stanje,
    int? kapacitet,
    double? hostReputacija,
    String? opis,
  }) {
    return Dogadjaj(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      naziv: naziv ?? this.naziv,
      stanje: stanje ?? this.stanje,
      kapacitet: kapacitet ?? this.kapacitet,
      hostReputacija: hostReputacija ?? this.hostReputacija,
      opis: opis ?? this.opis,
    );
  }
}
