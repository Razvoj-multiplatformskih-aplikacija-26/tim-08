import 'id_types.dart';

enum StatusPrijave {
  aktivna,
  otkazana,
}

class Prijava {
  final PrijavaId id;
  final DogadjajId dogadjajId;
  final KorisnikId korisnikId;
  final StatusPrijave status;

  const Prijava({
    required this.id,
    required this.dogadjajId,
    required this.korisnikId,
    this.status = StatusPrijave.aktivna,
  });

  Prijava copyWith({
    StatusPrijave? status,
  }) {
    return Prijava(
      id: id,
      dogadjajId: dogadjajId,
      korisnikId: korisnikId,
      status: status ?? this.status,
    );
  }
}