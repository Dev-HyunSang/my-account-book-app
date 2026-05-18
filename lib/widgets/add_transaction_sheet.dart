import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/money.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TxType _type = TxType.expense;
  int _amount = 0;
  String _category = '식비';
  String _memo = '';
  bool _recurring = false;
  late final TextEditingController _memoCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _memoCtrl = TextEditingController();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == TxType.income ? incomeCategories : expenseCategories;

  void _switchType(TxType t) {
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
        _amount = _amount * 1000;
      } else {
        _amount = _amount * 10 + int.parse(key);
      }
    });
  }

  Future<void> _save() async {
    if (_amount == 0) return;
    final item = TxItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      amount: _amount.toDouble(),
      category: _category,
      memo: _memo.trim(),
      date: _date,
      recurring: _recurring,
    );
    await context.read<TransactionProvider>().add(item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.paper,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.ink4,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              _typeToggle(),
              const SizedBox(height: 8),
              _amountDisplay(),
              const SizedBox(height: 8),
              _categoryChips(),
              const SizedBox(height: 12),
              _memoField(),
              const SizedBox(height: 12),
              _keypad(),
              const SizedBox(height: 12),
              _saveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTokens.paperDeep,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Row(
          children: [
            _typeButton('지출', TxType.expense, AppTokens.expense),
            _typeButton('수입', TxType.income, AppTokens.income),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String label, TxType t, Color accent) {
    final active = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTokens.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            boxShadow: active ? AppTokens.shadowSm : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: active ? accent : AppTokens.ink3,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountDisplay() {
    final hasAmount = _amount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatWon(_amount).replaceAll('원', ''),
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: hasAmount ? AppTokens.ink : AppTokens.ink4,
              letterSpacing: -1.1,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '원',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: hasAmount ? AppTokens.ink2 : AppTokens.ink4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final active = c == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppTokens.ink : AppTokens.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? Colors.transparent : AppTokens.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcons[c] ?? Icons.circle_outlined,
                    size: 14,
                    color: active ? AppTokens.onInk : AppTokens.ink2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? AppTokens.onInk : AppTokens.ink2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _memoField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: const Color(0x2913193A), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_outlined, size: 16, color: AppTokens.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _memoCtrl,
                onChanged: (v) => _memo = v,
                decoration: const InputDecoration(
                  hintText: '메모 (선택)',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTokens.ink,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _recurring = !_recurring),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _recurring
                      ? AppTokens.amberSoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 12,
                      color: _recurring
                          ? const Color(0xFF8B6A1F)
                          : AppTokens.ink3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '매월',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _recurring
                            ? const Color(0xFF8B6A1F)
                            : AppTokens.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keypad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', 'del'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          mainAxisExtent: 52,
        ),
        itemBuilder: (context, i) {
          final k = keys[i];
          return Material(
            color: AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              onTap: () => _press(k),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: AppTokens.divider),
                  boxShadow: AppTokens.shadowSm,
                ),
                alignment: Alignment.center,
                child: k == 'del'
                    ? const Icon(Icons.backspace_outlined,
                        size: 20, color: AppTokens.ink)
                    : Text(
                        k,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _saveButton() {
    final enabled = _amount > 0;
    final isIncome = _type == TxType.income;
    final bg = !enabled
        ? AppTokens.ink4
        : isIncome
            ? AppTokens.ink
            : AppTokens.stamp;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            disabledBackgroundColor: AppTokens.ink4,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
          ),
          child: Text(
            enabled
                ? '${formatWon(_amount)} ${isIncome ? '수입' : '지출'} 기록'
                : '금액을 입력하세요',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.17,
            ),
          ),
        ),
      ),
    );
  }
}
