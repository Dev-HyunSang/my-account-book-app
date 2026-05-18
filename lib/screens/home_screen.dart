import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../widgets/add_transaction_sheet.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 1;

  static const _pages = <Widget>[
    TransactionsScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SheetWrap(child: AddTransactionSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.paper,
      extendBody: true,
      body: SafeArea(bottom: false, child: _pages[_index]),
      bottomNavigationBar: _TeongjangNavBar(
        index: _index,
        onTab: (i) => setState(() => _index = i),
        onAdd: _openAdd,
      ),
    );
  }
}

class _SheetWrap extends StatelessWidget {
  const _SheetWrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusXl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    );
  }
}

class _TeongjangNavBar extends StatelessWidget {
  const _TeongjangNavBar({
    required this.index,
    required this.onTab,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTokens.paper.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppTokens.radiusXl),
              border: Border.all(color: AppTokens.divider),
              boxShadow: AppTokens.shadowMd,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _NavTab(
                    icon: Icons.list_alt_rounded,
                    label: '거래',
                    active: index == 0,
                    onTap: () => onTab(0),
                  ),
                ),
                Expanded(
                  child: _NavTab(
                    icon: Icons.calendar_month_rounded,
                    label: '캘린더',
                    active: index == 1,
                    onTap: () => onTab(1),
                  ),
                ),
                _AddButton(onTap: onAdd),
                Expanded(
                  child: _NavTab(
                    icon: Icons.settings_rounded,
                    label: '설정',
                    active: index == 2,
                    onTap: () => onTab(2),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTokens.ink : AppTokens.ink3;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: Material(
          color: AppTokens.stamp,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTokens.shadowStamp,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
