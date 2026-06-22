import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../services/api_client.dart';
import '../services/nl_entry_service.dart';
import '../theme/app_tokens.dart';

/// Quick-entry only sheet: type a natural-language note ("맥도날드 6000원"),
/// let Claude parse it into a structured entry, confirm the preview, and save.
/// No keypad / category chips / type toggle — one field does it all.
class AddTransactionSheet extends StatefulWidget {
  final DateTime? initialDate;
  final TxType initialType; // kept for call-site compatibility; unused
  const AddTransactionSheet({
    super.key,
    this.initialDate,
    this.initialType = TxType.expense,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _nlCtrl = TextEditingController();
  final _nl = NlEntryService();

  NlEntryResult? _parsed; // null until analyzed
  bool _busy = false;
  String? _error;

  static const _dow = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void dispose() {
    _nlCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _nlCtrl.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _nl.parse(text, now: widget.initialDate);
      if (!mounted) return;
      setState(() => _parsed = r);
    } on NlEntryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '분석에 실패했어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final r = _parsed;
    if (r == null || _busy) return;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final memo = r.memo.isEmpty ? (r.type == TxType.income ? '수입' : '지출') : r.memo;
      if (r.type == TxType.income) {
        await context.read<IncomeProvider>().add(
              incomeDate: r.date,
              amount: r.amount.toString(),
              memo: memo,
            );
      } else {
        await context.read<ExpenseProvider>().add(
              expenseDate: r.date,
              amount: r.amount.toString(),
              memo: memo,
            );
      }
      navigator.pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '저장에 실패했어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() => setState(() {
        _parsed = null;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: TjColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(TjRadii.xl)),
      ),
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TjColors.ink4,
                    borderRadius: BorderRadius.circular(TjRadii.full),
                  ),
                ),
              ),

              // Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 20, color: TjColors.stamp),
                    const SizedBox(width: 8),
                    Text('빠른 입력', style: TjType.h1.copyWith(fontSize: 22)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  '한 줄로 적으면 알아서 기록해요.  예) 맥도날드 6000원 · 어제 택시 8천 · 월급 300만원',
                  style: TjType.body.copyWith(color: TjColors.ink2, fontSize: 13, height: 1.5),
                ),
              ),

              // The single input
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: TextField(
                  controller: _nlCtrl,
                  enabled: !_busy,
                  autofocus: true,
                  textInputAction: TextInputAction.go,
                  onChanged: (_) {
                    if (_parsed != null || _error != null) _reset();
                  },
                  onSubmitted: (_) => _analyze(),
                  style: TjType.body.copyWith(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '예: 맥도날드 6000원',
                    prefixIcon: Icon(LucideIcons.pencilLine),
                  ),
                ),
              ),

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.circleAlert, size: 16, color: TjColors.expense),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_error!,
                            style: TjType.caption.copyWith(color: TjColors.expense)),
                      ),
                    ],
                  ),
                ),

              // Preview (after analysis)
              if (_parsed != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: _PreviewCard(result: _parsed!),
                ),
              ],

              // Primary action
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _parsed == null
                    ? FilledButton(
                        onPressed: _busy ? null : _analyze,
                        child: _busy
                            ? const _Spinner()
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('분석하기'),
                                  SizedBox(width: 6),
                                  Icon(LucideIcons.sparkles, size: 18, color: TjColors.onInk),
                                ],
                              ),
                      )
                    : Column(
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _parsed!.type == TxType.income
                                  ? TjColors.ink
                                  : TjColors.stamp,
                            ),
                            onPressed: _busy ? null : _save,
                            child: _busy
                                ? const _Spinner()
                                : Text(
                                    '${formatWon(_parsed!.amount)} '
                                    '${_parsed!.type == TxType.income ? '수입' : '지출'} 기록',
                                  ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _busy ? null : _reset,
                            child: const Text('다시 입력'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String prettyDate(DateTime d) => '${d.month}월 ${d.day}일 (${_dow[d.weekday % 7]})';
}

class _PreviewCard extends StatelessWidget {
  final NlEntryResult result;
  const _PreviewCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isIncome = result.type == TxType.income;
    final color = isIncome ? TjColors.income : TjColors.expense;
    final bg = isIncome ? TjColors.incomeSoft : TjColors.expenseSoft;
    final memo = result.memo.isEmpty ? (isIncome ? '수입' : '지출') : result.memo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TjColors.card,
        borderRadius: BorderRadius.circular(TjRadii.lg),
        border: Border.all(color: TjColors.divider),
        boxShadow: TjShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(TjRadii.md),
            ),
            child: Icon(
              isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TjType.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${isIncome ? '수입' : '지출'} · ${_AddTransactionSheetState.prettyDate(result.date)}',
                  style: TjType.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isIncome ? '+' : '-'}${formatWon(result.amount)}',
            style: TjType.money(size: 18, color: color),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: TjColors.onInk),
      );
}
