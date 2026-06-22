// NlEntryService tries the free offline LocalNlParser first; only notes it can't
// parse (no digits) fall through to the Google Gemini API. These tests exercise
// that LLM fallback path with digit-free inputs.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_account_book_app/models/transaction.dart';
import 'package:my_account_book_app/services/nl_entry_service.dart';

http.Response _ok(Map<String, dynamic> parsed) => http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': jsonEncode(parsed)}
              ]
            }
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('digit-free note falls through to Gemini', () async {
    late Map<String, dynamic> sent;
    final mock = MockClient((req) async {
      expect(req.url.host, 'generativelanguage.googleapis.com');
      expect(req.url.path, contains('gemini-2.0-flash'));
      expect(req.headers['x-goog-api-key'], 'test-key');
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return _ok({
        'type': 'expense',
        'amount': 6000,
        'memo': '맥도날드',
        'date': '2026-06-14',
      });
    });
    final svc = NlEntryService(client: mock, apiKey: 'test-key');

    // "육천" has no digits, so the local parser returns null.
    final r = await svc.parse('맥도날드 육천원', now: DateTime(2026, 6, 14));

    expect(sent['generationConfig']['responseMimeType'], 'application/json');
    expect(sent['generationConfig']['responseSchema'], isNotNull);
    expect(r.type, TxType.expense);
    expect(r.amount, 6000);
    expect(r.memo, '맥도날드');
    expect(r.date, DateTime(2026, 6, 14));
  });

  test('amount returned as a string is still parsed', () async {
    final mock = MockClient((_) async => _ok({
          'type': 'income',
          'amount': '3000000',
          'memo': '월급',
          'date': '2026-06-25',
        }));
    final svc = NlEntryService(client: mock, apiKey: 'test-key');

    final r = await svc.parse('월급으로 삼백만원 들어옴');
    expect(r.type, TxType.income);
    expect(r.amount, 3000000);
  });

  test('a zero/unknown amount from the LLM is rejected', () async {
    final mock = MockClient((_) async =>
        _ok({'type': 'expense', 'amount': 0, 'memo': '', 'date': '2026-06-14'}));
    final svc = NlEntryService(client: mock, apiKey: 'test-key');

    expect(() => svc.parse('뭔가 애매한 메모'), throwsA(isA<NlEntryException>()));
  });

  test('unparseable note without an API key throws without any network call',
      () async {
    var called = false;
    final mock = MockClient((_) async {
      called = true;
      return http.Response('{}', 200);
    });
    final svc = NlEntryService(client: mock, apiKey: '');

    // No digits → local parser returns null → no key → friendly error, no call.
    expect(() => svc.parse('점심값 얼마였더라'), throwsA(isA<NlEntryException>()));
    expect(called, isFalse);
  });
}
