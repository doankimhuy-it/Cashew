import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/transaction_filters.dart';
import 'package:budget/pages/transactions_search_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/navigation_framework.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/period_cycle_picker.dart';
import 'package:budget/widgets/util/keep_alive_client_mixin.dart';
import 'package:budget/widgets/transactions_amount_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePageAllSpendingSummary extends StatelessWidget {
  const HomePageAllSpendingSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return KeepAliveClientMixin(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13, left: 13, right: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TransactionsAmountBox(
                onLongPress: () async {
                  await openBottomSheet(
                    context,
                    PopupFramework(
                      title: "select-period".tr(),
                      child: PeriodCyclePicker(
                        cycleSettingsExtension: "AllSpendingSummary",
                      ),
                    ),
                  );
                  homePageStateKey.currentState?.refreshState();
                },
                label: "expense".tr(),
                amountStream: database.watchTotalOfWallet(
                  null,
                  isIncome: false,
                  allWallets: Provider.of<AllWallets>(context),
                  followCustomPeriodCycle: true,
                  cycleSettingsExtension: "AllSpendingSummary",
                ),
                textColor: getColor(context, "expenseAmount"),
                transactionsAmountStream:
                    database.watchTotalCountOfTransactionsInWallet(
                  null,
                  isIncome: false,
                  followCustomPeriodCycle: true,
                  cycleSettingsExtension: "AllSpendingSummary",
                ),
                openPage: TransactionsSearchPage(
                  initialFilters: SearchFilters(
                    expenseIncome: [ExpenseIncome.expense],
                  ),
                ),
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: TransactionsAmountBox(
                onLongPress: () async {
                  await openBottomSheet(
                    context,
                    PopupFramework(
                      title: "select-period".tr(),
                      child: PeriodCyclePicker(
                        cycleSettingsExtension: "AllSpendingSummary",
                      ),
                    ),
                  );
                  homePageStateKey.currentState?.refreshState();
                },
                label: "income".tr(),
                amountStream: database.watchTotalOfWallet(
                  null,
                  isIncome: true,
                  allWallets: Provider.of<AllWallets>(context),
                  followCustomPeriodCycle: true,
                  cycleSettingsExtension: "AllSpendingSummary",
                ),
                textColor: getColor(context, "incomeAmount"),
                transactionsAmountStream:
                    database.watchTotalCountOfTransactionsInWallet(
                  null,
                  isIncome: true,
                  followCustomPeriodCycle: true,
                  cycleSettingsExtension: "AllSpendingSummary",
                ),
                openPage: TransactionsSearchPage(
                  initialFilters: SearchFilters(
                    expenseIncome: [ExpenseIncome.income],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
