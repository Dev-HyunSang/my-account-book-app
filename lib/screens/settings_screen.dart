import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/tj_widgets.dart';

/// 내 정보 — profile card, settings rows, logout. Mirrors the design's MeScreen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TjColors.stamp),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final theme = context.watch<ThemeProvider>();
    final themeLabel = switch (theme.mode) {
      ThemeMode.light => '라이트',
      ThemeMode.dark => '다크',
      ThemeMode.system => '시스템 설정',
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 130),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: Text('내 정보', style: TjType.h1),
        ),

        // Profile card
        TjCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: TjColors.stampSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.wallet, size: 24, color: TjColors.stamp),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 가계부',
                      style: TjType.title.copyWith(fontSize: 16, letterSpacing: -0.16)),
                  const SizedBox(height: 2),
                  Text('오늘도 텅장 탈출 중', style: TjType.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Settings rows
        TjCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: LucideIcons.palette,
                label: '테마',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(themeLabel, style: TjType.caption),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 18, color: TjColors.ink4),
                  ],
                ),
                onTap: () => _pickTheme(context, theme),
                divider: true,
              ),
              _SettingRow(
                icon: LucideIcons.bell,
                label: '알림 설정',
                onTap: () => _soon(context),
                divider: true,
              ),
              _SettingRow(
                icon: LucideIcons.download,
                label: '데이터 내보내기',
                onTap: () => _soon(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout (ghost)
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(LucideIcons.logOut, size: 18, color: TjColors.ink),
            label: Text('로그아웃',
                style: TjType.title.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TjRadii.md)),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text('"오늘도 통장이 텅장이 되지 않게."',
            textAlign: TextAlign.center,
            style: TjType.caption.copyWith(height: 1.5)),
      ],
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('곧 만나요!')));
  }

  Future<void> _pickTheme(BuildContext context, ThemeProvider theme) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: TjColors.paper,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const {
              ThemeMode.system: '시스템 설정',
              ThemeMode.light: '라이트',
              ThemeMode.dark: '다크',
            }.entries)
              ListTile(
                title: Text(entry.value, style: TjType.body),
                trailing: theme.mode == entry.key
                    ? const Icon(LucideIcons.check, color: TjColors.stamp)
                    : null,
                onTap: () => Navigator.of(ctx).pop(entry.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) theme.setMode(picked);
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool divider;
  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: TjColors.ink2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TjType.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            trailing ??
                const Icon(LucideIcons.chevronRight, size: 18, color: TjColors.ink4),
          ],
        ),
      ),
    );
    if (!divider) return row;
    return Column(
      children: [row, const Divider(height: 1, indent: 16, endIndent: 16)],
    );
  }
}
