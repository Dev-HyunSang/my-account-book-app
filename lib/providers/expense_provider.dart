import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/expense_service.dart';

/// Holds the authenticated user's expense entries, backed by the REST API.
/// Mirrors [IncomeProvider].
class ExpenseProvider extends ChangeNotifier {
  final ExpenseService service;
  ExpenseProvider(this.service);

  final List<ExpenseItem> _items = [];
  List<ExpenseItem> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _loaded = false;
  bool get loaded => _loaded;

  double get total => _items.fold(0.0, (s, e) => s + e.amountValue);

  List<ExpenseItem> forDay(DateTime day) => _items
      .where((e) =>
          e.expenseDate.year == day.year &&
          e.expenseDate.month == day.month &&
          e.expenseDate.day == day.day)
      .toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await service.list(limit: 200);
      _items
        ..clear()
        ..addAll(list);
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add({
    required DateTime expenseDate,
    required String amount,
    String? memo,
  }) async {
    final created =
        await service.create(expenseDate: expenseDate, amount: amount, memo: memo);
    _items.add(created);
    _sort();
    notifyListeners();
  }

  Future<void> edit(
    String id, {
    DateTime? expenseDate,
    String? amount,
    String? memo,
  }) async {
    final updated = await service.update(id,
        expenseDate: expenseDate, amount: amount, memo: memo);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _items[idx] = updated;
      _sort();
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  void _sort() => _items.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
}
