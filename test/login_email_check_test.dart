// The email-first login screen calls /auth/check-email and branches:
//   available (not registered) → signup; otherwise → password step.

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

AuthProvider _authWith(bool available) {
  final mock = MockClient((req) async {
    if (req.url.path.endsWith('/auth/check-email')) {
      return http.Response('{"available":$available}', 200);
    }
    return http.Response('{}', 200);
  });
  final api = ApiClient(client: mock);
  return AuthProvider(client: api, service: AuthService(api));
}

void main() {
  testWidgets('new email branches into the signup nickname step', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app(_authWith(true)));

    await tester.enterText(find.byType(TextField).first, 'new@example.com');
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();

    // Signup mode badge + the nickname question are now active.
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('닉네임'), findsOneWidget);
    // The answered email is parked in the recap stack.
    expect(find.text('new@example.com'), findsOneWidget);
  });

  testWidgets('registered email branches into the login password step', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app(_authWith(false)));

    await tester.enterText(find.byType(TextField).first, 'known@example.com');
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();

    // Login mode: password is the single active field, CTA reads 로그인.
    expect(find.text('로그인'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
    expect(find.text('비밀번호'), findsWidgets);
  });
}
