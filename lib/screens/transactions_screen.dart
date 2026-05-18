import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###');
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('텅장 탈출기'),
            ),
            SliverToBoxAdapter(
              child: _SummaryCard(
                income: provider.totalIncome,
                expense: provider.totalExpense,
                balance: provider.balance,
              ),
            ),
            if (provider.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('아직 거래가 없습니다.\n+ 버튼으로 추가하세요.', textAlign: TextAlign.center)),
              )
            else
              SliverList.builder(
                itemCount: provider.items.length,
                itemBuilder: (context, i) {
                  final tx = provider.items[i];
                  final isIncome = tx.type == TxType.income;
                  return Dismissible(
                    key: ValueKey(tx.id),
                    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                    onDismissed: (_) => provider.remove(tx.id),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      title: Text(tx.category),
                      subtitle: Text('${DateFormat('yyyy-MM-dd').format(tx.date)}${tx.memo.isEmpty ? '' : ' · ${tx.memo}'}'),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${money.format(tx.amount)}원',
                        style: TextStyle(
                          color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  const _SummaryCard({required this.income, required this.expense, required this.balance});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###');
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('잔액'),
            const SizedBox(height: 4),
            Text(
              '${money.format(balance)}원',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Stat(label: '수입', value: '+${money.format(income)}원', color: Colors.green.shade700)),
                Expanded(child: _Stat(label: '지출', value: '-${money.format(expense)}원', color: Colors.red.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}
