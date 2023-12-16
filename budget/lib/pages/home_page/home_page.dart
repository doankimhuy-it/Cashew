import 'package:budget/colors.dart';
import 'package:budget/database/generate_preview_data.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/home_page/home_page_heatmap.dart';
import 'package:budget/pages/home_page/home_page_line_graph.dart';
import 'package:budget/pages/home_page/home_page_net_worth.dart';
import 'package:budget/pages/home_page/home_page_objectives.dart';
import 'package:budget/pages/home_page/home_page_pie_chart.dart';
import 'package:budget/pages/home_page/home_page_wallet_list.dart';
import 'package:budget/pages/home_page/home_page_wallet_switcher.dart';
import 'package:budget/pages/home_page/home_transactions.dart';
import 'package:budget/pages/home_page/home_page_username.dart';
import 'package:budget/pages/home_page/home_page_budgets.dart';
import 'package:budget/pages/home_page/home_page_upcoming_transactions.dart';
import 'package:budget/pages/home_page/home_page_all_spending_summary.dart';
import 'package:budget/pages/edit_home_page.dart';
import 'package:budget/pages/settings_page.dart';
import 'package:budget/pages/home_page/home_page_credit_debts.dart';
import 'package:budget/struct/currency_functions.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/share_budget.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/line_graph.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/selected_transactions_app_bar.dart';
import 'package:budget/widgets/util/keep_alive_client_mixin.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/transaction_entries.dart';
import 'package:budget/widgets/transaction_entry/swipe_to_select_transactions.dart';
import 'package:budget/widgets/transaction_entry/transaction_entry_amount.dart';
import 'package:budget/widgets/view_all_transactions_button.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/scrollbar_wrap.dart';
import 'package:budget/widgets/sliding_selector_income_expense.dart';
import 'package:provider/provider.dart';

