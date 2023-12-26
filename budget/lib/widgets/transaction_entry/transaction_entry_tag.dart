import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/objectives_list_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/category_icon.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/util/infinite_rotation_animation.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';
import 'package:provider/provider.dart';

class TransactionEntryTag extends StatelessWidget {
  const TransactionEntryTag({
    required this.transaction,
    this.showObjectivePercentage = true,
    this.subCategory,
    this.budget,
    this.objective,
    super.key,
  });
  final Transaction transaction;
  final bool showObjectivePercentage;
  final TransactionCategory? subCategory;
  final Budget? budget;
  final Objective? objective;

  @override
  Widget build(BuildContext context) {
    bool showObjectivePercentageCheck = showObjectivePercentage;
    if (transaction.sharedReferenceBudgetPk != null ||
        transaction.subCategoryFk != null) showObjectivePercentageCheck = false;
    return Padding(
      padding: const EdgeInsets.only(top: 1.0),
      child: Row(
        children: [
          if (appStateSettings["showAccountLabelTagInTransactionEntry"] == true)
            Flexible(
              child: TransactionTag(
                color: HexColor(
                    Provider.of<AllWallets>(context)
                        .indexedByPk[transaction.walletFk]
                        ?.colour,
                    defaultColor: Theme.of(context).colorScheme.primary),
                name: Provider.of<AllWallets>(context)
                        .indexedByPk[transaction.walletFk]
                        ?.name ??
                    "",
              ),
            ),
          if (transaction.subCategoryFk != null)
            Flexible(
              child: Builder(builder: (context) {
                if (subCategory != null) {
                  return SubCategoryTag(category: subCategory!);
                } else {
                  return StreamBuilder<TransactionCategory?>(
                    stream: database.getCategory(transaction.subCategoryFk!).$1,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        TransactionCategory? category = snapshot.data!;
                        return SubCategoryTag(category: category);
                      }
                      return SizedBox.shrink();
                    },
                  );
                }
              }),
            ),
          if (transaction.sharedReferenceBudgetPk != null)
            Flexible(
              child: Builder(builder: (context) {
                if (budget != null) {
                  return TransactionTag(
                    color: HexColor(budget?.colour,
                        defaultColor: Theme.of(context).colorScheme.primary),
                    name: budget?.name ?? "",
                  );
                } else {
                  return StreamBuilder<Budget>(
                    stream: database
                        .getBudget(transaction.sharedReferenceBudgetPk!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Budget budget = snapshot.data!;
                        return TransactionTag(
                          color: HexColor(budget.colour,
                              defaultColor:
                                  Theme.of(context).colorScheme.primary),
                          name: budget.name,
                        );
                      }
                      return Container();
                    },
                  );
                }
              }),
            ),
          if (transaction.objectiveLoanFk != null)
            Flexible(
              child: Builder(builder: (context) {
                if (objective != null) {
                  return ObjectivePercentTag(
                    transaction: transaction,
                    objective: objective!,
                    showObjectivePercentageCheck: showObjectivePercentageCheck,
                  );
                }
                return StreamBuilder<Objective>(
                  stream: database.getObjective(transaction.objectiveLoanFk!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Objective objective = snapshot.data!;
                      return ObjectivePercentTag(
                        transaction: transaction,
                        objective: objective,
                        showObjectivePercentageCheck:
                            showObjectivePercentageCheck,
                      );
                    }
                    return Container();
                  },
                );
              }),
            ),
          if (transaction.objectiveFk != null)
            Flexible(
              child: Builder(builder: (context) {
                if (objective != null) {
                  return ObjectivePercentTag(
                    transaction: transaction,
                    objective: objective!,
                    showObjectivePercentageCheck: showObjectivePercentageCheck,
                  );
                }
                return StreamBuilder<Objective>(
                  stream: database.getObjective(transaction.objectiveFk!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Objective objective = snapshot.data!;
                      return ObjectivePercentTag(
                        transaction: transaction,
                        objective: objective,
                        showObjectivePercentageCheck:
                            showObjectivePercentageCheck,
                      );
                    }
                    return Container();
                  },
                );
              }),
            ),
        ],
      ),
    );
  }
}

class SubCategoryTag extends StatelessWidget {
  const SubCategoryTag({required this.category, super.key});
  final TransactionCategory category;

  @override
  Widget build(BuildContext context) {
    return TransactionTag(
      color: HexColor(category.colour,
          defaultColor: Theme.of(context).colorScheme.primary),
      name: (category.emojiIconName != null
              ? ((category.emojiIconName ?? "") + " ")
              : "") +
          category.name,
      leading: category.emojiIconName != null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 3),
              child: CategoryIcon(
                categoryPk: "-1",
                category: category,
                size: 14,
                sizePadding: 1,
                noBackground: true,
                canEditByLongPress: false,
                margin: EdgeInsets.zero,
              ),
            ),
    );
  }
}

