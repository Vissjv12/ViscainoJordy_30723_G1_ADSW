import '../models/app_user.dart';

abstract class UserRepository {
  /// Busca un usuario registrado por su correo electrónico (Autenticación).
  Future<AppUser?> findByEmail(String email);

  /// Verifica si ya existe un usuario registrado en el dispositivo.
  /// Útil para saber si se debe mostrar la opción de "Crear Cuenta" o "Login".
  Future<bool> hasRegisteredUser();

  /// Registra al usuario único en el sistema.
  Future<void> createUser(AppUser user);
}