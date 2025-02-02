import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/home_page/home_page_wallet_switcher.dart';
import 'package:budget/pages/transaction_filters.dart';
import 'package:budget/pages/wallet_details_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/util/keep_alive_client_mixin.dart';
import 'package:budget/widgets/navigation_framework.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/outlined_button_stacked.dart';
import 'package:budget/widgets/period_cycle_picker.dart';
import 'package:budget/widgets/transactions_amount_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePageNetWorth extends StatelessWidget {
  const HomePageNetWorth({super.key});

  @override
  Widget build(BuildContext context) {
    return KeepAliveClientMixin(
      child: StreamBuilder<List<TransactionWallet>>(
          stream:
              database.getAllPinnedWallets(HomePageWidgetDisplay.NetWorth).$1,
          builder: (context, snapshot) {
            if (snapshot.hasData ||
                appStateSettings["netWorthAllWallets"] == true) {
              List<String>? walletPks =
                  (snapshot.data ?? []).map((item) => item.walletPk).toList();
              if (appStateSettings["netWorthAllWallets"] == true) {
                walletPks = null;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 13, left: 13, right: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TransactionsAmountBox(
                        onLongPress: () async {
                          await openNetWorthSettings(context);
                          homePageStateKey.currentState?.refreshState();
                        },
                        label: "net-worth".tr(),
                        absolute: false,
                        currencyKey: Provider.of<AllWallets>(context)
                            .indexedByPk[appStateSettings["selectedWalletPk"]]
                            ?.currency,
                        totalWithCountStream:
                            database.watchTotalWithCountOfWallet(
                          isIncome: null,
                          allWallets: Provider.of<AllWallets>(context),
                          followCustomPeriodCycle: true,
                          cycleSettingsExtension: "NetWorth",
                          searchFilters:
                              SearchFilters(walletPks: walletPks ?? []),
                        ),
                        textColor: getColor(context, "black"),
                        openPage: const WalletDetailsPage(wallet: null),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
    );
  }
}

class WalletPickerPeriodCycle extends StatefulWidget {
  const WalletPickerPeriodCycle({
    required this.allWalletsSettingKey,
    required this.cycleSettingsExtension,
    required this.homePageWidgetDisplay,
    this.onlyShowCycleOption = false,
    super.key,
  });
  final String? allWalletsSettingKey;
  final String cycleSettingsExtension;
  final HomePageWidgetDisplay? homePageWidgetDisplay;
  final bool onlyShowCycleOption;

  @override
  State<WalletPickerPeriodCycle> createState() =>
      _WalletPickerPeriodCycleState();
}

class _WalletPickerPeriodCycleState extends State<WalletPickerPeriodCycle> {
  late bool allWalletsSelected = appStateSettings[widget.allWalletsSettingKey];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.homePageWidgetDisplay != null &&
            widget.allWalletsSettingKey != null)
          Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: allWalletsSelected ? 1 : 0.5,
                  child: OutlinedButtonStacked(
                    filled: allWalletsSelected,
                    alignLeft: true,
                    alignBeside: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    text: "all-accounts".tr(),
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.account_balance_wallet_outlined
                        : Icons.account_balance_wallet_rounded,
                    onTap: () {
                      updateSettings(
                          widget.allWalletsSettingKey!, !allWalletsSelected,
                          updateGlobalState: false);
                      setState(() {
                        allWalletsSelected = !allWalletsSelected;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        if (widget.homePageWidgetDisplay != null &&
            widget.allWalletsSettingKey != null)
          const SizedBox(height: 10),
        // CheckItems(
        //   triggerInitialOnChanged: false,
        //   minVerticalPadding: 0,
        //   allSelected: allWalletsSelected,
        //   initial: (appStateSettings["netWorthSelectedWalletPks"] ?? [])
        //       .cast<String>(),
        //   items: [
        //     for (String walletPk
        //         in Provider.of<AllWallets>(context, listen: false)
        //             .indexedByPk
        //             .keys)
        //       walletPk
        //   ],
        //   onChanged: (currentValues) {
        //     updateSettings("netWorthAllWallets", false,
        //         updateGlobalState: false);
        //     setState(() {
        //       allWalletsSelected = false;
        //     });
        //   },
        //   displayFilter: (item, itemIndex) {
        //     return Provider.of<AllWallets>(context, listen: false)
        //         .indexedByPk[item]!
        //         .name;
        //   },
        //   colorFilter: (item) {
        //     return dynamicPastel(
        //       context,
        //       lightenPastel(
        //         HexColor(
        //             Provider.of<AllWallets>(context, listen: false)
        //                 .indexedByPk[item]!
        //                 .colour,
        //             defaultColor: Theme.of(context).colorScheme.primary),
        //         amount: 0.2,
        //       ),
        //       amount: 0.1,
        //     );
        //   },
        // ),
        if (widget.homePageWidgetDisplay != null &&
            widget.allWalletsSettingKey != null)
          EditHomePagePinnedWalletsPopup(
            includeFramework: false,
            homePageWidgetDisplay: widget.homePageWidgetDisplay!,
            highlightSelected: true,
            useCheckMarks: true,
            onAnySelected: () {
              updateSettings(widget.allWalletsSettingKey!, false,
                  updateGlobalState: false);
              setState(() {
                allWalletsSelected = false;
              });
            },
            allSelected: allWalletsSelected,
          ),
        Padding(
          padding: widget.homePageWidgetDisplay != null &&
                  widget.allWalletsSettingKey != null
              ? EdgeInsets.zero
              : const EdgeInsets.only(top: 8.0),
          child: HorizontalBreakAbove(
            enabled: widget.homePageWidgetDisplay != null &&
                widget.allWalletsSettingKey != null,
            child: PeriodCyclePicker(
              cycleSettingsExtension: widget.cycleSettingsExtension,
              onlyShowCycleOption: widget.onlyShowCycleOption,
            ),
          ),
        ),
      ],
    );
  }
}

Future openNetWorthSettings(BuildContext context) {
  return openBottomSheet(
    context,
    PopupFramework(
      title: "net-worth".tr(),
      subtitle: "applies-to-homepage".tr() +
          (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid
              ? " ${"and-applies-to-widget".tr()}"
              : ""),
      child: const WalletPickerPeriodCycle(
        allWalletsSettingKey: "netWorthAllWallets",
        cycleSettingsExtension: "NetWorth",
        homePageWidgetDisplay: HomePageWidgetDisplay.NetWorth,
      ),
    ),
  );
}
