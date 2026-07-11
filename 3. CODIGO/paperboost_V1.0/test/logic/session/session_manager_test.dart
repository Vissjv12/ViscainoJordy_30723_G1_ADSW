import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/app_user.dart';
import 'package:paperboost/logic/session/session_manager.dart';

void main() {
  group('SessionManager', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
    });

    const user = AppUser(
      id: 'USER-001',
      email: 'test@paperboost.com',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      role: 'Emprendedor',
    );

    test('currentUser es null al inicio', () {
      expect(sessionManager.currentUser, isNull);
    });

    test('isAuthenticated es false al inicio', () {
      expect(sessionManager.isAuthenticated, false);
    });

    test('login establece el usuario', () {
      sessionManager.login(user);
      expect(sessionManager.currentUser, isNotNull);
      expect(sessionManager.currentUser!.id, 'USER-001');
      expect(sessionManager.isAuthenticated, true);
    });

    test('logout limpia el usuario', () {
      sessionManager.login(user);
      expect(sessionManager.isAuthenticated, true);
      sessionManager.logout();
      expect(sessionManager.currentUser, isNull);
      expect(sessionManager.isAuthenticated, false);
    });

    test('clear limpia el usuario', () {
      sessionManager.login(user);
      expect(sessionManager.isAuthenticated, true);
      sessionManager.clear();
      expect(sessionManager.currentUser, isNull);
      expect(sessionManager.isAuthenticated, false);
    });

    test('logout y clear tienen el mismo efecto', () {
      sessionManager.login(user);
      sessionManager.logout();
      expect(sessionManager.currentUser, isNull);
      sessionManager.login(user);
      sessionManager.clear();
      expect(sessionManager.currentUser, isNull);
    });

    test('múltiples login actualizan el usuario', () {
      const anotherUser = AppUser(
        id: 'USER-002',
        email: 'otro@test.com',
        passwordHash: 'hash2',
        passwordSalt: 'salt2',
        role: 'Invitado',
      );
      sessionManager.login(user);
      expect(sessionManager.currentUser!.id, 'USER-001');
      sessionManager.login(anotherUser);
      expect(sessionManager.currentUser!.id, 'USER-002');
    });
  });

  group('SessionManager - Singleton', () {
    test('instance es singleton', () {
      final instance1 = SessionManager.instance;
      final instance2 = SessionManager.instance;
      expect(identical(instance1, instance2), true);
    });
  });
}
