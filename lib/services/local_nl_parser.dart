import '../models/transaction.dart';
import 'nl_entry_service.dart' show NlEntryResult;

/// Free, offline, no-API parser for simple Korean ledger notes like
/// "맥도날드 6000원". Returns null when it can't find an amount — the caller
/// can then fall back to an LLM (or surface a hint). Handles 만/천/백/억 units
/// ("6천"=6000, "1.5만"=15000, "3만5천"=35000, "300만"=3000000), income keywords,
/// and relative dates (오늘/어제/그제/내일, "M월 D일").
class LocalNlParser {
  LocalNlParser._();

  static const _incomeKeywords = [
    '월급', '급여', '용돈', '입금', '수입', '보너스', '상여', '정산',
    '환급', '이자', '알바', '아르바이트', '받',
  ];

  static final _amountToken = RegExp(r'(\d+(?:\.\d+)?)\s*(억|만|천|백|원)?');
  static final _mdRe = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일');
  static final _relDateRe = RegExp(r'(오늘|어제|그저께|그제|내일)');

  static NlEntryResult? parse(String input, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final text = input.trim();
    if (text.isEmpty) return null;

    // Strip date expressions before reading the amount so "6월 14일" digits
    // don't get mistaken for money.
    final amountText = text
        .replaceAll(_mdRe, ' ')
        .replaceAll(_relDateRe, ' ');
    final amount = _amount(amountText);
    if (amount == null || amount <= 0) return null;

    var type = TxType.expense;
    if (text.startsWith('+')) {
      type = TxType.income;
    } else if (text.startsWith('-')) {
      type = TxType.expense;
    } else if (_incomeKeywords.any(text.contains)) {
      type = TxType.income;
    }

    return NlEntryResult(
      type: type,
      amount: amount,
      memo: _memo(text),
      date: _date(text, today),
    );
  }

  static int? _amount(String text) {
    final cleaned = text.replaceAll(',', '');
    var total = 0;
    double? rawFallback; // last unit-less number, used only if no unit seen
    var sawUnit = false;
    for (final m in _amountToken.allMatches(cleaned)) {
      final value = double.tryParse(m.group(1)!);
      if (value == null) continue;
      switch (m.group(2)) {
        case '억':
          total += (value * 100000000).round();
          sawUnit = true;
        case '만':
          total += (value * 10000).round();
          sawUnit = true;
        case '천':
          total += (value * 1000).round();
          sawUnit = true;
        case '백':
          total += (value * 100).round();
          sawUnit = true;
        case '원':
          total += value.round();
          sawUnit = true;
        default:
          rawFallback = value; // unit-less → keep the last one
      }
    }
    if (sawUnit && total > 0) return total;
    return rawFallback?.round();
  }

  static DateTime _date(String text, DateTime today) {
    if (text.contains('그저께') || text.contains('그제')) {
      return today.subtract(const Duration(days: 2));
    }
    if (text.contains('어제')) return today.subtract(const Duration(days: 1));
    if (text.contains('내일')) return today.add(const Duration(days: 1));
    final md = _mdRe.firstMatch(text);
    if (md != null) {
      final mo = int.parse(md.group(1)!);
      final da = int.parse(md.group(2)!);
      if (mo >= 1 && mo <= 12 && da >= 1 && da <= 31) {
        return DateTime(today.year, mo, da);
      }
    }
    return today; // 오늘 or unspecified
  }

  static String _memo(String text) {
    var s = text
        .replaceAll(RegExp(r'^[+\-]\s*'), '')
        .replaceAll(_mdRe, ' ')
        .replaceAll(_relDateRe, ' ')
        // amount with explicit 원
        .replaceAll(RegExp(r'\d[\d,\.]*\s*(억|만|천|백)?\s*원'), ' ')
        // amount with a unit
        .replaceAll(RegExp(r'\d[\d,\.]*\s*(억|만|천|백)'), ' ')
        // any remaining multi-digit number
        .replaceAll(RegExp(r'\d[\d,\.]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s;
  }
}
