// When a live API call fails auth and can't be recovered, the app must drop
// the dead session so AuthGate returns the user to the login screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_account_book_app/providers/auth_provider.dart';
import 'package:my_account_book_app/services/api_client.dart';
import 'package:my_account_book_app/services/auth_service.dart';

void main() {
  test('unrecoverable 401 bounces AuthProvider to unauthenticated', () async {
    SharedPreferences.setMockInitialValues({});

    // Every request (including the refresh attempt) returns 401.
    final mock = MockClient((req) async =>
        http.Response('{"message":"unauthorized"}', 401));

    final api = ApiClient(client: mock);
    await api.setTokens(accessToken: 'access', refreshToken: 'refresh');

    final auth = AuthProvider(client: api, service: AuthService(api));
    expect(api.isAuthenticated, isTrue);

    // A live authenticated call fails → still throws to the caller…
    await expectLater(api.get('/incomes'), throwsA(isA<ApiException>()));

    // …but the dead session is dropped and tokens are cleared.
    expect(auth.status, AuthStatus.unauthenticated);
    expect(api.isAuthenticated, isFalse);
  });

  test('successful authenticated call leaves the session intact', () async {
    SharedPreferences.setMockInitialValues({});

    final mock = MockClient((req) async => http.Response('[]', 200));
    final api = ApiClient(client: mock);
    await api.setTokens(accessToken: 'access', refreshToken: 'refresh');
    final auth = AuthProvider(client: api, service: AuthService(api));

    await api.get('/incomes');

    expect(api.isAuthenticated, isTrue);
    // Status is only set by explicit flows; the guard must NOT fire here.
    expect(auth.status, isNot(AuthStatus.unauthenticated));
  });
}
