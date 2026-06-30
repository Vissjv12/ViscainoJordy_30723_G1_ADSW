import '../models/app_user.dart';
import '../security/password_hasher.dart';
import 'user_repository.dart';

class InMemoryUserRepository implements UserRepository {
  InMemoryUserRepository() {
    _loadInitialUser();
  }

  final List<AppUser> _users = [];

  void _loadInitialUser() {
    const salt = 'paperboost-admin-salt';

    final passwordHash = PasswordHasher.hash(
      password: 'Admin123*',
      salt: salt,
    );

    _users.add(
      AppUser(
        id: 'USER-001',
        email: 'admin@paperboost.com',
        passwordHash: passwordHash,
        passwordSalt: salt,
        role: 'Administrador',
      ),
    );
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
}