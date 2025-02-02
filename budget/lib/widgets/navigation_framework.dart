import 'package:budget/colors.dart';
import 'package:budget/database/initialize_default_database.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/about_page.dart';
import 'package:budget/pages/accounts_page.dart';
import 'package:budget/pages/add_budget_page.dart';
import 'package:budget/pages/add_category_page.dart';
import 'package:budget/pages/add_objective_page.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/add_wallet_page.dart';
import 'package:budget/pages/auto_transactions_page_email.dart';
import 'package:budget/pages/budgets_list_page.dart';
import 'package:budget/pages/edit_associated_titles_page.dart';
import 'package:budget/pages/edit_budget_page.dart';
import 'package:budget/pages/edit_objectives_page.dart';
import 'package:budget/pages/edit_wallets_page.dart';
import 'package:budget/pages/home_page/home_page.dart';
import 'package:budget/pages/notifications_page.dart';
import 'package:budget/pages/objectives_list_page.dart';
import 'package:budget/pages/settings_page.dart';
import 'package:budget/pages/subscriptions_page.dart';
import 'package:budget/pages/transactions_list_page.dart';
import 'package:budget/pages/upcoming_overdue_transactions_page.dart';
import 'package:budget/pages/wallet_details_page.dart';
import 'package:budget/pages/credit_debt_transactions_page.dart';
import 'package:budget/struct/currency_functions.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/nav_bar_icons_data.dart';
import 'package:budget/struct/quick_actions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/share_budget.dart';
import 'package:budget/struct/sync_client.dart';
import 'package:budget/widgets/account_and_backup.dart';
import 'package:budget/widgets/bottom_nav_bar.dart';
import 'package:budget/widgets/category_icon.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/icon_button_scaled.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/notifications_settings.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/outlined_button_stacked.dart';
import 'package:budget/widgets/select_amount.dart';
import 'package:budget/widgets/select_chips.dart';
import 'package:budget/widgets/selected_transactions_app_bar.dart';
import 'package:budget/struct/initialize_notifications.dart';
import 'package:budget/widgets/global_loading_progress.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/pages/edit_categories_page.dart';
import 'package:budget/struct/upcoming_transactions_functions.dart';
import 'package:budget/widgets/transaction_entry/transaction_entry.dart';
import 'package:budget/widgets/transaction_entry/transaction_label.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:provider/provider.dart';
// import 'package:feature_discovery/feature_discovery.dart';

class PageNavigationFramework extends StatefulWidget {
  const PageNavigationFramework({super.key});

  //PageNavigationFramework.changePage(context, 0);
  static void changePage(BuildContext context, page,
      {bool switchNavbar = false}) {
    context
        .findAncestorStateOfType<PageNavigationFrameworkState>()!
        .changePage(page, switchNavbar: switchNavbar);
  }

  @override
  State<PageNavigationFramework> createState() =>
      PageNavigationFrameworkState();
}

//can also do GlobalKey<dynamic> for private state classes, but bad practice and no autocomplete
GlobalKey<HomePageState> homePageStateKey = GlobalKey();
GlobalKey<TransactionsListPageState> transactionsListPageStateKey = GlobalKey();
GlobalKey<BudgetsListPageState> budgetsListPageStateKey = GlobalKey();
GlobalKey<MoreActionsPageState> settingsPageStateKey = GlobalKey();
GlobalKey<SettingsPageFrameworkState> settingsPageFrameworkStateKey =
    GlobalKey();
GlobalKey<AccountsPageState> accountsPageStateKey = GlobalKey();
GlobalKey<BottomNavBarState> navbarStateKey = GlobalKey();
GlobalKey<NavigationSidebarState> sidebarStateKey = GlobalKey();
GlobalKey<GlobalLoadingProgressState> loadingProgressKey = GlobalKey();
GlobalKey<GlobalLoadingIndeterminateState> loadingIndeterminateKey =
    GlobalKey();
GlobalKey<GlobalSnackbarState> snackbarKey = GlobalKey();

