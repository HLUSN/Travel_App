import '../models/user.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  static UserSession get instance => _instance;
  UserSession._internal();

  Users? _currentUser;

  Users? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  void login(Users user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }

  int? get currentUserId => _currentUser?.id;
  String? get currentUserName => _currentUser?.name;
  String? get currentUserEmail => _currentUser?.email;
}
