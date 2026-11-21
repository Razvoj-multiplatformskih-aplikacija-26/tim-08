import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class ModeratorAccounts extends StatefulWidget {
  const ModeratorAccounts({
    super.key,
    required this.client,
    required this.actor,
  });

  final ApiClient client;
  final Korisnik actor;

  @override
  State<ModeratorAccounts> createState() => _ModeratorAccountsState();
}

class _ModeratorAccountsState extends State<ModeratorAccounts> {
  late Future<List<Korisnik>> _users = _load();
  bool _saving = false;

  Future<List<Korisnik>> _load() async {
    final rows = await widget.client.getList(ApiRoutes.users);
    return rows
        .map((row) => korisnikFromApi(ApiUserDto.fromJson(row)))
        .toList();
  }

  void _refresh() => setState(() => _users = _load());

  Future<void> _save(String path, Map<String, Object?> body) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.client.patchObject(path, body: body);
    } on ApiHttpException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _refresh();
      }
    }
  }

  Future<void> _changeReputation(Korisnik user) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _ReputationDialog(user.reputacija),
    );
    if (result == null || !mounted) return;
    await _save(
      ApiRoutes.userReputation(user.id.value),
      ApiChangeUserReputationRequest(reputation: result).toJson(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nalozi'),
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Osvezi',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Korisnik>>(
      future: _users,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error is ApiHttpException
                  ? snapshot.error.toString()
                  : 'Ucitavanje naloga nije uspelo.',
            ),
          );
        }
        final users = snapshot.requireData;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.ime),
              subtitle: Text(
                '${user.email} · ${ulogaToApi(user.uloga)} · ${user.reputacija.toStringAsFixed(2)}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Promeni reputaciju',
                    onPressed: _saving || !mozeMenjatiReputaciju(widget.actor)
                        ? null
                        : () => _changeReputation(user),
                    icon: const Icon(Icons.star),
                  ),
                  IconButton(
                    tooltip: user.jeBanovan
                        ? 'Odblokiraj nalog'
                        : 'Blokiraj nalog',
                    onPressed:
                        _saving || !mozeBanovatiKorisnika(widget.actor, user)
                        ? null
                        : () => _save(
                            ApiRoutes.userBan(user.id.value),
                            ApiChangeBanRequest(
                              isBanned: !user.jeBanovan,
                            ).toJson(),
                          ),
                    icon: Icon(user.jeBanovan ? Icons.lock_open : Icons.block),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _ReputationDialog extends StatefulWidget {
  const _ReputationDialog(this.initial);
  final double initial;

  @override
  State<_ReputationDialog> createState() => _ReputationDialogState();
}

class _ReputationDialogState extends State<_ReputationDialog> {
  late final _value = TextEditingController(
    text: widget.initial.toStringAsFixed(2),
  );
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Promeni reputaciju'),
    content: TextField(
      controller: _value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Reputacija (1–5)',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Otkazi'),
      ),
      FilledButton(
        onPressed: () {
          final value = double.tryParse(_value.text.replaceAll(',', '.'));
          if (value == null ||
              proveriReputacijuHosta(value) is GreskaValidacije) {
            setState(() => _error = 'Reputacija mora biti između 1 i 5.');
            return;
          }
          Navigator.pop(context, value);
        },
        child: const Text('Sacuvaj'),
      ),
    ],
  );
}
