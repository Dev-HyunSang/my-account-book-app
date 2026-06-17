import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/income_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

/// Bottom sheet for adding a transaction — type toggle, big amount display,
/// category chips, memo, and a custom 12-key keypad. Mirrors AddEntrySheet.
class AddTransactionSheet extends StatefulWidget {
  final DateTime? initialDate;
  final TxType initialType;
  const AddTransactionSheet({
    super.key,
    this.initialDate,
    this.initialType = TxType.expense,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TxType _type = widget.initialType;
  int _amount = 0;
  late String _category = _categories.first;
  final _memoCtrl = TextEditingController();
  bool _submitting = false;

  List<String> get _categories =>
      _type == TxType.income ? kIncomeCategories : kExpenseCategories;

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  void _setType(TxType t) {
    setState(() {
      _type = t;
      if (!_categories.contains(_category)) _category = _categories.first;
    });
  }

  void _press(String key) {
    setState(() {
      if (key == 'del') {
        _amount = _amount ~/ 10;
      } else if (key == '000') {
        _amount *= 1000;
      } else {
        _amount = _amount * 10 + int.parse(key);
      }
      if (_amount > 9999999999) _amount = 9999999999; // sane cap
    });
  }

  Future<void> _save() async {
    if (_amount == 0 || _submitting) return;
    final memo = _memoCtrl.text.trim();
    final date = widget.initialDate ?? DateTime.now();

    if (_type == TxType.income) {
      // Income is backed by the REST API.
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _submitting = true);
      try {
        await context.read<IncomeProvider>().add(
              incomeDate: date,
              amount: _amount.toString(),
              memo: memo.isEmpty ? _category : memo,
            );
        navigator.pop();
      } on ApiException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } else {
      // Expense is stored locally.
      context.read<TransactionProvider>().add(TxItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            type: _type,
            amount: _amount.toDouble(),
            category: _category,
            memo: memo.isEmpty ? _category : memo,
            date: date,
          ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TxType.income;
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
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TjColors.ink4,
                  borderRadius: BorderRadius.circular(TjRadii.full),
                ),
              ),

              // Type toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: TjColors.paperDeep,
                    borderRadius: BorderRadius.circular(TjRadii.md),
                  ),
                  child: Row(
                    children: [
                      _typeBtn('지출', _type == TxType.expense, TjColors.expense,
                          () => _setType(TxType.expense)),
                      _typeBtn('수입', _type == TxType.income, TjColors.income,
                          () => _setType(TxType.income)),
                    ],
                  ),
                ),
              ),

              // Amount display
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatWon(_amount).replaceAll('원', ''),
                      style: TjType.money(
                        size: 44,
                        weight: FontWeight.w800,
                        color: _amount > 0 ? TjColors.ink : TjColors.ink4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('원',
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _amount > 0 ? TjColors.ink2 : TjColors.ink4,
                        )),
                  ],
                ),
              ),

              // Category chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = _categories[i];
                    final active = c == _category;
                    return _CategoryChip(
                      label: c,
                      active: active,
                      onTap: () => setState(() => _category = c),
                    );
                  },
                ),
              ),

              // Memo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: TjColors.card,
                    borderRadius: BorderRadius.circular(TjRadii.md),
                    border: Border.all(color: const Color(0x2913193A), width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.pencilLine, size: 16, color: TjColors.ink3),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _memoCtrl,
                          style: TjType.body.copyWith(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: '메모 (선택)',
                            isCollapsed: true,
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Keypad
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.9,
                  children: [
                    for (final k in const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', 'del'])
                      _KeypadButton(label: k, onTap: () => _press(k)),
                  ],
                ),
              ),

              // Save
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isIncome ? TjColors.ink : TjColors.stamp,
                      disabledBackgroundColor:
                          (isIncome ? TjColors.ink : TjColors.stamp).withValues(alpha: 0.4),
                    ),
                    onPressed: (_amount == 0 || _submitting) ? null : _save,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: TjColors.onInk),
                          )
                        : Text(
                            _amount == 0
                                ? '금액을 입력하세요'
                                : '${formatWon(_amount)} ${isIncome ? '수입' : '지출'} 기록',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String label, bool active, Color accent, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(TjRadii.sm),
            boxShadow: active ? TjShadows.sm : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: active ? accent : TjColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? TjColors.ink : TjColors.card,
          borderRadius: BorderRadius.circular(TjRadii.full),
          border: active ? null : Border.all(color: TjColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categoryIcon(label, isIncome: false),
                size: 14, color: active ? TjColors.onInk : TjColors.ink2),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? TjColors.onInk : TjColors.ink2,
                )),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TjColors.card,
      borderRadius: BorderRadius.circular(TjRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TjRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TjRadii.md),
            border: Border.all(color: TjColors.divider),
            boxShadow: TjShadows.sm,
          ),
          child: Center(
            child: label == 'del'
                ? const Icon(LucideIcons.delete, size: 20, color: TjColors.ink)
                : Text(label,
                    style: const TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: TjColors.ink,
                    )),
          ),
        ),
      ),
    );
  }
}
