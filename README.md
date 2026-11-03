Sistem za zakazivanje događaja

Aplikacija za planiranje događaja, koja koristi sistem reputacije za host i za goste da proceni stvarnu dolaznost unapred kao i kvalitet događaja.


Da bi se pristupilo backoffice-u, treba uraditi:
flutter run -d <Platform> -t backoffice_app/lib/main.dart

Tim:

Viktor Markovic 104/24 SI

Ognjen Bruksanin 128/24 SI


Uloge:

Korisnik – Pregleda događaje, ozančava da će ići na događaje, ostavlja recenzije

Host – Pravi događaje i određuje pravila

Admin – Upravlja nalozima, nadgleda sadržaje i sprečava prevare


Stanja:

Tipičan događaj prolazi kroz sledeća stanja:

Preliminarni događaj → Pušten u javnost → Održava se → Održan

I poseduje dodatno stanje: Otkazan



Pravila:

- Nije moguće otkazati događaj ako se održava

- Nije moguće praviti događaje ukoliko reputacija postane previše mala

- Nije moguće prijaviti se na događaje koji se dešavaju u isto vreme

- Ukoliko host postavi pravilo za striktan kapacitet, nije moguće više korisnika da se prijavi nego što ima kapaciteta



Rad bez Mreze:

Korisnik bez mreže može da vidi događaje na koje se već prijavio.

Izmene se čuvaju lokalno i ažuriraju se kada se veza ponovo uspostavi




Posao za osoblje:

Administratori imaju ulogu moderatora i oni mogu pomoću desktop aplikacije da:

- Pregledaju naloge

- Pregledaju događaje

- Banuju naloge

- Ukidaju događaje

- Menjaju reputaciju naloga korisnika i hostova




Javni sadrzaj:

Bez prijave na sistem posetiocima je dostupam:

- Pregled javnih događaja

- Pregled reputacija hostova i korisnika