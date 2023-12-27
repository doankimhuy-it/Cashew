import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/currency_functions.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/count_number.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

import 'income_amount_arrow.dart';

class TransactionEntryAmount extends StatelessWidget {
  const TransactionEntryAmount({
    required this.transaction,
    required this.showOtherCurrency,
    required this.unsetCustomCurrency,
    super.key,
  });
  final Transaction transaction;
  final bool showOtherCurrency;
  final bool unsetCustomCurrency;

  @override
  Widget build(BuildContext context) {
    double count = transaction.amount.abs() *
        (amountRatioToPrimaryCurrencyGivenPk(
            Provider.of<AllWallets>(context), transaction.walletFk));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            CountNumber(
              count: count,
              duration: const Duration(milliseconds: 1000),
              initialCount: count,
              textBuilder: (number) {
                return Row(
                  children: [
                    AnimatedSizeSwitcher(
                      child:
                          ((transaction.type == TransactionSpecialType.credit ||
                                      transaction.type ==
                                          TransactionSpecialType.debt) &&
                                  transaction.paid == false)
                              ? const SizedBox.shrink()
                              : IncomeOutcomeArrow(
                                  isIncome: transaction.income,
                                  color: getTransactionAmountColor(
                                    context,
                                    transaction,
                                  ),
                                  width: 15,
                                ),
                    ),
                    TextFont(
                      text: convertToMoney(
                        Provider.of<AllWallets>(context),
                        number,
                        finalNumber: count,
                      ),
                      fontSize: 19 - (showOtherCurrency ? 1 : 0),
                      fontWeight: FontWeight.bold,
                      textColor:
                          getTransactionAmountColor(context, transaction),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        // Original amount:
        AnimatedSizeSwitcher(
          child: showOtherCurrency
              ? TextFont(
                  key: const ValueKey(1),
                  text: convertToMoney(
                    Provider.of<AllWallets>(context),
                    transaction.amount.abs(),
                    decimals: Provider.of<AllWallets>(context)
                            .indexedByPk[transaction.walletFk]
                            ?.decimals ??
                        2,
                    currencyKey: Provider.of<AllWallets>(context)
                        .indexedByPk[transaction.walletFk]
                        ?.currency,
                    addCurrencyName: true,
                  ),
                  fontSize: 12,
                  textColor: getTransactionAmountColor(context, transaction),
                )
              : Container(
                  key: const ValueKey(0),
                ),
        ),
      ],
    );
  }
}

Color getTransactionAmountColor(BuildContext context, Transaction transaction) {
  Color color = transaction.objectiveLoanFk != null && transaction.paid
      ? transaction.income
          ? getColor(context, "unPaidOverdue")
          : getColor(context, "unPaidUpcoming")
      : (transaction.type == TransactionSpecialType.credit ||
                  transaction.type == TransactionSpecialType.debt) &&
              transaction.paid
          ? transaction.type == TransactionSpecialType.credit
              ? getColor(context, "unPaidUpcoming")
              : transaction.type == TransactionSpecialType.debt
                  ? getColor(context, "unPaidOverdue")
                  : getColor(context, "textLight")
          : (transaction.type == TransactionSpecialType.credit ||
                      transaction.type == TransactionSpecialType.debt) &&
                  transaction.paid == false
              ? getColor(context, "textLight")
              : transaction.paid
                  ? transaction.income == true
                      ? getColor(context, "incomeAmount")
                      : getColor(context, "expenseAmount")
                  : transaction.skipPaid
                      ? getColor(context, "textLight")
                      : transaction.dateCreated.millisecondsSinceEpoch <=
                              DateTime.now().millisecondsSinceEpoch
                          ? getColor(context, "textLight")
                          // getColor(context, "unPaidOverdue")
                          : getColor(context, "textLight");
  if (transaction.categoryFk == "0") {
    return dynamicPastel(context, color,
        inverse: true, amountLight: 0.3, amountDark: 0.25);
  }
  return color;
}
