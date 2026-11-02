import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'package:blocs/blocs.dart';

void main() {
  runApp(const BackofficeApp());
}

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DogadjajBloc(
        repository: MockBackofficeRepository(),
      )..add(UcitajDogadjajeEvent()),
      child: MaterialApp(
        title: 'Event Scheduler - Backoffice',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const BackofficeDashboardScreen(),
      ),
    );
  }
}

class MockBackofficeRepository implements DogadjajRepository {
  final List<Dogadjaj> _dogadjaji = [
    Dogadjaj(id: DogadjajId(1), naziv: 'Bajaga i instruktori comeback tour, Subotica', stanje: PustenUJavnost(), kapacitet: 120, hostReputacija: 4.8, opis:'Posle 5 godina kuvanja novog albuma...'),
    Dogadjaj(id: DogadjajId(2), naziv: 'Prljavo skladište tour, Batajnica', stanje: Preliminarni(), kapacitet: 30, hostReputacija: 2.2, opis:'Opis 2'),
    Dogadjaj(id: DogadjajId(3), naziv: 'Mongolian Throat Singing Festival, Konjarnik', stanje: OdrzavaSe(), kapacitet: 80, hostReputacija: 3.9, opis:'Opis 3'),
    Dogadjaj(id: DogadjajId(4), naziv: 'Kokoške za KFC, New album tour', stanje: Odrzan(), kapacitet: 50, hostReputacija: 3.5, opis:'Opis 4'),
    Dogadjaj(id: DogadjajId(5), naziv: 'Yuno Miles dolazi u Karaburmu!', stanje: Otkazan(), kapacitet: 100, hostReputacija: 4.0, opis:'Opis 5'),
  ];

  @override
  Future<List<Dogadjaj>> getDogadjaji() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_dogadjaji);
  }

  @override
  Future<Dogadjaj> promeniStanje(DogadjajId id, StanjeDogadjaja novoStanje) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
    throw Exception('Događaj nije pronađen');
  }

  @override
  Future<Dogadjaj> kreirajDogadjaj(Dogadjaj dogadjaj) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _dogadjaji.add(dogadjaj);
    return dogadjaj;
  }
}

class BackofficeDashboardScreen extends StatefulWidget {
  const BackofficeDashboardScreen({super.key});

  @override
  State<BackofficeDashboardScreen> createState() => _BackofficeDashboardScreenState();
}

class _BackofficeDashboardScreenState extends State<BackofficeDashboardScreen> {
  Dogadjaj? _selektovaniDogadjaj;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR): () {
          BlocProvider.of<DogadjajBloc>(context).add(UcitajDogadjajeEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Osveženi podaci preko prečice (R)!')),
          );
        },
      },
      child: Focus(
        focusNode: _focusNode,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Backoffice - Upravljanje Događajima (Osoblje)'),
            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    'Prečice: [R] Osveži',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          body: BlocBuilder<DogadjajBloc, DogadjajState>(
            builder: (context, state) {
              if (state is DogadjajiLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DogadjajiError) {
                return Center(child: Text('Greška: ${state.poruka}'));
              }
              if (state is DogadjajiEmpty) {
                return const Center(child: Text('Nema unetih događaja u sistemu.'));
              }
              if (state is DogadjajiLoaded) {
                final dogadjaji = state.dogadjaji;
                
                if (_selektovaniDogadjaj != null) {
                  try {
                    _selektovaniDogadjaj = dogadjaji.firstWhere((d) => d.id == _selektovaniDogadjaj!.id);
                  } catch (_) {
                    _selektovaniDogadjaj = null;
                  }
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWideScreen = constraints.maxWidth > 800;

                    if (!isWideScreen) {
                      return ListView.builder(
                        itemCount: dogadjaji.length,
                        itemBuilder: (context, index) {
                          final d = dogadjaji[index];
                          return Card(
                            child: ListTile(
                              title: Text(d.naziv),
                              subtitle: Text('Stanje: ${d.stanje.runtimeType}'),
                              onTap: () {
                                setState(() {
                                  _selektovaniDogadjaj = d;
                                });
                              },
                            ),
                          );
                        },
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Card(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  headingRowColor: WidgetStateProperty.all(Colors.indigo.withValues()),
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Naziv događaja')),
                                    DataColumn(label: Text('Kapacitet')),
                                    DataColumn(label: Text('Reputacija')),
                                    DataColumn(label: Text('Stanje')),
                                  ],
                                  rows: dogadjaji.map((d) {
                                    final bool isSelected = _selektovaniDogadjaj?.id == d.id;
                                    return DataRow(
                                      selected: isSelected,
                                      onSelectChanged: (_) {
                                        setState(() {
                                          _selektovaniDogadjaj = d;
                                        });
                                      },
                                      cells: [
                                        DataCell(Text('${d.id}')),
                                        DataCell(Text(d.naziv)),
                                        DataCell(Text('${d.kapacitet}')),
                                        DataCell(Text('${d.hostReputacija}')),
                                        DataCell(Text(d.stanje.runtimeType.toString())),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _selektovaniDogadjaj == null
                                    ? const Center(
                                        child: Text(
                                          'Izaberite red iz tabele da biste videli detalje i izvršili akcije osoblja.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Detalji zapisa (Bočni panel)',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                                          ),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Text('ID: ${_selektovaniDogadjaj!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text('Naziv: ${_selektovaniDogadjaj!.naziv}', style: const TextStyle(fontSize: 16)),
                                          const SizedBox(height: 8),
                                          Text('Kapacitet: ${_selektovaniDogadjaj!.kapacitet}'),
                                          const SizedBox(height: 8),
                                          Text('Reputacija hosta: ${_selektovaniDogadjaj!.hostReputacija}'),
                                          const SizedBox(height: 8),
                                          Text('Opis: ${_selektovaniDogadjaj!.opis}'),
                                          const SizedBox(height: 16),
                                          Text('Trenutno stanje: ${_selektovaniDogadjaj!.stanje.runtimeType}', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                          const Spacer(),
                                          const Text('Akcije osoblja:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                  onPressed: (_selektovaniDogadjaj!.stanje is Otkazan || _selektovaniDogadjaj!.stanje is Odrzan)
                                                      ? null
                                                      : () {
                                                          BlocProvider.of<DogadjajBloc>(context).add(
                                                            PromeniStanjeEvent(id: _selektovaniDogadjaj!.id, novoStanje: Otkazan()),
                                                          );
                                                        },
                                                  icon: const Icon(Icons.cancel),
                                                  label: const Text('Otkaži'),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                  onPressed: () {
                                                    BlocProvider.of<DogadjajBloc>(context).add(
                                                      PromeniStanjeEvent(id: _selektovaniDogadjaj!.id, novoStanje: PustenUJavnost()),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.check_circle),
                                                  label: const Text('Aktiviraj'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}