import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';

class IncomeOutcomeArrow extends StatelessWidget {
  const IncomeOutcomeArrow({
    required this.isIncome,
    this.color,
    this.iconSize,
    this.width,
    super.key,
  });
  final bool isIncome;
  final Color? color;
  final double? iconSize;
  final double? width;
  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 1700),
      curve: const ElasticOutCurve(0.5),
      turns: isIncome ? 0.5 : 0,
      child: SizedBox(
        width: width,
        child: UnconstrainedBox(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          child: Icon(
            appStateSettings["outlinedIcons"]
                ? Icons.arrow_drop_down_outlined
                : Icons.arrow_drop_down_rounded,
            color: color ?? (isIncome
                    ? getColor(context, "incomeAmount")
                    : getColor(context, "expenseAmount")),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
