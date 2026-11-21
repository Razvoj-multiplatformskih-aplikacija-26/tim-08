import 'dart:io';
import 'package:postgres/postgres.dart';

import 'app_database.dart';
import 'password_hasher.dart';

Future<void> seedDatabase(AppDatabase database) async {
  //check if database exists
  final result = await database.pool.execute('SELECT COUNT(*) FROM users');

  final existingUsers = int.parse(result.first[0].toString());

  if (existingUsers > 0) {
    stdout.writeln('Database already contains data. Skipping seed.');
    return;
  }

  stdout.writeln('Database is empty. Inserting initial data...');

  final hasher = PasswordHasher();

  // These are development-only passwords for the demo accounts.
  final passwords = [
    'ana12345',
    'marko12345',
    'dragan12345',
    'moderator12345',
    'jelena12345',
  ];

  final passwordHashes = <String>[];

  for (final password in passwords) {
    passwordHashes.add(await hasher.hash(password));
  }

  final users = <Map<String, Object?>>[
    {
      'id': 1,
      'name': 'Ana Host',
      'email': 'ana@gmail.com',
      'role': 'HOST',
      'reputation': 4.8,
      'isBanned': false,
      'passwordHash': passwordHashes[0],
    },
    {
      'id': 2,
      'name': 'Marko Korisnik',
      'email': 'marko@gmail.com',
      'role': 'USER',
      'reputation': 4.2,
      'isBanned': false,
      'passwordHash': passwordHashes[1],
    },
    {
      'id': 3,
      'name': 'Dragan Host',
      'email': 'dragan@gmail.com',
      'role': 'HOST',
      'reputation': 4.1,
      'isBanned': false,
      'passwordHash': passwordHashes[2],
    },
    {
      'id': 4,
      'name': 'Demo Moderator',
      'email': 'moderator@gmail.com',
      'role': 'MODERATOR',
      'reputation': 3.0,
      'isBanned': false,
      'passwordHash': passwordHashes[3],
    },
    {
      'id': 5,
      'name': 'Jelena Korisnik',
      'email': 'jelena@gmail.com',
      'role': 'USER',
      'reputation': 3.9,
      'isBanned': false,
      'passwordHash': passwordHashes[4],
    },
  ];

  final events = <Map<String, Object?>>[
    {
      'id': 1,
      'hostId': 1,
      'title': 'Letnji koncert u Subotici',
      'description': 'Veliki letnji koncert.',
      'state': 'PRELIMINARY',
      'capacity': 120,
    },
    {
      'id': 2,
      'hostId': 3,
      'title': 'Festival u Batajnici',
      'description': 'Muzicki festival.',
      'state': 'PUBLISHED',
      'capacity': 30,
    },
    {
      'id': 3,
      'hostId': 3,
      'title': 'Vece akusticne muzike',
      'description': 'Akusticni nastupi lokalnih izvodjaca.',
      'state': 'ONGOING',
      'capacity': 80,
    },
    {
      'id': 4,
      'hostId': 1,
      'title': 'Kokoške za KFC',
      'description': 'Dogadjaj broj 4.',
      'state': 'COMPLETED',
      'capacity': 50,
    },
    {
      'id': 5,
      'hostId': 3,
      'title': 'Yuno Miles Reunion',
      'description': 'Dogadjaj broj 5.',
      'state': 'CANCELLED',
      'capacity': 100,
    },
    {
      'id': 6,
      'hostId': 3,
      'title': 'Karotidne arterije',
      'description': 'Dogadjaj broj 6.',
      'state': 'PUBLISHED',
      'capacity': 40,
    },
    {
      'id': 7,
      'hostId': 1,
      'title': 'Kino koncert',
      'description': 'Dogadjaj broj 7.',
      'state': 'PRELIMINARY',
      'capacity': 60,
    },
    {
      'id': 8,
      'hostId': 3,
      'title': 'Burme Karaburme Reunion',
      'description': 'Dogadjaj broj 8.',
      'state': 'ONGOING',
      'capacity': 90,
    },
    {
      'id': 9,
      'hostId': 3,
      'title': 'Palanačke Palme Reunion',
      'description': 'Dogadjaj broj 9.',
      'state': 'COMPLETED',
      'capacity': 70,
    },
    {
      'id': 10,
      'hostId': 3,
      'title': 'Michael Jackson Reunion',
      'description': 'Dogadjaj broj 10.',
      'state': 'CANCELLED',
      'capacity': 150,
    },
  ];

  final registrations = <Map<String, Object?>>[
    {'id': 1, 'eventId': 2, 'userId': 2, 'status': 'ACTIVE'},
    {'id': 2, 'eventId': 2, 'userId': 5, 'status': 'ACTIVE'},
    {'id': 3, 'eventId': 4, 'userId': 2, 'status': 'ACTIVE'},
  ];

  //insert everything
  await database.pool.runTx((tx) async {
    for (final user in users) {
      await tx.execute(
        Sql.named('''
          INSERT INTO users (
            id,
            name,
            email,
            role,
            reputation,
            is_banned,
            password_hash
          )
          VALUES (
            @id,
            @name,
            @email,
            @role,
            @reputation,
            @isBanned,
            @passwordHash
          )
        '''),
        parameters: user,
      );
    }

    for (final event in events) {
      await tx.execute(
        Sql.named('''
          INSERT INTO events (
            id,
            host_id,
            title,
            description,
            state,
            capacity
          )
          VALUES (
            @id,
            @hostId,
            @title,
            @description,
            @state,
            @capacity
          )
        '''),
        parameters: event,
      );
    }

    for (final registration in registrations) {
      await tx.execute(
        Sql.named('''
          INSERT INTO registrations (
            id,
            event_id,
            user_id,
            status
          )
          VALUES (
            @id,
            @eventId,
            @userId,
            @status
          )
        '''),
        parameters: registration,
      );
    }


    for (final table in ['users', 'events', 'registrations']) {
      await tx.execute(
        "SELECT setval("
        "pg_get_serial_sequence('$table', 'id'), "
        "(SELECT COALESCE(MAX(id), 1) FROM $table)"
        ")",
      );
    }
  });

  stdout.writeln(
    'Seed completed: '
    '${users.length} users, '
    '${events.length} events, '
    '${registrations.length} registrations.',
  );
}
