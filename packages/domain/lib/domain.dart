library;

class Dogadjaj {
  final String id;
  final String naziv;
  final StanjeDogadjaja stanje;
  final int kapacitet;
  final double hostReputacija;
  final String opis;

  const Dogadjaj({
    required this.id,
    required this.naziv,
    required this.stanje,
    required this.kapacitet,
    required this.hostReputacija,
    required this.opis,
  });
}

sealed class StanjeDogadjaja {
  String get naziv;
}

class Preliminarni extends StanjeDogadjaja { //dogadjaj koji se desava pre nekog drugog
  @override String get naziv => 'Preliminarni';
}

class PustenUJavnost extends StanjeDogadjaja {
  @override String get naziv => 'Pušten u javnost';
}

class OdrzavaSe extends StanjeDogadjaja {
  @override String get naziv => 'Odrzava se';
}

class Odrzan extends StanjeDogadjaja {
  @override String get naziv => 'Odrzan';
}

class Otkazan extends StanjeDogadjaja {
  @override String get naziv => 'Otkazan';
}

sealed class ValidacioniRezultat {
  const ValidacioniRezultat();
}

class Uspeh extends ValidacioniRezultat {
  const Uspeh();
}

class Greska extends ValidacioniRezultat {
  final String sifraGreske;
  const Greska(this.sifraGreske);
}

ValidacioniRezultat proveriReputacijuHostova(String? vrednost) {
  if (vrednost == null || vrednost.trim().isEmpty) {
    return const Greska('POLJE_PRAZNO');
  }
  
  final broj = double.tryParse(vrednost);
  if (broj == null) {
    return const Greska('NIJE_BROJ');
  }

  if (broj < 1.0 || broj > 5.0) {
    return const Greska('VAN_OPSEGA_1_5');
  }

  return const Uspeh();
}

bool dozvoljenPrelazStanja(StanjeDogadjaja trenutno, StanjeDogadjaja novo) {
  if (trenutno is Preliminarni) {
    return novo is PustenUJavnost || novo is Otkazan;
  }
  if (trenutno is PustenUJavnost) {
    return novo is OdrzavaSe || novo is Otkazan;
  }
  if (trenutno is OdrzavaSe) {
    return novo is Odrzan || novo is Otkazan;
  }
  return false;
}