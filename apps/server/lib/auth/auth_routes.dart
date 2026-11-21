import 'dart:convert';
import 'dart:io';

import 'package:relic/relic.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';

import 'auth_service.dart';

class AuthRoutes {
  final AuthService authService;

  AuthRoutes(this.authService);

  Body _jsonBody(Object data) {
    return Body.fromString(jsonEncode(data), mimeType: MimeType.json);
  }

  Response _error(String code, int statusCode) {
    return Response(
      statusCode,
      body: _jsonBody(ApiErrorDto(code: code).toJson()),
    );
  }

  Future<Response> login(Request request) async {
    try {
      final rawBody = await request.readAsString();

      final decoded = jsonDecode(rawBody);

      if (decoded is! Map) {
        return _error('INVALID_REQUEST', 400);
      }

      final data = Map<String, dynamic>.from(decoded);

      final email = data['email'];
      final password = data['password'];
      final clientType = data['clientType'] ?? 'MOBILE';

      if (email is! String ||
          password is! String ||
          clientType is! String ||
          email.trim().isEmpty ||
          password.isEmpty) {
        return _error('INVALID_REQUEST', 400);
      }

      final response = await authService.login(
        email: email,
        password: password,
        clientType: clientType,
      );

      return Response.ok(body: _jsonBody(response.toJson()));
    } on AuthException catch (e) {
      return _error(e.code, e.statusCode);
    } on FormatException {
      return _error('INVALID_REQUEST', 400);
    } catch (e) {
      stderr.writeln('Login error: $e');

      return _error('INTERNAL_SERVER_ERROR', 500);
    }
  }

  Future<Response> logout(Request request) async {
    try {
      await authService.logout(request);

      return Response.noContent();
    } catch (e) {
      stderr.writeln('Logout error: $e');

      return _error('INTERNAL_SERVER_ERROR', 500);
    }
  }

  Future<Response> currentUser(Request request) async {
    try {
      final korisnik = await authService.requireUser(request);

      return Response.ok(body: _jsonBody(korisnikToApi(korisnik).toJson()));
    } on AuthException catch (e) {
      return _error(e.code, e.statusCode);
    } catch (e) {
      stderr.writeln('Current user error: $e');

      return _error('INTERNAL_SERVER_ERROR', 500);
    }
  }
}
