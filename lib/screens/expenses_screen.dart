import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/hero_total_card.dart';
import '../widgets/tj_widgets.dart';

/// 지출 — expense-only list from the local transaction store.
/// Hero total card, category breakdown, and a date-grouped row list.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  static const _dow = ['일', '월', '화', '수', '목', '금', '토'];
  static String _prettyDate(DateTime d) => '${d.month}월 ${d.day}일 (${_dow[d.weekday % 7]})';
  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final items = provider.items.where((t) => t.type == TxType.expense).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final total = items.fold<double>(0, (s, t) => s + t.amount);

        // Category breakdown (top 4)
        final byCat = <String, double>{};
        for (final t in items) {
          byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
        }
        final topCats = byCat.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top4 = topCats.take(4).toList();

        // Group by date
        final groups = <String, List<TxItem>>{};
        for (final t in items) {
          groups.putIfAbsent(_key(t.date), () => []).add(t);
        }
        final dateKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: EdgeInsets.only(top: topPad + 12, bottom: 130),
          children: [
            // Month chip + filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MonthChip(label: _monthLabelFull(items)),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.slidersHorizontal,
                        size: 22, color: TjColors.ink),
                  ),
                ],
              ),
            ),

            // Hero total
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: HeroTotalCard(
                isIncome: false,
                total: total,
                count: items.length,
                monthLabel: _monthShort(items),
              ),
            ),

            // Category breakdown
            if (top4.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TjSectionLabel('카테고리별'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: TjCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (var i = 0; i < top4.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                          child: _CategoryBar(
                            category: top4[i].key,
                            amount: top4[i].value,
                            pct: total == 0 ? 0 : top4[i].value / total * 100,
                            opacity: 0.85 - i * 0.15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Grouped list
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TjSectionLabel('전체 내역'),
            ),
            if (items.isEmpty)
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
            else
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
                            Text(_prettyDate(groups[date]!.first.date),
                                style: TjType.label.copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                            Text(
                              formatWon(groups[date]!.fold<double>(0, (s, t) => s + t.amount)),
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
                              onDismissed: (_) =>
                                  context.read<TransactionProvider>().remove(groups[date]![i].id),
                              background: _dismissBg(),
                              child: TxnRow(
                                isIncome: false,
                                category: groups[date]![i].category,
                                memo: groups[date]![i].memo,
                                amount: groups[date]![i].amount,
                                divider: i < groups[date]!.length - 1,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }

  static String _monthShort(List<TxItem> items) {
    final m = items.isNotEmpty ? items.first.date.month : DateTime.now().month;
    return '$m월';
  }

  static String _monthLabelFull(List<TxItem> items) {
    final d = items.isNotEmpty ? items.first.date : DateTime.now();
    return '${d.year}년 ${d.month}월';
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

class _MonthChip extends StatelessWidget {
  final String label;
  const _MonthChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: TjColors.card,
        borderRadius: BorderRadius.circular(TjRadii.full),
        border: Border.all(color: TjColors.divider),
        boxShadow: TjShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: kFontBody,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TjColors.ink,
              )),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronDown, size: 14, color: TjColors.ink),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double pct;
  final double opacity;
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.pct,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Row(
              children: [
                Icon(categoryIcon(category, isIncome: false), size: 14, color: TjColors.ink2),
                const SizedBox(width: 8),
                Text(category,
                    style: const TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TjColors.ink,
                    )),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatWon(amount), style: TjType.money(size: 13)),
                const SizedBox(width: 6),
                Text('${pct.toStringAsFixed(0)}%',
                    style: TjType.caption.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(TjRadii.full),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: TjColors.paperDeep,
            valueColor: AlwaysStoppedAnimation(
              TjColors.expense.withValues(alpha: opacity.clamp(0.0, 1.0)),
            ),
          ),
        ),
      ],
    );
  }
}
