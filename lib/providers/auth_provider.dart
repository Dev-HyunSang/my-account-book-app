import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient client;
  final AuthService service;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider({required this.client, required this.service});

  Future<void> bootstrap() async {
    await client.loadTokens();
    if (!client.isAuthenticated) {
      _set(AuthStatus.unauthenticated);
      return;
    }
    final ok = await service.verify();
    _set(ok ? AuthStatus.authenticated : AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    await service.login(email, password);
    _set(AuthStatus.authenticated);
  }

  Future<void> register({required String email, required String password, required String nickname}) async {
    await service.register(email: email, password: password, nickname: nickname);
    _set(AuthStatus.authenticated);
  }

  Future<void> logout() async {
    await service.logout();
    _set(AuthStatus.unauthenticated);
  }

  void _set(AuthStatus s) {
    _status = s;
    notifyListeners();
  }
}
