import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_account_book_app/main.dart';
import 'package:my_account_book_app/providers/theme_provider.dart';
import 'package:my_account_book_app/providers/transaction_provider.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final themeProvider = ThemeProvider();
    final txProvider = TransactionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
