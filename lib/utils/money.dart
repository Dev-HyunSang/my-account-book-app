// ignore_for_file: unnecessary_brace_in_string_interps
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _krw = NumberFormat('#,###', 'ko_KR');

String formatWon(num n, {bool sign = false}) {
  final abs = n.abs();
  final str = _krw.format(abs);
  if (sign) {
    if (n > 0) return '+${str}원';
    if (n < 0) return '-${str}원';
  }
  return '${str}원';
}

String formatWonShort(num n) {
  final abs = n.abs();
  if (abs >= 100000000) {
    return '${(abs / 100000000).toStringAsFixed(1)}억';
  }
  if (abs >= 10000) {
    final man = abs / 10000;
    return man == man.roundToDouble()
        ? '${man.toInt()}만'
        : '${man.toStringAsFixed(1)}만';
  }
  return _krw.format(abs);
}

String prettyDate(DateTime d) {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  return '${d.month}월 ${d.day}일 (${days[d.weekday - 1]})';
}

const incomeCategories = ['월급', '부수입'];
const expenseCategories = ['식비', '교통', '주거', '구독', '건강', '쇼핑'];

const Map<String, IconData> categoryIcons = {
  '월급': Icons.work_outline_rounded,
  '부수입': Icons.auto_awesome_rounded,
  '식비': Icons.restaurant_rounded,
  '교통': Icons.directions_car_filled_rounded,
  '주거': Icons.home_rounded,
  '구독': Icons.repeat_rounded,
  '건강': Icons.local_hospital_rounded,
  '쇼핑': Icons.shopping_bag_rounded,
};

IconData iconFor(String category, {bool isIncome = false}) {
  return categoryIcons[category] ??
      (isIncome ? Icons.south_west_rounded : Icons.north_east_rounded);
}
