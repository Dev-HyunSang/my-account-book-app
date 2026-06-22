import '../models/transaction.dart';
import 'api_client.dart';

/// REST client for the /expenses endpoints (mirrors [IncomeService]).
class ExpenseService {
  final ApiClient client;
  ExpenseService(this.client);

  Future<List<ExpenseItem>> list({int offset = 0, int limit = 50}) async {
    final j = await client.get('/expenses',
        query: {'offset': offset, 'limit': limit}) as Map<String, dynamic>;
    final items = (j['items'] as List?) ?? const [];
    return items
        .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseItem> create({required DateTime expenseDate, required String amount, String? memo}) async {
    final body = <String, dynamic>{
      'expenseDate': _formatDate(expenseDate),
      'amount': amount,
    };
    if (memo != null && memo.isNotEmpty) body['memo'] = memo;
    final j = await client.post('/expenses', body: body) as Map<String, dynamic>;
    return ExpenseItem.fromJson(j);
  }

  Future<ExpenseItem> update(String id, {DateTime? expenseDate, String? amount, String? memo}) async {
    final body = <String, dynamic>{};
    if (expenseDate != null) body['expenseDate'] = _formatDate(expenseDate);
    if (amount != null) body['amount'] = amount;
    if (memo != null) body['memo'] = memo;
    final j = await client.patch('/expenses/$id', body: body) as Map<String, dynamic>;
    return ExpenseItem.fromJson(j);
  }

  Future<void> delete(String id) async {
    await client.delete('/expenses/$id');
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}
