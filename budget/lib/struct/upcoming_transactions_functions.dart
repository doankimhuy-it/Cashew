import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/struct/initialize_notifications.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/select_amount.dart';
import 'package:budget/widgets/transaction_entry/transaction_label.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:provider/provider.dart';

Future createNewSubscriptionTransaction(
    BuildContext context, Transaction transaction) async {
  if (transaction.createdAnotherFutureTransaction == false) {
    if (transaction.type == TransactionSpecialType.subscription ||
        transaction.type == TransactionSpecialType.repetitive) {
      int yearOffset = 0;
      int monthOffset = 0;
      int dayOffset = 0;
      if (transaction.reoccurrence == BudgetReoccurence.yearly) {
        yearOffset = transaction.periodLength ?? 0;
      } else if (transaction.reoccurrence == BudgetReoccurence.monthly) {
        monthOffset = transaction.periodLength ?? 0;
      } else if (transaction.reoccurrence == BudgetReoccurence.weekly) {
        dayOffset = (transaction.periodLength ?? 0) * 7;
      } else if (transaction.reoccurrence == BudgetReoccurence.daily) {
        dayOffset = transaction.periodLength ?? 0;
      }
      DateTime newDate = DateTime(
        transaction.dateCreated.year + yearOffset,
        transaction.dateCreated.month + monthOffset,
        transaction.dateCreated.day + dayOffset,
        transaction.dateCreated.hour,
        transaction.dateCreated.minute,
        transaction.dateCreated.second,
        transaction.dateCreated.millisecond,
      );

      // After end date
      if (transaction.endDate != null &&
          transaction.endDate!.isBefore(newDate)) {
        String transactionName = await getTransactionLabel(transaction);
        openSnackbar(
          SnackbarMessage(
            title: "end-date-reached".tr(),
            description: "${"for".tr().capitalizeFirst} $transactionName",
            icon: appStateSettings["outlinedIcons"]
                ? Icons.event_available_outlined
                : Icons.event_available_rounded,
          ),
        );
        return;
      }

      //Goal reached
      if (transaction.objectiveFk != null && transaction.endDate == null) {
        Objective objective =
            await database.getObjectiveInstance(transaction.objectiveFk!);
        double? totalSpentOfObjective = await database.getTotalTowardsObjective(
            Provider.of<AllWallets>(context, listen: false),
            transaction.objectiveFk!,
            objective.type);

        bool willBeOverObjective = (totalSpentOfObjective ?? 0) >=
            (objective.amount * (objective.income ? 1 : -1));

        if (objective.income == false) {
          willBeOverObjective = !willBeOverObjective;
        }

        if ((totalSpentOfObjective ?? 0) ==
            (objective.amount * (objective.income ? 1 : -1))) {
          willBeOverObjective = true;
        }

        if (willBeOverObjective) {
          openSnackbar(
            SnackbarMessage(
              title: "goal-reached".tr(),
              description: "${"for".tr().capitalizeFirst} ${objective.name}",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.event_available_outlined
                  : Icons.event_available_rounded,
            ),
          );
          return;
        }
      }

      Transaction newTransaction = transaction.copyWith(
        paid: false,
        transactionPk: updatePredictableKey(transaction.transactionPk),
        dateCreated: newDate,
        createdAnotherFutureTransaction: const Value(false),
      );
      await database.createOrUpdateTransaction(insert: false, newTransaction);
      String transactionName = await getTransactionLabel(transaction);
      openSnackbar(
        SnackbarMessage(
          title: "${transaction.income ? "deposited".tr() : "paid".tr()}: $transactionName",
          description:
              "${"created-new-for".tr()} ${getWordedDateShort(newDate)}",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.event_repeat_outlined
              : Icons.event_repeat_rounded,
          onTap: () {
            pushRoute(
              context,
              AddTransactionPage(
                transaction: newTransaction,
                routesToPopAfterDelete: RoutesToPopAfterDelete.One,
              ),
            );
          },
        ),
      );
    }
  }
}

// We create a predictable key when a new repeat transaction is made
// So that when we sync, if the sync client syncs later but it was already automatically marked as paid
// It won't create a new entry (with a random key), it will just replace the entry that we predictably created
// with this key algorithm
// t.l.d.r: it prevents transactions from being duplicated with syncing and auto payments
String updatePredictableKey(String originalKey) {
  if (originalKey.contains("::predict::")) {
    try {
      List<String> parts = originalKey.split("::predict::");
      int currentNumber = int.parse(parts[1]);
      int newNumber = currentNumber + 1;

      return "${parts[0]}::predict::$newNumber";
    } catch (e) {
      print("Error creating predictable key! $e");
      return uuid.v4();
    }
  } else {
    return "$originalKey::predict::1";
  }
}

