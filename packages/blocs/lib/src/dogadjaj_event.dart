import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

abstract class DogadjajEvent extends Equatable {
  const DogadjajEvent();

  @override
  List<Object?> get props => [];
}

class UcitajDogadjajeEvent extends DogadjajEvent {
  const UcitajDogadjajeEvent();
}

class PromeniStanjeEvent extends DogadjajEvent {
  final DogadjajId id;
  final StanjeDogadjaja novoStanje;

  const PromeniStanjeEvent({
    required this.id,
    required this.novoStanje,
  });

  @override
  List<Object?> get props => [id, novoStanje];
}

class PromeniKapacitetEvent extends DogadjajEvent {
  final DogadjajId id;
  final int noviKapacitet;

  const PromeniKapacitetEvent({
    required this.id,
    required this.noviKapacitet,
  });

  @override
  List<Object?> get props => [id, noviKapacitet];
}

class KreirajDogadjajEvent extends DogadjajEvent {
  final Dogadjaj dogadjaj;

  const KreirajDogadjajEvent({
    required this.dogadjaj,
  });

  @override
  List<Object?> get props => [dogadjaj];
}

class PrijaviSeNaDogadjajEvent extends DogadjajEvent {
  final DogadjajId dogadjajId;

  const PrijaviSeNaDogadjajEvent({
    required this.dogadjajId,
  });

  @override
  List<Object?> get props => [dogadjajId];
}

class OtkaziPrijavuEvent extends DogadjajEvent {
  final PrijavaId prijavaId;

  const OtkaziPrijavuEvent({
    required this.prijavaId,
  });

  @override
  List<Object?> get props => [prijavaId];
}

class DodajRecenzijuEvent extends DogadjajEvent {
  final DogadjajId dogadjajId;
  final int ocena;
  final String komentar;

  const DodajRecenzijuEvent({
    required this.dogadjajId,
    required this.ocena,
    required this.komentar,
  });

  @override
  List<Object?> get props => [
    dogadjajId,
    ocena,
    komentar,
  ];
}
