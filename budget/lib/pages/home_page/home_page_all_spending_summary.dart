import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/home_page/home_page_net_worth.dart';
import 'package:budget/pages/transaction_filters.dart';
import 'package:budget/pages/transactions_search_page.dart';
import 'package:budget/pages/wallet_details_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
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
      child: StreamBuilder<List<TransactionWallet>>(
        stream: database
            .getAllPinnedWallets(HomePageWidgetDisplay.AllSpendingSummary)
            .$1,
        builder: (context, snapshot) {
          if (snapshot.hasData ||
              appStateSettings["allSpendingSummaryAllWallets"] == true) {
            List<String>? walletPks =
                (snapshot.data ?? []).map((item) => item.walletPk).toList();
            if (appStateSettings["allSpendingSummaryAllWallets"] == true)
              walletPks = null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 13, left: 13, right: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TransactionsAmountBox(
                      onLongPress: () async {
                        await openAllSpendingSettings(context);
                        homePageStateKey.currentState?.refreshState();
                      },
                      label: "expense".tr(),
                      totalWithCountStream:
                          database.watchTotalWithCountOfWallet(
                        isIncome: false,
                        allWallets: Provider.of<AllWallets>(context),
                        followCustomPeriodCycle: true,
                        cycleSettingsExtension: "AllSpendingSummary",
                        onlyIncomeAndExpense: true,
                        searchFilters:
                            SearchFilters(walletPks: walletPks ?? []),
                      ),
                      textColor: getColor(context, "expenseAmount"),
                      openPage: TransactionsSearchPage(
                        initialFilters: SearchFilters().copyWith(
                          dateTimeRange: getDateTimeRangeForPassedSearchFilters(
                              cycleSettingsExtension: "AllSpendingSummary"),
                          walletPks: walletPks ?? [],
                          expenseIncome: [ExpenseIncome.expense],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: TransactionsAmountBox(
                      onLongPress: () async {
                        await openAllSpendingSettings(context);
                        homePageStateKey.currentState?.refreshState();
                      },
                      label: "income".tr(),
                      totalWithCountStream:
                          database.watchTotalWithCountOfWallet(
                        isIncome: true,
                        allWallets: Provider.of<AllWallets>(context),
                        followCustomPeriodCycle: true,
                        cycleSettingsExtension: "AllSpendingSummary",
                        onlyIncomeAndExpense: true,
                        searchFilters:
                            SearchFilters(walletPks: walletPks ?? []),
                      ),
                      textColor: getColor(context, "incomeAmount"),
                      openPage: TransactionsSearchPage(
                        initialFilters: SearchFilters().copyWith(
                          dateTimeRange: getDateTimeRangeForPassedSearchFilters(
                              cycleSettingsExtension: "AllSpendingSummary"),
                          walletPks: walletPks ?? [],
                          expenseIncome: [ExpenseIncome.income],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}

Future openAllSpendingSettings(BuildContext context) {
  return openBottomSheet(
    context,
    PopupFramework(
      title: "income-and-expenses".tr(),
      subtitle: "applies-to-homepage".tr(),
      child: WalletPickerPeriodCycle(
        allWalletsSettingKey: "allSpendingSummaryAllWallets",
        cycleSettingsExtension: "AllSpendingSummary",
        homePageWidgetDisplay: HomePageWidgetDisplay.AllSpendingSummary,
      ),
    ),
  );
}
