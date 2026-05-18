import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';

  Future<void> save({required String accessToken, required String refreshToken}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_accessKey, accessToken);
    await p.setString(_refreshKey, refreshToken);
  }

  Future<({String? accessToken, String? refreshToken})> read() async {
    final p = await SharedPreferences.getInstance();
    return (
      accessToken: p.getString(_accessKey),
      refreshToken: p.getString(_refreshKey),
    );
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_accessKey);
    await p.remove(_refreshKey);
  }
}
