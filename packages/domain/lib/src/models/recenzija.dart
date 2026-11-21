import 'id_types.dart';

class Recenzija {
  final RecenzijaId id;
  final DogadjajId dogadjajId;
  final KorisnikId autorId;
  final int ocena;
  final String komentar;

  const Recenzija({
    required this.id,
    required this.dogadjajId,
    required this.autorId,
    required this.ocena,
    required this.komentar,
  });
}