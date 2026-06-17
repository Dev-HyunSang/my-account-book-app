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

  AuthProvider({required this.client, required this.service}) {
    // When a live API call hits an unrecoverable 401, drop the dead session
    // so AuthGate sends the user back to the login screen.
    client.onUnauthorized = _handleSessionExpired;
  }

  void _handleSessionExpired() {
    if (_status == AuthStatus.unauthenticated) return;
    client.clearTokens();
    _set(AuthStatus.unauthenticated);
  }

  Future<void> bootstrap() async {
    await client.loadTokens();
    if (!client.isAuthenticated) {
      _set(AuthStatus.unauthenticated);
      return;
    }
    if (await service.verify()) {
      _set(AuthStatus.authenticated);
      return;
    }
    // The access token may simply be expired — rotate it with the refresh
    // token before forcing the user back to the login screen.
    if (client.refreshToken != null && await client.refreshTokens()) {
      _set(await service.verify()
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated);
      return;
    }
    _set(AuthStatus.unauthenticated);
  }

  /// True when the email is not yet registered (→ send to signup).
  Future<bool> isEmailAvailable(String email) => service.isEmailAvailable(email);

  Future<void> login(String email, String password) async {
    await service.login(email, password);
    _set(AuthStatus.authenticated);
  }

  Future<void> register({
    required String email,
    required String password,
    required String nickname,
    required bool agreeTerms,
    required bool agreePrivacy,
  }) async {
    await service.register(
      email: email,
      password: password,
      nickname: nickname,
      agreeTerms: agreeTerms,
      agreePrivacy: agreePrivacy,
    );
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
