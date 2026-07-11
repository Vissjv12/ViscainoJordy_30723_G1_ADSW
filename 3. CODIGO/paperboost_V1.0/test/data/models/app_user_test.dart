import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/app_user.dart';

void main() {
  group('AppUser', () {
    const user = AppUser(
      id: 'USER-001',
      email: 'test@paperboost.com',
      passwordHash: 'hash123',
      passwordSalt: 'salt123',
      role: 'Emprendedor',
    );

    test('crear instancia correctamente', () {
      expect(user.id, 'USER-001');
      expect(user.email, 'test@paperboost.com');
      expect(user.passwordHash, 'hash123');
      expect(user.passwordSalt, 'salt123');
      expect(user.role, 'Emprendedor');
    });

    test('guest factory crea usuario invitado', () {
      final guest = AppUser.guest();
      expect(guest.id, 'GUEST-001');
      expect(guest.email, 'invitado@paperboost.com');
      expect(guest.passwordHash, '');
      expect(guest.passwordSalt, '');
      expect(guest.role, 'Invitado');
    });

    test('isGuest retorna true para guest', () {
      final guest = AppUser.guest();
      expect(guest.isGuest, true);
    });

    test('isGuest retorna false para usuario normal', () {
      expect(user.isGuest, false);
    });

    test('copyWith modifica campos correctamente', () {
      final copy = user.copyWith(email: 'new@paperboost.com', role: 'Admin');
      expect(copy.id, 'USER-001');
      expect(copy.email, 'new@paperboost.com');
      expect(copy.role, 'Admin');
      expect(copy.passwordHash, 'hash123');
    });

    test('copyWith sin argumentos retorna copia idéntica', () {
      final copy = user.copyWith();
      expect(copy.id, user.id);
      expect(copy.email, user.email);
      expect(copy.passwordHash, user.passwordHash);
      expect(copy.passwordSalt, user.passwordSalt);
      expect(copy.role, user.role);
    });

    test('toMap serializa correctamente', () {
      final map = user.toMap();
      expect(map['id'], 'USER-001');
      expect(map['email'], 'test@paperboost.com');
      expect(map['passwordHash'], 'hash123');
      expect(map['passwordSalt'], 'salt123');
      expect(map['role'], 'Emprendedor');
    });

    test('fromMap deserializa correctamente', () {
      final map = {
        'id': 'USER-002',
        'email': 'user2@paperboost.com',
        'passwordHash': 'abc',
        'passwordSalt': 'def',
        'role': 'Invitado',
      };
      final u = AppUser.fromMap(map);
      expect(u.id, 'USER-002');
      expect(u.email, 'user2@paperboost.com');
      expect(u.passwordHash, 'abc');
      expect(u.role, 'Invitado');
    });

    test('toString contiene información relevante', () {
      final str = user.toString();
      expect(str, contains('USER-001'));
      expect(str, contains('test@paperboost.com'));
      expect(str, contains('Emprendedor'));
    });
  });
}
