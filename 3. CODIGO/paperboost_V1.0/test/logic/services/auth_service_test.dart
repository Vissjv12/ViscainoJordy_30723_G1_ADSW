import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/app_user.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';
import 'package:paperboost/data/repositories/user_repository.dart';
import 'package:paperboost/logic/services/auth_service.dart';
import 'package:paperboost/logic/session/session_manager.dart';

void main() {
  group('AuthService - RQF-001: Validar Credenciales de Acceso', () {
    late AuthService authService;

    setUp(() {
      final userRepository = InMemoryUserRepository();
      final sessionManager = SessionManager();
      authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );
    });

    test('Login exitoso con credenciales válidas', () async {
      final result = await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(result.isSuccess, true);
      expect(result.message, contains('Inicio de sesión correcto'));
      expect(result.data, isNotNull);
      expect(result.data!.email, 'admin@paperboost.com');
    });

    test('Rechazar login sin correo', () async {
      final result = await authService.login(
        email: '',
        password: 'Admin123*',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Ingrese el correo'));
    });

    test('Rechazar login sin contraseña', () async {
      final result = await authService.login(
        email: 'admin@paperboost.com',
        password: '',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Ingrese la contraseña'));
    });

    test('Rechazar login con correo inválido', () async {
      final result = await authService.login(
        email: 'correo-sin-arroba',
        password: 'Admin123*',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('correo electrónico válido'));
    });

    test('Rechazar login con correo no registrado', () async {
      final result = await authService.login(
        email: 'inexistente@paperboost.com',
        password: 'Admin123*',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Correo o contraseña incorrectos'));
    });

    test('Rechazar login con contraseña incorrecta', () async {
      final result = await authService.login(
        email: 'admin@paperboost.com',
        password: 'ContraseñaIncorrecta',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Correo o contraseña incorrectos'));
    });

    test('Normalizar espacios en blanco en email', () async {
      final result = await authService.login(
        email: '  admin@paperboost.com  ',
        password: 'Admin123*',
      );

      expect(result.isSuccess, true);
    });

    test('Normalizar espacios en blanco en contraseña', () async {
      final result = await authService.login(
        email: 'admin@paperboost.com',
        password: '  Admin123*  ',
      );

      expect(result.isSuccess, true);
    });

    test('Email case-insensitive', () async {
      final result = await authService.login(
        email: 'ADMIN@PAPERBOOST.COM',
        password: 'Admin123*',
      );

      expect(result.isSuccess, true);
    });
  });

  group('AuthService - RQF-002: Almacenamiento de Credenciales', () {
    late AuthService authService;

    setUp(() {
      final userRepository = InMemoryUserRepository();
      final sessionManager = SessionManager();
      authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );
    });

    test('Credenciales se almacenan de forma segura (hasheadas)', () async {
      final result = await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(result.isSuccess, true);

      final user = result.data!;

      // Verificar que la contraseña no está en texto plano
      expect(user.passwordHash, isNotEmpty);
      expect(user.passwordHash, isNot('Admin123*'));
      expect(user.passwordSalt, isNotEmpty);
    });

    test('Usuario se almacena en sesión después del login', () async {
      expect(authService.currentUser, isNull);

      await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(authService.currentUser, isNotNull);
      expect(authService.isAuthenticated, true);
    });

    test('Sesión se limpia al hacer logout', () async {
      await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(authService.isAuthenticated, true);

      authService.logout();

      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, isNull);
    });

    test('No se puede hacer logout sin sesión activa', () async {
      final result = authService.logout();

      expect(result.isSuccess, false);
      expect(result.message, contains('No existe una sesión activa'));
    });

    test('isAuthenticated retorna true después del login', () async {
      expect(authService.isAuthenticated, false);

      await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(authService.isAuthenticated, true);
    });

    test('currentUser retorna null cuando no está autenticado', () async {
      expect(authService.currentUser, isNull);
    });

    test('currentUser retorna el usuario autenticado', () async {
      await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      final user = authService.currentUser!;

      expect(user.email, 'admin@paperboost.com');
      expect(user.role, 'Administrador');
    });
  });

  group('AuthService - Múltiples intentos de login', () {
    late AuthService authService;

    setUp(() {
      final userRepository = InMemoryUserRepository();
      final sessionManager = SessionManager();
      authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );
    });

    test('Múltiples logins exitosos mantienen la sesión actualizada',
        () async {
      final result1 = await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(result1.isSuccess, true);
      var currentUser = authService.currentUser;
      expect(currentUser!.id, 'USER-001');

      // Simular logout y nuevo login
      authService.logout();
      expect(authService.isAuthenticated, false);

      final result2 = await authService.login(
        email: 'admin@paperboost.com',
        password: 'Admin123*',
      );

      expect(result2.isSuccess, true);
      currentUser = authService.currentUser;
      expect(currentUser!.id, 'USER-001');
      expect(authService.isAuthenticated, true);
    });
  });

  group('AuthService - RQF-002: Registro de Usuario (Validaciones)', () {
    late AuthService authService;

    setUp(() {
      final userRepository = InMemoryUserRepository();
      final sessionManager = SessionManager();
      authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );
    });

    test('register rechaza campos vacíos', () async {
      final result = await authService.register(
        email: '',
        password: '',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('Todos los campos son obligatorios'));
    });

    test('register rechaza correo inválido', () async {
      final result = await authService.register(
        email: 'notanemail',
        password: 'Admin123*',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('formato del correo'));
    });

    test('register rechaza contraseña corta', () async {
      final result = await authService.register(
        email: 'test@paperboost.com',
        password: '12345',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('6 caracteres'));
    });

    test('register rechaza cuando ya existe usuario registrado', () async {
      final result = await authService.register(
        email: 'newuser@paperboost.com',
        password: 'NewUser123*',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('Ya existe un usuario registrado'));
    });
  });

  group('AuthService - RQF-002: Registro de Usuario (Repositorio limpio)', () {
    test('register crea cuenta exitosamente con repositorio limpio', () async {
      final userRepository = _CleanUserRepository();
      final sessionManager = SessionManager();
      final authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );

      final result = await authService.register(
        email: 'owner@paperboost.com',
        password: 'Owner123*',
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.email, 'owner@paperboost.com');
      expect(result.data!.passwordHash, isNotEmpty);
      expect(result.data!.passwordSalt, 'paperboost-owner-salt');
      expect(authService.isAuthenticated, true);
    });

    test('register maneja error del repositorio', () async {
      final userRepository = _ThrowingUserRepository();
      final sessionManager = SessionManager();
      final authService = AuthService(
        userRepository: userRepository,
        sessionManager: sessionManager,
      );

      final result = await authService.register(
        email: 'owner@paperboost.com',
        password: 'Owner123*',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo crear la cuenta'));
    });
  });
}

class _CleanUserRepository implements UserRepository {
  final List<AppUser> _users = [];

  @override
  Future<AppUser?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    for (final user in _users) {
      if (user.email.toLowerCase() == normalized) return user;
    }
    return null;
  }

  @override
  Future<bool> hasRegisteredUser() async => _users.isNotEmpty;

  @override
  Future<void> createUser(AppUser user) async {
    _users.add(user);
  }
}

class _ThrowingUserRepository implements UserRepository {
  @override
  Future<AppUser?> findByEmail(String email) async => null;

  @override
  Future<bool> hasRegisteredUser() async => false;

  @override
  Future<void> createUser(AppUser user) async {
    throw Exception('Simulated repository error');
  }
}
