import 'dart:io';

import 'package:postgres/postgres.dart';

class AppDatabase {
  final Pool<Object?> pool;

  AppDatabase._(this.pool);

  factory AppDatabase.fromEnvironment() {
    final env = Platform.environment;

    final endpoint = Endpoint(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.parse(env['DB_PORT'] ?? '5432'),
      database: env['DB_NAME'] ?? 'event_scheduler',
      username: env['DB_USER'] ?? 'event_user',
      password: env['DB_PASSWORD'] ?? 'development_password_change_me',
    );

    return AppDatabase._(
      Pool<Object?>.withEndpoints([
        endpoint,
      ], settings: PoolSettings(sslMode: SslMode.disable)),
    );
  }

  Future<void> close() {
    return pool.close();
  }
}
