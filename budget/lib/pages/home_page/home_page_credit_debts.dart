import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/credit_debt_transactions_page.dart';
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

class HomePageCreditDebts extends StatelessWidget {
  const HomePageCreditDebts({super.key});

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
                label: "lent".tr(),
                totalWithCountStream: database.watchTotalWithCountOfCreditDebt(
                  allWallets: Provider.of<AllWallets>(context),
                  isCredit: true,
                  followCustomPeriodCycle: true,
                  cycleSettingsExtension: "CreditDebts",
                  selectedTab: null,
                ),
                textColor: getColor(context, "unPaidUpcoming"),
                openPage: CreditDebtTransactions(isCredit: true),
                onLongPress: () async {
                  await openCreditDebtsSettings(context);
                  homePageStateKey.currentState?.refreshState();
                },
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: TransactionsAmountBox(
                label: "borrowed".tr(),
                totalWithCountStream: database.watchTotalWithCountOfCreditDebt(
                  allWallets: Provider.of<AllWallets>(context),
                  isCredit: false,
                  cycleSettingsExtension: "CreditDebts",
                  followCustomPeriodCycle: true,
                  selectedTab: null,
                ),
                textColor: getColor(context, "unPaidOverdue"),
                openPage: CreditDebtTransactions(isCredit: false),
                onLongPress: () async {
                  await openCreditDebtsSettings(context);
                  homePageStateKey.currentState?.refreshState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future openCreditDebtsSettings(BuildContext context) {
  return openBottomSheet(
    context,
    PopupFramework(
      title: "loans".tr(),
      subtitle: "applies-to-homepage".tr(),
      child: PeriodCyclePicker(cycleSettingsExtension: "CreditDebts"),
    ),
  );
}