bool runningCloudFunctions = false;
bool errorSigningInDuringCloud = false;
Future<bool> runAllCloudFunctions(BuildContext context,
    {bool forceSignIn = false}) async {
  print("Running All Cloud Functions");
  runningCloudFunctions = true;
  errorSigningInDuringCloud = false;
  try {
    loadingIndeterminateKey.currentState!.setVisibility(true);
    await syncData(context);
    if (appStateSettings["emailScanningPullToRefresh"] ||
        entireAppLoaded == false) {
      loadingIndeterminateKey.currentState!.setVisibility(true);
      await parseEmailsInBackground(context, forceParse: true);
    }
    loadingIndeterminateKey.currentState!.setVisibility(true);
    await syncPendingQueueOnServer(); //sync before download
    loadingIndeterminateKey.currentState!.setVisibility(true);
    await getCloudBudgets();
    loadingIndeterminateKey.currentState!.setVisibility(true);
    await createBackupInBackground(context);
    loadingIndeterminateKey.currentState!.setVisibility(true);
    await getExchangeRates();
  } catch (e) {
    print("Error running sync functions on load: $e");
    loadingIndeterminateKey.currentState!.setVisibility(false);
    runningCloudFunctions = false;
    canSyncData = true;
    if (e is DetailedApiRequestError &&
            e.status == 401 &&
            forceSignIn == true ||
        e is PlatformException) {
      // Request had invalid authentication credentials. Try logging out and back in.
      // This stems from silent sign-in not providing the credentials for GDrive API for e.g.
      await refreshGoogleSignIn();
      runAllCloudFunctions(context);
    }
    return false;
  }
  loadingIndeterminateKey.currentState!.setVisibility(false);
  Future.delayed(const Duration(milliseconds: 2000), () {
    runningCloudFunctions = false;
  });
  errorSigningInDuringCloud = false;
  return true;
}

class PageNavigationFrameworkState extends State<PageNavigationFramework> {
  late List<Widget> pages;
  late List<Widget> pagesExtended;

  int currentPage = 0;
  int previousPage = 0;

  void changePage(int page, {bool switchNavbar = true}) {
    if (switchNavbar) {
      sidebarStateKey.currentState?.setSelectedIndex(page);
      navbarStateKey.currentState?.setSelectedIndex(page >= 3 ? 3 : page);
    }
    setState(() {
      previousPage = currentPage;
      currentPage = page;
    });
  }

  @override
  void initState() {
    super.initState();

    // Functions to run after entire UI loaded
    Future.delayed(Duration.zero, () async {
      SystemChrome.setSystemUIOverlayStyle(
          getSystemUiOverlayStyle(Theme.of(context).brightness));

      bool isDatabaseCorruptedPopupShown = openDatabaseCorruptedPopup(context);
      if (isDatabaseCorruptedPopupShown) return;

      await initializeNotificationsPlatform();

      await setDailyNotifications(context);
      await initializeDefaultDatabase();
      runNotificationPayLoads(context);
      runQuickActionsPayLoads(context);

      if (entireAppLoaded == false) {
        await runAllCloudFunctions(context);
      }

      // Mark subscriptions as paid AFTER syncing with cloud
      // Maybe another device already marked them as paid
      await markSubscriptionsAsPaid(context);
      await markUpcomingAsPaid();

      // Should do this after syncing and after the subscriptions/upcoming transactions auto paid for
      // The upcoming transactions may have been modified after a sync
      await setUpcomingNotifications(context);

      database.deleteWanderingTransactions();

      entireAppLoaded = true;

      print("Entire app loaded");

      database.watchAllForAutoSync().listen((event) {
        // Must be logged in to perform an automatic sync - googleUser != null
        // If we remove this, it will ask the user to login though - but it can be annoying
        // Users can visually see the last time of sync, especially on web where sign-in is not automatic,
        // so it shouldn't be an issue
        if (runningCloudFunctions == false && googleUser != null) {
          createSyncBackup(changeMadeSync: true);
        }
      });
    });

    pages = [
      HomePage(key: homePageStateKey), // 0
      TransactionsListPage(key: transactionsListPageStateKey), //1
      BudgetsListPage(
          key: budgetsListPageStateKey, enableBackButton: false), //2
      MoreActionsPage(key: settingsPageStateKey), //3
    ];
    pagesExtended = [
      const MoreActionsPage(), //4
      const SubscriptionsPage(), //5
      const NotificationsPage(), //6
      const WalletDetailsPage(wallet: null), //7
      AccountsPage(key: accountsPageStateKey), // 8
      const EditWalletsPage(), //9
      const EditBudgetPage(), //10
      const EditCategoriesPage(), //11
      const EditAssociatedTitlesPage(), //12
      const AboutPage(), //13
      const ObjectivesListPage(backButton: false), //14
      const EditObjectivesPage(objectiveType: ObjectiveType.goal), //15
      const UpcomingOverdueTransactions(overdueTransactions: null), //16
      const CreditDebtTransactions(isCredit: null), //17
    ];

    // SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
    //   FeatureDiscovery.discoverFeatures(
    //     context,
    //     const <String>{
    //       'add_transaction_button',
    //     },
    //   );
    // });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Deselect selected transactions
        int notEmpty = 0;
        for (String key in globalSelectedID.value.keys) {
          if (globalSelectedID.value[key]?.isNotEmpty == true) notEmpty++;
          globalSelectedID.value[key] = [];
        }
        globalSelectedID.notifyListeners();

        // Allow the back button to exit the app when on home
        if (notEmpty <= 0) {
          if (currentPage == 0) {
            return true;
          } else {
            // Allow back button deselect a selected category first on All Spending page
            if (currentPage == 7 && categoryIsSelectedOnAllSpending) {
              return true;
            }
            changePage(0);
          }
        }

        return false;
      },

