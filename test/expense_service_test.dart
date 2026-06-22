// ExpenseService maps to the Swagger /expenses contract: string amount,
// yyyy-MM-dd dates, and a paginated { items, total, offset, limit } list.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_account_book_app/services/api_client.dart';
import 'package:my_account_book_app/services/expense_service.dart';

void main() {
  test('list() parses the paginated items payload', () async {
    final mock = MockClient((req) async {
      expect(req.url.path, endsWith('/expenses'));
      expect(req.url.queryParameters['limit'], '200');
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'e1',
              'expenseDate': '2026-05-17',
              'amount': '12000',
              'memo': '점심 식대',
              'createdAt': '2026-05-17T09:00:00.000Z',
              'updatedAt': '2026-05-17T09:00:00.000Z',
            }
          ],
          'total': 1,
          'offset': 0,
          'limit': 200,
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final svc = ExpenseService(ApiClient(client: mock));

    final items = await svc.list(limit: 200);
    expect(items, hasLength(1));
    expect(items.first.id, 'e1');
    expect(items.first.amountValue, 12000);
    expect(items.first.expenseDate, DateTime(2026, 5, 17));
    expect(items.first.memo, '점심 식대');
  });

  test('create() posts a yyyy-MM-dd date and string amount', () async {
    late Map<String, dynamic> sent;
    final mock = MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 'e2',
          'expenseDate': sent['expenseDate'],
          'amount': sent['amount'],
          'memo': sent['memo'],
          'createdAt': '2026-05-18T00:00:00.000Z',
          'updatedAt': '2026-05-18T00:00:00.000Z',
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final svc = ExpenseService(ApiClient(client: mock));

    final created = await svc.create(
      expenseDate: DateTime(2026, 5, 18),
      amount: '3500',
      memo: '커피',
    );
    expect(sent['expenseDate'], '2026-05-18');
    expect(sent['amount'], '3500');
    expect(sent['memo'], '커피');
    expect(created.id, 'e2');
    expect(created.amountValue, 3500);
  });
}
