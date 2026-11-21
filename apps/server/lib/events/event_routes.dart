import 'dart:convert';
import 'dart:developer' as developer;

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';

import '../auth/auth_service.dart';
import '../database/app_database.dart';
import 'registration_notifications.dart';

class EventRoutes {
  EventRoutes(this.database, this.auth, this.notifications);

  final AppDatabase database;
  final AuthService auth;
  final RegistrationNotifications notifications;

  static const _eventQuery = '''
    SELECT e.id, e.host_id, e.title, e.description, e.state, e.capacity,
           u.reputation
    FROM events e
    JOIN users u ON u.id = e.host_id
  ''';

  void register(RelicApp app) {
    const event = '${ApiRoutes.events}/:id';
    app
      ..get(ApiRoutes.events, (request) => _handle(() => _list(request)))
      ..get(event, (request) => _handle(() => _get(request)))
      ..post(ApiRoutes.events, (request) => _handle(() => _create(request)))
      ..patch('$event/state', (request) => _handle(() => _changeState(request)))
      ..patch(
        '$event/capacity',
        (request) => _handle(() => _changeCapacity(request)),
      )
      ..get(
        ApiRoutes.myRegistrations,
        (r) => _handle(() => _myRegistrations(r)),
      )
      ..get(
        '$event/registrations/count',
        (r) => _handle(() => _registrationCount(r)),
      )
      ..post('$event/registrations', (r) => _handle(() => _register(r)))
      ..delete(
        '/api/v1/registrations/:id',
        (r) => _handle(() => _cancelRegistration(r)),
      )
      ..get(ApiRoutes.reviews, (r) => _handle(() => _reviews(r)))
      ..get('$event/reviews', (r) => _handle(() => _reviews(r, _id(r))))
      ..post('$event/reviews', (r) => _handle(() => _review(r)))
      ..get(ApiRoutes.users, (r) => _handle(() => _users(r)))
      ..get(
        '${ApiRoutes.users}/:id',
        (r) => _handle(() => _users(r, id: _id(r))),
      )
      ..patch(
        '${ApiRoutes.users}/:id/ban',
        (r) => _handle(() => _moderate(r, ban: true)),
      )
      ..patch(
        '${ApiRoutes.users}/:id/reputation',
        (r) => _handle(() => _moderate(r, ban: false)),
      );
  }

  static const _registrationColumns = 'id, event_id, user_id, status';
  static const _reviewColumns = 'id, event_id, author_id, rating, comment';
  static const _userColumns = 'id, name, email, role, reputation, is_banned';

  Future<Response> _myRegistrations(Request request) async {
    final user = await auth.requireUser(request);
    final rows = await database.pool.execute(
      Sql.named(
        'SELECT $_registrationColumns FROM registrations WHERE user_id = @user ORDER BY id',
      ),
      parameters: {'user': user.id.value},
    );
    return _json(200, rows.map((row) => _registration(row).toJson()).toList());
  }

  Future<Response> _registrationCount(Request request) async {
    final actor = await _optionalUser(request);
    final id = _id(request);
    _checkVisibility(await _find(database.pool, id), actor);
    return _json(200, {'count': await _count(database.pool, id)});
  }

  Future<int> _count(Session session, int id) async {
    final rows = await session.execute(
      Sql.named(
        "SELECT COUNT(*) FROM registrations WHERE event_id = @id AND status = 'ACTIVE'",
      ),
      parameters: {'id': id},
    );
    return rows.single[0] as int;
  }

