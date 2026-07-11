import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/app_user.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';

void main() {
  group('InMemoryUserRepository - Usuario por defecto', () {
    late InMemoryUserRepository repository;

    setUp(() {
      repository = InMemoryUserRepository();
    });

    test('hasRegisteredUser retorna true por el usuario admin por defecto', () async {
      final hasUser = await repository.hasRegisteredUser();
      expect(hasUser, true);
    });

    test('findByEmail encuentra al admin por defecto', () async {
      final found = await repository.findByEmail('admin@paperboost.com');
      expect(found, isNotNull);
      expect(found!.id, 'USER-001');
      expect(found.role, 'Administrador');
    });

    test('findByEmail es case-insensitive para admin', () async {
      final found = await repository.findByEmail('ADMIN@PAPERBOOST.COM');
      expect(found, isNotNull);
    });

    test('findByEmail normaliza espacios', () async {
      final found = await repository.findByEmail('  admin@paperboost.com  ');
      expect(found, isNotNull);
    });

    test('findByEmail retorna null para email no registrado', () async {
      final found = await repository.findByEmail('noexiste@test.com');
      expect(found, isNull);
    });

    test('createUser lanza error porque ya existe el admin por defecto', () async {
      const newUser = AppUser(
        id: 'USER-002',
        email: 'otro@test.com',
        passwordHash: 'hash',
        passwordSalt: 'salt',
        role: 'Emprendedor',
      );
      expect(
        () => repository.createUser(newUser),
        throwsA(isA<StateError>()),
      );
    });
  });
}
