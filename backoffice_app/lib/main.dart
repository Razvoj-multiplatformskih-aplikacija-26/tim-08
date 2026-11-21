import 'package:api_client/api_client.dart';
import 'package:event_scheduler_app/session_gate.dart';
import 'package:event_scheduler_app/moderator_accounts.dart';
import 'package:event_scheduler_app/event_action_feedback.dart';
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
  Widget build(BuildContext context) => SessionGate(
    backoffice: true,
    builder: (client, actor) => BlocProvider(
      create: (context) => DogadjajBloc(
        repository: RemoteDogadjajRepository(client: client),
        prijavaRepository: RemotePrijavaRepository(client: client),
        recenzijaRepository: RemoteRecenzijaRepository(client: client),
        trenutniKorisnik: actor,
      )..add(const UcitajDogadjajeEvent()),
      child: MaterialApp(
        title: 'Event Scheduler - Backoffice',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => EventActionFeedback(child: child!),
        home: BackofficeDashboardScreen(client: client),
      ),
    ),
  );
}

class BackofficeDashboardScreen extends StatefulWidget {
  const BackofficeDashboardScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<BackofficeDashboardScreen> createState() =>
      _BackofficeDashboardScreenState();
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

  void _pomeriIzbor(BuildContext context, int smer) {
    final stanje = context.read<DogadjajBloc>().state;

    if (stanje is! DogadjajiLoaded || stanje.dogadjaji.isEmpty) {
      return;
    }

    final dogadjaji = stanje.dogadjaji;

    final trenutniIndex = dogadjaji.indexWhere(
      (d) => d.id == _selektovaniDogadjaj?.id,
    );

    int sledeciIndex;

    if (trenutniIndex == -1) {
      sledeciIndex = smer > 0 ? 0 : dogadjaji.length - 1;
    } else {
      sledeciIndex = (trenutniIndex + smer)
          .clamp(0, dogadjaji.length - 1)
          .toInt();
    }

    setState(() {
      _selektovaniDogadjaj = dogadjaji[sledeciIndex];
    });
  }

  Future<void> _izmeniKapacitet(Dogadjaj dogadjaj) async {
    final noviKapacitet = await showDialog<int>(
      context: context,
      builder: (context) {
        return _IzmenaKapacitetaDialog(pocetniKapacitet: dogadjaj.kapacitet);
      },
    );

    if (!mounted || noviKapacitet == null) {
      return;
    }

    context.read<DogadjajBloc>().add(
      PromeniKapacitetEvent(id: dogadjaj.id, noviKapacitet: noviKapacitet),
    );
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
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          _pomeriIzbor(context, 1);
        },

        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          _pomeriIzbor(context, -1);
        },
      },
      child: Focus(
        focusNode: _focusNode,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Backoffice - Upravljanje Događajima (Osoblje)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Osveži',
                onPressed: () => context.read<DogadjajBloc>().add(
                  const UcitajDogadjajeEvent(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.manage_accounts),
                tooltip: 'Nalozi',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModeratorAccounts(
                      client: widget.client,
                      actor: context.read<DogadjajBloc>().trenutniKorisnik,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Odjavi se',
                onPressed: () => SessionGate.of(context).signOut(),
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
                return const Center(
                  child: Text('Nema unetih događaja u sistemu.'),
                );
              }
              if (state is DogadjajiLoaded) {
                final dogadjaji = state.dogadjaji;

                if (_selektovaniDogadjaj != null) {
                  try {
                    _selektovaniDogadjaj = dogadjaji.firstWhere(
                      (d) => d.id == _selektovaniDogadjaj!.id,
                    );
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
                              selected: _selektovaniDogadjaj?.id == d.id,
                              selectedTileColor: Colors.indigo.withValues(
                                alpha: 0.25,
                              ),
                              title: Text(d.naziv),
                              subtitle: Text('Stanje: ${d.stanje.naziv}'),
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
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.indigo.withValues(),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Naziv događaja')),
                                    DataColumn(label: Text('Kapacitet')),
                                    DataColumn(label: Text('Reputacija')),
                                    DataColumn(label: Text('Stanje')),
                                  ],
                                  rows: dogadjaji.map((d) {
                                    final bool isSelected =
                                        _selektovaniDogadjaj?.id == d.id;
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
                                        DataCell(Text(d.stanje.naziv)),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Detalji zapisa (Bočni panel)',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigoAccent,
                                            ),
                                          ),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Text(
                                            'ID: ${_selektovaniDogadjaj!.id}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Naziv: ${_selektovaniDogadjaj!.naziv}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Text(
                                            'Kapacitet: ${_selektovaniDogadjaj!.kapacitet}',
                                          ),
                                          const SizedBox(height: 8),

                                          OutlinedButton.icon(
                                            onPressed: () {
                                              _izmeniKapacitet(
                                                _selektovaniDogadjaj!,
                                              );
                                            },
                                            icon: const Icon(Icons.edit),
                                            label: const Text(
                                              'Izmeni kapacitet',
                                            ),
                                          ),

                                          const SizedBox(height: 8),
                                          Text(
                                            'Reputacija hosta: ${_selektovaniDogadjaj!.hostReputacija}',
                                          ),

                                          const SizedBox(height: 8),
                                          Text(
                                            'Opis: ${_selektovaniDogadjaj!.opis}',
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Trenutno stanje: ${_selektovaniDogadjaj!.stanje.runtimeType}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                          const Spacer(),

                                          const Text(
                                            'Akcije osoblja:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Builder(
                                            builder: (context) {
                                              // Proveravamo koje akcije su dozvoljene
                                              final dogadjaj =
                                                  _selektovaniDogadjaj!;
                                              final actor = context
                                                  .read<DogadjajBloc>()
                                                  .trenutniKorisnik;

                                              final mozeOtkazati =
                                                  mozePromenitiStanjeDogadjaja(
                                                    actor,
                                                    dogadjaj,
                                                    const Otkazan(),
                                                  );

                                              return Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      onPressed: mozeOtkazati
                                                          ? () {
                                                              context
                                                                  .read<
                                                                    DogadjajBloc
                                                                  >()
                                                                  .add(
                                                                    PromeniStanjeEvent(
                                                                      id: dogadjaj
                                                                          .id,
                                                                      novoStanje:
                                                                          const Otkazan(),
                                                                    ),
                                                                  );
                                                            }
                                                          : null,
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                      ),
                                                      label: const Text(
                                                        'Otkaži',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
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

class _IzmenaKapacitetaDialog extends StatefulWidget {
  final int pocetniKapacitet;

  const _IzmenaKapacitetaDialog({required this.pocetniKapacitet});

  @override
  State<_IzmenaKapacitetaDialog> createState() =>
      _IzmenaKapacitetaDialogState();
}

class _IzmenaKapacitetaDialogState extends State<_IzmenaKapacitetaDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.pocetniKapacitet.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Izmena kapaciteta'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Novi kapacitet'),
          validator: (value) {
            final broj = int.tryParse(value ?? '');

            if (broj == null || broj <= 0) {
              return 'Unesite pozitivan ceo broj.';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(int.parse(_controller.text));
            }
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
