import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/security/password_hasher.dart';
import '../results/operation_result.dart';
import '../session/session_manager.dart';
import '../validators/auth_validator.dart';

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

    if (!AuthValidator.isValidEmail(normalizedEmail)) {
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

  /// Permite ingresar al sistema de forma inmediata sin credenciales.
  Future<OperationResult<AppUser>> loginAsGuest() async {
    final guestUser = AppUser.guest();
    _sessionManager.login(guestUser);

    return OperationResult<AppUser>.success(
      message: 'Ingreso exitoso sin cuenta.',
      data: guestUser,
    );
  }

  /// Registra al único dueño/emprendedor en el sistema.
  Future<OperationResult<AppUser>> register({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return OperationResult<AppUser>.failure(
        message: 'Todos los campos son obligatorios.',
      );
    }

    if (!AuthValidator.isValidEmail(normalizedEmail)) {
      return OperationResult<AppUser>.failure(
        message: 'El formato del correo electrónico no es válido.',
      );
    }

    if (!AuthValidator.isValidPassword(normalizedPassword)) {
      return OperationResult<AppUser>.failure(
        message: 'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    // Regla de Negocio: Validar si ya existe el usuario único
    final alreadyHasUser = await _userRepository.hasRegisteredUser();
    if (alreadyHasUser) {
      return OperationResult<AppUser>.failure(
        message: 'Ya existe un usuario registrado en este dispositivo.',
      );
    }

    const salt = 'paperboost-owner-salt';
    final passwordHash = PasswordHasher.hash(
      password: normalizedPassword,
      salt: salt,
    );

    final newUser = AppUser(
      id: 'USER-001',
      email: normalizedEmail,
      passwordHash: passwordHash,
      passwordSalt: salt,
      role: 'Emprendedor',
    );

    try {
      await _userRepository.createUser(newUser);
      
      // Loguear automáticamente tras el registro para ahorrar un paso extra
      _sessionManager.login(newUser);

      return OperationResult<AppUser>.success(
        message: 'Cuenta de seguridad creada con éxito.',
        data: newUser,
      );
    } catch (e) {
      return OperationResult<AppUser>.failure(
        message: 'No se pudo crear la cuenta: ${e.toString()}',
      );
    }
  }

  /// Consulta si el dispositivo ya cuenta con un usuario registrado.
  Future<bool> hasRegisteredUser() {
    return _userRepository.hasRegisteredUser();
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

  bool get isAuthenticated => _sessionManager.isAuthenticated;

  AppUser? get currentUser => _sessionManager.currentUser;
}