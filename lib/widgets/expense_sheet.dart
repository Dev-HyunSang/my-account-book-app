import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

/// Add/edit sheet for an expense, backed by the REST API. Mirrors [IncomeSheet].
class ExpenseSheet extends StatefulWidget {
  /// When provided, the sheet edits an existing expense; otherwise it creates one.
  final ExpenseItem? existing;
  final DateTime? initialDate;
  const ExpenseSheet({super.key, this.existing, this.initialDate});

  @override
  State<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _memoCtrl;
  late DateTime _date;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(text: e?.amount ?? '');
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _date = e?.expenseDate ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final provider = context.read<ExpenseProvider>();
    final amount = _amountCtrl.text.replaceAll(',', '').trim();
    final memo = _memoCtrl.text.trim();
    try {
      if (_isEdit) {
        await provider.edit(
          widget.existing!.id,
          expenseDate: _date,
          amount: amount,
          memo: memo,
        );
      } else {
        await provider.add(
          expenseDate: _date,
          amount: amount,
          memo: memo.isEmpty ? null : memo,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('저장에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy년 M월 d일').format(_date);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: TjColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(TjRadii.xl)),
      ),
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TjColors.ink4,
                      borderRadius: BorderRadius.circular(TjRadii.full),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(LucideIcons.arrowUpRight, size: 20, color: TjColors.expense),
                    const SizedBox(width: 8),
                    Text(_isEdit ? '지출 수정' : '지출 기록',
                        style: TjType.title.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TjType.money(size: 20),
                  decoration: const InputDecoration(
                    labelText: '금액',
                    suffixText: '원',
                    prefixIcon: Icon(LucideIcons.banknote),
                  ),
                  validator: (v) {
                    final value = (v ?? '').replaceAll(',', '').trim();
                    if (value.isEmpty) return '금액을 입력하세요';
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0) return '유효한 금액이 아닙니다';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoCtrl,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: '메모 (선택)',
                    prefixIcon: Icon(LucideIcons.pencilLine),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(TjRadii.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: TjColors.card,
                      borderRadius: BorderRadius.circular(TjRadii.md),
                      border: Border.all(color: const Color(0x2913193A), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 18, color: TjColors.ink3),
                        const SizedBox(width: 10),
                        Text(dateLabel,
                            style: TjType.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(LucideIcons.chevronRight, size: 18, color: TjColors.ink4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TjColors.stamp,
                    disabledBackgroundColor: TjColors.stamp.withValues(alpha: 0.4),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: TjColors.onInk),
                        )
                      : const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
