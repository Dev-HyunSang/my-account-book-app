import 'dart:convert';

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

enum TxType { income, expense }

class TxItem {
  final String id;
  final TxType type;
  final double amount;
  final String category;
  final String memo;
  final DateTime date;
  final bool recurring;

  TxItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.memo,
    required this.date,
    this.recurring = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'memo': memo,
        'date': date.toIso8601String(),
        'recurring': recurring,
      };

  factory TxItem.fromJson(Map<String, dynamic> j) => TxItem(
        id: j['id'] as String,
        type: TxType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TxType.expense,
        ),
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String? ?? '',
        memo: j['memo'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
        recurring: j['recurring'] as bool? ?? false,
      );

  static String encodeList(List<TxItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<TxItem> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TxItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
