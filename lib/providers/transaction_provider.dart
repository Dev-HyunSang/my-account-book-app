import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  static const _key = 'transactions_v1';

  final List<TxItem> _items = [];
  List<TxItem> get items => List.unmodifiable(_items);

  double get totalIncome => _items
      .where((e) => e.type == TxType.income)
      .fold(0.0, (s, e) => s + e.amount);

  double get totalExpense => _items
      .where((e) => e.type == TxType.expense)
      .fold(0.0, (s, e) => s + e.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      _items.addAll(TxItem.decodeList(raw));
    }
    _sort();
    notifyListeners();
  }

  Future<void> add(TxItem item) async {
    _items.add(item);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  List<TxItem> forDay(DateTime day) {
    return _items
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }

  void _sort() => _items.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, TxItem.encodeList(_items));
  }
}
