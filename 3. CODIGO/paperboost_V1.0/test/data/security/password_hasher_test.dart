import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/security/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    const password = 'Admin123*';
    const salt = 'test-salt';

    test('hash genera un string no vacío', () {
      final hash = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      expect(hash, isNotEmpty);
    });

    test('hash es determinista (misma entrada = misma salida)', () {
      final hash1 = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      final hash2 = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      expect(hash1, hash2);
    });

    test('hash diferente para distinta contraseña', () {
      final hash1 = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      final hash2 = PasswordHasher.hash(
        password: 'OtraPass123',
        salt: salt,
      );
      expect(hash1, isNot(hash2));
    });

    test('hash diferente para distinto salt', () {
      final hash1 = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      final hash2 = PasswordHasher.hash(
        password: password,
        salt: 'other-salt',
      );
      expect(hash1, isNot(hash2));
    });

    test('hash no contiene la contraseña original', () {
      final hash = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      expect(hash, isNot(contains(password)));
    });

    test('verify retorna true para credenciales correctas', () {
      final hash = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      final result = PasswordHasher.verify(
        password: password,
        salt: salt,
        expectedHash: hash,
      );
      expect(result, true);
    });

    test('verify retorna false para contraseña incorrecta', () {
      final hash = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      final result = PasswordHasher.verify(
        password: 'WrongPassword',
        salt: salt,
        expectedHash: hash,
      );
      expect(result, false);
    });

    test('verify retorna false para salt incorrecto', () {
      final hash = PasswordHasher.hash(
        password: password,
        salt: salt,
      );
      final result = PasswordHasher.verify(
        password: password,
        salt: 'wrong-salt',
        expectedHash: hash,
      );
      expect(result, false);
    });

    test('verify retorna false para hash incorrecto', () {
      final result = PasswordHasher.verify(
        password: password,
        salt: salt,
        expectedHash: 'invalid-hash',
      );
      expect(result, false);
    });

    test('se puede instanciar el constructor privado', () {
      expect(PasswordHasher(), isA<PasswordHasher>());
    });
  });
}
