import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';
import 'local_nl_parser.dart';

/// Resolves the Google Gemini API key without hard-coding it. Precedence:
///   1. --dart-define=GEMINI_API_KEY=...  (build-time)
///   2. GEMINI_API_KEY in the bundled .env  (loaded in main via flutter_dotenv)
/// Get a free key at https://aistudio.google.com/app/apikey
String resolveGeminiApiKey() {
  const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
  if (fromDefine.isNotEmpty) return fromDefine;
  if (dotenv.isInitialized) {
    return dotenv.maybeGet('GEMINI_API_KEY') ?? '';
  }
  return '';
}

/// Parsed result of a free-form note like "맥도날드 6000원".
class NlEntryResult {
  final TxType type;
  final int amount;
  final String memo;
  final DateTime date;

  NlEntryResult({
    required this.type,
    required this.amount,
    required this.memo,
    required this.date,
  });
}

class NlEntryException implements Exception {
  final String message;
  NlEntryException(this.message);
  @override
  String toString() => message;
}

/// Turns a free-form Korean ledger note into a structured income/expense entry
/// using Google Gemini (free tier) via the Generative Language API. The backend
/// has no category field, so the description is folded into [NlEntryResult.memo]
/// — matching how the rest of the app stores incomes/expenses.
class NlEntryService {
  final http.Client _http;
  final String apiKey;
  final String model;

  NlEntryService({http.Client? client, String? apiKey, this.model = 'gemini-2.0-flash'})
      : _http = client ?? http.Client(),
        apiKey = apiKey ?? resolveGeminiApiKey();

  Uri get _url => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');

  bool get isConfigured => apiKey.isNotEmpty;

  Future<NlEntryResult> parse(String text, {DateTime? now}) async {
    final today = now ?? DateTime.now();

    // 1) Free, offline, no-quota path — handles the common "가게명 금액" shape.
    final local = LocalNlParser.parse(text, now: today);
    if (local != null) return local;

    // 2) Only ambiguous free-form notes reach the LLM.
    if (!isConfigured) {
      throw NlEntryException(
          '금액을 못 찾았어요. "가게명 금액"으로 적어주세요. 예) 맥도날드 6000원');
    }
    final body = <String, dynamic>{
      'system_instruction': {
        'parts': [
          {'text': _system(_ymd(today))}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': text}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': _schema,
        'temperature': 0,
      },
    };

    http.Response res;
    try {
      res = await _http.post(
        _url,
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw NlEntryException('요청에 실패했어요: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw NlEntryException(_errorMessage(res));
    }

    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final raw = _extractJson(j);
    if (raw == null) {
      throw NlEntryException('응답을 이해하지 못했어요.');
    }
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    return _toResult(parsed, fallbackDate: today);
  }

  /// Gemini returns: candidates[0].content.parts[0].text (a JSON string).
  String? _extractJson(Map<String, dynamic> j) {
    final candidates = j['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final content = (candidates.first as Map)['content'] as Map?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;
    return (parts.first as Map)['text'] as String?;
  }

  NlEntryResult _toResult(Map<String, dynamic> j, {required DateTime fallbackDate}) {
    final typeStr = (j['type'] as String?) ?? 'expense';
    // Gemini may return amount as a number or a numeric string.
    final amountRaw = j['amount'];
    final amount = amountRaw is num
        ? amountRaw.round()
        : int.tryParse(amountRaw?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
    final memo = ((j['memo'] as String?) ?? '').trim();
    if (amount <= 0) throw NlEntryException('금액을 알아내지 못했어요.');

    var date = DateTime(fallbackDate.year, fallbackDate.month, fallbackDate.day);
    final dateStr = j['date'] as String?;
    if (dateStr != null) {
      final d = DateTime.tryParse(dateStr);
      if (d != null) date = DateTime(d.year, d.month, d.day);
    }

    return NlEntryResult(
      type: typeStr == 'income' ? TxType.income : TxType.expense,
      amount: amount,
      memo: memo,
      date: date,
    );
  }

  String _errorMessage(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is Map && j['error'] is Map && j['error']['message'] != null) {
        return 'AI 분석 실패: ${j['error']['message']}';
      }
    } catch (_) {}
    return 'AI 분석 실패 (HTTP ${res.statusCode})';
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _system(String today) =>
      '너는 한국어 가계부 메모 한 줄을 거래 항목으로 변환한다.\n'
      '오늘 날짜는 $today (KST) 기준이다.\n'
      '- type: 수입·급여·월급·용돈·입금·받은 돈이면 "income", 그 외에는 "expense".\n'
      '- amount: 원 단위 정수. "6천"=6000, "1만"=10000, "1.5만"=15000, "육천"=6000.\n'
      '- memo: 금액을 뺀 가게명·내용만 짧게. 없으면 빈 문자열.\n'
      '- date: yyyy-MM-dd. "오늘"=오늘, "어제"=어제, 명시가 없으면 오늘.\n'
      '반드시 주어진 스키마(JSON)로만 답한다.';

  // Gemini schema dialect — uppercase type names, propertyOrdering for stability.
  static const Map<String, dynamic> _schema = {
    'type': 'OBJECT',
    'properties': {
      'type': {
        'type': 'STRING',
        'enum': ['income', 'expense'],
      },
      'amount': {'type': 'INTEGER'},
      'memo': {'type': 'STRING'},
      'date': {'type': 'STRING'},
    },
    'required': ['type', 'amount', 'memo', 'date'],
    'propertyOrdering': ['type', 'amount', 'memo', 'date'],
  };
}
