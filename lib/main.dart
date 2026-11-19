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
        final args = state.extra as Map<String, dynamic>;

        final Dogadjaj dogadjaj = args['dogadjaj'] as Dogadjaj;
        final VoidCallback onOtkazi = args['onOtkazi'] as VoidCallback;

        return DetaljiDogadjajaScreen(
          dogadjaj: dogadjaj,
          onOtkazi: onOtkazi,
        );
      },
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
  final VoidCallback onOtkazi;

  const DetaljiDogadjajaScreen({super.key, required this.dogadjaj, required this.onOtkazi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dogadjaj.naziv)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID događaja: ${dogadjaj.id}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Naziv: ${dogadjaj.naziv}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Trenutno stanje: ${dogadjaj.stanje.naziv}', style: TextStyle(fontSize: 16, color: dogadjaj.stanje.boja, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Maksimalni kapacitet: ${dogadjaj.kapacitet}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Reputacija hosta: ${dogadjaj.hostReputacija}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Opis: ${dogadjaj.opis}', style: const TextStyle(fontSize: 18)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (dogadjaj.stanje is Otkazan || dogadjaj.stanje is Odrzan) ? null : () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Potvrda otkazivanja'),
                      content: Text('Da li ste sigurni da želite da otkažete događaj "${dogadjaj.naziv}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Odustani'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            onOtkazi();
                          },
                          child: const Text('Otkaži događaj'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Otkaži dogadjaj'),
              ),
            ),
          ],
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DogadjajBloc(
        repository: MockDogadjajRepository(),
      )..add(UcitajDogadjajeEvent()),
      child: MaterialApp.router(
        title: 'Sistem za zakazivanje dogadjaja',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}

class MockDogadjajRepository implements DogadjajRepository {
  bool _simulirajGresku = false;

  void setSimulirajGresku(bool vrednost) {
    _simulirajGresku = vrednost;
  }

  //laznjaci
  final List<Dogadjaj> _dogadjaji = [
    Dogadjaj(id: DogadjajId(1), naziv: 'Bajaga i instruktori comeback tour, Subotica', stanje: Objavljen(), kapacitet: 120, hostReputacija: 4.8, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(2), naziv: 'Prljavo skladište tour, Batajnica', stanje: Preliminarni(), kapacitet: 30, hostReputacija: 2.2, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(3), naziv: 'Mongolian Throat Singing Festival, Konjarnik', stanje: OdrzavaSe(), kapacitet: 80, hostReputacija: 3.9, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(4), naziv: 'Kokoške za KFC, New album tour', stanje: Odrzan(), kapacitet: 50, hostReputacija: 3.5, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(5), naziv: 'Yuno Miles dolazi u Karaburmu!', stanje: Otkazan(), kapacitet: 100, hostReputacija: 4.0, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(6), naziv: 'Karotidne Arterije, Pećinci', stanje: Objavljen(), kapacitet: 40, hostReputacija: 4.2, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(7), naziv: 'Kino koncert, Beograd', stanje: Preliminarni(), kapacitet: 60, hostReputacija: 5.0, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(8), naziv: 'Burme Karaburme Reunion', stanje: OdrzavaSe(), kapacitet: 90, hostReputacija: 4.7, opis:'neki opis'),
    Dogadjaj(id: DogadjajId(9), naziv: 'Palanačke Palme comeback tour', stanje: Odrzan(), kapacitet: 70, hostReputacija: 3.3, opis:'Palanačke Palme obilaze svaku Palanku u Srbiji i u širem reGIOnu u njihovoj najnovijom turi! Počevši od Smederevske Palanke naravno jer je najbolja'),
    Dogadjaj(id: DogadjajId(10), naziv: 'Michael Jackson comeback tour', stanje: Otkazan(), kapacitet: 150, hostReputacija: 2.0, opis:'Nahhhhhhh i dalje nije ziv'),
  ];

