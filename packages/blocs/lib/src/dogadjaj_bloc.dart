import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';

import 'dogadjaj_event.dart';
import 'dogadjaj_state.dart';

class DogadjajBloc extends Bloc<DogadjajEvent, DogadjajState> {
  final DogadjajRepository repository;
  final PrijavaRepository prijavaRepository;
  final RecenzijaRepository recenzijaRepository;

  Korisnik trenutniKorisnik;
  final Future<Korisnik> Function()? ucitajKorisnika;

  DogadjajBloc({
    required this.repository,
    required this.prijavaRepository,
    required this.recenzijaRepository,
    required this.trenutniKorisnik,
    this.ucitajKorisnika,
  }) : super(const DogadjajiLoading()) {
    on<UcitajDogadjajeEvent>(_onUcitajDogadjaje);
    on<PromeniStanjeEvent>(_onPromeniStanje);
    on<PromeniKapacitetEvent>(_onPromeniKapacitet);
    on<KreirajDogadjajEvent>(_onKreirajDogadjaj);
    on<PrijaviSeNaDogadjajEvent>(_onPrijaviSe);
    on<OtkaziPrijavuEvent>(_onOtkaziPrijavu);
    on<DodajRecenzijuEvent>(_onDodajRecenziju);
  }

  Dogadjaj? _pronadjiDogadjaj(
    List<Dogadjaj> dogadjaji,
    DogadjajId id,
  ) {
    for (final dogadjaj in dogadjaji) {
      if (dogadjaj.id == id) {
        return dogadjaj;
      }
    }

    return null;
  }



