import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher();

  static String hash({
    required String password,
    required String salt,
  }) {
    final key = utf8.encode(salt);
    final passwordBytes = utf8.encode(password);

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(passwordBytes);

    return digest.toString();
  }

  static bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    final calculatedHash = hash(
      password: password,
      salt: salt,
    );

    return calculatedHash == expectedHash;
  }
}