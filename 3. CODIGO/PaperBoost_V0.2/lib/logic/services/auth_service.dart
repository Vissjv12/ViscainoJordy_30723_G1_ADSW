import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/security/password_hasher.dart';
import '../results/operation_result.dart';
import '../session/session_manager.dart';

class AuthService {
  AuthService({
    required UserRepository userRepository,
    SessionManager? sessionManager,
  })  : _userRepository = userRepository,
        _sessionManager =
            sessionManager ?? SessionManager.instance;

  final UserRepository _userRepository;
  final SessionManager _sessionManager;

  Future<OperationResult<AppUser>> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty) {
      return OperationResult<AppUser>.failure(
        message: 'Ingrese el correo electrónico.',
      );
    }

    if (normalizedPassword.isEmpty) {
      return OperationResult<AppUser>.failure(
        message: 'Ingrese la contraseña.',
      );
    }

    if (!_isValidEmail(normalizedEmail)) {
      return OperationResult<AppUser>.failure(
        message: 'Ingrese un correo electrónico válido.',
      );
    }

    final user = await _userRepository.findByEmail(
      normalizedEmail,
    );

    if (user == null) {
      return OperationResult<AppUser>.failure(
        message: 'Correo o contraseña incorrectos.',
      );
    }

    final validPassword = PasswordHasher.verify(
      password: normalizedPassword,
      salt: user.passwordSalt,
      expectedHash: user.passwordHash,
    );

    if (!validPassword) {
      return OperationResult<AppUser>.failure(
        message: 'Correo o contraseña incorrectos.',
      );
    }

    _sessionManager.login(user);

    return OperationResult<AppUser>.success(
      message: 'Inicio de sesión correcto.',
      data: user,
    );
  }

  OperationResult<void> logout() {
    if (!_sessionManager.isAuthenticated) {
      return OperationResult<void>.failure(
        message: 'No existe una sesión activa.',
      );
    }

    _sessionManager.logout();

    return OperationResult<void>.success(
      message: 'Sesión cerrada correctamente.',
    );
  }

  bool get isAuthenticated =>
      _sessionManager.isAuthenticated;

  AppUser? get currentUser =>
      _sessionManager.currentUser;

  bool _isValidEmail(String email) {
    final emailExpression = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailExpression.hasMatch(email);
  }
}