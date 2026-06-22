import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

/// Decides what to show based on the auth status and keeps API-backed data
/// in sync with the session (loads incomes on sign-in, clears them on sign-out).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _previous;

  void _syncData(AuthStatus status) {
    if (status == _previous) return;
    _previous = status;
    final income = context.read<IncomeProvider>();
    final expense = context.read<ExpenseProvider>();
    // Defer to after the frame so notifyListeners() never fires mid-build.
    if (status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        income.load();
        expense.load();
      });
    } else if (status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        income.clear();
        expense.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    _syncData(status);

    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
    }
  }
}