Future openPayPopup(
  BuildContext context,
  Transaction transaction, {
  Function? runBefore,
}) async {
  String transactionName = await getTransactionLabel(transaction);
  return await openPopup(
    context,
    icon: appStateSettings["outlinedIcons"]
        ? Icons.check_circle_outlined
        : Icons.check_circle_rounded,
    title: "${transaction.income ? "deposit".tr() : "pay".tr()}?",
    subtitle: transactionName,
    description: transaction.income
        ? "deposit-description".tr()
        : "pay-description".tr(),
    onCancelLabel: "cancel".tr().tr(),
    onCancel: () {
      Navigator.pop(context, false);
    },
    onExtraLabel: "skip".tr(),
    onExtra: () async {
      if (runBefore != null) await runBefore();
      Navigator.pop(context);
      await markAsSkipped(
        transaction: transaction,
      );
    },
    onSubmitLabel: transaction.income ? "deposit".tr() : "pay".tr(),
    onSubmit: () async {
      if (runBefore != null) await runBefore();
      //double amount = transaction.amount;
      // if (transaction.amount == 0) {
      //   amount = await openBottomSheet(
      //     context,
      //     fullSnap: true,
      //     PopupFramework(
      //       title: "enter-amount".tr(),
      //       underTitleSpace: false,
      //       child: SelectAmount(
      //         setSelectedAmount: (_, __) {},
      //         nextLabel: "set-amount".tr(),
      //         popWithAmount: true,
      //       ),
      //     ),
      //   );
      //   amount = amount.abs() * (transaction.income ? 1 : -1);
      // }
      Navigator.pop(context);
      await markAsPaid(
        transaction: transaction,
      );
    },
  );
}

Future markAsPaid({
  required Transaction transaction,
  // Avoid infinite recursion
  bool updatingCloselyRelated = false,
}) async {
  if (updatingCloselyRelated == false && transaction.categoryFk == "0") {
    Transaction? closelyRelatedTransferCorrectionTransaction = await database
        .getCloselyRelatedBalanceCorrectionTransaction(transaction);
    if (closelyRelatedTransferCorrectionTransaction != null) {
      await markAsPaid(
        transaction: closelyRelatedTransferCorrectionTransaction,
        updatingCloselyRelated: true,
      );
    }
  }
  Transaction transactionNew = transaction.copyWith(
    paid: true,
    dateCreated:
        appStateSettings["markAsPaidOnOriginalDay"] ? null : DateTime.now(),
    createdAnotherFutureTransaction: const Value(true),
    originalDateDue: Value(transaction.dateCreated),
  );
  await database.createOrUpdateTransaction(transactionNew);
  await createNewSubscriptionTransaction(
      navigatorKey.currentContext!, transaction);
  await setUpcomingNotifications(navigatorKey.currentContext!);
}

Future markAsSkipped({
  required Transaction transaction,
  // Avoid infinite recursion
  bool updatingCloselyRelated = false,
}) async {
  if (updatingCloselyRelated == false && transaction.categoryFk == "0") {
    Transaction? closelyRelatedTransferCorrectionTransaction = await database
        .getCloselyRelatedBalanceCorrectionTransaction(transaction);
    if (closelyRelatedTransferCorrectionTransaction != null) {
      await markAsSkipped(
        transaction: closelyRelatedTransferCorrectionTransaction,
        updatingCloselyRelated: true,
      );
    }
  }
  Transaction transactionNew = transaction.copyWith(
    skipPaid: true,
    dateCreated: DateTime.now(),
    createdAnotherFutureTransaction: const Value(true),
  );
  await database.createOrUpdateTransaction(transactionNew);
  await createNewSubscriptionTransaction(
      navigatorKey.currentContext!, transaction);
  await setUpcomingNotifications(navigatorKey.currentContext!);
}