      // The global Widget stack
      child: Stack(children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: FadeIndexedStack(
            index: currentPage,
            duration: Duration.zero,
            children: [...pages, ...pagesExtended]
          ),
          extendBody: false,
          bottomNavigationBar: BottomNavBar(
            key: navbarStateKey,
            onChanged: (index) {
              changePage(index);
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: getHeightNavigationSidebar(context) + 15,
              right: 15,
            ),
            child: Stack(
              children: [
                // DescribedFeatureOverlay(
                //   featureId: 'add_transaction_button',
                //   tapTarget: IgnorePointer(
                //     child: AnimateFAB(
                //       fab: FAB(
                //         tooltip: "Add Transaction",
                //         openPage: AddTransactionPage(
                //
                //         ),
                //       ),
                //       condition: currentPage == 0 || currentPage == 1,
                //     ),
                //   ),
                //   pulseDuration: Duration(milliseconds: 3500),
                //   contentLocation: ContentLocation.above,
                //   title: TextFont(
                //     text: 'Add Transaction',
                //     fontWeight: FontWeight.bold,
                //     fontSize: 22,
                //     maxLines: 3,
                //   ),
                //   description: TextFont(
                //     text: 'Tap the plus to add a transaction',
                //     fontSize: 17,
                //     maxLines: 10,
                //   ),
                //   backgroundColor: Theme.of(context).primaryColor,
                //   textColor: Colors.white,
                //   child: AnimateFAB(
                //     fab: FAB(
                //       tooltip: "Add Transaction",
                //       openPage: AddTransactionPage(
                //
                //       ),
                //     ),
                //     condition: currentPage == 0 || currentPage == 1,
                //   ),
                // ),

                // AnimatedSwitcher(
                //   duration: Duration(milliseconds: 350),
                //   switchInCurve: Curves.easeOutCubic,
                //   switchOutCurve: Curves.ease,
                //   transitionBuilder:
                //       (Widget child, Animation<double> animation) {
                //     return FadeTransition(
                //       opacity: animation,
                //       child: ScaleTransition(
                //         scale: Tween<double>(begin: 0.4, end: 1.0)
                //             .animate(animation),
                //         child: child,
                //       ),
                //     );
                //   },
                //   child: currentPage == 0 ||
                //           currentPage == 1 ||
                //           (previousPage == 0 && currentPage != 2) ||
                //           (previousPage == 1 && currentPage != 2)
                //       ? AnimateFAB(
                //           key: ValueKey(1),
                //           fab: FAB(
                //             tooltip: "add-transaction".tr(),
                //             openPage: AddTransactionPage(
                //               routesToPopAfterDelete:
                //                   RoutesToPopAfterDelete.None,
                //             ),
                //           ),
                //           condition: currentPage == 0 || currentPage == 1,
                //         )
                //       : AnimateFAB(
                //           key: ValueKey(2),
                //           fab: FAB(
                //             tooltip: "add-budget".tr(),
                //             openPage: AddBudgetPage(
                //               routesToPopAfterDelete:
                //                   RoutesToPopAfterDelete.None,
                //             ),
                //           ),
                //           condition: currentPage == 2,
                //         ),
                // ),
                AnimateFAB(
                  key: const ValueKey(1),
                  fab: FAB(
                    tooltip: "add-transaction".tr(),
                    openPage: const AddTransactionPage(
                      routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                    ),
                  ),
                  condition: [0, 1, 2, 14].contains(currentPage),
                )
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class AddMoreThingsPopup extends StatelessWidget {
  const AddMoreThingsPopup({super.key});

  createTransactionFromCommon({
    required BuildContext context,
    required TransactionWithCount transactionWithCount,
    required Map<String, TransactionCategory> categoriesIndexed,
    double? customAmount,
  }) async {
    Navigator.pop(context);
    await duplicateTransaction(
      context,
      transactionWithCount.transaction.transactionPk,
      showDuplicatedMessage: false,
      useCurrentDate: true,
      customAmount: customAmount,
    );
    openSnackbar(
      SnackbarMessage(
        icon: navBarIconsData["transactions"]!.iconData,
        title: "created-transaction".tr(),
        description: getTransactionLabelSync(
          transactionWithCount.transaction,
          categoriesIndexed[transactionWithCount.transaction.categoryFk],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        AddThing(
          iconData: navBarIconsData["accountDetails"]!.iconData,
          title: "account".tr(),
          openPage: const AddWalletPage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
          widgetAfter: SelectChips(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            items: [
              if (Provider.of<AllWallets>(context).list.length > 1)
                "transfer-balance",
              "correct-total-balance"
            ],
            getSelected: (_) {
              return false;
            },
            onSelected: (String selection) async {
              if (selection == "transfer-balance") {
                Navigator.pop(context);
                openBottomSheet(
                  context,
                  fullSnap: true,
                  TransferBalancePopup(
                    allowEditWallet: true,
                    wallet: Provider.of<AllWallets>(context, listen: false)
                        .indexedByPk[appStateSettings["selectedWalletPk"]]!,
                  ),
                );
              } else if (selection == "correct-total-balance") {
                TransactionWallet? wallet =
                    Provider.of<AllWallets>(context, listen: false)
                        .indexedByPk[appStateSettings["selectedWalletPk"]];
                if (Provider.of<AllWallets>(context, listen: false)
                        .list
                        .length >
                    1) {
                  wallet = await selectWalletPopup(
                    context,
                    allowEditWallet: true,
                  );
                }
                if (wallet != null) {
                  Navigator.pop(context);
                  openBottomSheet(
                    context,
                    fullSnap: true,
                    CorrectBalancePopup(wallet: wallet),
                  );
                }
              }
            },
            getLabel: (String selection) {
              return selection.tr();
            },
            getAvatar: (String selection) {
              return LayoutBuilder(builder: (context2, constraints) {
                return Icon(
                  selection == "transfer-balance"
                      ? appStateSettings["outlinedIcons"]
                          ? Icons.compare_arrows_outlined
                          : Icons.compare_arrows_rounded
                      : appStateSettings["outlinedIcons"]
                          ? Icons.library_add_outlined
                          : Icons.library_add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: constraints.maxWidth,
                );
              });
            },
          ),
        ),
        StreamBuilder<Map<String, TransactionCategory>>(
          stream: database.watchAllCategoriesIndexed(),
          builder: (context, snapshotCategories) {
            Map<String, TransactionCategory> categoriesIndexed =
                snapshotCategories.data ?? {};
            return StreamBuilder<List<TransactionWithCount>>(
              stream: database.getCommonTransactions(),
              builder: (context, snapshot) {
                List<TransactionWithCount> commonTransactions =
                    snapshot.data ?? [];
                if (commonTransactions.isEmpty) {
                  return AddThing(
                    iconData: navBarIconsData["transactions"]!.iconData,
                    title: "transaction".tr(),
                    openPage: const AddTransactionPage(
                        routesToPopAfterDelete: RoutesToPopAfterDelete.None),
                  );
                }
                return AddThing(
                  infoButton: IconButtonScaled(
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.info_outlined
                        : Icons.info_outline_rounded,
                    iconSize: 14,
                    scale: 1.8,
                    padding: const EdgeInsets.all(5),
                    onTap: () {
                      openPopup(
                        context,
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.dynamic_feed_outlined
                            : Icons.dynamic_feed_rounded,
                        title: "most-common-transactions".tr(),
                        description:
                            "most-common-transactions-description".tr(),
                        onSubmit: () {
                          Navigator.pop(context);
                        },
                        onSubmitLabel: "ok".tr(),
                      );
                    },
                  ),
                  iconData: navBarIconsData["transactions"]!.iconData,
                  title: "transaction".tr(),
                  openPage: const AddTransactionPage(
                      routesToPopAfterDelete: RoutesToPopAfterDelete.None),
                  widgetAfter: SelectChips(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    items: commonTransactions,
                    getSelected: (_) {
                      return false;
                    },
                    onLongPress:
                        (TransactionWithCount transactionWithCount) async {
                      double amount = await openBottomSheet(
                        context,
                        fullSnap: true,
                        PopupFramework(
                          title: "enter-amount".tr(),
                          underTitleSpace: false,
                          child: SelectAmount(
                            setSelectedAmount: (_, __) {},
                            nextLabel: "set-amount".tr(),
                            popWithAmount: true,
                          ),
                        ),
                      );
                      amount = amount.abs() *
                          (transactionWithCount.transaction.income ? 1 : -1);
                      createTransactionFromCommon(
                        context: context,
                        transactionWithCount: transactionWithCount,
                        categoriesIndexed: categoriesIndexed,
                        customAmount: amount,
                      );
                    },
                    onSelected:
                        (TransactionWithCount transactionWithCount) async {
                      createTransactionFromCommon(
                        context: context,
                        transactionWithCount: transactionWithCount,
                        categoriesIndexed: categoriesIndexed,
                      );
                    },
                    getLabel: (TransactionWithCount transactionWithCount) {
                      double amountInPrimary =
                          transactionWithCount.transaction.amount *
                              (amountRatioToPrimaryCurrencyGivenPk(
                                  Provider.of<AllWallets>(context),
                                  transactionWithCount.transaction.walletFk));
                      return "${getTransactionLabelSync(
                            transactionWithCount.transaction,
                            categoriesIndexed[
                                transactionWithCount.transaction.categoryFk],
                          )} (${convertToMoney(
                            Provider.of<AllWallets>(context),
                            amountInPrimary,
                            currencyKey: Provider.of<AllWallets>(context)
                                .indexedByPk[
                                    transactionWithCount.transaction.walletFk]
                                ?.currency,
                          )})";
                    },
                    getCustomBorderColor:
                        (TransactionWithCount transactionWithCount) {
                      return dynamicPastel(
                        context,
                        lightenPastel(
                          HexColor(
                            categoriesIndexed[
                                    transactionWithCount.transaction.categoryFk]
                                ?.colour,
                            defaultColor: Theme.of(context).colorScheme.primary,
                          ),
                          amount: 0.3,
                        ),
                        amount: 0.4,
                      );
                    },
                    getAvatar: (TransactionWithCount transactionWithCount) {
                      return LayoutBuilder(builder: (context, constraints) {
                        return CategoryIcon(
                          categoryPk: "-1",
                          category: categoriesIndexed[
                              transactionWithCount.transaction.categoryFk],
                          emojiSize: constraints.maxWidth * 0.73,
                          emojiScale: 1.2,
                          size: constraints.maxWidth,
                          sizePadding: 0,
                          noBackground: true,
                          canEditByLongPress: false,
                          margin: EdgeInsets.zero,
                        );
                      });
                    },
                  ),
                );
              },
            );
          },
        ),
        AddThing(
          iconData: navBarIconsData["loans"]!.iconData,
          title: navBarIconsData["loans"]!.label.tr(),
          openPage: const AddObjectivePage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            objectiveType: ObjectiveType.loan,
          ),
          widgetAfter: SelectChips(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            items: const ["long-term", "one-time"],
            getSelected: (_) {
              return false;
            },
            // extraWidget: SelectChipsAddButtonExtraWidget(
            //   openPage: AddObjectivePage(
            //     routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            //   ),
            //   shouldPushRoute: true,
            //   popCurrentRoute: true,
            // ),
            // extraWidgetAtBeginning: true,
            onSelected: (String selection) async {
              Navigator.pop(context);
              if (selection == "long-term") {
                pushRoute(
                  context,
                  const AddObjectivePage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                    objectiveType: ObjectiveType.loan,
                  ),
                );
              } else {
                pushRoute(
                  context,
                  const AddTransactionPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                    selectedType: TransactionSpecialType.credit,
                  ),
                );
              }
            },
            getLabel: (String selection) {
              return selection.tr();
            },
            getAvatar: (String selection) {
              return LayoutBuilder(builder: (context2, constraints) {
                return Icon(
                  selection == "long-term"
                      ? appStateSettings["outlinedIcons"]
                          ? Icons.av_timer_outlined
                          : Icons.av_timer_rounded
                      : appStateSettings["outlinedIcons"]
                          ? Icons.event_available_outlined
                          : Icons.event_available_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: constraints.maxWidth,
                );
              });
            },
          ),
        ),
        AddThing(
          iconData: navBarIconsData["goals"]!.iconData,
          title: "goal".tr(),
          openPage: const AddObjectivePage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
          widgetAfter: SelectChips(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            items: const ["installment"],
            getSelected: (_) {
              return false;
            },
            // extraWidget: SelectChipsAddButtonExtraWidget(
            //   openPage: AddObjectivePage(
            //     routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            //   ),
            //   shouldPushRoute: true,
            //   popCurrentRoute: true,
            // ),
            // extraWidgetAtBeginning: true,
            onSelected: (String selection) async {
              if (navigatorKey.currentContext == null) {
                startCreatingInstallment(context: context);
              } else {
                Navigator.pop(context);
                startCreatingInstallment(context: navigatorKey.currentContext!);
              }
            },
            getLabel: (String selection) {
              return selection.tr();
            },
            getAvatar: (String selection) {
              return LayoutBuilder(builder: (context2, constraints) {
                return Icon(
                  appStateSettings["outlinedIcons"]
                      ? Icons.punch_clock_outlined
                      : Icons.punch_clock_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: constraints.maxWidth,
                );
              });
            },
          ),
        ),
        AddThing(
          iconData: navBarIconsData["budgets"]!.iconData,
          title: "budget".tr(),
          openPage: const AddBudgetPage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
          iconScale: navBarIconsData["budgets"]!.iconScale,
        ),
        AddThing(
          iconData: navBarIconsData["categoriesDetails"]!.iconData,
          title: "category".tr(),
          openPage: const AddCategoryPage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
        ),
      ],
    );
  }
}

class AddThing extends StatelessWidget {
  const AddThing({
    required this.iconData,
    required this.title,
    required this.openPage,
    this.onTap,
    this.widgetAfter,
    this.infoButton,
    this.iconScale = 1,
    super.key,
  });

