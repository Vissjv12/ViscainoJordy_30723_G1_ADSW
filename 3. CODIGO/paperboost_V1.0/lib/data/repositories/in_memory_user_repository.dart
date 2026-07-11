import '../models/app_user.dart';
import '../security/password_hasher.dart';
import 'user_repository.dart';

class InMemoryUserRepository implements UserRepository {
  InMemoryUserRepository() {
    _ensureDefaultUser();
  }

  final List<AppUser> _users = [];

  void _ensureDefaultUser() {
    const salt = 'paperboost-admin-salt';
    const defaultPassword = 'Admin123*';
    final hash = PasswordHasher.hash(
      password: defaultPassword,
      salt: salt,
    );
    _users.add(AppUser(
      id: 'USER-001',
      email: 'admin@paperboost.com',
      passwordHash: hash,
      passwordSalt: salt,
      role: 'Administrador',
    ));
  }

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