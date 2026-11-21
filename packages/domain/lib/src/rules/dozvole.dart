import '../models/korisnik.dart';
import '../models/dogadjaj.dart';
import '../models/prijava.dart';
import '../states/stanje_dogadjaja.dart';
import '../models/recenzija.dart';

const minimalnaReputacijaZaKreiranje = 3.0;

bool jeMobilnaUloga(UlogaKorisnika uloga) =>
    uloga == UlogaKorisnika.korisnik || uloga == UlogaKorisnika.host;

bool jeBackofficeUloga(UlogaKorisnika uloga) =>
    uloga == UlogaKorisnika.moderator;


bool mozeKreiratiDogadjaj(Korisnik akter) {
  return !akter.jeBanovan &&
      akter.uloga == UlogaKorisnika.host &&
      akter.reputacija >= minimalnaReputacijaZaKreiranje;
}


bool mozeUreditiDogadjaj(
  Korisnik akter,
  Dogadjaj dogadjaj,
) {
  if (akter.jeBanovan) {
    return false;
  }

  if (akter.uloga == UlogaKorisnika.moderator) {
    return true;
  }

  return akter.uloga == UlogaKorisnika.host && akter.id == dogadjaj.hostId;
}


bool mozeOtkazatiDogadjaj(
  Korisnik akter,
  Dogadjaj dogadjaj,
) =>
    mozePromenitiStanjeDogadjaja(akter, dogadjaj, const Otkazan());

bool mozePromenitiStanjeDogadjaja(
  Korisnik akter,
  Dogadjaj dogadjaj,
  StanjeDogadjaja novoStanje,
) =>
    imaPravoNaPromenuStanja(akter, dogadjaj, novoStanje) &&
    jeDozvoljenPrelaz(dogadjaj.stanje, novoStanje);

bool imaPravoNaPromenuStanja(
  Korisnik akter,
  Dogadjaj dogadjaj,
  StanjeDogadjaja novoStanje,
) =>
    !akter.jeBanovan &&
    ((akter.uloga == UlogaKorisnika.moderator && novoStanje is Otkazan) ||
        (akter.uloga == UlogaKorisnika.host && akter.id == dogadjaj.hostId));


bool mozeSePrijavitiNaDogadjaj(
  Korisnik akter,
  Dogadjaj dogadjaj,
) {
  return !akter.jeBanovan &&
      akter.uloga == UlogaKorisnika.korisnik &&
      dogadjaj.stanje is Objavljen;
}


bool mozeOtkazatiPrijavu(
  Korisnik akter,
  Prijava prijava,
) {
  return !akter.jeBanovan &&
      akter.uloga == UlogaKorisnika.korisnik &&
      akter.id == prijava.korisnikId &&
      prijava.status == StatusPrijave.aktivna;
}

bool mozeOstavitiRecenziju(
  Korisnik akter,
  Prijava prijava,
  Dogadjaj dogadjaj, {
  List<Recenzija> postojeceRecenzije = const [],
}) {
  final vecJeOcenio = postojeceRecenzije.any(
    (r) => r.dogadjajId == dogadjaj.id && r.autorId == akter.id,
  );

  return !akter.jeBanovan &&
      akter.uloga == UlogaKorisnika.korisnik &&
      akter.id == prijava.korisnikId &&
      prijava.dogadjajId == dogadjaj.id &&
      prijava.status == StatusPrijave.aktivna &&
      dogadjaj.stanje is Odrzan &&
      !vecJeOcenio;
}


bool mozeMenjatiReputaciju(Korisnik akter) {
  return !akter.jeBanovan && jeBackofficeUloga(akter.uloga);
}


bool mozeBanovatiKorisnika(
  Korisnik akter,
  Korisnik cilj,
) {
  return mozeMenjatiReputaciju(akter) && akter.id != cilj.id;
}