  final IconData iconData;
  final String title;
  final Widget openPage;
  final VoidCallback? onTap;
  final Widget? widgetAfter;
  final Widget? infoButton;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
        top: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButtonStacked(
              filled: false,
              alignLeft: true,
              alignBeside: true,
              padding: widgetAfter != null
                  ? const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 5)
                  : const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              text: title.capitalizeFirst,
              iconData: iconData,
              iconScale: iconScale,
              onTap: () {
                if (onTap != null) {
                  onTap!();
                } else {
                  Navigator.pop(context);
                  pushRoute(context, openPage);
                }
              },
              afterWidget: widgetAfter,
              afterWidgetPadding: widgetAfter != null
                  ? const EdgeInsets.only(bottom: 8)
                  : EdgeInsets.zero,
              infoButton: infoButton,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimateFAB extends StatelessWidget {
  const AnimateFAB({required this.condition, required this.fab, super.key});

  final bool condition;
  final Widget fab;

  @override
  Widget build(BuildContext context) {
    // return AnimatedOpacity(
    //   duration: Duration(milliseconds: 400),
    //   opacity: condition ? 1 : 0,
    //   child: AnimatedScale(
    //     duration: Duration(milliseconds: 1100),
    //     scale: condition ? 1 : 0,
    //     curve: Curves.easeInOutCubicEmphasized,
    //     child: fab,
    //     alignment: Alignment(0.7, 0.7),
    //   ),
    // );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutCubicEmphasized,
      switchOutCurve: Curves.ease,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeScaleTransitionButton(
          animation: animation,
          alignment: const Alignment(0.7, 0.7),
          child: child,
        );
      },
      child: condition
          ? fab
          : const SizedBox(
              key: ValueKey(1),
              width: 50,
              height: 50,
            ),
    );
  }
}

class FadeScaleTransitionButton extends StatelessWidget {
  const FadeScaleTransitionButton({
    super.key,
    required this.animation,
    required this.alignment,
    this.child,
  });

  final Animation<double> animation;
  final Widget? child;
  final Alignment alignment;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: const Interval(0.0, 0.7),
  );
  static final Animatable<double> _scaleInTransition = Tween<double>(
    begin: 0.30,
    end: 1.00,
  );
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0,
  );
  static final Animatable<double> _scaleOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleInTransition.animate(animation),
            alignment: alignment,
            child: child,
          ),
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleOutTransition.animate(animation),
            alignment: alignment,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 250,
    ),
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  FadeIndexedStackState createState() => FadeIndexedStackState();
}

class FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: LazyIndexedStack(
        index: widget.index,
        alignment: widget.alignment,
        textDirection: widget.textDirection,
        sizing: widget.sizing,
        children: widget.children,
      ),
    );
  }
}
