import '../../data/models/app_user.dart';

class SessionManager {
  SessionManager._internal();

  static final SessionManager _instance =
      SessionManager._internal();

  static SessionManager get instance => _instance;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  void login(AppUser user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }
}