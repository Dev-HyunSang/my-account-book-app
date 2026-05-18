import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/money.dart';
import '../widgets/txn_row.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key, required this.type});

  final TxType type;

  bool get isIncome => type == TxType.income;

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final filtered = provider.items.where((t) => t.type == type).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final total = filtered.fold<double>(0, (s, t) => s + t.amount);
        final color = isIncome ? AppTokens.income : AppTokens.expense;
        final softBg = isIncome ? AppTokens.incomeSoft : AppTokens.expenseSoft;

        final groups = <String, List<TxItem>>{};
        for (final t in filtered) {
          final key =
              '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
          groups.putIfAbsent(key, () => []).add(t);
        }
        final dateKeys = groups.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        final byCategory = <String, double>{};
        for (final t in filtered) {
          byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
        }
        final topCats = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final shownCats = topCats.take(4).toList();

        final now = DateTime.now();
        final monthLabel = '${now.year}년 ${now.month}월';

        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 16)),
            SliverToBoxAdapter(child: _topRow(monthLabel)),
            SliverToBoxAdapter(
              child: _heroTotal(
                total: total,
                count: filtered.length,
                color: color,
                softBg: softBg,
              ),
            ),
            if (!isIncome && shownCats.isNotEmpty)
              SliverToBoxAdapter(
                child: _categoryBreakdown(
                  total: total,
                  cats: shownCats,
                  color: color,
                ),
              ),
            SliverToBoxAdapter(child: _sectionLabel('전체 내역')),
            if (filtered.isEmpty)
              SliverToBoxAdapter(child: _emptyState())
            else
              SliverList.builder(
                itemCount: dateKeys.length,
                itemBuilder: (context, idx) {
                  final date = dateKeys[idx];
                  final items = groups[date]!;
                  final dayTotal = items.fold<double>(0, (s, t) => s + t.amount);
                  return _dateGroup(items, dayTotal, color);
                },
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
          ],
        );
      },
    );
  }

  Widget _topRow(String monthLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTokens.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTokens.divider),
              boxShadow: AppTokens.shadowSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppTokens.ink),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: AppTokens.ink),
          ),
        ],
      ),
    );
  }

  Widget _heroTotal({
    required double total,
    required int count,
    required Color color,
    required Color softBg,
  }) {
    final avg = count == 0 ? 0 : (total / count).round();
    final monthN = DateTime.now().month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTokens.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTokens.divider),
              boxShadow: AppTokens.shadowMd,
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$monthN월 ${isIncome ? '수입' : '지출'} 합계',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.88,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                      letterSpacing: -0.95,
                      height: 1.05,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(text: formatWon(total).replaceAll('원', '')),
                      const TextSpan(
                        text: ' 원',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '$count건',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink2,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTokens.ink4,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '건당 평균 ${formatWon(avg)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                  gradient: RadialGradient(
                    center: const Alignment(1, -1),
                    radius: 0.9,
                    colors: [softBg, softBg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdown({
    required double total,
    required List<MapEntry<String, double>> cats,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              '카테고리별',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTokens.ink3,
                letterSpacing: 0.48,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTokens.card,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: AppTokens.divider),
              boxShadow: AppTokens.shadowSm,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < cats.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                    child: _catRow(
                      label: cats[i].key,
                      amount: cats[i].value,
                      total: total,
                      color: color,
                      shade: 0.85 - i * 0.15,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catRow({
    required String label,
    required double amount,
    required double total,
    required Color color,
    required double shade,
  }) {
    final pct = total == 0 ? 0 : (amount / total) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(categoryIcons[label] ?? Icons.circle_outlined,
                size: 14, color: AppTokens.ink2),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink,
              ),
            ),
            const Spacer(),
            Text(
              formatWon(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTokens.ink,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: -0.13,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTokens.ink3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 4,
            color: AppTokens.paperDeep,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  color: color.withValues(alpha: shade.clamp(0.2, 1.0)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTokens.ink3,
          letterSpacing: 0.48,
        ),
      ),
    );
  }

  Widget _dateGroup(List<TxItem> items, double dayTotal, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prettyDate(items.first.date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink2,
                  ),
                ),
                Text(
                  formatWon(dayTotal),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -0.12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTokens.card,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: AppTokens.divider),
              boxShadow: AppTokens.shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  TxnRow(tx: items[i], divider: i < items.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: AppTokens.divider),
          boxShadow: AppTokens.shadowSm,
        ),
        child: Column(
          children: [
            Icon(
              isIncome
                  ? Icons.savings_outlined
                  : Icons.receipt_long_outlined,
              size: 32,
              color: AppTokens.ink4,
            ),
            const SizedBox(height: 12),
            Text(
              isIncome ? '이번 달은 아직 텅장…' : '아직 지출이 없어요',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isIncome ? '첫 수입을 기록해 볼까요?' : '필요하다면 + 버튼으로 추가하세요',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTokens.ink4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
