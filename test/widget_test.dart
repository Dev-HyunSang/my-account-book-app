// Smoke test: with no stored session, the app boots into the auth screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_account_book_app/main.dart';
import 'package:my_account_book_app/providers/auth_provider.dart';
import 'package:my_account_book_app/providers/income_provider.dart';
import 'package:my_account_book_app/providers/theme_provider.dart';
import 'package:my_account_book_app/providers/transaction_provider.dart';
import 'package:my_account_book_app/services/api_client.dart';
import 'package:my_account_book_app/services/auth_service.dart';
import 'package:my_account_book_app/services/income_service.dart';

void main() {
  testWidgets('Unauthenticated boot shows the login screen', (tester) async {
    // No tokens stored -> bootstrap resolves to unauthenticated without network.
    SharedPreferences.setMockInitialValues({});

    final apiClient = ApiClient();
    final authProvider =
        AuthProvider(client: apiClient, service: AuthService(apiClient));
    final incomeProvider = IncomeProvider(IncomeService(apiClient));
    final themeProvider = ThemeProvider();
    final txProvider = TransactionProvider();

    await themeProvider.load();
    await txProvider.load();
    await authProvider.bootstrap();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: txProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: incomeProvider),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The email-first auth screen asks for the email first, with the "다음" action.
    expect(find.text('이메일을\n입력해 주세요.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '다음'), findsOneWidget);
    expect(find.text('로그인도 가입도, 이메일 하나로 시작해요.'), findsOneWidget);
  });
}
