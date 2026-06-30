import '../models/app_user.dart';

abstract class UserRepository {
  Future<AppUser?> findByEmail(String email);
}