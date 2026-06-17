import 'api_client.dart';

class AuthService {
  final ApiClient client;
  AuthService(this.client);

  /// Returns true when the email is **available** (not yet registered), i.e.
  /// the user should be sent to signup. False means the account exists → login.
  Future<bool> isEmailAvailable(String email) async {
    final j = await client.post('/auth/check-email',
        body: {'email': email}, auth: false) as Map<String, dynamic>;
    return (j['available'] as bool?) ?? false;
  }

  Future<void> login(String email, String password) async {
    final j = await client.post('/auth/login',
        body: {'email': email, 'password': password}, auth: false) as Map<String, dynamic>;
    await client.setTokens(
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String nickname,
    required bool agreeTerms,
    required bool agreePrivacy,
  }) async {
    final j = await client.post('/auth/register',
        body: {
          'email': email,
          'password': password,
          'nickname': nickname,
          'agreeTerms': agreeTerms,
          'agreePrivacy': agreePrivacy,
        },
        auth: false) as Map<String, dynamic>;
    await client.setTokens(
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String,
    );
  }

  Future<bool> verify() async {
    if (!client.isAuthenticated) return false;
    try {
      final j = await client.get('/auth/verify') as Map<String, dynamic>;
      return (j['valid'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await client.post('/auth/logout');
    } catch (_) {
      // Even if revoke fails, clear local tokens.
    }
    await client.clearTokens();
  }
}
