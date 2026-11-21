import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';

import 'package:domain/domain.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';

import '../../database/app_database.dart';
import '../../database/password_hasher.dart';


class AuthException implements Exception {
  final String code;
  final int statusCode;

  const AuthException(this.code, this.statusCode);
}


class AuthService {
  final AppDatabase database;
  final PasswordHasher passwordHasher;
  final Duration sessionDuration;

  AuthService({
    required this.database,
    required this.passwordHasher,
    required this.sessionDuration,
  });


  Future<ApiLoginResponse> login({
    required String email,
    required String password,
    required String clientType,
  }) async {
    //find by email
    final result = await database.pool.execute(
      Sql.named('''
        SELECT
          id,
          name,
          email,
          role,
          reputation,
          is_banned,
          password_hash
        FROM users
        WHERE email = @email
      '''),
      parameters: {'email': email.trim().toLowerCase()},
    );

    if (result.isEmpty) {
      throw const AuthException('INVALID_CREDENTIALS', 401);
    }

    final row = result.first;

    final passwordHash = row[6] as String;

    //verify pass
    final validnaLozinka = await passwordHasher.verify(password, passwordHash);

    if (!validnaLozinka) {
      throw const AuthException('INVALID_CREDENTIALS', 401);
    }

    final role = ulogaFromApi(row[3] as String);
    final jeBanovan = row[5] as bool;

    if (jeBanovan) {
      throw const AuthException('ACCOUNT_BANNED', 403);
    }


    //moderator isn't accepted by mobile app
    if (clientType == 'MOBILE') {
      if (!jeMobilnaUloga(role)) {
        throw const AuthException('MOBILE_ROLE_REQUIRED', 403);
      }
    } else if (clientType == 'BACKOFFICE') {
      if (!jeBackofficeUloga(role)) {
        throw const AuthException('BACKOFFICE_ROLE_REQUIRED', 403);
      }
    } else {
      throw const AuthException('INVALID_REQUEST', 400);
    }

    //create session
    final token = _generisiToken();

    final expiresAt = DateTime.now().toUtc().add(sessionDuration);

    final tokenHash = await _hashToken(token);

    //hash
    await database.pool.execute(
      Sql.named('''
        INSERT INTO sessions (
          token_hash,
          user_id,
          expires_at
        )
        VALUES (
          @tokenHash,
          @userId,
          @expiresAt
        )
      '''),
      parameters: {
        'tokenHash': tokenHash,
        'userId': _asInt(row[0]),
        'expiresAt': expiresAt,
      },
    );

    //dto korisnika
    final korisnik = Korisnik(
      id: KorisnikId(_asInt(row[0])),
      ime: row[1] as String,
      email: row[2] as String,
      uloga: role,
      reputacija: _asDouble(row[4]),
      jeBanovan: jeBanovan,
    );

    return ApiLoginResponse(
      accessToken: token,
      expiresAt: expiresAt,
      user: korisnikToApi(korisnik),
    );
  }


  Future<void> logout(Request request) async {
    final token = _procitajToken(request);

    if (token == null) {
      return;
    }

    final tokenHash = await _hashToken(token);

    await database.pool.execute(
      Sql.named('''
        DELETE FROM sessions
        WHERE token_hash = @tokenHash
      '''),
      parameters: {'tokenHash': tokenHash},
    );
  }


  Future<Korisnik> requireUser(Request request) async {
    final token = _procitajToken(request);

    if (token == null) {
      throw const AuthException('UNAUTHENTICATED', 401);
    }

    final tokenHash = await _hashToken(token);

    final result = await database.pool.execute(
      Sql.named('''
        SELECT
          s.expires_at,
          u.id,
          u.name,
          u.email,
          u.role,
          u.reputation,
          u.is_banned
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.token_hash = @tokenHash
      '''),
      parameters: {'tokenHash': tokenHash},
    );

    if (result.isEmpty) {
      throw const AuthException('UNAUTHENTICATED', 401);
    }

    final row = result.first;

    final expiresAt = row[0] is DateTime
        ? (row[0] as DateTime).toUtc()
        : DateTime.parse(row[0].toString()).toUtc();


    if (!expiresAt.isAfter(DateTime.now().toUtc())) {
      await database.pool.execute(
        Sql.named('''
          DELETE FROM sessions
          WHERE token_hash = @tokenHash
        '''),
        parameters: {'tokenHash': tokenHash},
      );

      throw const AuthException('SESSION_EXPIRED', 401);
    }

    final jeBanovan = row[6] as bool;

    if (jeBanovan) {
      throw const AuthException('ACCOUNT_BANNED', 403);
    }

    return Korisnik(
      id: KorisnikId(_asInt(row[1])),
      ime: row[2] as String,
      email: row[3] as String,
      uloga: ulogaFromApi(row[4] as String),
      reputacija: _asDouble(row[5]),
      jeBanovan: jeBanovan,
    );
  }


  String _generisiToken() {
    final random = Random.secure();

    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> _hashToken(String token) async {
    final result = await Sha256().hash(utf8.encode(token));

    return result.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String? _procitajToken(Request request) {
    final authorization = request.headers.authorization;

    if (authorization is BearerAuthorizationHeader) {
      return authorization.token;
    }

    return null;
  }


  int _asInt(Object? value) {
    return int.parse(value.toString());
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.parse(value.toString());
  }
}