  Future<Response> _register(Request request) async {
    final user = await auth.requireUser(request);
    final id = _id(request);
    final registration = await database.pool.runTx((tx) async {
      final users = await tx.execute(
        Sql.named('SELECT $_userColumns FROM users WHERE id = @id FOR UPDATE'),
        parameters: {'id': user.id.value},
      );
      final currentUser = korisnikFromApi(_user(users.single));
      final event = dogadjajFromApi(await _find(tx, id, lock: true));
      if (currentUser.jeBanovan ||
          currentUser.uloga != UlogaKorisnika.korisnik) {
        throw const AuthException('FORBIDDEN', 403);
      }
      if (!mozeSePrijavitiNaDogadjaj(currentUser, event)) {
        throw const AuthException('EVENT_REGISTRATION_CLOSED', 409);
      }
      if (await _activeRegistration(tx, id, user.id.value) != null) {
        throw const AuthException('DUPLICATE_REGISTRATION', 409);
      }
      final count = await _count(tx, id);
      _validate(proveriSlobodnaMesta(event.kapacitet, count), 409, {
        'capacity': event.kapacitet,
        'activeRegistrations': count,
      });
      final rows = await tx.execute(
        Sql.named(
          'INSERT INTO registrations (event_id, user_id) VALUES (@id, @user) RETURNING $_registrationColumns',
        ),
        parameters: {'id': id, 'user': user.id.value},
      );
      return _registration(rows.single);
    });
    try {
      await notifications.confirm(prijavaFromApi(registration));
    } catch (error, stack) {
      developer.log(
        'Registration notification failed',
        error: error,
        stackTrace: stack,
      );
    }
    return _json(201, registration.toJson());
  }

  Future<ApiRegistrationDto?> _activeRegistration(
    Session session,
    int id,
    int user,
  ) async {
    final rows = await session.execute(
      Sql.named(
        "SELECT $_registrationColumns FROM registrations WHERE event_id = @id AND user_id = @user AND status = 'ACTIVE'",
      ),
      parameters: {'id': id, 'user': user},
    );
    return rows.isEmpty ? null : _registration(rows.single);
  }

