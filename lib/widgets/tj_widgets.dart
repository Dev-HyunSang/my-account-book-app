// Shared 텅장 atoms — wordmark, paper card, transaction row, badges.
// Mirrors the atoms in the design's shared.jsx / CalendarScreen.jsx.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_tokens.dart';

/// The 텅장 wordmark: 텅 [||] 장 — two red bars standing in the empty space.
class TjLogo extends StatelessWidget {
  final double size;
  final Color color;
  final Color accent;
  const TjLogo({
    super.key,
    this.size = 48,
    this.color = TjColors.ink,
    this.accent = TjColors.stamp,
  });

  @override
  Widget build(BuildContext context) {
    final barW = (size * 0.06).clamp(3.0, 8.0);
    final barH = size * 0.66;
    final glyph = TextStyle(
      fontFamily: kFontDisplay,
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1,
      letterSpacing: -size * 0.04,
      color: color,
    );
    Widget bar() => Container(
          width: barW,
          height: barH,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(barW / 2),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('텅', style: glyph),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.06),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [bar(), SizedBox(width: barW + 2), bar()],
          ),
        ),
        Text('장', style: glyph),
      ],
    );
  }
}

/// Paper-on-paper content surface: white, 16-radius, hairline border, soft shadow.
class TjCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> shadow;
  final VoidCallback? onTap;
  const TjCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = TjRadii.lg,
    this.shadow = TjShadows.sm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: TjColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: TjColors.divider),
        boxShadow: shadow,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// Uppercase eyebrow label used above sections.
class TjSectionLabel extends StatelessWidget {
  final String text;
  const TjSectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text.toUpperCase(), style: TjType.section),
      );
}

/// Amber "매월" recurring pill.
class RecurringBadge extends StatelessWidget {
  const RecurringBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: TjColors.amberSoft,
          borderRadius: BorderRadius.circular(TjRadii.full),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.repeat, size: 10, color: TjColors.amberInk),
            SizedBox(width: 3),
            Text('매월',
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TjColors.amberInk,
                )),
          ],
        ),
      );
}

/// A single transaction row: category circle, memo + category, signed amount.
/// Generic over raw values so both local TxItem and API IncomeItem can use it.
class TxnRow extends StatelessWidget {
  final bool isIncome;
  final String category;
  final String memo;
  final num amount;
  final bool recurring;
  final bool divider;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TxnRow({
    super.key,
    required this.isIncome,
    required this.category,
    required this.memo,
    required this.amount,
    this.recurring = false,
    this.divider = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? TjColors.income : TjColors.expense;
    final bg = isIncome ? TjColors.incomeSoft : TjColors.expenseSoft;
    final sign = isIncome ? '+' : '-';
    final title = memo.isEmpty ? category : memo;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(TjRadii.md),
            ),
            child: Icon(categoryIcon(category, isIncome: isIncome), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.075,
                          color: TjColors.ink,
                        ),
                      ),
                    ),
                    if (recurring) ...[
                      const SizedBox(width: 6),
                      const RecurringBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(category, style: TjType.caption),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              Text('$sign${formatWon(amount)}', style: TjType.money(size: 16, color: color)),
        ],
      ),
    );

    final content = onTap == null
        ? row
        : InkWell(onTap: onTap, child: row);

    if (!divider) return content;
    return Column(
      children: [
        content,
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

/// Wraps a list of TxnRow-like children in a single padding-0 TjCard.
class TxnRowCard extends StatelessWidget {
  final List<Widget> children;
  const TxnRowCard({super.key, required this.children});
  @override
  Widget build(BuildContext context) => TjCard(
        padding: EdgeInsets.zero,
        child: Column(children: children),
      );
}