class ObjectivePercentTag extends StatelessWidget {
  const ObjectivePercentTag(
      {required this.transaction,
      required this.objective,
      required this.showObjectivePercentageCheck,
      super.key});
  final Transaction transaction;
  final Objective objective;
  final bool showObjectivePercentageCheck;
  @override
  Widget build(BuildContext context) {
    return WatchTotalAndAmountOfObjective(
      objective: objective,
      builder: (objectiveAmount, totalAmount, percentageTowardsGoal) {
        return Row(
          children: [
            Flexible(
              child: TransactionTag(
                color: HexColor(objective.colour,
                    defaultColor: Theme.of(context).colorScheme.primary),
                name: objective.name +
                    ": " +
                    convertToPercent(percentageTowardsGoal * 100,
                        numberDecimals: 0),
                progress: percentageTowardsGoal,
              ),
            ),
          ],
        );
      },
    );
  }
}

class TransactionTag extends StatelessWidget {
  final Color color;
  final String name;
  final Widget? leading;
  final double? progress;

  TransactionTag({
    required this.color,
    required this.name,
    this.leading,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    Widget tagWidget = Container(
      decoration: BoxDecoration(
        color: color.withOpacity(progress != null ? 0.15 : 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.05),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? SizedBox.shrink(),
          Flexible(
            child: TextFont(
              text: name,
              fontSize: 11.5,
              textColor: getColor(context, "black").withOpacity(0.7),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
    if (progress != null)
      return Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Stack(
          children: [
            tagWidget,
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress?.clamp(0, 1),
                    heightFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    return Padding(padding: EdgeInsets.only(left: 3), child: tagWidget);
  }
}

class SharedBudgetLabel extends StatelessWidget {
  const SharedBudgetLabel({required this.transaction, super.key});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1.0),
      child: Row(
        children: [
          transaction.sharedStatus == SharedStatus.waiting
              ? Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: InfiniteRotationAnimation(
                    duration: Duration(milliseconds: 5000),
                    child: Icon(
                      transaction.sharedStatus == SharedStatus.waiting
                          ? appStateSettings["outlinedIcons"]
                              ? Icons.sync_outlined
                              : Icons.sync_rounded
                          : transaction.transactionOwnerEmail !=
                                  appStateSettings["currentUserEmail"]
                              ? appStateSettings["outlinedIcons"]
                                  ? Icons.arrow_circle_down_outlined
                                  : Icons.arrow_circle_down_rounded
                              : appStateSettings["outlinedIcons"]
                                  ? Icons.arrow_circle_up_outlined
                                  : Icons.arrow_circle_up_rounded,
                      size: 14,
                      color: getColor(context, "black").withOpacity(0.7),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    transaction.transactionOwnerEmail !=
                            appStateSettings["currentUserEmail"]
                        ? appStateSettings["outlinedIcons"]
                            ? Icons.arrow_circle_down_outlined
                            : Icons.arrow_circle_down_rounded
                        : appStateSettings["outlinedIcons"]
                            ? Icons.arrow_circle_up_outlined
                            : Icons.arrow_circle_up_rounded,
                    size: 14,
                    color: getColor(context, "black").withOpacity(0.7),
                  ),
                ),
          SizedBox(width: 2),
          Expanded(
            child: Row(
              children: [
                transaction.sharedReferenceBudgetPk == null
                    ? SizedBox.shrink()
                    : Expanded(
                        child: StreamBuilder<Budget>(
                          stream: database
                              .getBudget(transaction.sharedReferenceBudgetPk!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return TextFont(
                                overflow: TextOverflow.ellipsis,
                                text: (transaction.transactionOwnerEmail
                                                .toString() ==
                                            appStateSettings["currentUserEmail"]
                                        ? getMemberNickname(appStateSettings[
                                            "currentUserEmail"])
                                        : transaction.sharedStatus ==
                                                    SharedStatus.waiting &&
                                                (transaction.transactionOwnerEmail ==
                                                        appStateSettings[
                                                            "currentUserEmail"] ||
                                                    transaction
                                                            .transactionOwnerEmail ==
                                                        null)
                                            ? getMemberNickname(
                                                appStateSettings[
                                                    "currentUserEmail"])
                                            : getMemberNickname(transaction
                                                .transactionOwnerEmail
                                                .toString())) +
                                    " for " +
                                    snapshot.data!.name,
                                fontSize: 12.5,
                                textColor:
                                    getColor(context, "black").withOpacity(0.7),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
