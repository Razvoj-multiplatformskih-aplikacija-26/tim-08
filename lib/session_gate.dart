import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'session_store.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    this.backoffice = false,
    this.onSessionClosed,
    required this.builder,
  });

  final bool backoffice;
  final VoidCallback? onSessionClosed;
  final Widget Function(ApiClient client, Korisnik actor) builder;

  static SessionGateState of(BuildContext context) =>
      context.findAncestorStateOfType<SessionGateState>()!;

  @override
  State<SessionGate> createState() => SessionGateState();
}

class SessionGateState extends State<SessionGate> {
  static final guest = Korisnik(
    id: KorisnikId(0),
    ime: 'Gost',
    email: '',
    uloga: UlogaKorisnika.korisnik,
    jeBanovan: true,
  );

  late final ApiClient _client;
  ApiClient get client => _client;
  late final SessionStore _store;
  final _email = TextEditingController();
  final _password = TextEditingController();
  Korisnik? _actor;
  Timer? _expiry;
  bool _busy = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    _client = ApiClient(
      baseUri: Uri.parse(
        configuredUrl.isEmpty
            ? (android ? 'http://10.0.2.2:8080' : 'http://localhost:8080')
            : configuredUrl,
      ),
    );
    _client.onSessionRejected = (error) {
      if (_actor != null && _client.hasSession) {
        unawaited(_clear(error.toString()));
      }
    };
    _store = SecureSessionStore(
      'event_scheduler_${widget.backoffice ? 'backoffice' : 'mobile'}_${_client.baseUri}',
    );
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final saved = await _store.read();
      if (saved == null) return;
      final session = ApiLoginResponse.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
      if (!session.expiresAt.isAfter(DateTime.now())) {
        await _clear('Sesija je istekla. Prijavite se ponovo.');
        return;
      }
      _client.setAccessToken(session.accessToken);
      try {
        final current = ApiUserDto.fromJson(
          await _client.getObject(ApiRoutes.me),
        );
        _open(session, current);
      } on ApiHttpException catch (error) {
        if (error.error.code == 'SERVER_UNAVAILABLE') {
          _open(session, session.user);
        } else {
          await _clear(error.toString());
        }
      }
    } catch (_) {
      _client.clearAccessToken();
      _message = 'Sačuvana prijava nije dostupna. Prijavite se ponovo.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(ApiLoginResponse session, ApiUserDto user) {
    if (!mounted) return;
    _expiry?.cancel();
    _expiry = Timer(session.expiresAt.difference(DateTime.now()), () {
      unawaited(_clear('Sesija je istekla. Prijavite se ponovo.'));
    });
    final actor = korisnikFromApi(user);
    setState(() => _actor = actor);
  }

  Future<void> _login() async {
    if (_busy || _email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final session = await _client.login(
        ApiLoginRequest(
          email: _email.text.trim(),
          password: _password.text,
          clientType: widget.backoffice ? 'BACKOFFICE' : 'MOBILE',
        ),
      );
      await _store.write(jsonEncode(session.toJson()));
      _open(session, session.user);
    } on ApiHttpException catch (error) {
      _message = error.toString();
    } catch (_) {
      _client.clearAccessToken();
      _message = 'Prijava nije mogla da se sačuva na uređaju.';
    } finally {
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    String? message;
    try {
      if (_client.hasSession) await _client.logout();
    } on ApiHttpException catch (error) {
      message = error.toString();
    } finally {
      await _clear(message);
    }
  }

  Future<void> _clear(String? message) async {
    _expiry?.cancel();
    _client.clearAccessToken();
    if (mounted) {
      widget.onSessionClosed?.call();
      setState(() {
        _actor = null;
        _message = message;
        _busy = true;
      });
    }
    try {
      await _store.clear();
    } catch (_) {
      _message = 'Sacuvana prijava nije mogla da se ukloni';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _client.close();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actor = _actor;
    if (actor != null) return widget.builder(_client, actor);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.backoffice ? 'Prijava za backoffice' : 'Prijava'),
        ),
        body: Center(
          child: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                if (_message != null) Text(_message!),
                if (_busy) const LinearProgressIndicator(),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: const Text('Prijavi se'),
                ),
                if (!widget.backoffice)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _actor = guest),
                    child: const Text('Pogledaj javne dogadjaje'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
