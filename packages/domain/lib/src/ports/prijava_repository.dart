import '../models/id_types.dart';
import '../models/prijava.dart';

abstract interface class PrijavaRepository {
  Future<List<Prijava>> getMojePrijave();
  Future<int> getBrojAktivnihPrijava(DogadjajId dogadjajId);
  Future<Prijava> kreirajPrijavu(DogadjajId dogadjajId);
  Future<void> otkaziPrijavu(PrijavaId prijavaId);
}