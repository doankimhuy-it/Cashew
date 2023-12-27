import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/subscriptions_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/initialize_notifications.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/upcoming_transactions_functions.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/dropdown_select.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fade_in.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/no_results.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/selected_transactions_app_bar.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/settings_containers.dart';
import 'package:budget/widgets/sliding_selector_income_expense.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/transaction_entry/transaction_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/count_number.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/transaction_entry/income_amount_arrow.dart';

class UpcomingOverdueTransactions extends StatefulWidget {
  const UpcomingOverdueTransactions(
      {required this.overdueTransactions, super.key});
  final bool? overdueTransactions;

  @override
  State<UpcomingOverdueTransactions> createState() =>
      _UpcomingOverdueTransactionsState();
}

class _UpcomingOverdueTransactionsState
    extends State<UpcomingOverdueTransactions> {
  late bool? overdueTransactions = widget.overdueTransactions;
  String? searchValue;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    String pageId = "OverdueUpcoming";
    return WillPopScope(
      onWillPop: () async {
        if ((globalSelectedID.value[pageId] ?? []).isNotEmpty) {
          globalSelectedID.value[pageId] = [];
          globalSelectedID.notifyListeners();
          return false;
        } else {
          return true;
        }
      },
      child: Stack(
        children: [
          PageFramework(
            resizeToAvoidBottomInset: true,
            floatingActionButton: AnimateFABDelayed(
              enabled: overdueTransactions == null,
              fab: AnimateFABDelayed(
                fab: FAB(
                  tooltip: "add-upcoming".tr(),
                  openPage: const AddTransactionPage(
                    selectedType: TransactionSpecialType.upcoming,
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                  ),
                ),
              ),
            ),
            listID: pageId,
            title: "scheduled".tr(),
            dragDownToDismiss: true,
            actions: [
              CustomPopupMenuButton(
                showButtons: enableDoubleColumn(context),
                keepOutFirst: true,
                items: [
                  DropdownItemMenu(
                    id: "settings",
                    label: "settings".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.settings_outlined
                        : Icons.settings_rounded,
                    action: () {
                      openBottomSheet(
                          context,
                          const PopupFramework(
                            hasPadding: false,
                            child: UpcomingOverdueSettings(),
                          ));
                    },
                  ),
                ],
              ),
            ],
            slivers: [
              SliverToBoxAdapter(
                  child: CenteredAmountAndNumTransactions(
                totalWithCountStream:
                    database.watchTotalWithCountOfUpcomingOverdue(
                  allWallets: Provider.of<AllWallets>(context),
                  isOverdueTransactions: overdueTransactions,
                  searchString: searchValue,
                ),
                textColor: overdueTransactions == null
                    ? getColor(context, "black")
                    : overdueTransactions == true
                        ? getColor(context, "unPaidOverdue")
                        : getColor(context, "unPaidUpcoming"),
              )),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getHorizontalPaddingConstrained(context)),
                  child: Row(
                    children: [
                      const SizedBox(width: 13),
                      Flexible(
                        child: AnimatedSize(
                          clipBehavior: Clip.none,
                          duration: const Duration(milliseconds: 500),
                          child: SlidingSelectorIncomeExpense(
                            useHorizontalPaddingConstrained: false,
                            initialIndex: overdueTransactions == null
                                ? 0
                                : overdueTransactions == false
                                    ? 1
                                    : 2,
                            onSelected: (int index) {
                              if (index == 1) {
                                overdueTransactions = null;
                              } else if (index == 2)
                                overdueTransactions = false;
                              else if (index == 3) overdueTransactions = true;
                              setState(() {});
                            },
                            options: const ["all", "upcoming", "overdue"],
                            customPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      AnimatedSizeSwitcher(
                        child: searchValue == null
                            ? Padding(
                                padding: const EdgeInsets.only(left: 7.0),
                                child: ButtonIcon(
                                  key: const ValueKey(1),
                                  onTap: () {
                                    setState(() {
                                      searchValue = "";
                                    });
                                    _searchFocusNode.requestFocus();
                                  },
                                  icon: appStateSettings["outlinedIcons"]
                                      ? Icons.search_outlined
                                      : Icons.search_rounded,
                                ),
                              )
                            : Container(
                                key: const ValueKey(2),
                              ),
                      ),
                      const SizedBox(width: 13),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getHorizontalPaddingConstrained(context)),
                  child: AnimatedExpanded(
                    expand: searchValue != null,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, top: 8),
                      child: TextInput(
                        labelText: "search-transactions-placeholder".tr(),
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.search_outlined
                            : Icons.search_rounded,
                        focusNode: _searchFocusNode,
                        onSubmitted: (value) {
                          setState(() {
                            searchValue = value == "" ? null : value;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            searchValue = value == "" ? null : value;
                          });
                        },
                        autoFocus: false,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 15),
              ),
              StreamBuilder<List<Transaction>>(
                stream: database.watchAllOverdueUpcomingTransactions(
                    overdueTransactions,
                    searchString: searchValue),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child:
                              NoResults(message: "no-transactions-found".tr()),
                        ),
                      );
                    }
                    return SliverImplicitlyAnimatedList<Transaction>(
                      items: snapshot.data!,
                      areItemsTheSame: (a, b) =>
                          a.transactionPk == b.transactionPk,
                      insertDuration: const Duration(milliseconds: 500),
                      removeDuration: const Duration(milliseconds: 500),
                      updateDuration: const Duration(milliseconds: 500),
                      itemBuilder: (BuildContext context,
                          Animation<double> animation,
                          Transaction item,
                          int index) {
                        return SizeFadeTransition(
                          sizeFraction: 0.7,
                          curve: Curves.easeInOut,
                          animation: animation,
                          child: Column(
                            key: ValueKey(item.transactionPk),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UpcomingTransactionDateHeader(transaction: item),
                              TransactionEntry(
                                openPage: AddTransactionPage(
                                  transaction: item,
                                  routesToPopAfterDelete:
                                      RoutesToPopAfterDelete.One,
                                ),
                                transaction: item,
                                listID: pageId,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const SliverToBoxAdapter();
                  }
                },
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 75),
              ),
            ],
          ),
          SelectedTransactionsAppBar(
            pageID: pageId,
          ),
        ],
      ),
    );
  }
}

