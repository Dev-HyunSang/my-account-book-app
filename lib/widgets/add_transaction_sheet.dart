import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends StatefulWidget {
  final DateTime? initialDate;
  const AddTransactionSheet({super.key, this.initialDate});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  TxType _type = TxType.expense;
  late DateTime _date = widget.initialDate ?? DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final item = TxItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
      category: _categoryCtrl.text.trim().isEmpty
          ? (_type == TxType.income ? '수입' : '지출')
          : _categoryCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      date: _date,
    );
    context.read<TransactionProvider>().add(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy-MM-dd').format(_date);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: inset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('거래 추가', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('지출')),
                ButtonSegment(value: TxType.income, label: Text('수입')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '금액'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '금액을 입력하세요';
                final parsed = double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) return '유효한 금액이 아닙니다';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: '카테고리 (선택)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모 (선택)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(dateLabel),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}
