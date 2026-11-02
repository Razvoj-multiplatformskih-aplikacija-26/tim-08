import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';

void main() {
  runApp(const MainApp());
}

//GoRouter
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
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
        return DetaljiDogadjajaScreen(
          dogadjaj: args['dogadjaj'],
          onOtkazi: args['onOtkazi'],
        );
      },
    ),
  ],
);

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
  
  // static metoda gde implementiramo light/dark mode
  static MainAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainAppState>();
}

class MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  // Funkcija koja menja mod
  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sistem za zakazivanje dogadjaja',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode, // Ovde prosleđujemo trenutni režim
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

extension StanjeUiExtension on StanjeDogadjaja {
  Color get boja {
    if (this is Preliminarni) return Colors.orange;
    if (this is PustenUJavnost) return Colors.blue;
    if (this is OdrzavaSe) return Colors.green;
    if (this is Odrzan) return Colors.grey;
    if (this is Otkazan) return Colors.red;
    return Colors.black;
  }
}

// lažni podaci
final List<Dogadjaj> lazniDogadjaji = [
  Dogadjaj(id: '1', naziv: 'Bajaga i instruktori comeback tour, Subotica', stanje: PustenUJavnost(), kapacitet: 120, hostReputacija: 4.8, opis:'Posle 5 godina kuvanja novog albuma, Bajaga i instruktori se vraćaju nazad jače nego ikad u ovoj novoj comeback turi!'),
  Dogadjaj(id: '2', naziv: 'Prljavo skladište tour, Batajnica', stanje: Preliminarni(), kapacitet: 30, hostReputacija: 2.2, opis:'<Insert opis here>'),
  Dogadjaj(id: '3', naziv: 'Mongolian Throat Singing Festival, Konjarnik', stanje: OdrzavaSe(), kapacitet: 80, hostReputacija: 3.9, opis:'<Insert opis here>'),
  Dogadjaj(id: '4', naziv: 'Kokoške za KFC, New album tour, Padinačka skela', stanje: Odrzan(), kapacitet: 50, hostReputacija: 3.5, opis:'<Insert opis here>'),
  Dogadjaj(id: '5', naziv: 'Yuno Miles dolazi u Karaburmu!', stanje: Otkazan(), kapacitet: 100, hostReputacija: 4.0, opis:'Yuno Miles, popularni američki reper, dolazi u Karaburmu da blagoslovi ovo naselje svojim prisustvom (i vrhunskim pesmama)!'),
  Dogadjaj(id: '6', naziv: 'Karotidne Arterije, New album tour, Pećinci', stanje: PustenUJavnost(), kapacitet: 40, hostReputacija: 4.2, opis:'<Insert opis here>'),
  Dogadjaj(id: '7', naziv: 'Kino koncert, Omladinski stadion, Beograd', stanje: Preliminarni(), kapacitet: 60, hostReputacija: 5.0, opis:'<Insert opis here>'),
  Dogadjaj(id: '8', naziv: 'Burme Karaburme Reunion concert, Višnjička Banja', stanje: OdrzavaSe(), kapacitet: 90, hostReputacija: 4.7, opis:'<Insert opis here>'),
  Dogadjaj(id: '9', naziv: 'Palanačke Palme comeback tour, Sve Palanke u Srbiji', stanje: Odrzan(), kapacitet: 70, hostReputacija: 3.3, opis:'Palanačke Palme su smotale nov album i sad idu na turneju! Lokacije: Smederevska Palanka, Bačka Palanka, Bela Palanka, Kriva Palanka, neka peta Palanka ne znam'),
  Dogadjaj(id: '10', naziv: 'Michael Jackson comeback tour', stanje: Otkazan(), kapacitet: 150, hostReputacija: 2.0, opis:'Nahhhhhh i dalje je mrtav'),
];

class ListaDogadjajaScreen extends StatefulWidget {
  const ListaDogadjajaScreen({super.key});

  @override
  State<ListaDogadjajaScreen> createState() => _ListaDogadjajaScreenState();
}

class _ListaDogadjajaScreenState extends State<ListaDogadjajaScreen> {
  List<Dogadjaj> dogadjaji = List.from(lazniDogadjaji);

  void _otkaziDogadjaj(Dogadjaj dogadjaj) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda otkazivanja'),
        content: Text('Da li ste sigurni da želite da otkažete dogadjaj "${dogadjaj.naziv}"? Ova akcija je nepovratna.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                dogadjaji = dogadjaji.map<Dogadjaj>((d) {
                  if (d.id == dogadjaj.id) {
                    return Dogadjaj(
                      id: d.id,
                      naziv: d.naziv,
                      stanje: Otkazan(),
                      kapacitet: d.kapacitet,
                      hostReputacija: d.hostReputacija,
                      opis: d.opis,
                    );
                  }
                  return d;
                }).toList();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dogadjaj je uspešno otkazan.')),
              );
            },
            child: const Text('Otkaži dogadjaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Scheduler'),
        actions: [
          IconButton( //dugme za light/dark mode
            icon: const Icon(Icons.brightness_6),
              onPressed: () {
              MainApp.of(context)?.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final double? minimalnaReputacija = await context.push<double>('/filter');
              
              if (minimalnaReputacija != null) {
                setState(() {
                  dogadjaji = lazniDogadjaji.where((d) => d.hostReputacija >= minimalnaReputacija).toList();
                });
              }
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: dogadjaji.length,
        itemBuilder: (context, index) {
          final d = dogadjaji[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(d.naziv, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Kapacitet: ${d.kapacitet} | Reputacija: ${d.hostReputacija}'),
              trailing: Chip(
                label: Text(d.stanje.naziv, style: const TextStyle(color: Colors.white)),
                backgroundColor: d.stanje.boja,
              ),
              onTap: () {
                context.push(
                  '/detalji',
                  extra: {
                    'dogadjaj': d,
                    'onOtkazi': () => _otkaziDogadjaj(d),
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
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
            Text(
              'Opis: ${dogadjaj.opis}', 
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: dogadjaj.stanje is Otkazan ? null : onOtkazi,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Otkaži događaj (Nepovratna akcija)'),
                ),
              ),
          ],
        ),
      ),
    ); 
  }
}

//Forma sa pravilom
class FormaFilterScreen extends StatefulWidget {
  const FormaFilterScreen({super.key});

  @override
  State<FormaFilterScreen> createState() => _FormaFilterScreenState();
}

class _FormaFilterScreenState extends State<FormaFilterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

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
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimalna reputacija (1.0 - 5.0)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Polje ne sme biti prazno!';
                  }
                  final broj = double.tryParse(value);
                  if (broj == null) {
                    return 'Unesite validan broj!';
                  }
                  if (broj < 1.0 || broj > 5.0) {
                    return 'Reputacija mora biti u opsegu između 1.0 i 5.0!'; // Pravilo opsega za reputaciju
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final double minimalnaReputacija = double.parse(_controller.text);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uspešno primenjen filter!')),
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