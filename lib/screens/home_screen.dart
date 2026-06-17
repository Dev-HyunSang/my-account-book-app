import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/transaction.dart';
import '../theme/app_tokens.dart';
import '../widgets/add_transaction_sheet.dart';
import 'calendar_screen.dart';
import 'expenses_screen.dart';
import 'incomes_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _incomeIndex = 1;

  static const _pages = <Widget>[
    CalendarScreen(),
    IncomesScreen(),
    ExpensesScreen(),
    SettingsScreen(),
  ];

  void _openAdd() {
    // One unified keypad sheet for both — pre-set the type based on the tab.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialType: _index == _incomeIndex ? TxType.income : TxType.expense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TjColors.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _index, children: _pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _TjTabBar(
              index: _index,
              onTap: (i) => setState(() => _index = i),
              onAdd: _openAdd,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating glass tab bar with a center 도장-red add button.
class _TjTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _TjTabBar({required this.index, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: (bottomInset > 0 ? bottomInset : 8) + 8,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Bar (clipped, blurred) with a gap in the middle for the button.
          ClipRRect(
            borderRadius: BorderRadius.circular(TjRadii.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(TjRadii.xl),
                  border: Border.all(color: TjColors.divider),
                  boxShadow: TjShadows.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TabItem(
                      icon: LucideIcons.calendar,
                      label: '캘린더',
                      active: index == 0,
                      onTap: () => onTap(0),
                    ),
                    _TabItem(
                      icon: LucideIcons.arrowDownLeft,
                      label: '수입',
                      active: index == 1,
                      onTap: () => onTap(1),
                    ),
                    const SizedBox(width: 64), // gap for the floating add button
                    _TabItem(
                      icon: LucideIcons.arrowUpRight,
                      label: '지출',
                      active: index == 2,
                      onTap: () => onTap(2),
                    ),
                    _TabItem(
                      icon: LucideIcons.user,
                      label: '내 정보',
                      active: index == 3,
                      onTap: () => onTap(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating add button — outside the ClipRRect so it stays a full circle.
          Positioned(
            top: -14,
            child: _AddButton(onTap: onAdd),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? TjColors.ink : TjColors.ink3;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TjRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.11,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: TjColors.stamp,
          shape: BoxShape.circle,
          boxShadow: TjShadows.stampGlow,
        ),
        child: const Icon(LucideIcons.plus, size: 26, color: Colors.white),
      ),
    );
  }
}
