import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_tokens.dart';
import '../utils/money.dart';

class TxnRow extends StatelessWidget {
  const TxnRow({
    super.key,
    required this.tx,
    this.divider = true,
    this.onTap,
  });

  final TxItem tx;
  final bool divider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TxType.income;
    final color = isIncome ? AppTokens.income : AppTokens.expense;
    final bg = isIncome ? AppTokens.incomeSoft : AppTokens.expenseSoft;
    final sign = isIncome ? '+' : '-';
    return InkWell(
      onTap: onTap,
      child: Container(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              alignment: Alignment.center,
              child: Icon(
                iconFor(tx.category, isIncome: isIncome),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.memo.isEmpty ? tx.category : tx.memo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.ink,
                            letterSpacing: -0.075,
                          ),
                        ),
                      ),
                      if (tx.recurring) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.amberSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat_rounded,
                                  size: 10, color: Color(0xFF8B6A1F)),
                              SizedBox(width: 3),
                              Text(
                                '매월',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8B6A1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${formatWon(tx.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.16,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryStat extends StatelessWidget {
  const SummaryStat({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    this.sign,
    this.bold = false,
  });

  final String label;
  final num amount;
  final Color color;
  final String? sign;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink3,
              letterSpacing: 0.44,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${sign ?? ''}${formatWonShort(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: bold ? 17 : 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.34,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
