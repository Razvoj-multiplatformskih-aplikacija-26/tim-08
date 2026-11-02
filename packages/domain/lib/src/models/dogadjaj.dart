import '../states/stanje_dogadjaja.dart';
import 'id_types.dart';

class Dogadjaj {
  final DogadjajId id;
  final String naziv;
  final StanjeDogadjaja stanje;
  final int kapacitet;
  final double hostReputacija;
  final String opis;

  const Dogadjaj({
    required this.id,
    required this.naziv,
    required this.stanje,
    required this.kapacitet,
    required this.hostReputacija,
    required this.opis,
  });

  Dogadjaj copyWith({
    DogadjajId? id,
    String? naziv,
    StanjeDogadjaja? stanje,
    int? kapacitet,
    double? hostReputacija,
    String? opis,
  }) {
    return Dogadjaj(
      id: id ?? this.id,
      naziv: naziv ?? this.naziv,
      stanje: stanje ?? this.stanje,
      kapacitet: kapacitet ?? this.kapacitet,
      hostReputacija: hostReputacija ?? this.hostReputacija,
      opis: opis ?? this.opis,
    );
  }
}