// The free, offline parser for simple "가게명 금액" notes.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_account_book_app/models/transaction.dart';
import 'package:my_account_book_app/services/local_nl_parser.dart';

void main() {
  final today = DateTime(2026, 6, 14); // (일) Sunday

  test('"맥도날드 6000원" → expense 6000 today', () {
    final r = LocalNlParser.parse('맥도날드 6000원', now: today)!;
    expect(r.type, TxType.expense);
    expect(r.amount, 6000);
    expect(r.memo, '맥도날드');
    expect(r.date, today);
  });

  test('comma + 원 ("점심 12,000원")', () {
    final r = LocalNlParser.parse('점심 12,000원', now: today)!;
    expect(r.amount, 12000);
    expect(r.memo, '점심');
  });

  group('Korean units', () {
    final cases = {
      '택시 8천': 8000,
      '커피 1.5만': 15000,
      '월세 300만원': 3000000,
      '용돈 3만5천': 35000,
      '간식 4500': 4500,
    };
    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(LocalNlParser.parse(input, now: today)!.amount, expected);
      });
    });
  });

  test('income keyword → income', () {
    final r = LocalNlParser.parse('월급 3000000', now: today)!;
    expect(r.type, TxType.income);
    expect(r.amount, 3000000);
  });

  test('leading + forces income', () {
    expect(LocalNlParser.parse('+용돈 50000', now: today)!.type, TxType.income);
  });

  test('relative date "어제 택시 8천"', () {
    final r = LocalNlParser.parse('어제 택시 8천', now: today)!;
    expect(r.date, DateTime(2026, 6, 13));
    expect(r.amount, 8000);
    expect(r.memo, '택시');
  });

  test('explicit "M월 D일" date is not mistaken for an amount', () {
    final r = LocalNlParser.parse('6월 10일 마트 23000원', now: today)!;
    expect(r.date, DateTime(2026, 6, 10));
    expect(r.amount, 23000);
  });

  test('returns null when there is no numeric amount', () {
    expect(LocalNlParser.parse('맥도날드 육천원', now: today), isNull);
    expect(LocalNlParser.parse('점심 먹음', now: today), isNull);
  });
}
