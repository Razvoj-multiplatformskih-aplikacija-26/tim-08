import 'package:domain/domain.dart';
import 'package:api_contract/api_contract.dart';


String stanjeToApi(StanjeDogadjaja stanje) {
  return switch (stanje) {
    Preliminarni() => 'PRELIMINARY',
    Objavljen() => 'PUBLISHED',
    OdrzavaSe() => 'ONGOING',
    Odrzan() => 'COMPLETED',
    Otkazan() => 'CANCELLED',
  };
}

StanjeDogadjaja stanjeFromApi(String stanje) {
  return switch (stanje) {
    'PRELIMINARY' => const Preliminarni(),
    'PUBLISHED' => const Objavljen(),
    'ONGOING' => const OdrzavaSe(),
    'COMPLETED' => const Odrzan(),
    'CANCELLED' => const Otkazan(),
    _ => throw FormatException(
        'Nepoznato stanje događaja: $stanje',
      ),
  };
}


String ulogaToApi(UlogaKorisnika uloga) {
  return switch (uloga) {
    UlogaKorisnika.korisnik => 'USER',
    UlogaKorisnika.host => 'HOST',
    UlogaKorisnika.moderator => 'MODERATOR',
  };
}

UlogaKorisnika ulogaFromApi(String uloga) {
  return switch (uloga) {
    'USER' => UlogaKorisnika.korisnik,
    'HOST' => UlogaKorisnika.host,
    'MODERATOR' => UlogaKorisnika.moderator,
    _ => throw FormatException(
        'Nepoznata korisnička uloga: $uloga',
      ),
  };
}


String statusPrijaveToApi(StatusPrijave status) {
  return switch (status) {
    StatusPrijave.aktivna => 'ACTIVE',
    StatusPrijave.otkazana => 'CANCELLED',
  };
}

StatusPrijave statusPrijaveFromApi(String status) {
  return switch (status) {
    'ACTIVE' => StatusPrijave.aktivna,
    'CANCELLED' => StatusPrijave.otkazana,
    _ => throw FormatException(
        'Nepoznat status prijave: $status',
      ),
  };
}


Korisnik korisnikFromApi(ApiUserDto dto) {
  return Korisnik(
    id: KorisnikId(dto.id),
    ime: dto.name,
    email: dto.email,
    uloga: ulogaFromApi(dto.role),
    reputacija: dto.reputation,
    jeBanovan: dto.isBanned,
  );
}

ApiUserDto korisnikToApi(Korisnik korisnik) {
  return ApiUserDto(
    id: korisnik.id.value,
    name: korisnik.ime,
    email: korisnik.email,
    role: ulogaToApi(korisnik.uloga),
    reputation: korisnik.reputacija,
    isBanned: korisnik.jeBanovan,
  );
}


Dogadjaj dogadjajFromApi(ApiEventDto dto) {
  return Dogadjaj(
    id: DogadjajId(dto.id),
    hostId: KorisnikId(dto.hostId),
    naziv: dto.title,
    stanje: stanjeFromApi(dto.state),
    kapacitet: dto.capacity,
    hostReputacija: dto.hostReputation,
    opis: dto.description,
  );
}

ApiEventDto dogadjajToApi(Dogadjaj dogadjaj) {
  return ApiEventDto(
    id: dogadjaj.id.value,
    hostId: dogadjaj.hostId.value,
    title: dogadjaj.naziv,
    state: stanjeToApi(dogadjaj.stanje),
    capacity: dogadjaj.kapacitet,
    hostReputation: dogadjaj.hostReputacija,
    description: dogadjaj.opis,
  );
}


ApiCreateEventRequest dogadjajToCreateRequest(
  Dogadjaj dogadjaj,
) {
  return ApiCreateEventRequest(
    title: dogadjaj.naziv,
    description: dogadjaj.opis,
    capacity: dogadjaj.kapacitet,
  );
}

ApiChangeEventStateRequest stanjeToChangeRequest(
  StanjeDogadjaja stanje,
) {
  return ApiChangeEventStateRequest(
    state: stanjeToApi(stanje),
  );
}

ApiChangeCapacityRequest kapacitetToChangeRequest(
  int kapacitet,
) {
  return ApiChangeCapacityRequest(
    capacity: kapacitet,
  );
}


Prijava prijavaFromApi(ApiRegistrationDto dto) {
  return Prijava(
    id: PrijavaId(dto.id),
    dogadjajId: DogadjajId(dto.eventId),
    korisnikId: KorisnikId(dto.userId),
    status: statusPrijaveFromApi(dto.status),
  );
}

ApiRegistrationDto prijavaToApi(Prijava prijava) {
  return ApiRegistrationDto(
    id: prijava.id.value,
    eventId: prijava.dogadjajId.value,
    userId: prijava.korisnikId.value,
    status: statusPrijaveToApi(prijava.status),
  );
}


Recenzija recenzijaFromApi(ApiReviewDto dto) {
  return Recenzija(
    id: RecenzijaId(dto.id),
    dogadjajId: DogadjajId(dto.eventId),
    autorId: KorisnikId(dto.authorId),
    ocena: dto.rating,
    komentar: dto.comment,
  );
}

ApiReviewDto recenzijaToApi(Recenzija recenzija) {
  return ApiReviewDto(
    id: recenzija.id.value,
    eventId: recenzija.dogadjajId.value,
    authorId: recenzija.autorId.value,
    rating: recenzija.ocena,
    comment: recenzija.komentar,
  );
}

ApiCreateReviewRequest recenzijaToCreateRequest(
  Recenzija recenzija,
) {
  return ApiCreateReviewRequest(
    rating: recenzija.ocena,
    comment: recenzija.komentar,
  );
}
