import '../models/id_types.dart';
import '../models/recenzija.dart';

abstract interface class RecenzijaRepository {

  Future<List<Recenzija>> getRecenzije();


  Future<Recenzija> kreirajRecenziju({
    required DogadjajId dogadjajId,
    required int ocena,
    required String komentar,
  });
}