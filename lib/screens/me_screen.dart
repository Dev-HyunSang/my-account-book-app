import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = const [
      (Icons.notifications_outlined, '알림 설정'),
      (Icons.lock_outline_rounded, '비밀번호 변경'),
      (Icons.download_rounded, '데이터 내보내기'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 140),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 24),
          child: Text(
            '내 정보',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTokens.ink,
              letterSpacing: -0.48,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: AppTokens.divider),
            boxShadow: AppTokens.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppTokens.stampSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'ㄱ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.stamp,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'guest@teongjang.app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink,
                      letterSpacing: -0.16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '가입 2026년 5월',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
              for (var i = 0; i < rows.length; i++)
                _settingsRow(
                  icon: rows[i].$1,
                  label: rows[i].$2,
                  divider: i < rows.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppTokens.ink,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('로그아웃'),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            '"오늘도 통장이 텅장이 되지 않게."',
            style: TextStyle(
              fontSize: 12,
              color: AppTokens.ink3,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required bool divider,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: divider ? AppTokens.divider : Colors.transparent,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTokens.ink2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppTokens.ink4),
        ],
      ),
    );
  }
}
