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

class GreskaPreklapanjeTermina extends GreskaValidacije {
  const GreskaPreklapanjeTermina();
}


//Provera opsega reputacije 1.0 - 5.0
RezultatValidacije proveriReputacijuHosta(double reputacija) {
  if (reputacija < 1.0 || reputacija > 5.0) {
    return const GreskaReputacijaIzvanOpsega();
  }
  return const UspehValidacije();
}

//rovera kapaciteta (mora biti veći od 0)
RezultatValidacije proveriKapacitet(int kapacitet) {
  if (kapacitet <= 0) {
    return const GreskaNeodgovarajuciKapacitet();
  }
  return const UspehValidacije();
}

//(Izračunavanje nad listama): Izračun preostalih slobodnih mesta
int izracunajPreostalaMesta(int ukupniKapacitet, int brojPrijavljenih) {
  final preostalo = ukupniKapacitet - brojPrijavljenih;
  return preostalo > 0 ? preostalo : 0;
}