Future openPayDebtCreditPopup(
  BuildContext context,
  Transaction transaction, {
  Function? runBefore,
}) async {
  String transactionName = await getTransactionLabel(transaction);
  return await openPopup(
    context,
    icon: appStateSettings["outlinedIcons"]
        ? Icons.check_circle_outlined
        : Icons.check_circle_rounded,
    title: "${transaction.type == TransactionSpecialType.credit
            ? "collect".tr()
            : transaction.type == TransactionSpecialType.debt
                ? "settled".tr()
                : ""}?",
    subtitle: transactionName,
    description: transaction.type == TransactionSpecialType.credit
        ? "collect-description".tr()
        : transaction.type == TransactionSpecialType.debt
            ? "settle-description".tr()
            : "",
    onCancelLabel: "cancel".tr(),
    onCancel: () {
      Navigator.pop(context, false);
    },
    onSubmitLabel: transaction.type == TransactionSpecialType.credit
        ? "collect-all".tr()
        : transaction.type == TransactionSpecialType.debt
            ? "settle-all".tr()
            : "",
    onSubmit: () async {
      if (runBefore != null) await runBefore();
      Transaction transactionNew = transaction.copyWith(
        //we don't want it to count towards the total - net is zero now
        paid: false,
      );
      Navigator.pop(context, true);
      await database.createOrUpdateTransaction(transactionNew);
    },
    onExtraLabel2: transaction.type == TransactionSpecialType.credit
        ? "partially-collect".tr()
        : transaction.type == TransactionSpecialType.debt
            ? "partially-settle".tr()
            : "",
    onExtra2: () async {
      double selectedAmount = 0;
      String selectedWalletFk = transaction.walletFk;

      await openBottomSheet(
        context,
        fullSnap: true,
        PopupFramework(
          title: transaction.type == TransactionSpecialType.credit
              ? "amount-collected".tr()
              : transaction.type == TransactionSpecialType.debt
                  ? "amount-settled".tr()
                  : "",
          hasPadding: false,
          underTitleSpace: false,
          child: SelectAmount(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onlyShowCurrencyIcon: true,
            selectedWalletPk: selectedWalletFk,
            walletPkForCurrency: selectedWalletFk,
            setSelectedWalletPk: (walletFk) {
              selectedWalletFk = walletFk;
            },
            allowZero: true,
            allDecimals: true,
            convertToMoney: true,
            setSelectedAmount: (amount, __) {
              selectedAmount = amount;
            },
            next: () {
              Navigator.pop(context);
            },
            nextLabel: "set-amount".tr(),
            currencyKey: null,
            enableWalletPicker: true,
          ),
        ),
      );
      if (selectedAmount == 0) {
        return;
      }
      Navigator.pop(context, true);

      TransactionCategory category =
          await database.getCategory(transaction.categoryFk).$2;
      String transactionLabel = getTransactionLabelSync(transaction, category);
      int numberOfObjectives = (await database.getTotalCountOfObjectives(
              objectiveType: ObjectiveType.loan))[0] ??
          0;
      // Invert the amount, because the objective is of opposite polarity of the current transaction
      // Borrowed is considered positive
      // Lent is considered negative
      int? rowId = await database.createOrUpdateObjective(
        Objective(
          amount: transaction.amount.abs(), //always positive
          income: !transaction.income,
          objectivePk: "-1",
          name: transactionLabel,
          order: numberOfObjectives,
          dateCreated: transaction.dateCreated,
          pinned: false,
          walletFk: transaction.walletFk,
          iconName: category.iconName,
          emojiIconName: category.emojiIconName,
          colour: category.colour,
          type: ObjectiveType.loan,
          archived: false,
        ),
        insert: true,
      );
      final Objective objectiveJustAdded =
          await database.getObjectiveFromRowId(rowId);
      // Set up the initial amount
      await database.createOrUpdateTransaction(
        transaction.copyWith(
          type: const Value(null),
          objectiveLoanFk: Value(objectiveJustAdded.objectivePk),
          amount: transaction.amount,
          name: "initial-record".tr(),
        ),
      );
      // Add the first payment/record
      // Inverse polarity!
      await database.createOrUpdateTransaction(
        transaction.copyWith(
          type: const Value(null),
          objectiveLoanFk: Value(objectiveJustAdded.objectivePk),
          income: !transaction.income,
          amount: selectedAmount * (!transaction.income ? 1 : -1),
          dateCreated: DateTime.now(),
          walletFk: selectedWalletFk,
        ),
        insert: true,
      );
    },
  );
}

Future openRemoveSkipPopup(
  BuildContext context,
  Transaction transaction, {
  Function? runBefore,
}) async {
  String transactionName = await getTransactionLabel(transaction);
  return await openPopup(
    context,
    icon: appStateSettings["outlinedIcons"]
        ? Icons.unpublished_outlined
        : Icons.unpublished_rounded,
    title: "${"remove-skip".tr()}?",
    subtitle: transactionName,
    description: "remove-skip-description".tr(),
    onCancelLabel: "cancel".tr(),
    onCancel: () {
      Navigator.pop(context, false);
    },
    onSubmitLabel: "remove".tr(),
    onSubmit: () async {
      if (runBefore != null) await runBefore();

      Transaction transactionNew = transaction.copyWith(skipPaid: false);
      Navigator.pop(context, true);
      await database.createOrUpdateTransaction(transactionNew);
      await setUpcomingNotifications(navigatorKey.currentContext!);
    },
  );
}

