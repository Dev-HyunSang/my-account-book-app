import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth_gate.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'services/income_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load local secrets (Gemini API key for the quick-entry parser). Optional —
  // the app still runs if .env is missing; quick entry just stays disabled.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // REST API wiring: a single ApiClient owns the tokens and is shared by the
  // auth and income services.
  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final incomeService = IncomeService(apiClient);
  final expenseService = ExpenseService(apiClient);

  final themeProvider = ThemeProvider();
  final txProvider = TransactionProvider();
  final authProvider =
      AuthProvider(client: apiClient, service: authService);
  final incomeProvider = IncomeProvider(incomeService);
  final expenseProvider = ExpenseProvider(expenseService);

  await Future.wait([themeProvider.load(), txProvider.load()]);
  // Restore the session (validates any stored token against the API).
  await authProvider.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: txProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: incomeProvider),
        ChangeNotifierProvider.value(value: expenseProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp(
      title: '텅장 탈출기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