  @override
  Future<List<Dogadjaj>> getDogadjaji() async {
    await Future.delayed(const Duration(milliseconds: 800)); //Simulacija kasnjenja
    
    if (_simulirajGresku) {
      _simulirajGresku = false; //kada se desi greska u simulaciji, stavlja se na false da bi posle radilo kako treba
      throw Exception('Greška prilikom učitavanja podataka sa servera!');
    }

    return List.from(_dogadjaji);
  }

  @override
  Future<Dogadjaj> promeniStanje(DogadjajId id, StanjeDogadjaja novoStanje) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _dogadjaji.indexWhere((d) => d.id == id);
    if (index != -1) {
      final stari = _dogadjaji[index];
      final azurirani = Dogadjaj(
        id: stari.id,
        naziv: stari.naziv,
        stanje: novoStanje,
        kapacitet: stari.kapacitet,
        hostReputacija: stari.hostReputacija,
        opis: stari.opis,
      );
      _dogadjaji[index] = azurirani;
      return azurirani;
    }
    throw Exception('Događaj nije pronađen!');
  }

  @override
  Future<Dogadjaj> kreirajDogadjaj(Dogadjaj dogadjaj) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _dogadjaji.add(dogadjaj);
    return dogadjaj;
  }

  @override
  Future<Dogadjaj> promeniKapacitet(
      DogadjajId id,
      int noviKapacitet,
      ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _dogadjaji.indexWhere((d) => d.id == id);

    if (index != -1) {
      final azurirani = _dogadjaji[index].copyWith(
        kapacitet: noviKapacitet,
      );

      _dogadjaji[index] = azurirani;

      return azurirani;
    }

    throw Exception('Događaj nije pronađen!');
  }
}

extension StanjeUiExtension on StanjeDogadjaja {
  Color get boja {
    if (this is Preliminarni) return Colors.orange;
    if (this is Objavljen) return Colors.blue;
    if (this is OdrzavaSe) return Colors.green;
    if (this is Odrzan) return Colors.grey;
    if (this is Otkazan) return Colors.red;
    return Colors.black;
  }
}


class ListaDogadjajaScreen extends StatefulWidget {
  const ListaDogadjajaScreen({super.key});

  @override
  State<ListaDogadjajaScreen> createState() =>
      _ListaDogadjajaScreenState();
}

class _ListaDogadjajaScreenState extends State<ListaDogadjajaScreen> {
  double? _minimalnaReputacija;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Scheduler (Bloc)'),
        actions: [
          // Dugme za simulaciju greske
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Simuliraj grešku sledećeg zahteva',
            onPressed: () {
              final repo = BlocProvider.of<DogadjajBloc>(context)
                  .repository as MockDogadjajRepository;

              repo.setSimulirajGresku(true);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sledeći zahtev će izazvati grešku!'),
                ),
              );
            },
          ),

          // Promena teme
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => MainApp.of(context)?.toggleTheme(),
          ),

          // Otvaranje filtera
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtriraj po reputaciji hosta',
            onPressed: () async {
              final double? rezultat =
              await context.push<double>('/filter');

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
        ],
      ),

      body: BlocBuilder<DogadjajBloc, DogadjajState>(
        builder: (context, state) {

          //ucitavanje
          if (state is DogadjajiLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          //greska
          if (state is DogadjajiError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
                      context.push(
                        '/detalji',
                        extra: {
                          'dogadjaj': d,
                          'onOtkazi': () {
                            context.read<DogadjajBloc>().add(
                              PromeniStanjeEvent(
                                id: d.id,
                                novoStanje: const Otkazan(),
                              ),
                            );

                            Navigator.pop(context);
                          },
                        },
                      );
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
  State<FormaFilterScreen> createState() =>
      _FormaFilterScreenState();
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
      appBar: AppBar(
        title: const Text('Unos minimalne reputacije hosta'),
      ),

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
                    final double minimalnaReputacija =
                    double.parse(_controller.text.trim());

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
