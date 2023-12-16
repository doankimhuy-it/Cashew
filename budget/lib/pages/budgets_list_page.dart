import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_budget_page.dart';
import 'package:budget/pages/add_category_page.dart';
import 'package:budget/pages/edit_budget_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/budget_container.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/no_results.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/util/widget_size.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart'
    hide SliverReorderableList, ReorderableDelayedDragStartListener;

class BudgetsListPage extends StatefulWidget {
  const BudgetsListPage({required this.enableBackButton, Key? key})
      : super(key: key);
  final bool enableBackButton;

  @override
  State<BudgetsListPage> createState() => BudgetsListPageState();
}

class BudgetsListPageState extends State<BudgetsListPage>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<PageFrameworkState> pageState = GlobalKey();

  void refreshState() {
    setState(() {});
  }

  void scrollToTop() {
    pageState.currentState!.scrollToTop();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      key: pageState,
      title: "budgets".tr(),
      backButton: widget.enableBackButton,
      dragDownToDismiss: widget.enableBackButton,
      horizontalPadding: enableDoubleColumn(context) == false
          ? getHorizontalPaddingConstrained(context)
          : 0,
      actions: [
        IconButton(
          padding: EdgeInsets.all(15),
          tooltip: "edit-budgets".tr(),
          onPressed: () {
            pushRoute(
              context,
              EditBudgetPage(),
            );
          },
          icon: Icon(
            appStateSettings["outlinedIcons"]
                ? Icons.edit_outlined
                : Icons.edit_rounded,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        if (getIsFullScreen(context))
          IconButton(
            padding: EdgeInsets.all(15),
            tooltip: "add-budget".tr(),
            onPressed: () {
              pushRoute(
                context,
                AddBudgetPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None),
              );
            },
            icon: Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.add_outlined
                  : Icons.add_rounded,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
      ],
      slivers: [
        StreamBuilder<List<Budget>>(
          stream: database.watchAllBudgets(hideArchived: true),
          builder: (context, snapshot) {
            if (snapshot.hasData && (snapshot.data ?? []).length <= 0) {
              return SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 13),
                sliver: SliverToBoxAdapter(
                  child: AddButton(
                    onTap: () {},
                    openPage: AddBudgetPage(
                      routesToPopAfterDelete:
                          RoutesToPopAfterDelete.PreventDelete,
                    ),
                    height: 180,
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              return SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 13),
                sliver: enableDoubleColumn(context)
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 600.0,
                          mainAxisExtent: 190,
                          mainAxisSpacing: 15.0,
                          crossAxisSpacing: 15.0,
                          childAspectRatio: 5,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            if (index == snapshot.data?.length) {
                              return AddButton(
                                onTap: () {},
                                openPage: AddBudgetPage(
                                  routesToPopAfterDelete:
                                      RoutesToPopAfterDelete.PreventDelete,
                                ),
                              );
                            } else {
                              return BudgetContainer(
                                budget: snapshot.data![index],
                              );
                            }
                          },
                          childCount: (snapshot.data?.length ?? 0) + 1,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            if (index == snapshot.data?.length) {
                              return AddButton(
                                onTap: () {},
                                openPage: AddBudgetPage(
                                  routesToPopAfterDelete:
                                      RoutesToPopAfterDelete.PreventDelete,
                                ),
                                height: 180,
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: BudgetContainer(
                                  budget: snapshot.data![index],
                                  squishInactiveBudgetContainerHeight: true,
                                ),
                              );
                            }
                          },
                          childCount: (snapshot.data?.length ?? 0) +
                              1, //snapshot.data?.length
                        ),
                      ),
              );
            } else {
              return SliverToBoxAdapter();
            }
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 50),
        ),
      ],
    );
  }
}
