import '../models/dogadjaj.dart';
import '../models/id_types.dart';
import '../states/stanje_dogadjaja.dart';

abstract interface class DogadjajRepository {
  Future<List<Dogadjaj>> getDogadjaji();
  Future<Dogadjaj> promeniStanje(DogadjajId id, StanjeDogadjaja novoStanje);
  Future<Dogadjaj> kreirajDogadjaj(Dogadjaj dogadjaj);
}