sealed class StanjeDogadjaja {
  const StanjeDogadjaja();
  String get naziv;
}

class Preliminarni extends StanjeDogadjaja {
  const Preliminarni();
  @override
  String get naziv => 'Preliminarni';
}

class Objavljen extends StanjeDogadjaja {
  const Objavljen();
  @override
  String get naziv => 'Objavljen';
}

class OdrzavaSe extends StanjeDogadjaja {
  const OdrzavaSe();
  @override
  String get naziv => 'Održava se';
}

class Odrzan extends StanjeDogadjaja {
  const Odrzan();
  @override
  String get naziv => 'Održan';
}

class Otkazan extends StanjeDogadjaja {
  const Otkazan();
  @override
  String get naziv => 'Otkazan';
}

/// Funkcija koja definira koji su prelazi između stanja dozvoljeni (Zahtev 2)
bool jeDozvoljenPrelaz(StanjeDogadjaja trenutno, StanjeDogadjaja novo) {
  return switch ((trenutno, novo)) {
    (Preliminarni(), Objavljen()) => true,
    (Preliminarni(), Otkazan()) => true,
    (Objavljen(), OdrzavaSe()) => true,
    (Objavljen(), Otkazan()) => true,
    (OdrzavaSe(), Odrzan()) => true,
    // Otkazan i Odrzan su konačna stanja
    _ => false,
  };
}


StanjeDogadjaja? sledeceStanjeDogadjaja(
    StanjeDogadjaja trenutno,
    ) {
  return switch (trenutno) {
    Preliminarni() => const Objavljen(),
    Objavljen() => const OdrzavaSe(),
    OdrzavaSe() => const Odrzan(),
    Odrzan() => null,
    Otkazan() => null,
  };
}