Future openUnpayPopup(
  BuildContext context,
  Transaction transaction, {
  Function? runBefore,
}) async {
  String transactionName = await getTransactionLabel(transaction);
  return await openPopup(context,
      icon: appStateSettings["outlinedIcons"]
          ? Icons.unpublished_outlined
          : Icons.unpublished_rounded,
      title: "${"remove-payment".tr()}?",
      subtitle: transactionName,
      description: "remove-payment-description".tr(),
      onCancelLabel: "cancel".tr(),
      onCancel: () {
        Navigator.pop(context, false);
      },
      onSubmitLabel: "remove".tr(),
      onSubmit: () async {
        await database.deleteTransaction(transaction.transactionPk);
        Transaction transactionNew = transaction.copyWith(
          paid: false,
          sharedKey: const Value(null),
          transactionOriginalOwnerEmail: const Value(null),
          sharedDateUpdated: const Value(null),
          sharedStatus: const Value(null),
        );
        Navigator.pop(context, true);
        await database.createOrUpdateTransaction(transactionNew);
        await setUpcomingNotifications(navigatorKey.currentContext!);
      });
}

Future openUnpayDebtCreditPopup(
  BuildContext context,
  Transaction transaction, {
  Function? runBefore,
}) async {
  String transactionName = await getTransactionLabel(transaction);
  return await openPopup(
    context,
    icon: appStateSettings["outlinedIcons"]
        ? Icons.unpublished_outlined
        : Icons.unpublished_rounded,
    title: "${"remove-payment".tr()}?",
    subtitle: transactionName,
    description: "remove-payment-description".tr(),
    onCancelLabel: "cancel".tr(),
    onCancel: () {
      Navigator.pop(context, false);
    },
    onSubmitLabel: "remove".tr(),
    onSubmit: () async {
      if (runBefore != null) await runBefore();
      Transaction transactionNew = transaction.copyWith(
        //we want it to count towards the total now - net is not zero
        paid: true,
      );
      Navigator.pop(context, true);
      await database.createOrUpdateTransaction(transactionNew,
          updateSharedEntry: false);
    },
  );
}

Future<bool> markSubscriptionsAsPaid(BuildContext context,
    {int? iteration}) async {
  if (appStateSettings["automaticallyPaySubscriptions"] ||
      appStateSettings["automaticallyPayRepetitive"]) {
    // Loop through, because a new one that was created automatically may be past due
    if (iteration != null && iteration > 50) {
      return true;
    }
    List<Transaction> subscriptions = [
      if (appStateSettings["automaticallyPaySubscriptions"])
        ...(await database.getAllSubscriptions().$2),
      if (appStateSettings["automaticallyPayRepetitive"])
        ...(await database.getAllOverdueRepetitiveTransactions().$2)
    ];
    bool hasUpdatedASubscription = false;
    for (Transaction transaction in subscriptions) {
       // Only mark it as paid if it was not marked as unpaid at any point (createdAnotherFutureTransaction == false)
      if (transaction.createdAnotherFutureTransaction != true &&
          transaction.dateCreated.isBefore(DateTime.now())) {
        hasUpdatedASubscription = true;
        Transaction transactionNew = transaction.copyWith(
          paid: true,
          dateCreated: transaction.dateCreated,
          createdAnotherFutureTransaction: const Value(true),
        );
        await database.createOrUpdateTransaction(transactionNew);
        await createNewSubscriptionTransaction(context, transaction);
      }
    }
    if (hasUpdatedASubscription) {
      await markSubscriptionsAsPaid(context, iteration: (iteration ?? 0) + 1);
    }
    print("Automatically paid subscriptions with iteration: $iteration");
  }
  return true;
}

Future<bool> markUpcomingAsPaid() async {
  if (appStateSettings["automaticallyPayUpcoming"]) {
    List<Transaction> upcoming =
        await database.getAllOverdueUpcomingTransactions().$2;
    for (Transaction transaction in upcoming) {
      // Only mark it as paid if it was not marked as unpaid at any point (createdAnotherFutureTransaction == false)
      if (transaction.createdAnotherFutureTransaction != true &&
          transaction.dateCreated.isBefore(DateTime.now())) {
        Transaction transactionNew = transaction.copyWith(
          paid: true,
          dateCreated: transaction.dateCreated,
        );
        await database.createOrUpdateTransaction(transactionNew);
      }
    }
    print("Automatically paid upcoming transactions");
  }
  return true;
}
