import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'dogadjaj_event.dart';
import 'dogadjaj_state.dart';

class DogadjajBloc extends Bloc<DogadjajEvent, DogadjajState> {
  final DogadjajRepository repository;
  bool _sledeciZahtevPraviGresku = false;

  DogadjajBloc({required this.repository}) : super(const DogadjajiLoading()) {
    on<UcitajDogadjajeEvent>(_onUcitajDogadjaje);
    on<PromeniStanjeEvent>(_onPromeniStanje);
    on<SimulirajGreskuEvent>(_onSimulirajGresku);
  }

  void _onSimulirajGresku(SimulirajGreskuEvent event, Emitter<DogadjajState> emit) {
    _sledeciZahtevPraviGresku = true;
  }

  Future<void> _onUcitajDogadjaje(UcitajDogadjajeEvent event, Emitter<DogadjajState> emit) async {
    emit(const DogadjajiLoading());
    try {
      //Simulacija kasnjenja
      await Future.delayed(const Duration(milliseconds: 800));

      if (_sledeciZahtevPraviGresku) {
        _sledeciZahtevPraviGresku = false;
        throw Exception('Namerna greška zahteva!');
      }

      final lista = await repository.getDogadjaji();
      if (lista.isEmpty) {
        emit(const DogadjajiEmpty());
      } else {
        emit(DogadjajiLoaded(lista));
      }
    } catch (e) {
      emit(DogadjajiError(e.toString()));
    }
  }

  Future<void> _onPromeniStanje(PromeniStanjeEvent event, Emitter<DogadjajState> emit) async {
    try {
      await repository.promeniStanje(event.id, event.novoStanje);
      // Ponovo učitaj podatke nakon promene
      add(const UcitajDogadjajeEvent());
    } catch (e) {
      emit(DogadjajiError(e.toString()));
    }
  }
}