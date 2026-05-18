import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###');
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final dayItems = provider.forDay(_selected);
        return Column(
          children: [
            AppBar(title: const Text('캘린더')),
            TableCalendar<TxItem>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focused,
              calendarFormat: _format,
              onFormatChanged: (f) => setState(() => _format = f),
              selectedDayPredicate: (d) => isSameDay(_selected, d),
              eventLoader: (day) => provider.forDay(day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
              },
              onPageChanged: (focused) => _focused = focused,
            ),
            const Divider(height: 1),
            Expanded(
              child: dayItems.isEmpty
                  ? const Center(child: Text('이 날 거래가 없습니다.'))
                  : ListView.builder(
                      itemCount: dayItems.length,
                      itemBuilder: (context, i) {
                        final tx = dayItems[i];
                        final isIncome = tx.type == TxType.income;
                        return ListTile(
                          title: Text(tx.category),
                          subtitle: tx.memo.isEmpty ? null : Text(tx.memo),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${money.format(tx.amount)}원',
                            style: TextStyle(
                              color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
