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
    on<PromeniKapacitetEvent>(_onPromeniKapacitet);
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

  Future<void> _onPromeniStanje(
      PromeniStanjeEvent event,
      Emitter<DogadjajState> emit,
      ) async {
    final trenutnoStanje = state;

    if (trenutnoStanje is! DogadjajiLoaded) {
      return;
    }

    Dogadjaj? dogadjaj;

    for (final d in trenutnoStanje.dogadjaji) {
      if (d.id == event.id) {
        dogadjaj = d;
        break;
      }
    }

    if (dogadjaj == null) {
      emit(const DogadjajiError('Događaj nije pronađen!'));
      return;
    }

    if (!jeDozvoljenPrelaz(dogadjaj.stanje, event.novoStanje)) {
      emit(const DogadjajiError('Tražena promena stanja nije dozvoljena!'));
      return;
    }

    try {
      await repository.promeniStanje(event.id, event.novoStanje);
      add(const UcitajDogadjajeEvent());
    } catch (e) {
      emit(DogadjajiError(e.toString()));
    }
  }

  Future<void> _onPromeniKapacitet(
      PromeniKapacitetEvent event,
      Emitter<DogadjajState> emit,
      ) async {
    final rezultat = proveriKapacitet(event.noviKapacitet);

    if (rezultat is GreskaNeodgovarajuciKapacitet) {
      emit(const DogadjajiError('Kapacitet mora biti veći od 0!'));
      return;
    }

    try {
      await repository.promeniKapacitet(
        event.id,
        event.noviKapacitet,
      );

      add(const UcitajDogadjajeEvent());
    } catch (e) {
      emit(DogadjajiError(e.toString()));
    }
  }
}