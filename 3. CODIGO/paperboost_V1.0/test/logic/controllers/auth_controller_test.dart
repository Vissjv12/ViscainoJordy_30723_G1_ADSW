import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';
import 'package:paperboost/logic/controllers/auth_controller.dart';
import 'package:paperboost/logic/services/auth_service.dart';
import 'package:paperboost/logic/session/session_manager.dart';

void main() {
  group('AuthController', () {
    late AuthController authController;
    late SessionManager sessionManager;

    setUp(() {
      final userRepository = InMemoryUserRepository();
      sessionManager = SessionManager();
      final authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );
      authController = AuthController(authService: authService);
    });

    test('login delega al servicio y retorna éxito', () async {
      final result = await authController.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
    });

    test('login retorna failure con credenciales incorrectas', () async {
      final result = await authController.login(
        email: 'wrong@test.com',
        password: 'wrong',
      );
      expect(result.isSuccess, false);
    });

    test('loginAsGuest retorna éxito', () async {
      final result = await authController.loginAsGuest();
      expect(result.isSuccess, true);
      expect(result.data!.isGuest, true);
    });

    test('register rechaza registro porque ya existe admin por defecto',
        () async {
      final result = await authController.register(
        email: 'nuevo@paperboost.com',
        password: 'Password123',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('Ya existe un usuario registrado'));
    });

    test('register rechaza datos inválidos', () async {
      final result = await authController.register(
        email: '',
        password: '',
      );
      expect(result.isSuccess, false);
    });

    test('hasRegisteredUser retorna true por el admin por defecto', () async {
      final hasUser = await authController.hasRegisteredUser();
      expect(hasUser, true);
    });

    test('logout cierra sesión correctamente', () async {
      await authController.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );
      expect(authController.isAuthenticated, true);
      final result = authController.logout();
      expect(result.isSuccess, true);
      expect(authController.isAuthenticated, false);
    });

    test('isAuthenticated retorna false sin sesión', () {
      expect(authController.isAuthenticated, false);
    });

    test('currentUser retorna null sin sesión', () {
      expect(authController.currentUser, isNull);
    });
  });
}
