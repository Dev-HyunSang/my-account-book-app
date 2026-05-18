import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_tokens.dart';
import '../utils/money.dart';
import '../widgets/txn_row.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final perDay = _aggregate(provider.items);
        final totals = perDay.values.fold(
          (income: 0.0, expense: 0.0),
          (acc, d) => (
            income: acc.income + d.income,
            expense: acc.expense + d.expense,
          ),
        );
        final net = totals.income - totals.expense;
        final selectedItems = provider.forDay(_selected)
          ..sort((a, b) => a.type == TxType.income ? -1 : 1);

        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 16)),
            SliverToBoxAdapter(child: _monthHeader()),
            SliverToBoxAdapter(child: _summaryStrip(totals, net)),
            SliverToBoxAdapter(child: _weekdayHeader()),
            SliverToBoxAdapter(child: _grid(perDay)),
            SliverToBoxAdapter(child: _detailHeader(selectedItems.length)),
            if (selectedItems.isEmpty)
              SliverToBoxAdapter(child: _emptyDetail())
            else
              SliverToBoxAdapter(child: _detailCard(selectedItems)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
          ],
        );
      },
    );
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTokens.ink,
            onPressed: () => setState(() {
              _cursor = DateTime(_cursor.year, _cursor.month - 1, 1);
            }),
          ),
          Text(
            '${_cursor.year}년 ${_cursor.month}월',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink,
              letterSpacing: -0.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTokens.ink,
            onPressed: () => setState(() {
              _cursor = DateTime(_cursor.year, _cursor.month + 1, 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip(
      ({double income, double expense}) totals, double net) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: AppTokens.divider),
          boxShadow: AppTokens.shadowSm,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              SummaryStat(
                label: '수입',
                amount: totals.income,
                color: AppTokens.income,
              ),
              const VerticalDivider(
                  color: AppTokens.divider, width: 24, thickness: 1),
              SummaryStat(
                label: '지출',
                amount: totals.expense,
                color: AppTokens.expense,
              ),
              const VerticalDivider(
                  color: AppTokens.divider, width: 24, thickness: 1),
              SummaryStat(
                label: '잔액',
                amount: net.abs(),
                color: net >= 0 ? AppTokens.ink : AppTokens.expense,
                sign: net >= 0 ? '+' : '-',
                bold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekdayHeader() {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(7, (i) {
          final color = i == 0
              ? AppTokens.expense
              : i == 6
                  ? const Color(0xFF4674C6)
                  : AppTokens.ink3;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                days[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.55,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _grid(Map<DateTime, _DaySum> perDay) {
    final year = _cursor.year;
    final month = _cursor.month;
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final lastDay = DateTime(year, month + 1, 0).day;
    final cells = <_Cell?>[];
    for (var i = 0; i < 42; i++) {
      final dayNum = i - firstWeekday + 1;
      if (dayNum < 1 || dayNum > lastDay) {
        cells.add(null);
      } else {
        cells.add(_Cell(dayNum: dayNum, date: DateTime(year, month, dayNum)));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: cells.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          mainAxisExtent: 64,
        ),
        itemBuilder: (context, i) {
          final cell = cells[i];
          if (cell == null) return const SizedBox.shrink();
          final selected = _isSameDay(cell.date, _selected);
          final weekday = i % 7;
          final dayColor = weekday == 0
              ? AppTokens.expense
              : weekday == 6
                  ? const Color(0xFF4674C6)
                  : AppTokens.ink;
          final data = perDay[_normalize(cell.date)];
          return _DayCell(
            cell: cell,
            selected: selected,
            dayColor: dayColor,
            data: data,
            onTap: () => setState(() => _selected = cell.date),
          );
        },
      ),
    );
  }

  Widget _detailHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            prettyDate(_selected),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count건',
            style: const TextStyle(
              fontSize: 12,
              color: AppTokens.ink3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDetail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: AppTokens.divider),
          boxShadow: AppTokens.shadowSm,
        ),
        child: const Center(
          child: Text(
            '이 날은 기록이 없어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTokens.ink3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailCard(List<TxItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
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
    );
  }

  Map<DateTime, _DaySum> _aggregate(List<TxItem> items) {
    final map = <DateTime, _DaySum>{};
    for (final t in items) {
      if (t.date.year != _cursor.year || t.date.month != _cursor.month) {
        continue;
      }
      final key = _normalize(t.date);
      final d = map.putIfAbsent(key, _DaySum.new);
      if (t.type == TxType.income) {
        d.income += t.amount;
      } else {
        d.expense += t.amount;
      }
      if (t.recurring) d.recurring = true;
    }
    return map;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Cell {
  _Cell({required this.dayNum, required this.date});
  final int dayNum;
  final DateTime date;
}

class _DaySum {
  double income = 0;
  double expense = 0;
  bool recurring = false;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cell,
    required this.selected,
    required this.dayColor,
    required this.data,
    required this.onTap,
  });

  final _Cell cell;
  final bool selected;
  final Color dayColor;
  final _DaySum? data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTokens.onInk : dayColor;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppTokens.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${cell.dayNum}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1,
              ),
            ),
            const Spacer(),
            if (data != null) ...[
              if (data!.income > 0)
                Text(
                  formatWonShort(data!.income),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF9FE0BA)
                        : AppTokens.income,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -0.2,
                  ),
                ),
              if (data!.expense > 0)
                Text(
                  formatWonShort(data!.expense),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFFF5B5B0)
                        : AppTokens.expense,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -0.2,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
