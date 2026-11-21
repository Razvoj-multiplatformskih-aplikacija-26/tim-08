import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

abstract class DogadjajState extends Equatable {
  const DogadjajState();

  @override
  List<Object?> get props => [];
}

class DogadjajiLoading extends DogadjajState {
  const DogadjajiLoading();
}

class DogadjajiError extends DogadjajState {
  final String poruka;
  final bool nakonIzmene;
  const DogadjajiError(this.poruka, {this.nakonIzmene = false});

  @override
  List<Object?> get props => [poruka, nakonIzmene];
}

class DogadjajiEmpty extends DogadjajState {
  const DogadjajiEmpty();
}

class DogadjajiLoaded extends DogadjajState {
  final List<Dogadjaj> dogadjaji;
  final List<Prijava> mojePrijave;
  final List<Recenzija> recenzije;

  const DogadjajiLoaded(
    this.dogadjaji, {
    this.mojePrijave = const [],
    this.recenzije = const [],
  });

  @override
  List<Object?> get props => [
        dogadjaji,
        mojePrijave,
        recenzije,
      ];
}
