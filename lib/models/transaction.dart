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