import '../../widgets/linear_gradient_faded_edges.dart';
import '../../widgets/pull_down_to_refresh_sync.dart';
import '../../widgets/util/right_side_clipper.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  void refreshState() {
    setState(() {});
  }

  void scrollToTop({int duration = 1200}) {
    _scrollController.animateTo(0,
        duration: Duration(
            milliseconds:
                (getPlatform() == PlatformOS.isIOS ? duration * 0.2 : duration)
                    .round()),
        curve: getPlatform() == PlatformOS.isIOS
            ? Curves.easeInOut
            : Curves.elasticOut);
  }

  @override
  bool get wantKeepAlive => true;
  bool showElevation = false;
  late ScrollController _scrollController;
  late AnimationController _animationControllerHeader;
  late AnimationController _animationControllerHeader2;
  int selectedSlidingSelector = 1;

  void initState() {
    super.initState();
    _animationControllerHeader = AnimationController(vsync: this, value: 1);
    _animationControllerHeader2 = AnimationController(vsync: this, value: 1);

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    double percent = _scrollController.offset / (200);
    if (percent <= 1) {
      double offset = _scrollController.offset;
      if (percent >= 1) offset = 0;
      _animationControllerHeader.value = 1 - offset / (200);
      _animationControllerHeader2.value = 1 - offset * 2 / (200);
    }
  }

  @override
  void dispose() {
    _animationControllerHeader.dispose();
    _animationControllerHeader2.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool areAllDisabledAfterTransactionsList(
      Map<String, Widget?> homePageSections) {
    int countAfter = -1;
    for (String sectionKey in appStateSettings["homePageOrder"]) {
      if (sectionKey == "transactionsList" &&
          homePageSections[sectionKey] != null) {
        countAfter = 0;
      } else if (countAfter == 0 && homePageSections[sectionKey] != null) {
        countAfter++;
      }
    }
    return countAfter == 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool showUsername = appStateSettings["username"] != "";
    Widget slidingSelector = SlidingSelectorIncomeExpense(
        useHorizontalPaddingConstrained: false,
        onSelected: (index) {
          setState(() {
            selectedSlidingSelector = index;
          });
        });
    Widget? homePageTransactionsList =
        isHomeScreenSectionEnabled(context, "showTransactionsList") == true
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  slidingSelector,
                  SizedBox(height: 8),
                  HomeTransactions(
                      selectedSlidingSelector: selectedSlidingSelector),
                  SizedBox(height: 7),
                  Center(
                    child: ViewAllTransactionsButton(),
                  ),
                  if (enableDoubleColumn(context)) SizedBox(height: 35),
                ],
              )
            : null;
    if (homePageTransactionsList != null)
      homePageTransactionsList = enableDoubleColumn(context)
          ? KeepAliveClientMixin(
              child: homePageTransactionsList,
            )
          : KeepAliveClientMixin(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: homePageTransactionsList,
              ),
            );

    Map<String, Widget?> homePageSections = {
      "wallets": isHomeScreenSectionEnabled(context, "showWalletSwitcher")
          ? HomePageWalletSwitcher()
          : null,
      "walletsList": isHomeScreenSectionEnabled(context, "showWalletList")
          ? HomePageWalletList()
          : null,
      "budgets": isHomeScreenSectionEnabled(context, "showPinnedBudgets")
          ? HomePageBudgets()
          : null,
      "overdueUpcoming":
          isHomeScreenSectionEnabled(context, "showOverdueUpcoming")
              ? HomePageUpcomingTransactions()
              : null,
      "allSpendingSummary":
          isHomeScreenSectionEnabled(context, "showAllSpendingSummary")
              ? HomePageAllSpendingSummary()
              : null,
      "netWorth": isHomeScreenSectionEnabled(context, "showNetWorth")
          ? HomePageNetWorth()
          : null,
      "objectives": isHomeScreenSectionEnabled(context, "showObjectives")
          ? HomePageObjectives(objectiveType: ObjectiveType.goal)
          : null,
      "creditDebts": isHomeScreenSectionEnabled(context, "showCreditDebt")
          ? HomePageCreditDebts()
          : null,
      "objectiveLoans":
          isHomeScreenSectionEnabled(context, "showObjectiveLoans")
              ? HomePageObjectives(objectiveType: ObjectiveType.loan)
              : null,
      "spendingGraph": isHomeScreenSectionEnabled(context, "showSpendingGraph")
          ? HomePageLineGraph(selectedSlidingSelector: selectedSlidingSelector)
          : null,
      "pieChart": isHomeScreenSectionEnabled(context, "showPieChart")
          ? HomePagePieChart(selectedSlidingSelector: selectedSlidingSelector)
          : null,
      "heatMap": isHomeScreenSectionEnabled(context, "showHeatMap")
          ? HomePageHeatMap()
          : null,
      "transactionsList": homePageTransactionsList ?? SizedBox.shrink(),
    };
    bool showWelcomeBanner =
        isHomeScreenSectionEnabled(context, "showUsernameWelcomeBanner");
    bool useSmallBanner = showWelcomeBanner == false;

    List<String> homePageSectionsFullScreenCenter = [];
    List<String> homePageSectionsFullScreenLeft = [];
    List<String> homePageSectionsFullScreenRight = [];

    String section = "";

    for (String item
        in appStateSettings[getHomePageOrderSettingsKey(context)]) {
      if (item == "ORDER:LEFT") {
        section = item;
      } else if (item == "ORDER:RIGHT") {
        section = item;
      } else if (section == "ORDER:LEFT") {
        homePageSectionsFullScreenLeft.add(item);
      } else if (section == "ORDER:RIGHT") {
        homePageSectionsFullScreenRight.add(item);
      } else {
        homePageSectionsFullScreenCenter.add(item);
      }
    }

    return SwipeToSelectTransactions(
      listID: "0",
      child: PullDownToRefreshSync(
        scrollController: _scrollController,
        child: Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset: false,
              body: ScrollbarWrap(
                child: ListView(
                  controller: _scrollController,
                  children: [
                    PreviewDemoWarning(),
                    if (useSmallBanner) SizedBox(height: 13),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        useSmallBanner
                            ? HomePageWelcomeBannerSmall(
                                showUsername: showUsername,
                              )
                            : SizedBox.shrink(),
                        Tooltip(
                          message: "edit-home".tr(),
                          child: IconButton(
                            padding: EdgeInsets.all(15),
                            onPressed: () {
                              pushRoute(context, EditHomePage());
                            },
                            icon: Icon(appStateSettings["outlinedIcons"]
                                ? Icons.more_vert_outlined
                                : Icons.more_vert_rounded),
                          ),
                        ),
                      ],
                    ),
                    // Wipe all remaining pixels off - sometimes graphics artifacts are left behind
                    Container(height: 1, color: Theme.of(context).canvasColor),

                    showWelcomeBanner
                        ? ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: getExpandedHeaderHeight(
                                        context, null,
                                        isHomePageSpace: true) /
                                    1.34),
                            child: Container(
                              // Subtract one (1) here because of the thickness of the wiper above
                              alignment: Alignment.bottomLeft,
                              padding: EdgeInsets.only(
                                  left: 9,
                                  bottom: enableDoubleColumn(context) ? 10 : 17,
                                  right: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  HomePageUsername(
                                    animationControllerHeader:
                                        _animationControllerHeader,
                                    animationControllerHeader2:
                                        _animationControllerHeader2,
                                    showUsername: showUsername,
                                    appStateSettings: appStateSettings,
                                    enterNameBottomSheet: enterNameBottomSheet,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(height: 5),
                    // Not full screen
                    if (enableDoubleColumn(context) != true) ...[
                      for (String sectionKey
                          in appStateSettings["homePageOrder"])
                        homePageSections[sectionKey] ?? SizedBox.shrink()
                    ],
                    // Full screen top section
                    if (enableDoubleColumn(context) == true) ...[
                      for (String sectionKey
                          in appStateSettings["homePageOrderFullScreen"])
                        if (homePageSectionsFullScreenCenter
                            .contains(sectionKey))
                          homePageSections[sectionKey] ?? SizedBox.shrink()
                    ],
                    // Full screen bottom split section
                    if (enableDoubleColumn(context) == true)
                      LayoutBuilder(builder: (context, constraints) {
                        print(constraints);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Column(
                                children: [
                                  for (String sectionKey in appStateSettings[
                                      "homePageOrderFullScreen"])
                                    if (homePageSectionsFullScreenLeft
                                        .contains(sectionKey))
                                      LinearGradientFadedEdges(
                                        enableLeft: false,
                                        enableBottom: false,
                                        enableTop: false,
                                        child: ClipRRect(
                                          clipper: RightSideClipper(),
                                          child: homePageSections[sectionKey] ??
                                              SizedBox.shrink(),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                children: [
                                  for (String sectionKey in appStateSettings[
                                      "homePageOrderFullScreen"])
                                    if (homePageSectionsFullScreenRight
                                        .contains(sectionKey))
                                      LinearGradientFadedEdges(
                                        enableRight: false,
                                        enableBottom: false,
                                        enableTop: false,
                                        child: ClipRRect(
                                          clipper: RightSideClipper(),
                                          child: homePageSections[sectionKey] ??
                                              SizedBox.shrink(),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    SizedBox(
                      height: enableDoubleColumn(context) == true
                          ? 40
                          : areAllDisabledAfterTransactionsList(
                                  homePageSections)
                              ? 25
                              : 73,
                    ),
                    // Wipe all remaining pixels off - sometimes graphics artifacts are left behind
                    Container(height: 1, color: Theme.of(context).canvasColor),
                  ],
                ),
              ),
            ),
            SelectedTransactionsAppBar(
              pageID: "0",
            ),
          ],
        ),
      ),
    );
  }
}
