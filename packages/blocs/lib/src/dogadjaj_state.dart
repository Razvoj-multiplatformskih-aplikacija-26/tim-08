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
  const DogadjajiError(this.poruka);

  @override
  List<Object?> get props => [poruka];
}

class DogadjajiEmpty extends DogadjajState {
  const DogadjajiEmpty();
}

class DogadjajiLoaded extends DogadjajState {
  final List<Dogadjaj> dogadjaji;
  const DogadjajiLoaded(this.dogadjaji);

  @override
  List<Object?> get props => [dogadjaji];
}