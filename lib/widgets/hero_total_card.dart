import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_tokens.dart';

/// The hero total card at the top of the income / expense list screens.
/// A white card with a soft corner glow, an accent eyebrow, a Gmarket hero
/// number, and a count / average meta row.
class HeroTotalCard extends StatelessWidget {
  final bool isIncome;
  final num total;
  final int count;
  final String monthLabel; // e.g. '5월'
  const HeroTotalCard({
    super.key,
    required this.isIncome,
    required this.total,
    required this.count,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? TjColors.income : TjColors.expense;
    final soft = isIncome ? TjColors.incomeSoft : TjColors.expenseSoft;
    final title = isIncome ? '수입' : '지출';
    final avg = count == 0 ? 0 : (total / count).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: TjColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TjColors.divider),
          boxShadow: TjShadows.md,
        ),
        child: Stack(
          children: [
            // Corner color glow
            Positioned(
              top: -48,
              right: -48,
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [soft, soft.withValues(alpha: 0)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$monthLabel $title 합계'.toUpperCase(),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.88,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _thousands(total),
                            style: TjType.money(size: 38, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('원', style: TjType.money(size: 24, color: TjColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TjColors.ink2,
                    ),
                    child: Row(
                      children: [
                        Text('$count건'),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: TjColors.ink4,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text('건당 평균 ${_thousands(avg)}원'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _thousands(num n) {
    final digits = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
