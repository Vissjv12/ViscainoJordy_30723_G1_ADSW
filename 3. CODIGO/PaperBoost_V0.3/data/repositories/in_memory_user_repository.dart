import '../models/app_user.dart';
import 'user_repository.dart';

class InMemoryUserRepository implements UserRepository {
  InMemoryUserRepository();

  // La lista ahora inicia completamente vacía, no hay usuarios de prueba por defecto.
  final List<AppUser> _users = [];

  @override
  Future<AppUser?> findByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    for (final user in _users) {
      if (user.email.toLowerCase() == normalizedEmail) {
        return user;
      }
    }

    return null;
  }

  @override
  Future<bool> hasRegisteredUser() async {
    // Al estar enfocado en un solo emprendedor, si la lista no está vacía significa que ya hay un dueño.
    return _users.isNotEmpty;
  }

  @override
  Future<void> createUser(AppUser user) async {
    // Garantizamos la restricción de seguridad de un único usuario a nivel de persistencia
    if (_users.isEmpty) {
      _users.add(user);
    } else {
      throw StateError(
        'El sistema ya cuenta con un usuario registrado y no admite múltiples cuentas.',
      );
    }
  }
}