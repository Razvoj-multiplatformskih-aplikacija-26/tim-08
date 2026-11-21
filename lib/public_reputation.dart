import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:flutter/material.dart';

class PublicReputation extends StatefulWidget {
  const PublicReputation({super.key, required this.client});

  final ApiClient client;

  @override
  State<PublicReputation> createState() => _PublicReputationState();
}

class _PublicReputationState extends State<PublicReputation> {
  late Future<List<ApiPublicUserDto>> _users = _load();

  Future<List<ApiPublicUserDto>> _load() async =>
      (await widget.client.getList(ApiRoutes.users))
          .map(ApiPublicUserDto.fromJson)
          .where((user) => user.role != 'MODERATOR')
          .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reputacije'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Osvezi',
          onPressed: () => setState(() => _users = _load()),
        ),
      ],
    ),
    body: FutureBuilder(
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
                  : 'Ucitavanje reputacija nije uspelo',
            ),
          );
        }
        final users = snapshot.requireData;
        return ListView(
          children: [
            for (final user in users)
              ListTile(
                title: Text(user.name),
                subtitle: Text(user.role == 'HOST' ? 'Host' : 'Korisnik'),
                trailing: Text('${user.reputation.toStringAsFixed(2)} / 5'),
              ),
          ],
        );
      },
    ),
  );
}
