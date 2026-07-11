import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/logic/validators/auth_validator.dart';

void main() {
  group('AuthValidator', () {
    group('isValidEmail', () {
      test('retorna true para email válido', () {
        expect(AuthValidator.isValidEmail('user@example.com'), true);
      });

      test('retorna true para email con subdominio', () {
        expect(AuthValidator.isValidEmail('user@sub.example.com'), true);
      });

      test('retorna true para email con caracteres especiales', () {
        expect(AuthValidator.isValidEmail('user.name+tag@example.com'), true);
      });

      test('retorna true para email con números', () {
        expect(AuthValidator.isValidEmail('user123@example.com'), true);
      });

      test('retorna false para email sin arroba', () {
        expect(AuthValidator.isValidEmail('userexample.com'), false);
      });

      test('retorna false para email sin dominio', () {
        expect(AuthValidator.isValidEmail('user@'), false);
      });

      test('retorna false para email vacío', () {
        expect(AuthValidator.isValidEmail(''), false);
      });

      test('retorna false para email con espacios', () {
        expect(AuthValidator.isValidEmail('user @example.com'), false);
      });

      test('normaliza espacios antes de validar', () {
        expect(AuthValidator.isValidEmail('  user@example.com  '), true);
      });
    });

    group('isValidPassword', () {
      test('retorna true para contraseña de 6 caracteres', () {
        expect(AuthValidator.isValidPassword('123456'), true);
      });

      test('retorna true para contraseña larga', () {
        expect(AuthValidator.isValidPassword('Admin123*'), true);
      });

      test('retorna false para contraseña de 5 caracteres', () {
        expect(AuthValidator.isValidPassword('12345'), false);
      });

      test('retorna false para contraseña vacía', () {
        expect(AuthValidator.isValidPassword(''), false);
      });

      test('normaliza espacios en blanco', () {
        expect(AuthValidator.isValidPassword('  123456  '), true);
      });

      test('retorna false si tras trim es menor a 6', () {
        expect(AuthValidator.isValidPassword('  12345  '), false);
      });
    });

    test('se puede instanciar el constructor privado', () {
      expect(AuthValidator(), isA<AuthValidator>());
    });
  });
}
