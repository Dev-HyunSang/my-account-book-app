// The Toss-style signup flow asks one thing per screen and requires a strong,
// twice-entered password before registration is allowed.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_account_book_app/providers/auth_provider.dart';
import 'package:my_account_book_app/screens/auth_screen.dart';
import 'package:my_account_book_app/services/api_client.dart';
import 'package:my_account_book_app/services/auth_service.dart';

Widget _app(AuthProvider auth) => MultiProvider(
      providers: [ChangeNotifierProvider.value(value: auth)],
      child: const MaterialApp(home: AuthScreen()),
    );

/// New-email signup; captures the /auth/register body so we can assert on it.
(AuthProvider, List<Map<String, dynamic>>) _signupHarness() {
  final registered = <Map<String, dynamic>>[];
  final mock = MockClient((req) async {
    if (req.url.path.endsWith('/auth/check-email')) {
      return http.Response('{"available":true}', 200);
    }
    if (req.url.path.endsWith('/auth/register')) {
      registered.add(jsonDecode(req.body) as Map<String, dynamic>);
      return http.Response('{"accessToken":"a","refreshToken":"r"}', 200);
    }
    return http.Response('{}', 200);
  });
  final api = ApiClient(client: mock);
  return (AuthProvider(client: api, service: AuthService(api)), registered);
}

Future<void> _tapNext(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('weak password is rejected before reaching the confirm step',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (auth, _) = _signupHarness();
    await tester.pumpWidget(_app(auth));

    await tester.enterText(find.byType(TextField).first, 'new@example.com');
    await _tapNext(tester, '다음'); // email -> nickname
    await tester.enterText(find.byType(TextField).first, '현상');
    await _tapNext(tester, '다음'); // nickname -> password

    // Missing uppercase / special char -> stays on the password step.
    await tester.enterText(find.byType(TextField).first, 'abcdefgh');
    await _tapNext(tester, '다음');
    expect(find.textContaining('특수문자'), findsWidgets);
    expect(find.text('비밀번호를\n한 번 더 입력해 주세요.'), findsNothing);
  });

  testWidgets('strong password requires a matching confirmation to register',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (auth, registered) = _signupHarness();
    await tester.pumpWidget(_app(auth));

    await tester.enterText(find.byType(TextField).first, 'new@example.com');
    await _tapNext(tester, '다음'); // email -> nickname
    await tester.enterText(find.byType(TextField).first, '현상');
    await _tapNext(tester, '다음'); // nickname -> password

    await tester.enterText(find.byType(TextField).first, 'Abcdef1!');
    await _tapNext(tester, '다음'); // password -> confirm
    expect(find.text('비밀번호를\n한 번 더 입력해 주세요.'), findsOneWidget);

    // Mismatched confirmation blocks progress.
    await tester.enterText(find.byType(TextField).first, 'Abcdef1?');
    await _tapNext(tester, '다음');
    expect(find.text('비밀번호가 일치하지 않아요'), findsOneWidget);

    // Matching confirmation advances to the agreements step.
    await tester.enterText(find.byType(TextField).first, 'Abcdef1!');
    await _tapNext(tester, '다음'); // confirm -> agreements
    await tester.tap(find.text('약관 전체 동의'));
    await tester.pumpAndSettle();
    await _tapNext(tester, '가입 완료');

    expect(auth.isAuthenticated, isTrue);
    expect(registered, hasLength(1));
    expect(registered.first['password'], 'Abcdef1!');
    expect(registered.first['nickname'], '현상');
  });
}
