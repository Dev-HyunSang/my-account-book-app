import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return CustomScrollView(
      slivers: [
        SliverAppBar(floating: true, title: const Text('설정')),
        SliverList(
          delegate: SliverChildListDelegate([
            ListTile(
              title: const Text('테마'),
              subtitle: Text(switch (theme.mode) {
                ThemeMode.light => '라이트',
                ThemeMode.dark => '다크',
                ThemeMode.system => '시스템 설정 따름',
              }),
              trailing: PopupMenuButton<ThemeMode>(
                onSelected: theme.setMode,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: ThemeMode.system, child: Text('시스템')),
                  PopupMenuItem(value: ThemeMode.light, child: Text('라이트')),
                  PopupMenuItem(value: ThemeMode.dark, child: Text('다크')),
                ],
                child: const Icon(Icons.chevron_right),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
