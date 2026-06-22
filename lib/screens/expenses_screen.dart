import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';
import '../widgets/expense_sheet.dart';
import '../widgets/hero_total_card.dart';
import '../widgets/tj_widgets.dart';

/// 지출 — expense list backed by the REST API. Hero total card + date-grouped
/// rows, mirroring [IncomesScreen]. The API has no category field, so entries
/// are keyed on their memo.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  static const _dow = ['일', '월', '화', '수', '목', '금', '토'];
  static String _prettyDate(DateTime d) => '${d.month}월 ${d.day}일 (${_dow[d.weekday % 7]})';
  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _openEdit(BuildContext context, ExpenseItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseSheet(existing: item),
    );
  }

  Future<void> _delete(BuildContext context, ExpenseItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ExpenseProvider>().remove(item.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final items = [...provider.items]
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

        final groups = <String, List<ExpenseItem>>{};
        for (final it in items) {
          groups.putIfAbsent(_key(it.expenseDate), () => []).add(it);
        }
        final dateKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return RefreshIndicator(
          onRefresh: provider.load,
          color: TjColors.ink,
          child: ListView(
            padding: EdgeInsets.only(top: topPad + 12, bottom: 130),
            children: [
              // Header row: title + refresh
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('지출', style: TjType.h1.copyWith(fontSize: 24)),
                    IconButton(
                      onPressed: provider.loading ? null : provider.load,
                      icon: const Icon(LucideIcons.refreshCw, size: 20, color: TjColors.ink),
                    ),
                  ],
                ),
              ),

              // Hero total
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: HeroTotalCard(
                  isIncome: false,
                  total: provider.total,
                  count: items.length,
                  monthLabel: _monthShort(items),
                ),
              ),

              // States
              if (provider.loading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: TjColors.ink)),
                )
              else if (provider.error != null && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: TjCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.cloudOff, size: 32, color: TjColors.ink4),
                        const SizedBox(height: 12),
                        Text('불러오지 못했어요',
                            style: TjType.body.copyWith(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${provider.error}',
                            textAlign: TextAlign.center,
                            style: TjType.caption.copyWith(color: TjColors.ink4)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: provider.load, child: const Text('다시 시도')),
                        ),
                      ],
                    ),
                  ),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: TjCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.receipt, size: 32, color: TjColors.ink4),
                        const SizedBox(height: 12),
                        Text('아직 지출이 없어요',
                            style: TjType.body.copyWith(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('필요하다면 + 버튼으로 추가하세요',
                            style: TjType.caption.copyWith(color: TjColors.ink4)),
                      ],
                    ),
                  ),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TjSectionLabel('전체 내역'),
                ),
                for (final date in dateKeys)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_prettyDate(groups[date]!.first.expenseDate),
                                  style: TjType.label.copyWith(
                                      fontWeight: FontWeight.w700, fontSize: 12)),
                              Text(
                                formatWon(groups[date]!
                                    .fold<double>(0, (s, t) => s + t.amountValue)),
                                style: TjType.money(size: 12, color: TjColors.expense),
                              ),
                            ],
                          ),
                        ),
                        TxnRowCard(
                          children: [
                            for (var i = 0; i < groups[date]!.length; i++)
                              Dismissible(
                                key: ValueKey(groups[date]![i].id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _delete(context, groups[date]![i]),
                                background: _dismissBg(),
                                child: TxnRow(
                                  isIncome: false,
                                  category: '지출',
                                  memo: groups[date]![i].memo ?? '',
                                  amount: groups[date]![i].amountValue,
                                  divider: i < groups[date]!.length - 1,
                                  onTap: () => _openEdit(context, groups[date]![i]),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _monthShort(List<ExpenseItem> items) {
    final m = items.isNotEmpty ? items.first.expenseDate.month : DateTime.now().month;
    return '$m월';
  }

  static Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TjColors.expense,
          borderRadius: BorderRadius.circular(TjRadii.lg),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      );
}