  Future<void> _onUcitajDogadjaje(
    UcitajDogadjajeEvent event,
    Emitter<DogadjajState> emit,
  ) async {
    emit(const DogadjajiLoading());

    try {
      final lista = await repository.getDogadjaji();
      final mojePrijave = await prijavaRepository.getMojePrijave();
      final recenzije = await recenzijaRepository.getRecenzije();
      final reloadUser = ucitajKorisnika;
      if (reloadUser != null) trenutniKorisnik = await reloadUser();

      if (lista.isEmpty) {
        emit(const DogadjajiEmpty());
      } else {
        emit(
          DogadjajiLoaded(
            List.unmodifiable(lista),
            mojePrijave: List.unmodifiable(mojePrijave),
            recenzije: List.unmodifiable(recenzije),
          ),
        );
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

    final dogadjaj = _pronadjiDogadjaj(
      trenutnoStanje.dogadjaji,
      event.id,
    );

    if (dogadjaj == null) {
      emit(const DogadjajiError('Događaj nije pronađen!'));
      return;
    }

    if (!mozePromenitiStanjeDogadjaja(
      trenutniKorisnik,
      dogadjaj,
      event.novoStanje,
    )) {
      emit(
        const DogadjajiError(
          'Nemate dozvolu za ovu promenu stanja ili prelaz nije dozvoljen!',
        ),
      );
      return;
    }

    try {
      final azuriraniDogadjaj = await repository.promeniStanje(
        event.id,
        event.novoStanje,
      );

      final azuriranaLista = trenutnoStanje.dogadjaji.map((d) {
        return d.id == azuriraniDogadjaj.id ? azuriraniDogadjaj : d;
      }).toList();

      emit(
        DogadjajiLoaded(
          List.unmodifiable(azuriranaLista),
          mojePrijave: trenutnoStanje.mojePrijave,
          recenzije: trenutnoStanje.recenzije,
        ),
      );
    } catch (e) {
      emit(DogadjajiError(e.toString(), nakonIzmene: true));
      if (!isClosed) add(const UcitajDogadjajeEvent());
    }
  }



  Future<void> _onPromeniKapacitet(
    PromeniKapacitetEvent event,
    Emitter<DogadjajState> emit,
  ) async {
    final trenutnoStanje = state;

    if (trenutnoStanje is! DogadjajiLoaded) {
      return;
    }

    final dogadjaj = _pronadjiDogadjaj(
      trenutnoStanje.dogadjaji,
      event.id,
    );

    if (dogadjaj == null) {
      emit(const DogadjajiError('Događaj nije pronađen!'));
      return;
    }

    if (!mozeUreditiDogadjaj(trenutniKorisnik, dogadjaj)) {
      emit(
        const DogadjajiError(
          'Nemate dozvolu da menjate ovaj događaj!',
        ),
      );
      return;
    }

    final rezultat = proveriKapacitet(event.noviKapacitet);

    if (rezultat is GreskaNeodgovarajuciKapacitet) {
      emit(
        const DogadjajiError(
          'Kapacitet mora biti veći od 0!',
        ),
      );
      return;
    }

    try {
      await repository.promeniKapacitet(
        event.id,
        event.noviKapacitet,
      );

      add(const UcitajDogadjajeEvent());
    } catch (e) {
      emit(DogadjajiError(e.toString(), nakonIzmene: true));
      if (!isClosed) add(const UcitajDogadjajeEvent());
    }
  }



  Future<void> _onKreirajDogadjaj(
    KreirajDogadjajEvent event,
    Emitter<DogadjajState> emit,
  ) async {
    final dogadjaj = event.dogadjaj;

    if (!mozeKreiratiDogadjaj(trenutniKorisnik) ||
        dogadjaj.hostId != trenutniKorisnik.id) {
      emit(
        const DogadjajiError(
          'Nemate dozvolu da kreirate događaj za ovaj nalog!',
        ),
      );
      return;
    }

    if (dogadjaj.stanje is! Preliminarni) {
      emit(
        const DogadjajiError(
          'Novi događaj mora biti u preliminarnom stanju!',
        ),
      );
      return;
    }

    final validacijaReputacije =
        proveriReputacijuHosta(dogadjaj.hostReputacija);

    if (validacijaReputacije is GreskaReputacijaIzvanOpsega) {
      emit(
        const DogadjajiError(
          'Reputacija hosta mora biti između 1.0 i 5.0!',
        ),
      );
      return;
    }

    final validacijaKapaciteta = proveriKapacitet(dogadjaj.kapacitet);

    if (validacijaKapaciteta is GreskaNeodgovarajuciKapacitet) {
      emit(
        const DogadjajiError(
          'Kapacitet mora biti veći od 0!',
        ),
      );
      return;
    }

    try {
      await repository.kreirajDogadjaj(dogadjaj);

      add(const UcitajDogadjajeEvent());
    } catch (e) {
      emit(DogadjajiError(e.toString(), nakonIzmene: true));
      if (!isClosed) add(const UcitajDogadjajeEvent());
    }
  }


  Future<void> _onPrijaviSe(
    PrijaviSeNaDogadjajEvent event,
    Emitter<DogadjajState> emit,
  ) async {
    final trenutnoStanje = state;

    if (trenutnoStanje is! DogadjajiLoaded) {
      return;
    }

    final dogadjaj = _pronadjiDogadjaj(
      trenutnoStanje.dogadjaji,
      event.dogadjajId,
    );

    if (dogadjaj == null) {
      emit(const DogadjajiError('Događaj nije pronađen!'));
      return;
    }

    if (!mozeSePrijavitiNaDogadjaj(
      trenutniKorisnik,
      dogadjaj,
    )) {
      emit(
        const DogadjajiError(
          'Nemate dozvolu za prijavu na ovaj događaj!',
        ),
      );
      return;
    }

    final vecJePrijavljen = trenutnoStanje.mojePrijave.any(
      (prijava) =>
          prijava.dogadjajId == dogadjaj.id &&
          prijava.status == StatusPrijave.aktivna,
    );

    if (vecJePrijavljen) {
      emit(
        const DogadjajiError(
          'Već ste prijavljeni na ovaj događaj!',
        ),
      );
      return;
    }

    try {
      final brojPrijavljenih =
          await prijavaRepository.getBrojAktivnihPrijava(dogadjaj.id);
      if (proveriSlobodnaMesta(dogadjaj.kapacitet, brojPrijavljenih)
          is GreskaNemaSlobodnihMesta) {
        emit(
            const DogadjajiError('Nema više slobodnih mesta za ovaj događaj!'));
        add(const UcitajDogadjajeEvent());
        return;
      }

      await prijavaRepository.kreirajPrijavu(dogadjaj.id);

      add(const UcitajDogadjajeEvent());
    } catch (e) {
      emit(DogadjajiError(e.toString(), nakonIzmene: true));
      if (!isClosed) add(const UcitajDogadjajeEvent());
    }
  }



  Future<void> _onOtkaziPrijavu(
    OtkaziPrijavuEvent event,
    Emitter<DogadjajState> emit,
  ) async {
    final trenutnoStanje = state;

    if (trenutnoStanje is! DogadjajiLoaded) {
      return;
    }

    Prijava? prijava;

    for (final p in trenutnoStanje.mojePrijave) {
      if (p.id == event.prijavaId) {
        prijava = p;
        break;
      }
    }

    if (prijava == null || !mozeOtkazatiPrijavu(trenutniKorisnik, prijava)) {
      emit(
        const DogadjajiError(
          'Možete otkazati samo svoju aktivnu prijavu!',
        ),
      );
      return;
    }

    try {
      await prijavaRepository.otkaziPrijavu(event.prijavaId);


      final azuriranePrijave = await prijavaRepository.getMojePrijave();

      emit(
        DogadjajiLoaded(
          trenutnoStanje.dogadjaji,
          mojePrijave: List.unmodifiable(azuriranePrijave),
          recenzije: trenutnoStanje.recenzije,
        ),
      );
    } catch (e) {
      emit(DogadjajiError(e.toString(), nakonIzmene: true));
      if (!isClosed) add(const UcitajDogadjajeEvent());
    }
  }

  Future<void> _onDodajRecenziju(
    DodajRecenzijuEvent event,
    Emitter<DogadjajState> emit,
  ) async {
    final trenutnoStanje = state;

    if (trenutnoStanje is! DogadjajiLoaded) {
      return;
    }

    final dogadjaj = _pronadjiDogadjaj(
      trenutnoStanje.dogadjaji,
      event.dogadjajId,
    );

    if (dogadjaj == null) {
      emit(const DogadjajiError('Događaj nije pronađen!'));
      return;
    }

    Prijava? mojaPrijava;

    for (final prijava in trenutnoStanje.mojePrijave) {
      if (prijava.dogadjajId == event.dogadjajId &&
          prijava.status == StatusPrijave.aktivna) {
        mojaPrijava = prijava;
        break;
      }
    }

    if (mojaPrijava == null ||
        !mozeOstavitiRecenziju(
          trenutniKorisnik,
          mojaPrijava,
          dogadjaj,
          postojeceRecenzije: trenutnoStanje.recenzije,
        )) {
      emit(
        const DogadjajiError(
          'Nemate pravo da ostavite recenziju za ovaj događaj '
          'ili ste je već ostavili!',
        ),
      );
      return;
    }


    final rezultatOcene = proveriOcenuRecenzije(event.ocena);

    if (rezultatOcene is GreskaOcenaIzvanOpsega) {
      emit(
        const DogadjajiError(
          'Ocena mora biti između 1 i 5!',
        ),
      );
      return;
    }


    final rezultatKomentara = proveriDuzinuKomentara(event.komentar);

    if (rezultatKomentara is GreskaKomentarPrekratak) {
      emit(
        const DogadjajiError(
          'Komentar mora imati najmanje 5 karaktera!',
        ),
      );
      return;
    }

    if (rezultatKomentara is GreskaKomentarPredugacak) {
      emit(
        const DogadjajiError(
          'Komentar ne može imati više od 500 karaktera!',
        ),
      );
      return;
    }

    try {
      await recenzijaRepository.kreirajRecenziju(
        dogadjajId: event.dogadjajId,
        ocena: event.ocena,
        komentar: event.komentar.trim(),
      );

      final azuriraneRecenzije = await recenzijaRepository.getRecenzije();

      emit(
        DogadjajiLoaded(
          trenutnoStanje.dogadjaji,
          mojePrijave: trenutnoStanje.mojePrijave,
          recenzije: List.unmodifiable(azuriraneRecenzije),
        ),
      );
    } catch (e) {
      emit(DogadjajiError(e.toString(), nakonIzmene: true));
      if (!isClosed) add(const UcitajDogadjajeEvent());
    }
  }
}
