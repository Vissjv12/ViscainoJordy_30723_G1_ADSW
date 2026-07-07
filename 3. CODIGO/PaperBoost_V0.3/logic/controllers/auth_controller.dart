import '../../data/models/app_user.dart';
import '../results/operation_result.dart';
import '../services/auth_service.dart';

class AuthController {
  AuthController({
    required AuthService authService,
  }) : _authService = authService;

  final AuthService _authService;

  Future<OperationResult<AppUser>> login({
    required String email,
    required String password,
  }) {
    return _authService.login(
      email: email,
      password: password,
    );
  }

  /// Expone el inicio de sesión rápido como invitado.
  Future<OperationResult<AppUser>> loginAsGuest() {
    return _authService.loginAsGuest();
  }

  /// Expone la creación del usuario único del sistema.
  Future<OperationResult<AppUser>> register({
    required String email,
    required String password,
  }) {
    return _authService.register(
      email: email,
      password: password,
    );
  }

  /// Informa si ya existe una cuenta creada en el sistema.
  Future<bool> hasRegisteredUser() {
    return _authService.hasRegisteredUser();
  }

  OperationResult<void> logout() {
    return _authService.logout();
  }

  bool get isAuthenticated => _authService.isAuthenticated;

  AppUser? get currentUser => _authService.currentUser;
}