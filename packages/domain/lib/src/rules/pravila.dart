sealed class RezultatValidacije {
  const RezultatValidacije();
}

class UspehValidacije extends RezultatValidacije {
  const UspehValidacije();
}

sealed class GreskaValidacije extends RezultatValidacije {
  const GreskaValidacije();
}

class GreskaReputacijaIzvanOpsega extends GreskaValidacije {
  const GreskaReputacijaIzvanOpsega();
}

class GreskaNeodgovarajuciKapacitet extends GreskaValidacije {
  const GreskaNeodgovarajuciKapacitet();
}

class GreskaNemaSlobodnihMesta extends GreskaValidacije {
  const GreskaNemaSlobodnihMesta();
}

class GreskaOcenaIzvanOpsega extends GreskaValidacije {
  const GreskaOcenaIzvanOpsega();
}

class GreskaKomentarPrekratak extends GreskaValidacije {
  const GreskaKomentarPrekratak();
}

class GreskaKomentarPredugacak extends GreskaValidacije {
  const GreskaKomentarPredugacak();
}


RezultatValidacije proveriReputacijuHosta(double reputacija) {
  if (!reputacija.isFinite || reputacija < 1.0 || reputacija > 5.0) {
    return const GreskaReputacijaIzvanOpsega();
  }

  return const UspehValidacije();
}


RezultatValidacije proveriKapacitet(int kapacitet) {
  if (kapacitet <= 0) {
    return const GreskaNeodgovarajuciKapacitet();
  }
  return const UspehValidacije();
}


int izracunajPreostalaMesta(int ukupniKapacitet, int brojPrijavljenih) {
  final preostalo = ukupniKapacitet - brojPrijavljenih;
  return preostalo > 0 ? preostalo : 0;
}

RezultatValidacije proveriSlobodnaMesta(
  int ukupniKapacitet,
  int brojAktivnihPrijava,
) {
  if (izracunajPreostalaMesta(
        ukupniKapacitet,
        brojAktivnihPrijava,
      ) <=
      0) {
    return const GreskaNemaSlobodnihMesta();
  }

  return const UspehValidacije();
}


RezultatValidacije proveriOcenuRecenzije(int ocena) {
  if (ocena < 1 || ocena > 5) {
    return const GreskaOcenaIzvanOpsega();
  }

  return const UspehValidacije();
}

RezultatValidacije proveriDuzinuKomentara(String komentar) {
  final duzina = komentar.trim().length;

  if (duzina < 5) {
    return const GreskaKomentarPrekratak();
  }

  if (duzina > 500) {
    return const GreskaKomentarPredugacak();
  }

  return const UspehValidacije();
}
