import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';

class ApiHttpException implements Exception {
  final ApiMappedError error;

  const ApiHttpException(this.error);

  @override
  String toString() => switch (error.code) {
        'INVALID_CREDENTIALS' => 'Email ili lozinka nisu ispravni.',
        'BACKOFFICE_ROLE_REQUIRED' => 'Backoffice je namenjen moderatorima.',
        'MOBILE_ROLE_REQUIRED' =>
          'Ova aplikacija je namenjena korisnicima i hostovima.',
        'ACCOUNT_BANNED' => 'Vaš nalog je blokiran.',
        'SESSION_EXPIRED' ||
        'UNAUTHENTICATED' =>
          'Sesija je istekla. Prijavite se ponovo.',
        'EVENT_CAPACITY_REACHED' =>
          'Nema više slobodnih mesta za ovaj događaj!',
        'INVALID_CAPACITY' => 'Kapacitet mora biti veći od 0!',
        'INVALID_REVIEW_RATING' => 'Ocena mora biti između 1 i 5!',
        'REVIEW_COMMENT_TOO_SHORT' =>
          'Komentar mora imati najmanje 5 karaktera!',
        'REVIEW_COMMENT_TOO_LONG' =>
          'Komentar ne može imati više od 500 karaktera!',
        'HOST_REPUTATION_OUT_OF_RANGE' => 'Reputacija mora biti između 1 i 5.',
        'HOST_REPUTATION_TOO_LOW' =>
          'Za kreiranje događaja potrebna je reputacija najmanje ${error.details['min']}.',
        'INVALID_EVENT_TRANSITION' =>
          'Prelaz u izabrano stanje nije dozvoljen.',
        'EVENT_REGISTRATION_CLOSED' => 'Prijave za ovaj događaj su zatvorene.',
        'DUPLICATE_REGISTRATION' => 'Već ste prijavljeni na ovaj događaj!',
        'DUPLICATE_REVIEW' => 'Već ste ostavili recenziju!',
        'FORBIDDEN' => 'Nemate dozvolu za ovu akciju.',
        'SERVER_UNAVAILABLE' => 'Server nije dostupan. Pokušajte ponovo.',
        _ => 'Zahtev nije uspeo. Osvežite podatke i pokušajte ponovo.',
      };
}

class ApiHttpClient {
  final Uri baseUri;
  final http.Client _client;

  String? _accessToken;
  void Function(ApiHttpException)? onSessionRejected;
  bool get hasSession => _accessToken != null;

  ApiHttpClient({
    required Uri baseUri,
    http.Client? client,
  })  : baseUri = _normaliseBaseUri(baseUri),
        _client = client ?? http.Client();

  static Uri _normaliseBaseUri(Uri uri) {
    if (uri.path.endsWith('/')) {
      return uri;
    }

    return uri.replace(path: '${uri.path}/');
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  void close() {
    _client.close();
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final uri = baseUri.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );

    final request = http.Request(method, uri);

    request.headers.addAll(_headers());

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final token = _accessToken;
    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw _unavailable;
    } on http.ClientException {
      throw _unavailable;
    }

    Object? decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw const FormatException(
            'Server returned invalid JSON.',
          );
        }
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      ApiErrorDto errorDto;

      if (decoded is Map<String, dynamic> && decoded.containsKey('code')) {
        errorDto = ApiErrorDto.fromJson(decoded);
      } else {
        errorDto = ApiErrorDto(
          code: 'HTTP_ERROR',
          details: {
            'status': response.statusCode,
          },
        );
      }

      final exception = ApiHttpException(
        apiErrorToDomain(errorDto),
      );
      if (token != null &&
          token == _accessToken &&
          (response.statusCode == 401 || errorDto.code == 'ACCOUNT_BANNED')) {
        onSessionRejected?.call(exception);
      }
      throw exception;
    }

    return decoded;
  }

  static const _unavailable = ApiHttpException(ApiMappedError(
    code: 'SERVER_UNAVAILABLE',
    category: ApiErrorCategory.server,
    details: {},
  ));

  Future<Map<String, dynamic>> getObject(
    String path,
  ) async {
    final result = await _request('GET', path);

    if (result is! Map) {
      throw const FormatException(
        'Expected a JSON object from server.',
      );
    }

    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path,
  ) async {
    final result = await _request('GET', path);

    if (result is! List) {
      throw const FormatException(
        'Expected a JSON list from server.',
      );
    }

    return result
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  Future<Map<String, dynamic>> postObject(
    String path, {
    Map<String, Object?>? body,
  }) async {
    final result = await _request(
      'POST',
      path,
      body: body,
    );

    if (result is! Map) {
      throw const FormatException(
        'Expected a JSON object from server.',
      );
    }

    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> patchObject(
    String path, {
    required Map<String, Object?> body,
  }) async {
    final result = await _request(
      'PATCH',
      path,
      body: body,
    );

    if (result is! Map) {
      throw const FormatException(
        'Expected a JSON object from server.',
      );
    }

    return Map<String, dynamic>.from(result);
  }

  Future<void> delete(String path) async {
    await _request('DELETE', path);
  }

  Future<void> postVoid(
    String path, {
    Map<String, Object?>? body,
  }) async {
    await _request(
      'POST',
      path,
      body: body,
    );
  }
}

class ApiClient extends ApiHttpClient {
  ApiClient({
    required super.baseUri,
    super.client,
  });

  Future<Korisnik> currentUser() async =>
      korisnikFromApi(ApiUserDto.fromJson(await getObject(ApiRoutes.me)));

  Future<ApiLoginResponse> login(
    ApiLoginRequest request,
  ) async {
    final result = await postObject(
      ApiRoutes.login,
      body: request.toJson(),
    );

    final loginResponse = ApiLoginResponse.fromJson(
      result,
    );

    setAccessToken(loginResponse.accessToken);

    return loginResponse;
  }

  Future<void> logout() async {
    try {
      await postVoid(
        ApiRoutes.logout,
        body: const {},
      );
    } finally {
      clearAccessToken();
    }
  }
}
