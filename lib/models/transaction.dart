import 'dart:convert';

enum TxType { income, expense }

class TxItem {
  final String id;
  final TxType type;
  final double amount;
  final String category;
  final String memo;
  final DateTime date;

  TxItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.memo,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'memo': memo,
        'date': date.toIso8601String(),
      };

  factory TxItem.fromJson(Map<String, dynamic> j) => TxItem(
        id: j['id'] as String,
        type: TxType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => TxType.expense,
        ),
        amount: (j['amount'] as num).toDouble(),
        category: (j['category'] as String?) ?? '',
        memo: (j['memo'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
      );

  static String encodeList(List<TxItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<TxItem> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => TxItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class IncomeItem {
  final String id;
  final DateTime incomeDate;
  final String amount;
  final String? memo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  IncomeItem({
    required this.id,
    required this.incomeDate,
    required this.amount,
    this.memo,
    this.createdAt,
    this.updatedAt,
  });

  double get amountValue => double.tryParse(amount) ?? 0;

  factory IncomeItem.fromJson(Map<String, dynamic> j) => IncomeItem(
        id: j['id'] as String,
        incomeDate: DateTime.parse(j['incomeDate'] as String),
        amount: j['amount'].toString(),
        memo: j['memo'] as String?,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt'] as String),
        updatedAt: j['updatedAt'] == null ? null : DateTime.tryParse(j['updatedAt'] as String),
      );
}

class ExpenseItem {
  final String id;
  final DateTime expenseDate;
  final String amount;
  final String? memo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseItem({
    required this.id,
    required this.expenseDate,
    required this.amount,
    this.memo,
    this.createdAt,
    this.updatedAt,
  });

  double get amountValue => double.tryParse(amount) ?? 0;

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        id: j['id'] as String,
        expenseDate: DateTime.parse(j['expenseDate'] as String),
        amount: j['amount'].toString(),
        memo: j['memo'] as String?,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt'] as String),
        updatedAt: j['updatedAt'] == null ? null : DateTime.tryParse(j['updatedAt'] as String),
      );
}
