import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/add_wallet_page.dart';
import 'package:budget/pages/transaction_filters.dart';
import 'package:budget/pages/wallet_details_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/util/on_app_resume.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

class AndroidOnly extends StatelessWidget {
  const AndroidOnly({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) {
      return const SizedBox.shrink();
    }
    return child;
  }
}

class CheckWidgetLaunch extends StatefulWidget {
  const CheckWidgetLaunch({super.key});

  @override
  State<CheckWidgetLaunch> createState() => _CheckWidgetLaunchState();
}

bool hasDoneWidgetAction = false;

class _CheckWidgetLaunchState extends State<CheckWidgetLaunch> {
  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('WIDGET_GROUP_ID');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }

  // For some reason, older Android versions open an entirely new app instance... weird!
  void _launchedFromWidget(Uri? uri) async {
    // Only perform one widget action per launch/continue of the app
    if (hasDoneWidgetAction == true) return;
    hasDoneWidgetAction = true;

    String widgetPayload = (uri ?? "").toString();
    if (widgetPayload == "addTransaction") {
      pushRoute(
        context,
        const AddTransactionPage(
          routesToPopAfterDelete: RoutesToPopAfterDelete.None,
        ),
      );
    } else if (widgetPayload == "transferTransaction") {
      // This fixes an issue on older versions of Android where the route would popup twice
      // We can detect when this is going to happen if the Provider is not yet loaded, so just pop
      // the route when this is called so the first time routing does not persist (i.e. we end with one route)
      if (Provider.of<AllWallets>(context, listen: false)
              .indexedByPk[appStateSettings["selectedWalletPk"]] ==
          null) Navigator.of(context).popUntil((route) => route.isFirst);

      openBottomSheet(
        context,
        fullSnap: true,
        TransferBalancePopup(
          allowEditWallet: true,
          wallet: Provider.of<AllWallets>(context, listen: false)
              .indexedByPk[appStateSettings["selectedWalletPk"]],
          showAllEditDetails: true,
        ),
      );
    } else if (widgetPayload == "netWorthLaunch") {
      pushRoute(
        context,
        const WalletDetailsPage(
          wallet: null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnAppResume(
      onAppResume: () {
        hasDoneWidgetAction = false;
      },
      child: const SizedBox.shrink(),
    );
  }
}

class RenderHomePageWidgets extends StatefulWidget {
  const RenderHomePageWidgets({super.key});

  @override
  State<RenderHomePageWidgets> createState() => _RenderHomePageWidgetsState();
}

Future updateWidgetColorsAndText(BuildContext context) async {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return;
  await Future.delayed(const Duration(milliseconds: 500), () async {
    await HomeWidget.saveWidgetData<String>('netWorthTitle', "net-worth".tr());
    await HomeWidget.saveWidgetData<String>(
      'widgetColorBackground',
      colorToHex(Theme.of(context).colorScheme.secondaryContainer),
    );
    await HomeWidget.saveWidgetData<String>(
      'widgetColorPrimary',
      colorToHex(Theme.of(context).colorScheme.primary),
    );
    await HomeWidget.saveWidgetData<String>(
      'widgetColorText',
      colorToHex(Theme.of(context).colorScheme.onSecondaryContainer),
    );
    await HomeWidget.updateWidget(
      name: 'NetWorthWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'NetWorthPlusWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'PlusWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'TransferWidgetProvider',
    );
  });

  return;
}

class _RenderHomePageWidgetsState extends State<RenderHomePageWidgets> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      updateWidgetColorsAndText(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionWallet>>(
      stream: database.getAllPinnedWallets(HomePageWidgetDisplay.NetWorth).$1,
      builder: (context, snapshot) {
        List<String>? walletPks =
            (snapshot.data ?? []).map((item) => item.walletPk).toList();
        if (appStateSettings["netWorthAllWallets"] == true) walletPks = null;
        return Container(
          child: StreamBuilder<TotalWithCount?>(
            stream: database.watchTotalWithCountOfWallet(
              isIncome: null,
              allWallets: Provider.of<AllWallets>(context),
              followCustomPeriodCycle: true,
              cycleSettingsExtension: "NetWorth",
              searchFilters: SearchFilters(walletPks: walletPks ?? []),
            ),
            builder: (context, snapshot) {
              Future.delayed(Duration.zero, () async {
                int totalCount = snapshot.data?.count ?? 0;
                String netWorthTransactionsNumber = "$totalCount ${totalCount == 1
                        ? "transaction".tr().toLowerCase()
                        : "transactions".tr().toLowerCase()}";
                double totalSpent = snapshot.data?.total ?? 0;
                String netWorthAmount = convertToMoney(
                  Provider.of<AllWallets>(context, listen: false),
                  totalSpent,
                );
                await HomeWidget.saveWidgetData<String>(
                  'netWorthAmount',
                  netWorthAmount,
                );
                await HomeWidget.saveWidgetData<String>(
                  'netWorthTransactionsNumber',
                  netWorthTransactionsNumber,
                );
                await HomeWidget.updateWidget(
                  name: 'NetWorthWidgetProvider',
                );
                await HomeWidget.updateWidget(
                  name: 'NetWorthPlusWidgetProvider',
                );
              });

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
