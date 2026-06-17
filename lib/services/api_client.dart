import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

String _defaultBaseUrl() {
  // Android emulator routes host machine via 10.0.2.2
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
  return 'http://localhost:3000/api/v1';
}

class ApiClient {
  final String baseUrl;
  final AuthStorage storage;
  final http.Client _http;

  String? _accessToken;
  String? _refreshToken;

  Future<void>? _refreshing;

  /// Invoked when an authenticated request fails with 401 and the session
  /// cannot be recovered (no refresh token, or refresh failed). The app uses
  /// this to bounce the user back to the login screen.
  void Function()? onUnauthorized;

  ApiClient({String? baseUrl, AuthStorage? storage, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl(),
        storage = storage ?? AuthStorage(),
        _http = client ?? http.Client();

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;

  Future<void> loadTokens() async {
    final t = await storage.read();
    _accessToken = t.accessToken;
    _refreshToken = t.refreshToken;
  }

  Future<void> setTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await storage.save(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await storage.clear();
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    final qp = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) qp[k] = v.toString();
    });
    return base.replace(
      path: '${base.path}$path',
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  Map<String, String> _headers({bool auth = true}) {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth && _accessToken != null) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    return h;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) {
    return _send('DELETE', path, body: body, auth: auth);
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? query, Object? body, bool auth = true, bool retry = true}) async {
    final url = _uri(path, query);
    final headers = _headers(auth: auth);
    final encoded = body == null ? null : jsonEncode(body);

    final req = http.Request(method, url)
      ..headers.addAll(headers)
      ..body = encoded ?? '';
    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 401 && auth && retry && _refreshToken != null) {
      final ok = await _tryRefresh();
      if (ok) return _send(method, path, query: query, body: body, auth: auth, retry: false);
    }

    // Authenticated request still unauthorized after any refresh attempt →
    // the session is dead; notify so the app can return to login.
    if (res.statusCode == 401 && auth) {
      onUnauthorized?.call();
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String msg = res.body;
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['message'] != null) {
        final m = j['message'];
        msg = m is List ? m.join(', ') : m.toString();
      }
    } catch (_) {}
    throw ApiException(res.statusCode, msg.isEmpty ? 'HTTP ${res.statusCode}' : msg);
  }

  /// Force a token rotation using the stored refresh token.
  /// Returns true when a fresh access token was obtained.
  Future<bool> refreshTokens() => _tryRefresh();

  Future<bool> _tryRefresh() {
    _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
    return _refreshing!.then((_) => _accessToken != null).catchError((_) => false);
  }

  Future<void> _doRefresh() async {
    final rt = _refreshToken;
    if (rt == null) return;
    final url = _uri('/auth/refresh');
    final res = await _http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': rt}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      await setTokens(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
      );
    } else {
      await clearTokens();
    }
  }
}
