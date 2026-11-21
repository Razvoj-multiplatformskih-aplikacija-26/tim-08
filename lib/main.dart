import 'package:api_client/api_client.dart';
import 'session_gate.dart';
import 'public_reputation.dart';
import 'event_action_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:blocs/blocs.dart';

void main() {
  runApp(const MainApp());
}

// GoRouter
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ListaDogadjajaScreen(),
    ),
    GoRoute(
      path: '/filter',
      builder: (context, state) => const FormaFilterScreen(),
    ),
    GoRoute(
      path: '/detalji',
      builder: (context, state) {
        final args = state.extra;
        final dogadjaj = args is Map ? args['dogadjaj'] : null;
        if (dogadjaj is! Dogadjaj) return const ListaDogadjajaScreen();

        return DetaljiDogadjajaScreen(dogadjaj: dogadjaj);
      },
    ),
    GoRoute(
      path: '/kreiraj',
      builder: (context, state) => const FormaKreiranjaDogadjajaScreen(),
    ),
  ],
);

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();

  static MainAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainAppState>();
}

class DetaljiDogadjajaScreen extends StatelessWidget {
  final Dogadjaj dogadjaj;

  const DetaljiDogadjajaScreen({super.key, required this.dogadjaj});

  Widget _akcijaPrijave(BuildContext context, Dogadjaj trenutniDogadjaj) {
    return BlocBuilder<DogadjajBloc, DogadjajState>(
      builder: (context, state) {
        if (state is DogadjajiLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DogadjajiError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.poruka, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<DogadjajBloc>().add(
                    const UcitajDogadjajeEvent(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          );
        }

        if (state is DogadjajiEmpty) {
          return const Text('Nema dostupnih događaja.');
        }

        if (state is! DogadjajiLoaded) {
          return const Text('Podaci trenutno nisu dostupni.');
        }

        final bloc = context.read<DogadjajBloc>();
        final korisnik = bloc.trenutniKorisnik;

        Prijava? mojaAktivnaPrijava;

        for (final prijava in state.mojePrijave) {
          if (prijava.dogadjajId == trenutniDogadjaj.id &&
              prijava.status == StatusPrijave.aktivna) {
            mojaAktivnaPrijava = prijava;
            break;
          }
        }


        if (mojaAktivnaPrijava != null) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.event_busy),
              label: const Text('Otkaži moju prijavu'),
              onPressed: () async {
                final potvrda = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Potvrda otkazivanja'),
                    content: Text(
                      'Da li ste sigurni da želite da otkažete '
                      'svoju prijavu za događaj '
                      '"${trenutniDogadjaj.naziv}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        child: const Text('Odustani'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        child: const Text('Otkaži prijavu'),
                      ),
                    ],
                  ),
                );

                if (potvrda == true && context.mounted) {
                  context.read<DogadjajBloc>().add(
                    OtkaziPrijavuEvent(prijavaId: mojaAktivnaPrijava!.id),
                  );
                }
              },
            ),
          );
        }


        final mozeSePrijaviti = mozeSePrijavitiNaDogadjaj(
          korisnik,
          trenutniDogadjaj,
        );

        if (korisnik.uloga != UlogaKorisnika.korisnik) {
          return const SizedBox.shrink();
        }

        if (mozeSePrijaviti) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('Prijavi se na događaj'),
              onPressed: () {
                context.read<DogadjajBloc>().add(
                  PrijaviSeNaDogadjajEvent(dogadjajId: trenutniDogadjaj.id),
                );
              },
            ),
          );
        }

        return const SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            child: Text('Prijava nije dostupna'),
          ),
        );
      },
    );
  }

  Widget _akcijaNapredovanjaDogadjaja(BuildContext context, Dogadjaj dogadjaj) {
    return BlocBuilder<DogadjajBloc, DogadjajState>(
      builder: (context, state) {
        if (state is! DogadjajiLoaded) {
          return const SizedBox.shrink();
        }

        final bloc = context.read<DogadjajBloc>();
        final korisnik = bloc.trenutniKorisnik;

        final novoStanje = sledeceStanjeDogadjaja(dogadjaj.stanje);

        if (novoStanje == null) {
          return const SizedBox.shrink();
        }

        final dozvoljeno = mozePromenitiStanjeDogadjaja(
          korisnik,
          dogadjaj,
          novoStanje,
        );

        if (!dozvoljeno) {
          return const SizedBox.shrink();
        }

        final String tekst;
        final IconData ikonica;

        if (novoStanje is Objavljen) {
          tekst = 'Objavi događaj';
          ikonica = Icons.publish;
        } else if (novoStanje is OdrzavaSe) {
          tekst = 'Označi da se događaj održava';
          ikonica = Icons.play_circle;
        } else {
          tekst = 'Označi kao održan';
          ikonica = Icons.check_circle;
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<DogadjajBloc>().add(
                PromeniStanjeEvent(id: dogadjaj.id, novoStanje: novoStanje),
              );
            },
            icon: Icon(ikonica),
            label: Text(tekst),
          ),
        );
      },
    );
  }

  Widget _akcijaOtkazivanjaDogadjaja(BuildContext context, Dogadjaj dogadjaj) {
    return BlocBuilder<DogadjajBloc, DogadjajState>(
      builder: (context, state) {
        if (state is! DogadjajiLoaded) {
          return const SizedBox.shrink();
        }

        final bloc = context.read<DogadjajBloc>();
        final korisnik = bloc.trenutniKorisnik;

        // Only the host who owns this event sees this action.
        if (korisnik.uloga != UlogaKorisnika.host ||
            korisnik.id != dogadjaj.hostId) {
          return const SizedBox.shrink();
        }

        final mozeOtkazati = mozeOtkazatiDogadjaj(korisnik, dogadjaj);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.white54,
                ),
                icon: const Icon(Icons.cancel),
                label: const Text('Otkaži moj događaj'),
                onPressed: mozeOtkazati
                    ? () async {
                        final potvrda = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Potvrda otkazivanja'),
                            content: Text(
                              'Da li ste sigurni da želite da '
                              'otkažete događaj "${dogadjaj.naziv}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                child: const Text('Odustani'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext, true);
                                },
                                child: const Text('Otkaži događaj'),
                              ),
                            ],
                          ),
                        );

                        if (potvrda == true && context.mounted) {
                          context.read<DogadjajBloc>().add(
                            PromeniStanjeEvent(
                              id: dogadjaj.id,
                              novoStanje: const Otkazan(),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ),

            if (!mozeOtkazati)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Događaj nije moguće otkazati u trenutnom stanju.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sekcijaRecenzija(BuildContext context, Dogadjaj dogadjaj) {
    return BlocBuilder<DogadjajBloc, DogadjajState>(
      builder: (context, state) {
        if (state is! DogadjajiLoaded) {
          return const SizedBox.shrink();
        }

        final korisnik = context.read<DogadjajBloc>().trenutniKorisnik;

        final recenzijeZaDogadjaj = state.recenzije
            .where((r) => r.dogadjajId == dogadjaj.id)
            .toList();

        final prosecnaOcena = izracunajProsecnuOcenuDogadjaja(
          dogadjaj.id,
          state.recenzije,
        );

        Prijava? mojaPrijava;

        for (final p in state.mojePrijave) {
          if (p.dogadjajId == dogadjaj.id &&
              p.status == StatusPrijave.aktivna) {
            mojaPrijava = p;
            break;
          }
        }

        final vecJeOcenio = state.recenzije.any(
          (r) => r.dogadjajId == dogadjaj.id && r.autorId == korisnik.id,
        );

        final mozeOstaviti =
            mojaPrijava != null &&
            mozeOstavitiRecenziju(
              korisnik,
              mojaPrijava,
              dogadjaj,
              postojeceRecenzije: state.recenzije,
            );

        final reputacijaHosta = izracunajReputacijuHosta(
          hostId: dogadjaj.hostId,
          dogadjaji: state.dogadjaji,
          recenzije: state.recenzije,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),

            const Text(
              'Recenzije i reputacija',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              prosecnaOcena == null
                  ? 'Ocena događaja: Još nema recenzija'
                  : 'Ocena događaja: '
                        '${prosecnaOcena.toStringAsFixed(2)} / 5',
            ),

            const SizedBox(height: 6),

            Text(
              reputacijaHosta == null
                  ? 'Reputacija hosta prema recenzijama: Nema ocena'
                  : 'Reputacija hosta prema recenzijama: '
                        '${reputacijaHosta.toStringAsFixed(2)} / 5',
            ),

            const SizedBox(height: 16),

            if (mozeOstaviti)
              FormaRecenzijeWidget(dogadjaj: dogadjaj)
            else if (vecJeOcenio)
              const Text(
                'Već ste ostavili recenziju za ovaj događaj.',
                style: TextStyle(color: Colors.green),
              )
            else if (korisnik.uloga == UlogaKorisnika.korisnik &&
                dogadjaj.stanje is Odrzan)
              const Text(
                'Recenziju mogu ostaviti samo korisnici '
                'koji imaju aktivnu prijavu za ovaj događaj.',
              ),

            if (recenzijeZaDogadjaj.isNotEmpty) ...[
              const SizedBox(height: 16),

              const Text(
                'Ostavljene recenzije:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              ...recenzijeZaDogadjaj.map(
                (r) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${r.ocena}')),
                    title: Text('Korisnik #${r.autorId.value}'),
                    subtitle: Text(r.komentar),
                    trailing: const Icon(Icons.star),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DogadjajBloc, DogadjajState>(
      builder: (context, state) {

        Dogadjaj trenutniDogadjaj = dogadjaj;

        if (state is DogadjajiLoaded) {
          for (final d in state.dogadjaji) {
            if (d.id == dogadjaj.id) {
              trenutniDogadjaj = d;
              break;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(title: Text(trenutniDogadjaj.naziv)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID događaja: ${trenutniDogadjaj.id.value}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),

                Text(
                  'Naziv: ${trenutniDogadjaj.naziv}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Trenutno stanje: ${trenutniDogadjaj.stanje.naziv}',
                  style: TextStyle(
                    fontSize: 16,
                    color: trenutniDogadjaj.stanje.boja,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Kapacitet: ${trenutniDogadjaj.kapacitet}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),

                Text(
                  'Reputacija hosta: ${trenutniDogadjaj.hostReputacija.toStringAsFixed(2)} / 5',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),

                Text(
                  'Opis: ${trenutniDogadjaj.opis}',
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 20),

                _akcijaPrijave(context, trenutniDogadjaj),

                const SizedBox(height: 12),

                _akcijaNapredovanjaDogadjaja(context, trenutniDogadjaj),

                const SizedBox(height: 12),

                _akcijaOtkazivanjaDogadjaja(context, trenutniDogadjaj),

                const SizedBox(height: 20),

                _sekcijaRecenzija(context, trenutniDogadjaj),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FormaRecenzijeWidget extends StatefulWidget {
  final Dogadjaj dogadjaj;

  const FormaRecenzijeWidget({super.key, required this.dogadjaj});

  @override
  State<FormaRecenzijeWidget> createState() => _FormaRecenzijeWidgetState();
}

class _FormaRecenzijeWidgetState extends State<FormaRecenzijeWidget> {
  final _formKey = GlobalKey<FormState>();
  final _komentarController = TextEditingController();

  int _ocena = 5;

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ostavite recenziju',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _ocena,
                decoration: const InputDecoration(
                  labelText: 'Ocena',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) {
                  final ocena = index + 1;

                  return DropdownMenuItem(
                    value: ocena,
                    child: Text('$ocena / 5'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _ocena = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null ||
                      proveriOcenuRecenzije(value) is GreskaOcenaIzvanOpsega) {
                    return 'Izaberite ocenu od 1 do 5!';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _komentarController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Komentar',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final rezultat = proveriDuzinuKomentara(value ?? '');

                  if (rezultat is GreskaKomentarPrekratak) {
                    return 'Komentar mora imati najmanje 5 karaktera!';
                  }

                  if (rezultat is GreskaKomentarPredugacak) {
                    return 'Komentar ne može imati više od 500 karaktera!';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  context.read<DogadjajBloc>().add(
                    DodajRecenzijuEvent(
                      dogadjajId: widget.dogadjaj.id,
                      ocena: _ocena,
                      komentar: _komentarController.text.trim(),
                    ),
                  );
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('Pošalji recenziju'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) => SessionGate(
    onSessionClosed: () => _router.go('/'),
    builder: (client, actor) => BlocProvider(
      key: ValueKey(actor.id.value),
      create: (context) => DogadjajBloc(
        repository: RemoteDogadjajRepository(client: client),
        prijavaRepository: RemotePrijavaRepository(client: client),
        recenzijaRepository: RemoteRecenzijaRepository(client: client),
        trenutniKorisnik: actor,
        ucitajKorisnika: actor.uloga == UlogaKorisnika.host
            ? client.currentUser
            : null,
      )..add(const UcitajDogadjajeEvent()),
      child: MaterialApp.router(
        title: 'Sistem za zakazivanje dogadjaja',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        builder: (context, child) => EventActionFeedback(child: child!),
      ),
    ),
  );
}

extension StanjeUiExtension on StanjeDogadjaja {
  Color get boja => switch (this) {
    Preliminarni() => Colors.orange,
    Objavljen() => Colors.blue,
    OdrzavaSe() => Colors.green,
    Odrzan() => Colors.grey,
    Otkazan() => Colors.red,
  };
}

class ListaDogadjajaScreen extends StatefulWidget {
  const ListaDogadjajaScreen({super.key});

  @override
  State<ListaDogadjajaScreen> createState() => _ListaDogadjajaScreenState();
}

class _ListaDogadjajaScreenState extends State<ListaDogadjajaScreen> {
  double? _minimalnaReputacija;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Scheduler (Bloc)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Osveži',
            onPressed: () =>
                context.read<DogadjajBloc>().add(const UcitajDogadjajeEvent()),
          ),
          // Promena teme
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Reputacije',
            onPressed: () {
              final client = SessionGate.of(context).client;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicReputation(client: client),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => MainApp.of(context)?.toggleTheme(),
          ),

          // Otvaranje filtera
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtriraj po reputaciji hosta',
            onPressed: () async {
              final double? rezultat = await context.push<double>('/filter');

              if (rezultat != null && mounted) {
                setState(() {
                  _minimalnaReputacija = rezultat;
                });
              }
            },
          ),

          // Uklanjanje aktivnog filtera
          if (_minimalnaReputacija != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Ukloni filter',
              onPressed: () {
                setState(() {
                  _minimalnaReputacija = null;
                });
              },
            ),

          BlocBuilder<DogadjajBloc, DogadjajState>(
            builder: (context, state) {
              if (!mozeKreiratiDogadjaj(
                context.read<DogadjajBloc>().trenutniKorisnik,
              )) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Kreiraj događaj',
                onPressed: () => context.push('/kreiraj'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Prijava / odjava',
            onPressed: () => SessionGate.of(context).signOut(),
          ),
        ],
      ),

      body: BlocBuilder<DogadjajBloc, DogadjajState>(
        builder: (context, state) {
          //ucitavanje
          if (state is DogadjajiLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          //greska
          if (state is DogadjajiError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),

                  Text(
                    state.poruka,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<DogadjajBloc>().add(
                        const UcitajDogadjajeEvent(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            );
          }

          //prazna lista
          if (state is DogadjajiEmpty) {
            return const Center(
              child: Text(
                'Nema dostupnih događaja.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          //ucitani podaci
          if (state is DogadjajiLoaded) {
            //le filter
            final dogadjaji = state.dogadjaji.where((d) {
              if (_minimalnaReputacija == null) {
                return true;
              }

              return d.hostReputacija >= _minimalnaReputacija!;
            }).toList();

            //ako nista nema
            if (dogadjaji.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.filter_alt_off,
                      size: 50,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Nema događaja sa reputacijom hosta '
                      'najmanje ${_minimalnaReputacija!.toStringAsFixed(1)}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minimalnaReputacija = null;
                        });
                      },
                      child: const Text('Ukloni filter'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: dogadjaji.length,
              itemBuilder: (context, index) {
                final d = dogadjaji[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      d.naziv,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      'Kapacitet: ${d.kapacitet} | '
                      'Reputacija: ${d.hostReputacija}',
                    ),

                    trailing: Chip(
                      label: Text(
                        d.stanje.naziv,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: d.stanje.boja,
                    ),

                    onTap: () {
                      context.push('/detalji', extra: {'dogadjaj': d});
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class FormaFilterScreen extends StatefulWidget {
  const FormaFilterScreen({super.key});

  @override
  State<FormaFilterScreen> createState() => _FormaFilterScreenState();
}

class _FormaFilterScreenState extends State<FormaFilterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unos minimalne reputacije hosta')),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //min rep unos
              TextFormField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Minimalna reputacija (1.0 - 5.0)',
                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Polje ne sme biti prazno!';
                  }

                  final broj = double.tryParse(value.trim());

                  if (broj == null) {
                    return 'Unesite validan broj!';
                  }

                  if (!broj.isFinite) {
                    return 'Unesite konačan broj!';
                  }

                  //praviloooo
                  final rezultat = proveriReputacijuHosta(broj);

                  if (rezultat is GreskaReputacijaIzvanOpsega) {
                    return 'Reputacija mora biti u opsegu '
                        'između 1.0 i 5.0!';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              //primena za filter
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final double minimalnaReputacija = double.parse(
                      _controller.text.trim(),
                    );

                    context.pop<double>(minimalnaReputacija);
                  }
                },
                child: const Text('Primeni filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormaKreiranjaDogadjajaScreen extends StatefulWidget {
  const FormaKreiranjaDogadjajaScreen({super.key});

  @override
  State<FormaKreiranjaDogadjajaScreen> createState() =>
      _FormaKreiranjaDogadjajaScreenState();
}

class _FormaKreiranjaDogadjajaScreenState
    extends State<FormaKreiranjaDogadjajaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nazivController = TextEditingController();
  final _opisController = TextEditingController();
  final _kapacitetController = TextEditingController();
  @override
  void dispose() {
    _nazivController.dispose();
    _opisController.dispose();
    _kapacitetController.dispose();
    super.dispose();
  }

  void _sacuvajDogadjaj() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final bloc = context.read<DogadjajBloc>();
    final korisnik = bloc.trenutniKorisnik;
    final state = bloc.state;

    if (!mozeKreiratiDogadjaj(korisnik)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nemate dozvolu za kreiranje događaja!')),
      );
      return;
    }

    if (state is! DogadjajiLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaci trenutno nisu dostupni.')),
      );
      return;
    }

    final noviDogadjaj = Dogadjaj(
      id: DogadjajId(0),
      hostId: korisnik.id,
      naziv: _nazivController.text.trim(),
      opis: _opisController.text.trim(),
      stanje: const Preliminarni(),
      kapacitet: int.parse(_kapacitetController.text.trim()),
      hostReputacija: korisnik.reputacija,
    );

    bloc.add(KreirajDogadjajEvent(dogadjaj: noviDogadjaj));

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kreiranje događaja')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informacije o događaju',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nazivController,
                decoration: const InputDecoration(
                  labelText: 'Naziv događaja',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesite naziv događaja!';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _opisController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Opis događaja',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesite opis događaja!';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _kapacitetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maksimalni kapacitet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final broj = int.tryParse(value?.trim() ?? '');

                  if (broj == null) {
                    return 'Unesite validan ceo broj!';
                  }

                  final rezultat = proveriKapacitet(broj);

                  if (rezultat is GreskaNeodgovarajuciKapacitet) {
                    return 'Kapacitet mora biti veći od 0!';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Događaj će biti kreiran u preliminarnom stanju. '
                'Nakon toga možete ga objaviti.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _sacuvajDogadjaj,
                icon: const Icon(Icons.add),
                label: const Text('Kreiraj događaj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
