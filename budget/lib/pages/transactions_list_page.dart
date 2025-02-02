import 'package:budget/pages/transaction_filters.dart';
import 'package:budget/pages/upcoming_overdue_transactions_page.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/scrollbar_wrap.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/transactions_search_page.dart';
import 'package:budget/widgets/selected_transactions_app_bar.dart';
import 'package:budget/widgets/month_selector.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/settings_containers.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/transaction_entries.dart';
import 'package:budget/widgets/transaction_entry/swipe_to_select_transactions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:budget/widgets/util/sliver_pinned_overlap_injector.dart';
import 'package:budget/widgets/util/multi_directional_infinite_scroll.dart';
import 'package:budget/widgets/pull_down_to_refresh_sync.dart';

class TransactionsListPage extends StatefulWidget {
  const TransactionsListPage({super.key});

  @override
  State<TransactionsListPage> createState() => TransactionsListPageState();
}

class TransactionsListPageState extends State<TransactionsListPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  void refreshState() {
    setState(() {});
  }

  void scrollToTop({int duration = 1200}) {
    if (_scrollController.offset <= 0) {
      pushRoute(context, const TransactionsSearchPage());
    } else {
      _scrollController.animateTo(0,
          duration: Duration(
              milliseconds: (getPlatform() == PlatformOS.isIOS
                      ? duration * 0.2
                      : duration)
                  .round()),
          curve: getPlatform() == PlatformOS.isIOS
              ? Curves.easeInOut
              : Curves.elasticOut);
    }
  }

  @override
  bool get wantKeepAlive => true;

  bool showAppBarPaddingOffset = false;
  bool alreadyChanged = false;

  bool scaleInSearchIcon = false;

  late ScrollController _scrollController;
  late PageController _pageController;
  late List<int> selectedTransactionIDs = [];

  GlobalKey<MonthSelectorState> monthSelectorStateKey = GlobalKey();

  late SearchFilters searchFilters;

  onSelected(Transaction transaction, bool selected) {
    // print(transaction.transactionPk.toString() + " selected!");
    // print(globalSelectedID["Transactions"]);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController(initialPage: 1000000);

    searchFilters = SearchFilters();
    searchFilters.loadFilterString(
      appStateSettings["transactionsListPageSetFiltersString"],
      skipDateTimeRange: true,
      skipSearchQuery: true,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> selectFilters(BuildContext context) async {
    await openBottomSheet(
      context,
      PopupFramework(
        title: "filters".tr(),
        hasPadding: false,
        child: TransactionFiltersSelection(
          setSearchFilters: setSearchFilters,
          searchFilters: searchFilters,
          clearSearchFilters: clearSearchFilters,
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      updateSettings(
        "transactionsListPageSetFiltersString",
        searchFilters.getFilterString(),
        updateGlobalState: false,
      );
      setState(() {});
    });
  }

  void setSearchFilters(SearchFilters searchFilters) {
    this.searchFilters = searchFilters;
  }

  void clearSearchFilters() {
    searchFilters.clearSearchFilters();
    updateSettings("transactionsListPageSetFiltersString", null,
        updateGlobalState: false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cancelParentScroll,
      builder: (context, value, widget) {
        return PullDownToRefreshSync(
          scrollController: _scrollController,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  //Minimize keyboard when tap non interactive widget
                  FocusScopeNode currentFocus = FocusScope.of(context);
                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                },
                child: NestedScrollView(
                  controller: _scrollController,
                  physics: value ? const NeverScrollableScrollPhysics() : null,
                  headerSliverBuilder:
                      (BuildContext contextHeader, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                            contextHeader),
                        sliver: MultiSliver(
                          children: [
                            PageFrameworkSliverAppBar(
                              belowAppBarPaddingWhenCenteredTitleSmall: 0,
                              title: "transactions".tr(),
                              actions: [
                                IconButton(
                                  tooltip: "filters".tr(),
                                  onPressed: () {
                                    selectFilters(context);
                                  },
                                  padding: const EdgeInsets.all(15 - 8),
                                  icon: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    decoration: BoxDecoration(
                                      color: searchFilters.isClear()
                                          ? Colors.transparent
                                          : Theme.of(context)
                                              .colorScheme
                                              .tertiary
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      appStateSettings["outlinedIcons"]
                                          ? Icons.filter_alt_outlined
                                          : Icons.filter_alt_rounded,
                                      color: searchFilters.isClear()
                                          ? null
                                          : Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: const EdgeInsets.all(15),
                                  tooltip: "search-transactions".tr(),
                                  onPressed: () {
                                    pushRoute(
                                        context, const TransactionsSearchPage());
                                  },
                                  icon: Icon(
                                    appStateSettings["outlinedIcons"]
                                        ? Icons.search_outlined
                                        : Icons.search_rounded,
                                  ),
                                ),
                              ],
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: MonthSelector(
                                  key: monthSelectorStateKey,
                                  setSelectedDateStart:
                                      (DateTime currentDateTime, int index) {
                                    if (((_pageController.page ?? 0) -
                                                index -
                                                _pageController.initialPage)
                                            .abs() ==
                                        1) {
                                      _pageController.animateToPage(
                                        _pageController.initialPage + index,
                                        duration: const Duration(milliseconds: 1000),
                                        curve: Curves.easeInOutCubicEmphasized,
                                      );
                                    } else {
                                      _pageController.jumpToPage(
                                        _pageController.initialPage + index,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: AppliedFilterChips(
                                searchFilters: searchFilters,
                                openFiltersSelection: () {
                                  selectFilters(context);
                                },
                                clearSearchFilters: clearSearchFilters,
                                padding: const EdgeInsets.symmetric(vertical: 5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: Stack(
                    children: [
                      Builder(
                        builder: (contextPageView) {
                          return PageView.builder(
                            controller: _pageController,
                            onPageChanged: (int index) {
                              final int pageOffset =
                                  index - _pageController.initialPage;
                              DateTime startDate = DateTime(DateTime.now().year,
                                  DateTime.now().month + pageOffset);
                              monthSelectorStateKey.currentState
                                  ?.setSelectedDateStart(startDate, pageOffset);
                              double middle = -(MediaQuery.sizeOf(context)
                                              .width -
                                          getWidthNavigationSidebar(context)) /
                                      2 +
                                  100 / 2;
                              monthSelectorStateKey.currentState?.scrollTo(
                                  middle + (pageOffset - 1) * 100 + 100);
                              // transactionsListPageStateKey.currentState!
                              //     .scrollToTop();
                            },
                            itemBuilder: (BuildContext context, int index) {
                              final int pageOffset =
                                  index - _pageController.initialPage;
                              DateTime startDate = DateTime(DateTime.now().year,
                                  DateTime.now().month + pageOffset);

                              return SwipeToSelectTransactions(
                                listID: "Transactions",
                                child: ScrollbarWrap(
                                  child: CustomScrollView(
                                    slivers: [
                                      SliverPinnedOverlapInjector(
                                        handle: NestedScrollView
                                            .sliverOverlapAbsorberHandleFor(
                                                contextPageView),
                                      ),
                                      TransactionEntries(
                                        searchFilters: searchFilters,
                                        renderType: TransactionEntriesRenderType
                                            .implicitlyAnimatedSlivers,
                                        startDate,
                                        DateTime(
                                            startDate.year,
                                            startDate.month + 1,
                                            startDate.day - 1),
                                        onSelected: onSelected,
                                        listID: "Transactions",
                                        noResultsMessage: "${"no-transactions-for"
                                                .tr()} ${getMonth(startDate,
                                                includeYear: startDate.year !=
                                                    DateTime.now().year)}.",
                                        showTotalCashFlow: true,
                                        enableSpendingSummary: true,
                                        showSpendingSummary: appStateSettings[
                                            "showTransactionsMonthlySpendingSummary"],
                                        onLongPressSpendingSummary: () {
                                          openBottomSheet(
                                            context,
                                            PopupFramework(
                                              hasPadding: false,
                                              child: Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: TextFont(
                                                      text:
                                                          "enabled-in-settings-at-any-time"
                                                              .tr(),
                                                      fontSize: 14,
                                                      maxLines: 5,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  const ShowTransactionsMonthlySpendingSummarySettingToggle(),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Wipe all remaining pixels off - sometimes graphics artifacts are left behind
                                      const SliverToBoxAdapter(
                                        child: SizedBox(
                                          height: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      getIsFullScreen(context) == false
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  padding: const EdgeInsets.all(15),
                                  icon: Icon(
                                    appStateSettings["outlinedIcons"]
                                        ? Icons.arrow_left_outlined
                                        : Icons.arrow_left_rounded,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    _pageController.animateToPage(
                                      (_pageController.page ??
                                                  _pageController.initialPage)
                                              .round() -
                                          1,
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutCubicEmphasized,
                                    );
                                  },
                                ),
                              ),
                            ),
                      getIsFullScreen(context) == false
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  padding: const EdgeInsets.all(15),
                                  icon: Icon(
                                    appStateSettings["outlinedIcons"]
                                        ? Icons.arrow_right_outlined
                                        : Icons.arrow_right_rounded,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    _pageController.animateToPage(
                                      (_pageController.page ??
                                                  _pageController.initialPage)
                                              .round() +
                                          1,
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutCubicEmphasized,
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SelectedTransactionsAppBar(
                pageID: "Transactions",
              ),
            ],
          ),
        );
      },
    );
  }
}

class TransactionsSettings extends StatelessWidget {
  const TransactionsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MarkAsPaidOnDaySetting(),
        NetSpendingDayTotalSetting(),
        ShowTransactionsMonthlySpendingSummarySettingToggle(),
        ShowTransactionsBalanceTransferTabSettingToggle(),
      ],
    );
  }
}

class ShowTransactionsMonthlySpendingSummarySettingToggle
    extends StatelessWidget {
  const ShowTransactionsMonthlySpendingSummarySettingToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "monthly-spending-summary".tr(),
      description: "monthly-spending-summary-description".tr(),
      onSwitched: (value) {
        updateSettings("showTransactionsMonthlySpendingSummary", value,
            updateGlobalState: false, pagesNeedingRefresh: [1]);
      },
      initialValue: appStateSettings["showTransactionsMonthlySpendingSummary"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.balance_outlined
          : Icons.balance_rounded,
    );
  }
}

class ShowTransactionsBalanceTransferTabSettingToggle extends StatelessWidget {
  const ShowTransactionsBalanceTransferTabSettingToggle({super.key});

  @override
  Widget build(BuildContext context) {
    if (Provider.of<AllWallets>(context).indexedByPk.keys.length <= 1) {
      return const SizedBox.shrink();
    }
    return SettingsContainerSwitch(
      title: "show-balance-transfer-tab".tr(),
      description: "show-balance-transfer-tab-description".tr(),
      onSwitched: (value) {
        updateSettings("showTransactionsBalanceTransferTab", value,
            updateGlobalState: false);
      },
      initialValue: appStateSettings["showTransactionsBalanceTransferTab"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.compare_arrows_outlined
          : Icons.compare_arrows_rounded,
    );
  }
}

class NetSpendingDayTotalSetting extends StatelessWidget {
  const NetSpendingDayTotalSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "date-banner-total".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.playlist_add_outlined
          : Icons.playlist_add_rounded,
      initial: appStateSettings["netSpendingDayTotal"].toString(),
      items: const ["false", "true"],
      onChanged: (value) async {
        updateSettings("netSpendingDayTotal", value == "true" ? true : false,
            updateGlobalState: true, pagesNeedingRefresh: [1]);
      },
      getLabel: (item) {
        if (item == "false") return "day-total".tr().capitalizeFirst;
        if (item == "true") return "net-total".tr().capitalizeFirst;
      },
    );
  }
}