class CenteredAmountAndNumTransactions extends StatelessWidget {
  const CenteredAmountAndNumTransactions({
    required this.totalWithCountStream,
    required this.textColor,
    this.getTextColor,
    this.getInitialText,
    this.showIncomeArrow = true,
    super.key,
  });

  final Stream<TotalWithCount?> totalWithCountStream;
  final Color textColor;
  final String? Function(double totalAmount)? getInitialText;
  final Color? Function(double totalAmount)? getTextColor;
  final bool showIncomeArrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        StreamBuilder<TotalWithCount?>(
          stream: totalWithCountStream,
          builder: (context, snapshot) {
            double totalSpent = snapshot.data?.total ?? 0;
            int totalCount = snapshot.data?.count ?? 0;
            return Column(
              children: [
                AnimatedSizeSwitcher(
                  child: getInitialText != null &&
                          getInitialText!(totalSpent) != null
                      ? TextFont(
                          key: ValueKey(getInitialText!(totalSpent) ?? ""),
                          text: getInitialText!(totalSpent) ?? "",
                          fontSize: 16,
                          textColor: getColor(context, "textLight"),
                        )
                      : Container(
                          key: const ValueKey(2),
                        ),
                ),
                Tappable(
                  color: Colors.transparent,
                  borderRadius: 15,
                  onLongPress: () {
                    copyToClipboard(
                      convertToMoney(
                        Provider.of<AllWallets>(context, listen: false),
                        totalSpent.abs(),
                        finalNumber: totalSpent,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        showIncomeArrow
                            ? AnimatedSizeSwitcher(
                                child: totalSpent == 0
                                    ? Container(
                                        key: const ValueKey(1),
                                      )
                                    : IncomeOutcomeArrow(
                                        key: const ValueKey(2),
                                        color: textColor,
                                        isIncome: totalSpent > 0,
                                        iconSize: 30,
                                        width: 20,
                                      ),
                              )
                            : const SizedBox.shrink(),
                        CountNumber(
                          count: totalSpent.abs(),
                          duration: const Duration(milliseconds: 450),
                          initialCount: (0),
                          textBuilder: (number) {
                            return TextFont(
                              text: convertToMoney(
                                  Provider.of<AllWallets>(context), number,
                                  finalNumber: totalSpent.abs()),
                              fontSize: 30,
                              textColor: getTextColor != null
                                  ? (getTextColor!(totalSpent) ?? textColor)
                                  : textColor,
                              fontWeight: FontWeight.bold,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                TextFont(
                  text: "$totalCount ${totalCount == 1
                          ? "transaction".tr().toLowerCase()
                          : "transactions".tr().toLowerCase()}",
                  fontSize: 16,
                  textColor: getColor(context, "textLight"),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class AutoPayUpcomingSetting extends StatelessWidget {
  const AutoPayUpcomingSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "pay-upcoming".tr(),
      description: "pay-upcoming-description".tr(),
      onSwitched: (value) async {
        // Need to change setting first, otherwise the function would not run!
        await updateSettings("automaticallyPayUpcoming", value,
            updateGlobalState: false);
        await markUpcomingAsPaid();
        await setUpcomingNotifications(context);
      },
      initialValue: appStateSettings["automaticallyPayUpcoming"],
      icon: getTransactionTypeIcon(TransactionSpecialType.upcoming),
    );
  }
}

class AutoPayRepetitiveSetting extends StatelessWidget {
  const AutoPayRepetitiveSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "pay-repetitive".tr(),
      description: "pay-repetitive-description".tr(),
      onSwitched: (value) async {
        // Need to change setting first, otherwise the function would not run!
        await updateSettings("automaticallyPayRepetitive", value,
            updateGlobalState: false);
        // Repetitive and subscriptions are handled by the same function
        await markSubscriptionsAsPaid(context);
        await setUpcomingNotifications(context);
      },
      initialValue: appStateSettings["automaticallyPayRepetitive"],
      icon: getTransactionTypeIcon(TransactionSpecialType.repetitive),
    );
  }
}

class MarkAsPaidOnDaySetting extends StatelessWidget {
  const MarkAsPaidOnDaySetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "paid-date".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.event_available_outlined
          : Icons.event_available_rounded,
      initial: appStateSettings["markAsPaidOnOriginalDay"].toString(),
      items: const ["false", "true"],
      onChanged: (value) async {
        updateSettings(
            "markAsPaidOnOriginalDay", value == "true" ? true : false,
            updateGlobalState: false);
      },
      getLabel: (item) {
        if (item == "false") return "current-date".tr().capitalizeFirst;
        if (item == "true") return "transaction-date".tr().capitalizeFirst;
      },
    );
  }
}

class UpcomingOverdueSettings extends StatelessWidget {
  const UpcomingOverdueSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AutoPayUpcomingSetting(),
        AutoPayRepetitiveSetting(),
        AutoPaySubscriptionsSetting(),
        AutoPaySettingDescription(),
      ],
    );
  }
}

class AutoPaySettingDescription extends StatelessWidget {
  const AutoPaySettingDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 13, bottom: 3, left: 25, right: 25),
      child: TextFont(
        text: "auto-pay-description".tr(),
        fontSize: 14,
        textColor: getColor(context, "textLight"),
        textAlign: TextAlign.center,
        maxLines: 5,
      ),
    );
  }
}
