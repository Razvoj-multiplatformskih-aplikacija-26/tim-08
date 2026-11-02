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

  const PromeniStanjeEvent({required this.id, required this.novoStanje});

  @override
  List<Object?> get props => [id, novoStanje];
}

class SimulirajGreskuEvent extends DogadjajEvent {
  const SimulirajGreskuEvent();
}