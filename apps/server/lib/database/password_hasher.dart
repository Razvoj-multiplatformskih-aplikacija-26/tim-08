import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordHasher {
  static const int iterations = 100000;

  Pbkdf2 _algorithm(int brojIteracija) {
    return Pbkdf2.hmacSha256(
      iterations: brojIteracija,
      bits: 256,
    );
  }

  Future<String> hash(String password) async {
    final random = Random.secure();

    final salt = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    final secretKey = await _algorithm(iterations)
        .deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final hash = await secretKey.extractBytes();

    return 'pbkdf2:$iterations:${_toHex(salt)}:${_toHex(hash)}';
  }

  Future<bool> verify(
      String password,
      String storedHash,
      ) async {
    final parts = storedHash.split(':');

    if (parts.length != 4 || parts[0] != 'pbkdf2') {
      return false;
    }

    final brojIteracija = int.tryParse(parts[1]);

    if (brojIteracija == null ||
        brojIteracija < 1 ||
        brojIteracija > 1000000) {
      return false;
    }

    final salt = _fromHex(parts[2]);
    final originalniHash = _fromHex(parts[3]);

    if (salt == null ||
        originalniHash == null ||
        originalniHash.length != 32) {
      return false;
    }

    final secretKey = await _algorithm(brojIteracija)
        .deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final noviHash = await secretKey.extractBytes();

    return _jednakiBajtovi(noviHash, originalniHash);
  }

  bool _jednakiBajtovi(
      List<int> a,
      List<int> b,
      ) {
    if (a.length != b.length) {
      return false;
    }

    int razlika = 0;

    for (int i = 0; i < a.length; i++) {
      razlika |= a[i] ^ b[i];
    }

    return razlika == 0;
  }

  String _toHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  List<int>? _fromHex(String value) {
    if (value.length.isOdd) {
      return null;
    }

    try {
      return List<int>.generate(
        value.length ~/ 2,
            (index) => int.parse(
          value.substring(index * 2, index * 2 + 2),
          radix: 16,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}