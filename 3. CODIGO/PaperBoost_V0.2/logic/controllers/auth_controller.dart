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

  OperationResult<void> logout() {
    return _authService.logout();
  }

  bool get isAuthenticated =>
      _authService.isAuthenticated;

  AppUser? get currentUser =>
      _authService.currentUser;
}