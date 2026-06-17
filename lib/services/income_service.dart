import '../models/transaction.dart';
import 'api_client.dart';

class IncomeService {
  final ApiClient client;
  IncomeService(this.client);

  Future<List<IncomeItem>> list({int offset = 0, int limit = 50}) async {
    final j = await client.get('/incomes',
        query: {'offset': offset, 'limit': limit}) as Map<String, dynamic>;
    final items = (j['items'] as List?) ?? const [];
    return items
        .map((e) => IncomeItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IncomeItem> create({required DateTime incomeDate, required String amount, String? memo}) async {
    final body = <String, dynamic>{
      'incomeDate': _formatDate(incomeDate),
      'amount': amount,
    };
    if (memo != null && memo.isNotEmpty) body['memo'] = memo;
    final j = await client.post('/incomes', body: body) as Map<String, dynamic>;
    return IncomeItem.fromJson(j);
  }

  Future<IncomeItem> update(String id, {DateTime? incomeDate, String? amount, String? memo}) async {
    final body = <String, dynamic>{};
    if (incomeDate != null) body['incomeDate'] = _formatDate(incomeDate);
    if (amount != null) body['amount'] = amount;
    if (memo != null) body['memo'] = memo;
    final j = await client.patch('/incomes/$id', body: body) as Map<String, dynamic>;
    return IncomeItem.fromJson(j);
  }

  Future<void> delete(String id) async {
    await client.delete('/incomes/$id');
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}