  Future<Response> _cancelRegistration(Request request) async {
    final user = await auth.requireUser(request);
    final id = _id(request);
    await database.pool.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named(
          'SELECT $_registrationColumns FROM registrations WHERE id = @id',
        ),
        parameters: {'id': id},
      );
      if (rows.isEmpty) {
        throw const AuthException('REGISTRATION_NOT_FOUND', 404);
      }
      final registration = _registration(rows.single);
      final domainRegistration = prijavaFromApi(registration);
      if (domainRegistration.korisnikId == user.id &&
          domainRegistration.status == StatusPrijave.otkazana) {
        return;
      }
      if (!mozeOtkazatiPrijavu(user, domainRegistration)) {
        throw const AuthException('FORBIDDEN', 403);
      }
      await _find(tx, registration.eventId, lock: true);
      await tx.execute(
        Sql.named(
          "UPDATE registrations SET status = 'CANCELLED' WHERE id = @id AND status = 'ACTIVE' RETURNING id",
        ),
        parameters: {'id': id},
      );
    });
    return Response.noContent();
  }

  Future<Response> _reviews(Request request, [int? id]) async {
    if (id != null) {
      _checkVisibility(
        await _find(database.pool, id),
        await _optionalUser(request),
      );
    }
    final rows = await database.pool.execute(
      Sql.named(
        'SELECT $_reviewColumns FROM reviews WHERE event_id = COALESCE(@id, event_id) ORDER BY id',
      ),
      parameters: {'id': id},
    );
    return _json(200, rows.map((row) => _reviewDto(row).toJson()).toList());
  }

  Future<Response> _review(Request request) async {
    final user = await auth.requireUser(request);
    final id = _id(request);
    final body = await _body(request);
    final rating = body['rating'];
    final comment = body['comment'];
    if (rating is! int || comment is! String) throw const FormatException();
    _validate(proveriOcenuRecenzije(rating), 400, {'min': 1, 'max': 5});
    _validate(proveriDuzinuKomentara(comment), 400, {'min': 5, 'max': 500});
    final review = await database.pool.runTx((tx) async {
      final event = dogadjajFromApi(await _find(tx, id, lock: true));
      final registration = await _activeRegistration(tx, id, user.id.value);
      if (registration == null ||
          !mozeOstavitiRecenziju(user, prijavaFromApi(registration), event)) {
        throw const AuthException('FORBIDDEN', 403);
      }
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO reviews (event_id, author_id, rating, comment)
          VALUES (@id, @user, @rating, @comment)
          ON CONFLICT (event_id, author_id) DO NOTHING
          RETURNING $_reviewColumns
        '''),
        parameters: {
          'id': id,
          'user': user.id.value,
          'rating': rating,
          'comment': comment.trim(),
        },
      );
      if (rows.isEmpty) throw const AuthException('DUPLICATE_REVIEW', 409);
      await tx.execute(
        Sql.named('SELECT id FROM users WHERE id = @host FOR UPDATE'),
        parameters: {'host': event.hostId.value},
      );
      final hostReviews = await tx.execute(
        Sql.named('''
          SELECT r.id, r.event_id, r.author_id, r.rating, r.comment
          FROM reviews r JOIN events e ON e.id = r.event_id
          WHERE e.host_id = @host
        '''),
        parameters: {'host': event.hostId.value},
      );
      final hostEvents = await tx.execute(
        Sql.named('$_eventQuery WHERE e.host_id = @host'),
        parameters: {'host': event.hostId.value},
      );
      final reputation = izracunajReputacijuHosta(
        hostId: event.hostId,
        dogadjaji: hostEvents.map((row) => dogadjajFromApi(_dto(row))).toList(),
        recenzije: hostReviews
            .map((row) => recenzijaFromApi(_reviewDto(row)))
            .toList(),
      );
      await tx.execute(
        Sql.named('UPDATE users SET reputation = @reputation WHERE id = @host'),
        parameters: {'reputation': reputation!, 'host': event.hostId.value},
      );
      return _reviewDto(rows.single);
    });
    return _json(201, review.toJson());
  }

  Future<Response> _users(Request request, {int? id}) async {
    final actor = await _optionalUser(request);
    final moderator = actor != null && mozeMenjatiReputaciju(actor);
    final rows = await database.pool.execute(
      Sql.named(
        'SELECT $_userColumns FROM users WHERE id = COALESCE(@id, id) ORDER BY id',
      ),
      parameters: {'id': id},
    );
    Map<String, Object?> visible(ResultRow row) {
      final user = _user(row);
      if (moderator) return user.toJson();
      return ApiPublicUserDto(
        id: user.id,
        name: user.name,
        role: user.role,
        reputation: user.reputation,
      ).toJson();
    }

    if (id == null) return _json(200, rows.map(visible).toList());
    if (rows.isEmpty) throw const AuthException('USER_NOT_FOUND', 404);
    return _json(200, visible(rows.single));
  }

  Future<Response> _moderate(Request request, {required bool ban}) async {
    final actor = await auth.requireUser(request);
    if (!mozeMenjatiReputaciju(actor)) {
      throw const AuthException('FORBIDDEN', 403);
    }
    final id = _id(request);
    final body = await _body(request);
    final value = body[ban ? 'isBanned' : 'reputation'];
    if (ban) {
      if (value is! bool) throw const FormatException();
      final target = await _findUser(id);
      if (!mozeBanovatiKorisnika(actor, korisnikFromApi(target))) {
        throw const AuthException('FORBIDDEN', 403);
      }
    } else {
      if (value is! num) throw const FormatException();
      _validate(proveriReputacijuHosta(value.toDouble()), 400, {
        'min': 1,
        'max': 5,
      });
    }
    final column = ban ? 'is_banned' : 'reputation';
    final rows = await database.pool.execute(
      Sql.named(
        'UPDATE users SET $column = @value WHERE id = @id RETURNING $_userColumns',
      ),
      parameters: {'value': value, 'id': id},
    );
    if (rows.isEmpty) throw const AuthException('USER_NOT_FOUND', 404);
    return _json(200, _user(rows.single).toJson());
  }

  Future<ApiUserDto> _findUser(int id) async {
    final rows = await database.pool.execute(
      Sql.named('SELECT $_userColumns FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) throw const AuthException('USER_NOT_FOUND', 404);
    return _user(rows.single);
  }

  ApiRegistrationDto _registration(ResultRow row) => ApiRegistrationDto(
    id: row[0] as int,
    eventId: row[1] as int,
    userId: row[2] as int,
    status: row[3] as String,
  );

  ApiReviewDto _reviewDto(ResultRow row) => ApiReviewDto(
    id: row[0] as int,
    eventId: row[1] as int,
    authorId: row[2] as int,
    rating: row[3] as int,
    comment: row[4] as String,
  );

  ApiUserDto _user(ResultRow row) => ApiUserDto(
    id: row[0] as int,
    name: row[1] as String,
    email: row[2] as String,
    role: row[3] as String,
    reputation: double.parse(row[4].toString()),
    isBanned: row[5] as bool,
  );

  void _validate(
    RezultatValidacije result,
    int status,
    Map<String, Object?> details,
  ) {
    if (result is GreskaValidacije) {
      throw _EventError(
        status,
        domainValidationToApi(result, details: details),
      );
    }
  }

  Future<Response> _list(Request request) async {
    final actor = await _optionalUser(request);
    final query = request.url.queryParameters;
    final afterId = int.tryParse(query['afterId'] ?? '0');
    final limit = query['limit'] == null ? null : int.tryParse(query['limit']!);
    if (afterId == null ||
        afterId < 0 ||
        (query.containsKey('limit') &&
            (limit == null || limit < 1 || limit > 100))) {
      throw const FormatException();
    }
    final rows = await database.pool.execute(
      Sql.named('''
        $_eventQuery
        WHERE e.id > @afterId
          AND (e.state <> 'PRELIMINARY' OR @moderator OR e.host_id = @actorId)
        ORDER BY e.id
        LIMIT @limit
      '''),
      parameters: {
        'moderator': actor?.uloga == UlogaKorisnika.moderator,
        'actorId': actor?.id.value,
        'afterId': afterId,
        'limit': limit,
      },
    );
    return _json(200, rows.map((row) => _dto(row).toJson()).toList());
  }

  Future<Response> _get(Request request) async {
    final actor = await _optionalUser(request);
    final event = await _find(database.pool, _id(request));
    _checkVisibility(event, actor);
    return _json(200, event.toJson());
  }

  void _checkVisibility(ApiEventDto event, Korisnik? actor) {
    if (event.state == 'PRELIMINARY' &&
        actor?.uloga != UlogaKorisnika.moderator &&
        actor?.id.value != event.hostId) {
      throw const AuthException('EVENT_NOT_FOUND', 404);
    }
  }

  Future<Response> _create(Request request) async {
    final actor = await auth.requireUser(request);
    if (!mozeKreiratiDogadjaj(actor)) {
      if (actor.uloga == UlogaKorisnika.host &&
          actor.reputacija < minimalnaReputacijaZaKreiranje) {
        throw const _EventError(
          403,
          ApiErrorDto(
            code: 'HOST_REPUTATION_TOO_LOW',
            details: {'min': minimalnaReputacijaZaKreiranje},
          ),
        );
      }
      throw const AuthException('FORBIDDEN', 403);
    }
    final body = await _body(request);
    final title = body['title'];
    final description = body['description'];
    if (title is! String || title.trim().isEmpty || description is! String) {
      throw const FormatException();
    }
    final capacity = _capacity(body['capacity']);
    final event = await database.pool.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO events
            (host_id, title, description, state, capacity)
          VALUES (@host, @title, @description, @state, @capacity)
          RETURNING id
        '''),
        parameters: {
          'host': actor.id.value,
          'title': title.trim(),
          'description': description.trim(),
          'state': stanjeToApi(const Preliminarni()),
          'capacity': capacity,
        },
      );
      return _find(tx, rows.single[0] as int);
    });
    return _json(201, event.toJson());
  }

  Future<Response> _changeState(Request request) async {
    final actor = await auth.requireUser(request);
    final body = await _body(request);
    final state = body['state'];
    if (state is! String) throw const FormatException();
    final next = stanjeFromApi(state);
    final id = _id(request);
    final event = await database.pool.runTx((tx) async {
      final current = dogadjajFromApi(await _find(tx, id, lock: true));
      if (!imaPravoNaPromenuStanja(actor, current, next)) {
        throw const AuthException('FORBIDDEN', 403);
      }
      if (!mozePromenitiStanjeDogadjaja(actor, current, next)) {
        throw _EventError(
          409,
          ApiErrorDto(
            code: 'INVALID_EVENT_TRANSITION',
            details: {
              'currentState': stanjeToApi(current.stanje),
              'state': state,
            },
          ),
        );
      }
      await tx.execute(
        Sql.named('UPDATE events SET state = @state WHERE id = @id'),
        parameters: {'id': id, 'state': state},
      );
      return _find(tx, id);
    });
    return _json(200, event.toJson());
  }

  Future<Response> _changeCapacity(Request request) async {
    final actor = await auth.requireUser(request);
    final body = await _body(request);
    final capacity = _capacity(body['capacity']);
    final id = _id(request);
    final event = await database.pool.runTx((tx) async {
      final current = dogadjajFromApi(await _find(tx, id, lock: true));
      if (!mozeUreditiDogadjaj(actor, current)) {
        throw const AuthException('FORBIDDEN', 403);
      }
      final rows = await tx.execute(
        Sql.named('''
          SELECT COUNT(*) FROM registrations
          WHERE event_id = @id AND status = 'ACTIVE'
        '''),
        parameters: {'id': id},
      );
      final count = rows.single[0] as int;
      if (count > capacity) {
        throw _EventError(
          409,
          domainValidationToApi(
            const GreskaNemaSlobodnihMesta(),
            details: {'capacity': capacity, 'activeRegistrations': count},
          ),
        );
      }
      await tx.execute(
        Sql.named('UPDATE events SET capacity = @capacity WHERE id = @id'),
        parameters: {'id': id, 'capacity': capacity},
      );
      return _find(tx, id);
    });
    return _json(200, event.toJson());
  }

  Future<ApiEventDto> _find(
    Session session,
    int id, {
    bool lock = false,
  }) async {
    final rows = await session.execute(
      Sql.named(
        '$_eventQuery WHERE e.id = @id ${lock ? 'FOR UPDATE OF e' : ''}',
      ),
      parameters: {'id': id},
    );
    if (rows.isEmpty) throw const AuthException('EVENT_NOT_FOUND', 404);
    return _dto(rows.single);
  }

  ApiEventDto _dto(ResultRow row) => ApiEventDto(
    id: row[0] as int,
    hostId: row[1] as int,
    title: row[2] as String,
    description: row[3] as String,
    state: row[4] as String,
    capacity: row[5] as int,
    hostReputation: double.parse(row[6].toString()),
  );

  Future<Korisnik?> _optionalUser(Request request) async {
    if (request.headers.authorization == null) return null;
    return auth.requireUser(request);
  }

  int _id(Request request) {
    final value = request.pathParameters.get(PathParam<String>(#id, (s) => s));
    final id = int.tryParse(value);
    if (id == null || id <= 0) throw const FormatException();
    return id;
  }

  int _capacity(Object? value) {
    if (value is! int || value > 2147483647) throw const FormatException();
    final result = proveriKapacitet(value);
    if (result is GreskaValidacije) {
      throw _EventError(
        400,
        domainValidationToApi(result, details: {'min': 1}),
      );
    }
    return value;
  }

  Future<Map<String, dynamic>> _body(Request request) async {
    final decoded = jsonDecode(await request.readAsString());
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  Future<Response> _handle(Future<Response> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      return _json(error.statusCode, ApiErrorDto(code: error.code).toJson());
    } on _EventError catch (error) {
      return _json(error.status, error.dto.toJson());
    } on FormatException {
      return _json(400, const ApiErrorDto(code: 'INVALID_REQUEST').toJson());
    } catch (error, stack) {
      developer.log('Event request failed', error: error, stackTrace: stack);
      return _json(
        500,
        const ApiErrorDto(code: 'INTERNAL_SERVER_ERROR').toJson(),
      );
    }
  }

  Response _json(int status, Object data) => Response(
    status,
    body: Body.fromString(jsonEncode(data), mimeType: MimeType.json),
  );
}

class _EventError implements Exception {
  const _EventError(this.status, this.dto);

  final int status;
  final ApiErrorDto dto;
}
