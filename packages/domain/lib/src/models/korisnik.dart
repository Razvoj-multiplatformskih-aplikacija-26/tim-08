import 'id_types.dart';

enum UlogaKorisnika {
  korisnik,
  host,
  moderator,
}

class Korisnik {
  final KorisnikId id;
  final String ime;
  final String email;
  final UlogaKorisnika uloga;
  final double reputacija;
  final bool jeBanovan;

  const Korisnik({
    required this.id,
    required this.ime,
    required this.email,
    required this.uloga,
    this.reputacija = 3.0,
    this.jeBanovan = false,
  });

  Korisnik copyWith({
    String? ime,
    String? email,
    UlogaKorisnika? uloga,
    double? reputacija,
    bool? jeBanovan,
  }) {
    return Korisnik(
      id: id,
      ime: ime ?? this.ime,
      email: email ?? this.email,
      uloga: uloga ?? this.uloga,
      reputacija: reputacija ?? this.reputacija,
      jeBanovan: jeBanovan ?? this.jeBanovan,
    );
  }
}