import 'dart:convert';
import 'dart:io';

import 'package:relic/relic.dart';

import 'package:api_contract/api_contract.dart';

import 'database/app_database.dart';
import 'database/seed_database.dart';
import 'database/password_hasher.dart';

import 'auth/auth_service.dart';
import 'auth/auth_routes.dart';
import 'events/event_routes.dart';
import 'events/registration_notifications.dart';

Future<void> main() async {
  final env = Platform.environment;

  final port = int.parse(env['PORT'] ?? '8080');

  final sessionHours = int.tryParse(env['SESSION_TTL_HOURS'] ?? '24') ?? 24;

  final database = AppDatabase.fromEnvironment();

  try {

    await seedDatabase(database);


    final authService = AuthService(
      database: database,
      passwordHasher: PasswordHasher(),
      sessionDuration: Duration(hours: sessionHours),
    );

    final authRoutes = AuthRoutes(authService);

    final app = RelicApp()

      ..get('/health', (request) {
        return Response.ok(
          body: Body.fromString(
            jsonEncode({'status': 'ok', 'service': 'event-scheduler-server'}),
            mimeType: MimeType.json,
          ),
        );
      })

      ..post(ApiRoutes.login, authRoutes.login)

      ..post(ApiRoutes.logout, authRoutes.logout)

      ..get(ApiRoutes.me, authRoutes.currentUser);

    EventRoutes(
      database,
      authService,
      const DevelopmentRegistrationNotifications(),
    ).register(app);

    final server = RelicServer(
      () => IOAdapter.bind(InternetAddress.anyIPv4, port: port),
    );
    await server.mountAndStart(_withCors(app.asHandler));
    stdout.writeln('Event Scheduler server running on port $port');
  } catch (_) {
    await database.close();
    rethrow;
  }
}

Handler _withCors(Handler next) => (request) async {
  final result = request.method == Method.options
      ? Response.noContent()
      : await next(request);
  if (result is! Response) return result;
  return result.copyWith(
    headers: result.headers.transform((headers) {
      headers['access-control-allow-origin'] = ['*'];
      headers['access-control-allow-methods'] = [
        'GET, POST, PATCH, DELETE, OPTIONS',
      ];
      headers['access-control-allow-headers'] = ['Authorization, Content-Type'];
    }),
  );
};
