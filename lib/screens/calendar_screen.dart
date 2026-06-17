import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/tj_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selected = DateTime.now();

  static const _dow = ['일', '월', '화', '수', '목', '금', '토'];

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final year = _focused.year;
        final month = _focused.month;

        // Aggregate per-day income/expense for the visible month.
        final perDay = <String, ({double income, double expense})>{};
        double monthIncome = 0, monthExpense = 0;
        for (final t in provider.items) {
          if (t.date.year != year || t.date.month != month) continue;
          final k = _key(t.date);
          final cur = perDay[k] ?? (income: 0.0, expense: 0.0);
          if (t.type == TxType.income) {
            perDay[k] = (income: cur.income + t.amount, expense: cur.expense);
            monthIncome += t.amount;
          } else {
            perDay[k] = (income: cur.income, expense: cur.expense + t.amount);
            monthExpense += t.amount;
          }
        }
        final net = monthIncome - monthExpense;

        final dayItems = provider.forDay(_selected)
          ..sort((a, b) => a.type == TxType.income ? -1 : 1);

        return ListView(
          padding: EdgeInsets.only(top: topPad + 12, bottom: 130),
          children: [
            // Month header (drives _focused; chevrons + swipe stay in sync)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(
                    icon: LucideIcons.chevronLeft,
                    onTap: () =>
                        setState(() => _focused = DateTime(year, month - 1, 1)),
                  ),
                  Text(
                    '$year년 $month월',
                    style: const TextStyle(
                      fontFamily: kFontDisplay,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: TjColors.ink,
                    ),
                  ),
                  _RoundIconButton(
                    icon: LucideIcons.chevronRight,
                    onTap: () =>
                        setState(() => _focused = DateTime(year, month + 1, 1)),
                  ),
                ],
              ),
            ),

            // Month summary strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: TjCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _SummaryStat(label: '수입', amount: monthIncome, color: TjColors.income),
                      const VerticalDivider(width: 1, color: TjColors.divider),
                      _SummaryStat(label: '지출', amount: monthExpense, color: TjColors.expense),
                      const VerticalDivider(width: 1, color: TjColors.divider),
                      _SummaryStat(
                        label: '잔액',
                        amount: net.abs(),
                        sign: net >= 0 ? '+' : '-',
                        color: net >= 0 ? TjColors.ink : TjColors.expense,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Calendar — table_calendar handles paging / horizontal swipe.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TableCalendar<TxItem>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focused,
                currentDay: DateTime.now(),
                headerVisible: false,
                rowHeight: 64,
                daysOfWeekHeight: 28,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                availableGestures: AvailableGestures.horizontalSwipe,
                selectedDayPredicate: (d) => isSameDay(_selected, d),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  cellMargin: EdgeInsets.all(1),
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selected = selected;
                    _focused = focused;
                  });
                },
                onPageChanged: (focused) =>
                    setState(() => _focused = DateTime(focused.year, focused.month, 1)),
                calendarBuilders: CalendarBuilders<TxItem>(
                  dowBuilder: (context, day) {
                    final i = day.weekday % 7; // Sun=0
                    return Center(
                      child: Text(
                        _dow[i],
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.55,
                          color: i == 0
                              ? TjColors.expense
                              : i == 6
                                  ? TjColors.saturday
                                  : TjColors.ink3,
                        ),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, _) =>
                      _cell(day, perDay[_key(day)], selected: false),
                  todayBuilder: (context, day, _) =>
                      _cell(day, perDay[_key(day)], selected: false),
                  selectedBuilder: (context, day, _) =>
                      _cell(day, perDay[_key(day)], selected: true),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Selected-day detail
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _prettyDate(_selected),
                          style: const TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                            color: TjColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${dayItems.length}건', style: TjType.caption),
                      ],
                    ),
                  ),
                  if (dayItems.isEmpty)
                    const TjCard(
                      child: Center(
                        child: Text(
                          '이 날은 기록이 없어요',
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: TjColors.ink3,
                          ),
                        ),
                      ),
                    )
                  else
                    TxnRowCard(
                      children: [
                        for (var idx = 0; idx < dayItems.length; idx++)
                          TxnRow(
                            isIncome: dayItems[idx].type == TxType.income,
                            category: dayItems[idx].category,
                            memo: dayItems[idx].memo,
                            amount: dayItems[idx].amount,
                            divider: idx < dayItems.length - 1,
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

  /// A single calendar cell rendered to match the 텅장 design — day number
  /// (weekend-colored), plus income (green) / expense (red) short totals.
  Widget _cell(
    DateTime day,
    ({double income, double expense})? data, {
    required bool selected,
  }) {
    final weekday = day.weekday % 7; // Sun=0
    final dayColor = selected
        ? TjColors.onInk
        : weekday == 0
            ? TjColors.expense
            : weekday == 6
                ? TjColors.saturday
                : TjColors.ink;
    return Container(
      decoration: BoxDecoration(
        color: selected ? TjColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1,
              color: dayColor,
            ),
          ),
          const Spacer(),
          if (data != null && data.income > 0)
            _amt(formatWonShort(data.income),
                selected ? TjColors.incomeOnInk : TjColors.income),
          if (data != null && data.expense > 0)
            _amt(formatWonShort(data.expense),
                selected ? TjColors.expenseOnInk : TjColors.expense),
        ],
      ),
    );
  }

  Widget _amt(String text, Color color) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: TextStyle(
          fontFamily: kFontBody,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.25,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  static String _prettyDate(DateTime d) =>
      '${d.month}월 ${d.day}일 (${_dow[d.weekday % 7]})';
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final double amount;
  final String? sign;
  final Color color;
  const _SummaryStat({
    required this.label,
    required this.amount,
    this.sign,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                style: TjType.section.copyWith(letterSpacing: 0.44)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${sign ?? ''}${formatWonShort(amount)}',
                style: TjType.money(size: 16, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 22, color: TjColors.ink),
      ),
    );
  }
}
