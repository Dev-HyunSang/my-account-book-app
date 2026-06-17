import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/income_service.dart';

class IncomeProvider extends ChangeNotifier {
  final IncomeService service;
  IncomeProvider(this.service);

  final List<IncomeItem> _items = [];
  List<IncomeItem> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _loaded = false;
  bool get loaded => _loaded;

  double get total => _items.fold(0.0, (s, e) => s + e.amountValue);

  List<IncomeItem> forDay(DateTime day) => _items
      .where((e) =>
          e.incomeDate.year == day.year &&
          e.incomeDate.month == day.month &&
          e.incomeDate.day == day.day)
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
    required DateTime incomeDate,
    required String amount,
    String? memo,
  }) async {
    final created =
        await service.create(incomeDate: incomeDate, amount: amount, memo: memo);
    _items.add(created);
    _sort();
    notifyListeners();
  }

  Future<void> edit(
    String id, {
    DateTime? incomeDate,
    String? amount,
    String? memo,
  }) async {
    final updated = await service.update(id,
        incomeDate: incomeDate, amount: amount, memo: memo);
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

  void _sort() => _items.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
}
