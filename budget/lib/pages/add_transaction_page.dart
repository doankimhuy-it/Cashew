import 'package:budget/database/generate_preview_data.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/accounts_page.dart';
import 'package:budget/pages/add_budget_page.dart';
import 'package:budget/pages/add_category_page.dart';
import 'package:budget/pages/add_objective_page.dart';
import 'package:budget/pages/add_wallet_page.dart';
import 'package:budget/pages/edit_objectives_page.dart';
import 'package:budget/pages/objectives_list_page.dart';
import 'package:budget/pages/premium_page.dart';
import 'package:budget/pages/shared_budget_settings.dart';
import 'package:budget/pages/transactions_list_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/nav_bar_icons_data.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/upload_attachment.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/category_icon.dart';
import 'package:budget/widgets/dropdown_select.dart';
import 'package:budget/widgets/fade_in.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/widgets/income_expense_tab_selector.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/pie_chart.dart';
import 'package:budget/widgets/selected_transactions_app_bar.dart';
import 'package:budget/widgets/sliver_sticky_label_divider.dart';
import 'package:budget/widgets/time_digits.dart';
import 'package:budget/struct/initialize_notifications.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/radio_tems.dart';
import 'package:budget/widgets/select_amount.dart';
import 'package:budget/widgets/select_category.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/select_chips.dart';
import 'package:budget/widgets/save_bottom_button.dart';
import 'package:budget/widgets/transaction_entry/income_amount_arrow.dart';
import 'package:budget/widgets/transaction_entry/transaction_entry.dart';
import 'package:budget/widgets/transaction_entry/transaction_entry_type_button.dart';
import 'package:budget/widgets/transaction_entry/transaction_label.dart';
import 'package:budget/widgets/util/context_menu.dart';
import 'package:budget/widgets/util/show_date_picker.dart';
import 'package:budget/widgets/util/widget_size.dart';
import 'package:budget/widgets/view_all_transactions_button.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/util/show_time_picker.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/struct/currency_functions.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/icon_button_scaled.dart';

import '../struct/link_highlighter.dart';
import '../widgets/list_item.dart';
import '../widgets/outlined_button_stacked.dart';
import '../widgets/tappable_text_entry.dart';

//TODO
//only show the tags that correspond to selected category
//put recent used tags at the top? when no category selected

dynamic transactionTypeDisplayToEnum = {
  "Default": null,
  "Upcoming": TransactionSpecialType.upcoming,
  "Subscription": TransactionSpecialType.subscription,
  "Repetitive": TransactionSpecialType.repetitive,
  "Borrowed": TransactionSpecialType.debt,
  "Lent": TransactionSpecialType.credit,
  null: "Default",
  TransactionSpecialType.upcoming: "Upcoming",
  TransactionSpecialType.subscription: "Subscription",
  TransactionSpecialType.repetitive: "Repetitive",
  TransactionSpecialType.debt: "Borrowed",
  TransactionSpecialType.credit: "Lent",
};

class AddTransactionPage extends StatefulWidget {
  AddTransactionPage({
    Key? key,
    this.transaction,
    this.selectedBudget,
    this.selectedType,
    this.selectedObjective,
    this.selectedIncome,
    this.selectedAmount,
    this.selectedTitle,
    this.selectedCategory,
    this.startInitialAddTransactionSequence = true,
    required this.routesToPopAfterDelete,
  }) : super(key: key);

  //When a transaction is passed in, we are editing that transaction
  final Transaction? transaction;
  final Budget? selectedBudget;
  final TransactionSpecialType? selectedType;
  final Objective? selectedObjective;
  final RoutesToPopAfterDelete routesToPopAfterDelete;
  final bool? selectedIncome;
  final double? selectedAmount;
  final String? selectedTitle;
  final TransactionCategory? selectedCategory;
  final bool startInitialAddTransactionSequence;

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  TransactionCategory? selectedCategory;
  TransactionCategory? selectedSubCategory;
  double? selectedAmount;
  String? selectedAmountCalculation;
  String? selectedTitle;
  TransactionSpecialType? selectedType = null;
  List<String> selectedTags = [];
  DateTime selectedDate = DateTime.now();
  DateTime? selectedEndDate = null;
  int selectedPeriodLength = 1;
  String selectedRecurrence = "Monthly";
  String selectedRecurrenceDisplay = "month";
  BudgetReoccurence selectedRecurrenceEnum = BudgetReoccurence.monthly;
  bool selectedIncome = false;
  bool initiallySettingSelectedIncome = false;
  String? selectedPayer;
  String? selectedObjectivePk;
  String? selectedObjectiveLoanPk;
  String? selectedBudgetPk;
  Budget? selectedBudget;
  bool selectedBudgetIsShared = false;
  String selectedWalletPk = appStateSettings["selectedWalletPk"];
  bool notesInputFocused = false;
  bool showMoreOptions = false;
  List<String> selectedExcludedBudgetPks = [];
  late bool isAddedToLoanObjective =
      widget.selectedObjective?.type == ObjectiveType.loan ||
          widget.transaction?.objectiveLoanFk != null;
  // bool isSettingUpBalanceTransfer = false;

  String? textAddTransaction = "add-transaction".tr();

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked =
        await showCustomDatePicker(context, selectedEndDate ?? DateTime.now());
    if (picked != null) setSelectedEndDate(picked);
  }

  setSelectedEndDate(DateTime? date) {
    if (date != selectedEndDate) {
      setState(() {
        selectedEndDate = date;
      });
    }
  }

  void clearSelectedCategory() {
    setState(() {
      selectedCategory = null;
      selectedSubCategory = null;
    });
  }

  void setSelectedCategory(TransactionCategory category,
      {bool setIncome = true}) {
    if (isAddedToLoanObjective == false &&
        setIncome &&
        category.categoryPk != "0") {
      setSelectedIncome(category.income);
    }
    setState(() {
      if (selectedCategory != category) selectedSubCategory = null;
      selectedCategory = category;
    });
    return;
  }

  void setSelectedSubCategory(TransactionCategory? category, {toggle = false}) {
    setState(() {
      if (category == null) {
        selectedSubCategory = null;
      } else if (selectedSubCategory?.categoryPk == category.categoryPk &&
          toggle) {
        selectedSubCategory = null;
      } else {
        selectedSubCategory = category;
      }
    });
    return;
  }

  void setSelectedAmount(double amount, String amountCalculation) {
    if (amount == double.infinity ||
        amount == double.negativeInfinity ||
        amount.isNaN) {
      return;
    }
    if (amount == selectedAmount) {
      selectedAmountCalculation = amountCalculation;
    } else {
      setState(() {
        selectedAmount = amount;
        selectedAmountCalculation = amountCalculation;
      });
    }
    return;
  }

  void setSelectedTitle(String title, {bool setInput = true}) {
    if (setInput) setTextInput(_titleInputController, title);
    selectedTitle = title.trim();
    return;
  }

  void setSelectedTitleController(String title, {bool setInput = true}) {
    if (setInput) setTextInput(_titleInputController, title);
    selectedTitle = title;
    return;
  }

  void setSelectedTags(List<String> tags) {
    setState(() {
      selectedTags = tags;
    });
  }

  void setSelectedNoteController(String note, {bool setInput = true}) {
    if (setInput) setTextInput(_noteInputController, note);
    return;
  }

  void setSelectedType(String type) {
    setState(() {
      selectedType = transactionTypeDisplayToEnum[type];
    });
    return;
  }

  void setSelectedPayer(String payer) {
    setState(() {
      selectedPayer = payer;
    });
    return;
  }

  void setSelectedBudgetPk(Budget? selectedBudgetPassed,
      {bool isSharedBudget = false}) {
    setState(() {
      selectedBudgetPk =
          selectedBudgetPassed == null ? null : selectedBudgetPassed.budgetPk;
      selectedBudget = selectedBudgetPassed;
      selectedBudgetIsShared = isSharedBudget;
      if (selectedBudgetPk != null && selectedPayer == null)
        selectedPayer = appStateSettings["currentUserEmail"] ?? "";
      if (isSharedBudget == false || selectedBudgetPassed?.sharedKey == null) {
        selectedPayer = null;
      }
    });
    return;
  }

  void setSelectedExcludedBudgetPks(List<String>? budgetPks) {
    setState(() {
      selectedExcludedBudgetPks = budgetPks ?? [];
    });
    return;
  }

  void setSelectedObjectivePk(String? selectedObjectivePkPassed) {
    setState(() {
      selectedObjectivePk = selectedObjectivePkPassed;
    });
    return;
  }

  TransactionWallet? getSelectedWallet({required bool listen}) {
    return Provider.of<AllWallets>(context, listen: listen)
        .indexedByPk[selectedWalletPk];
  }

  void setSelectedIncome(bool value, {bool initiallySetting = false}) {
    setState(() {
      selectedIncome = value;
      initiallySettingSelectedIncome = initiallySetting;
    });
  }

  void setSelectedWalletPk(String selectedWalletPkPassed) {
    setState(() {
      selectedWalletPk = selectedWalletPkPassed;
    });
  }

  Transaction addDefaultMissingValues(Transaction transaction) {
    return transaction.copyWith(
      reoccurrence:
          Value(transaction.reoccurrence ?? BudgetReoccurence.monthly),
      periodLength: Value(transaction.periodLength ?? 1),
    );
  }

  Future<bool> addTransaction() async {
    if (appStateSettings["canShowTransactionActionButtonTip"] == true &&
        selectedType != null) {
      await openBottomSheet(
        context,
        fullSnap: true,
        PopupFramework(
          title: "transaction-type".tr(),
          child: Column(
            children: [
              SelectTransactionTypePopup(
                setTransactionType: (type) {},
                selectedTransactionType: selectedType,
                onlyShowOneTransactionType: selectedType,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Flexible(
                      child: Button(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                        label: "do-not-show-again".tr(),
                        onTap: () {
                          updateSettings(
                              "canShowTransactionActionButtonTip", false,
                              updateGlobalState: false);
                          Navigator.pop(context);
                        },
                        expandedLayout: true,
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Button(
                        label: "ok".tr(),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        expandedLayout: true,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }
    try {
      print("Added transaction");
      if (selectedTitle != null &&
          selectedCategory != null &&
          selectedTitle != "") {
        // if (selectedSubCategory != null) {
        //   await addAssociatedTitles(selectedTitle!, selectedSubCategory!);
        // } else {
        //   await addAssociatedTitles(selectedTitle!, selectedCategory!);
        // }
        await addAssociatedTitles(selectedTitle!, selectedCategory!);
      }

      Transaction createdTransaction = await createTransaction();

      if (widget.transaction != null) {
        // Only ask if changes were made that will affect other balance correction
        // set in the logic of updateCloselyRelatedBalanceTransfer

        // If these fields are touched they will not trigger the popup
        if (addDefaultMissingValues(widget.transaction!).copyWith(
              dateTimeModified: Value(null),
              walletFk: "",
              name: "",
              note: "",
              income: false,
              amount: widget.transaction!.amount.abs(),
              objectiveFk: Value(null),
            ) !=
            createdTransaction.copyWith(
              dateTimeModified: Value(null),
              walletFk: "",
              name: "",
              note: "",
              income: false,
              amount: createdTransaction.amount.abs(),
              objectiveFk: Value(null),
            )) {
          Transaction? closelyRelatedTransferCorrectionTransaction =
              await database.getCloselyRelatedBalanceCorrectionTransaction(
                  widget.transaction!);

          if (closelyRelatedTransferCorrectionTransaction != null) {
            await openPopup(
              context,
              title: "update-both-transfers-question".tr(),
              description: "update-both-transfers-question-description".tr(),
              descriptionWidget: IgnorePointer(
                child: Column(
                  children: [
                    HorizontalBreak(
                        padding: EdgeInsets.only(top: 15, bottom: 10)),
                    TransactionEntry(
                      useHorizontalPaddingConstrained: false,
                      openPage: Container(),
                      transaction: createTransaction(),
                      containerColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.4),
                      customPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 5),
                    TransactionEntry(
                      useHorizontalPaddingConstrained: false,
                      openPage: Container(),
                      transaction: closelyRelatedTransferCorrectionTransaction,
                      containerColor: Colors.transparent,
                      customPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              onCancel: () {
                Navigator.pop(context);
              },
              onCancelLabel: "only-current".tr(),
              onSubmit: () async {
                AllWallets allWallets =
                    Provider.of<AllWallets>(context, listen: false);
                await database.updateCloselyRelatedBalanceTransfer(
                  allWallets,
                  createdTransaction,
                  closelyRelatedTransferCorrectionTransaction,
                );
                Navigator.pop(context);
              },
              onSubmitLabel: "update-both".tr(),
            );
          }
        }
      }

      final int? rowId = await database.createOrUpdateTransaction(
        insert: widget.transaction == null,
        createdTransaction,
        originalTransaction: widget.transaction,
      );

      if (rowId != null) {
        final Transaction transactionJustAdded =
            await database.getTransactionFromRowId(rowId);
        print("Transaction just added:");
        print(transactionJustAdded);

        // Do the flash animation only if the date was changed
        if (transactionJustAdded.dateCreated !=
            widget.transaction?.dateCreated) {
          flashTransaction(transactionJustAdded.transactionPk);

          // If a new transaction with an added date of 5 minutes of less before, flash only a bit
          if (widget.transaction == null &&
              transactionJustAdded.dateCreated.isAfter(
                DateTime.now().subtract(
                  Duration(minutes: 5),
                ),
              )) {
            flashTransaction(transactionJustAdded.transactionPk, flashCount: 2);
          } else {
            flashTransaction(transactionJustAdded.transactionPk);
          }
        }
      }

      if ([
        TransactionSpecialType.repetitive,
        TransactionSpecialType.subscription,
        TransactionSpecialType.upcoming
      ].contains(createdTransaction.type)) {
        await setUpcomingNotifications(context);
      }

      // recentlyAddedTransactionID.value =

      if (widget.transaction == null &&
          appStateSettings["purchaseID"] == null) {
        updateSettings("premiumPopupAddTransactionCount",
            (appStateSettings["premiumPopupAddTransactionCount"] ?? 0) + 1,
            updateGlobalState: false);
      }

      return true;
    } catch (e) {
      if (e.toString() == "category-no-longer-exists") {
        openSnackbar(SnackbarMessage(
          title: "cannot-create-transaction".tr(),
          description: "category-no-longer-exists".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_amber_outlined
              : Icons.warning_amber_rounded,
        ));
        clearSelectedCategory();
      } else {
        openSnackbar(SnackbarMessage(
          title: "cannot-create-transaction".tr(),
          description: e.toString(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_amber_outlined
              : Icons.warning_amber_rounded,
        ));
      }
      return false;
    }
  }

  Transaction createTransaction({bool removeShared = false}) {
    bool? createdAnotherFutureTransaction = widget.transaction != null
        ? widget.transaction!.createdAnotherFutureTransaction
        : null;
    bool paid = widget.transaction != null
        ? widget.transaction!.paid
        : selectedType == null;
    bool skipPaid = widget.transaction != null
        ? widget.transaction!.skipPaid
        : selectedType == null;

    if (selectedType != null &&
        widget.transaction != null &&
        widget.transaction!.type != selectedType) {
      createdAnotherFutureTransaction = false;

      if ([TransactionSpecialType.credit, TransactionSpecialType.debt]
          .contains(selectedType)) {
        paid = true;
        skipPaid = false;
      } else {
        paid = false;
        skipPaid = false;
      }
    }

    Transaction createdTransaction = Transaction(
      transactionPk:
          widget.transaction != null ? widget.transaction!.transactionPk : "-1",
      pairedTransactionFk: widget.transaction?.pairedTransactionFk,
      name: (selectedTitle ?? "").trim(),
      amount: (selectedIncome || selectedAmount == 0 //Prevent negative 0
          ? (selectedAmount ?? 0).abs()
          : (selectedAmount ?? 0).abs() * -1),
      note: _noteInputController.text,
      categoryFk: selectedCategory?.categoryPk ?? "-1",
      subCategoryFk: selectedSubCategory?.categoryPk,
      dateCreated: selectedDate,
      endDate: selectedEndDate,
      dateTimeModified: null,
      income: selectedIncome,
      walletFk: selectedWalletPk,
      paid: paid,
      skipPaid: skipPaid,
      type: selectedType,
      reoccurrence: selectedRecurrenceEnum,
      periodLength: selectedPeriodLength <= 0 && selectedType != null
          ? 1
          : selectedPeriodLength,
      methodAdded:
          widget.transaction != null ? widget.transaction!.methodAdded : null,
      createdAnotherFutureTransaction: createdAnotherFutureTransaction,
      sharedKey: removeShared == false && widget.transaction != null
          ? widget.transaction!.sharedKey
          : null,
      sharedOldKey:
          widget.transaction != null ? widget.transaction!.sharedOldKey : null,
      transactionOwnerEmail: selectedPayer,
      transactionOriginalOwnerEmail:
          removeShared == false && widget.transaction != null
              ? widget.transaction!.transactionOriginalOwnerEmail
              : null,
      sharedStatus: removeShared == false && widget.transaction != null
          ? widget.transaction!.sharedStatus
          : null,
      sharedDateUpdated: removeShared == false && widget.transaction != null
          ? widget.transaction!.sharedDateUpdated
          : null,
      sharedReferenceBudgetPk: selectedBudgetPk,
      upcomingTransactionNotification: widget.transaction != null
          ? widget.transaction!.upcomingTransactionNotification
          : null,
      originalDateDue: widget.transaction != null
          ? widget.transaction!.originalDateDue
          : null,
      objectiveFk: selectedObjectivePk,
      objectiveLoanFk: selectedObjectiveLoanPk,
      budgetFksExclude:
          selectedExcludedBudgetPks.isEmpty ? null : selectedExcludedBudgetPks,
    );

    if (widget.transaction != null &&
        widget.transaction!.type != null &&
        createdTransaction.type == null) {
      createdTransaction = createdTransaction.copyWith(paid: true);
    }

    if ((createdTransaction.type == TransactionSpecialType.credit ||
            createdTransaction.type == TransactionSpecialType.debt) &&
        (widget.transaction == null)) {
      createdTransaction = createdTransaction.copyWith(paid: true);
    }

    return createdTransaction;
  }

  Transaction? transactionInitial;

  // If a change was made, show the discard changes popup
  // When creating a new entry only
  void showDiscardChangesPopupIfNotEditing() {
    Transaction transactionCreated = createTransaction();
    if (transactionCreated != transactionInitial &&
        widget.transaction == null) {
      discardChangesPopup(context, forceShow: true);
    } else {
      Navigator.pop(context);
    }
  }

  late TextEditingController _titleInputController;
  late TextEditingController _noteInputController;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      //We are editing a transaction
      //Fill in the information from the passed in transaction
      _titleInputController =
          new TextEditingController(text: widget.transaction!.name);
      _noteInputController =
          new LinkHighlighter(initialText: widget.transaction!.note);
      selectedTitle = widget.transaction!.name;
      selectedDate = widget.transaction!.dateCreated;
      selectedEndDate = widget.transaction!.endDate;
      selectedWalletPk = widget.transaction!.walletFk;
      selectedAmount = widget.transaction!.amount.abs();
      selectedType = widget.transaction!.type;
      selectedPeriodLength = widget.transaction!.periodLength ?? 1;
      selectedRecurrenceEnum =
          widget.transaction!.reoccurrence ?? BudgetReoccurence.monthly;
      selectedRecurrence = enumRecurrence[selectedRecurrenceEnum];
      if (selectedPeriodLength == 1) {
        selectedRecurrenceDisplay = nameRecurrence[selectedRecurrence];
      } else {
        selectedRecurrenceDisplay = namesRecurrence[selectedRecurrence];
      }
      selectedIncome = widget.transaction!.income;
      selectedPayer = widget.transaction!.transactionOwnerEmail;
      selectedBudgetPk = widget.transaction!.sharedReferenceBudgetPk;
      selectedObjectivePk = widget.transaction!.objectiveFk;
      selectedObjectiveLoanPk = widget.transaction!.objectiveLoanFk;
      selectedExcludedBudgetPks = widget.transaction!.budgetFksExclude ?? [];
      // var amountString = widget.transaction!.amount.toStringAsFixed(2);
      // if (amountString.substring(amountString.length - 2) == "00") {
      //   selectedAmountCalculation =
      //       amountString.substring(0, amountString.length - 3);
      // } else {
      //   selectedAmountCalculation = amountString;
      // }
      textAddTransaction = "save-changes".tr();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateInitial();
      });
    } else {
      if (widget.selectedType != null) {
        selectedType = widget.selectedType;
      }

      _titleInputController = new TextEditingController();
      _noteInputController = new LinkHighlighter();

      Future.delayed(Duration(milliseconds: 0), () async {
        await premiumPopupAddTransaction(context);
        if (widget.startInitialAddTransactionSequence == false) return;
        if (appStateSettings["askForTransactionTitle"]) {
          openBottomSheet(
            context,
            // Only allow full snap when entering a title
            fullSnap: true,
            SelectTitle(
              selectedTitle: selectedTitle,
              setSelectedNote: setSelectedNoteController,
              setSelectedTitle: setSelectedTitleController,
              setSelectedTags: setSelectedTags,
              selectedCategory: selectedCategory,
              setSelectedCategory: setSelectedCategory,
              next: () {
                afterSetTitle();
              },
              noteInputController: _noteInputController,
            ),
          );
          // Fix over-scroll stretch when keyboard pops up quickly
          Future.delayed(Duration(milliseconds: 100), () {
            bottomSheetControllerGlobal.scrollTo(0,
                duration: Duration(milliseconds: 100));
          });
        } else {
          afterSetTitle();
        }
      });
    }
    if (widget.selectedBudget != null) {
      selectedBudget = widget.selectedBudget;
      selectedBudgetPk = widget.selectedBudget!.budgetPk;
      selectedPayer = appStateSettings["currentUserEmail"];
      selectedBudgetIsShared = widget.selectedBudget!.sharedKey != null;
    }
    if (widget.selectedObjective != null) {
      if (widget.selectedObjective?.type == ObjectiveType.loan) {
        selectedObjectiveLoanPk = widget.selectedObjective!.objectivePk;
      } else {
        selectedObjectivePk = widget.selectedObjective!.objectivePk;
      }
    }
    if (widget.selectedAmount != null) {
      selectedAmount = widget.selectedAmount;
    }
    if (widget.selectedCategory != null) {
      selectedCategory = widget.selectedCategory;
    }
    if (widget.selectedTitle != null) {
      selectedTitle = widget.selectedTitle;
      Future.delayed(Duration.zero, () {
        setSelectedTitle(widget.selectedTitle ?? "");
      });
    }
    if (widget.selectedIncome != null) {
      selectedIncome = widget.selectedIncome!;
    }
    if (widget.transaction == null) {
      Future.delayed(Duration.zero, () {
        transactionInitial = createTransaction();
      });
    }

    setState(() {});
  }

  updateInitial() async {
    if (widget.transaction != null) {
      TransactionCategory? getSelectedCategory =
          await database.getCategoryInstance(widget.transaction!.categoryFk);

      TransactionCategory? getSelectedSubCategory =
          widget.transaction!.subCategoryFk == null
              ? null
              : await database.getCategoryInstanceOrNull(
                  widget.transaction!.subCategoryFk!);
      Budget? getBudget;
      try {
        getBudget = await database.getBudgetInstance(
            widget.transaction!.sharedReferenceBudgetPk ?? "-1");
      } catch (e) {}

      setState(() {
        selectedCategory = getSelectedCategory;
        selectedSubCategory = getSelectedSubCategory;
        selectedBudget = getBudget;
        selectedBudgetIsShared =
            getBudget == null ? false : getBudget.sharedKey != null;
      });
    }
  }

  Future afterSetTitle() async {
    MainAndSubcategory mainAndSubcategory = await selectCategorySequence(
      context,
      selectedCategory: selectedCategory,
      setSelectedCategory: (TransactionCategory category) {
        setSelectedCategory(category,
            setIncome: initiallySettingSelectedIncome == false);
      },
      selectedSubCategory: selectedSubCategory,
      setSelectedSubCategory: setSelectedSubCategory,
      setSelectedIncome: (value) {
        setSelectedIncome(value == true, initiallySetting: value != null);
      },
      skipIfSet: true,
      selectedIncomeInitial: null,
      extraWidgetAfter: Column(
        children: [
          SelectAddedBudget(
            setSelectedBudget: setSelectedBudgetPk,
            selectedBudgetPk: selectedBudgetPk,
            extraHorizontalPadding: 13,
            wrapped: false,
          ),
          SelectObjective(
            setSelectedObjective: setSelectedObjectivePk,
            selectedObjectivePk: selectedObjectivePk,
            extraHorizontalPadding: 13,
            wrapped: false,
          ),
        ],
      ),
    );

    if (mainAndSubcategory.main != null &&
        mainAndSubcategory.ignoredSubcategorySelection == false) {
      selectAmountPopup(
        next: () async {
          await addTransaction();
          Navigator.pop(context);
          Navigator.pop(context);
        },
        nextLabel: textAddTransaction,
      );
    }
  }

  selectAmountPopup({VoidCallback? next, String? nextLabel}) async {
    await openBottomSheet(
      context,
      fullSnap: true,
      PopupFramework(
        title: "enter-amount".tr(),
        hasPadding: false,
        underTitleSpace: false,
        child: SelectAmount(
          enableWalletPicker: true,
          selectedWalletPk: selectedWalletPk,
          setSelectedWalletPk: setSelectedWalletPk,
          padding: EdgeInsets.symmetric(horizontal: 18),
          walletPkForCurrency: selectedWalletPk,
          // onlyShowCurrencyIcon:
          //     appStateSettings[
          //             "selectedWalletPk"] ==
          //         selectedWalletPk,
          onlyShowCurrencyIcon: true,
          amountPassed: (selectedAmount ?? "0").toString(),
          setSelectedAmount: setSelectedAmount,
          next: next ??
              () async {
                Navigator.pop(context);
              },
          nextLabel: nextLabel ?? "set-amount".tr(),
        ),
      ),
    );
  }

  // void initializeBalanceTransfer() async {
  //   if (isSettingUpBalanceTransfer == false) {
  //     isSettingUpBalanceTransfer = true;
  //     TransactionCategory balanceCorrectionCategory =
  //         await initializeBalanceCorrectionCategory();
  //     setSelectedCategory(balanceCorrectionCategory);
  //     setSelectedWalletPk(appStateSettings["selectedWalletPk"]);
  //     setState(() {});
  //   }
  // }

  // void resetInitializeBalanceTransfer() {
  //   if (isSettingUpBalanceTransfer == true) {
  //     print("RESET");
  //     clearSelectedCategory();
  //     setState(() {
  //       isSettingUpBalanceTransfer = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    Color categoryColor = dynamicPastel(
      context,
      HexColor(
        selectedCategory?.colour,
        defaultColor: dynamicPastel(
          context,
          Theme.of(context).colorScheme.primary,
          amount: appStateSettings["materialYou"] ? 0.55 : 0.2,
        ),
      ),
      amount: 0.35,
    );

    Widget transactionTextInput = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        enableDoubleColumn(context)
            ? Container(height: 20)
            : Container(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: TextInput(
            padding: EdgeInsets.zero,
            labelText: "title-placeholder".tr(),
            icon: appStateSettings["outlinedIcons"]
                ? Icons.title_outlined
                : Icons.title_rounded,
            controller: _titleInputController,
            onChanged: (text) async {
              setSelectedTitle(text, setInput: false);
            },
            autoFocus: kIsWeb && getIsFullScreen(context),
          ),
        ),
        Container(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: TransactionNotesTextInput(
            noteInputController: _noteInputController,
            setNotesInputFocused: (isFocused) {
              setState(() {
                notesInputFocused = isFocused;
              });
            },
            setSelectedNoteController: setSelectedNoteController,
          ),
        ),
      ],
    );

    Widget transactionDetailsParameters = Flexible(
      child: Container(
        constraints: BoxConstraints(maxWidth: 900),
        child: FractionallySizedBox(
          widthFactor: enableDoubleColumn(context) == false ? 1 : 0.95,
          child: Column(
            children: [
              Container(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: DateButton(
                    key: ValueKey(selectedDate.toString()),
                    initialSelectedDate: selectedDate,
                    initialSelectedTime: TimeOfDay(
                        hour: selectedDate.hour, minute: selectedDate.minute),
                    setSelectedDate: (date) {
                      selectedDate = date;
                    },
                    setSelectedTime: (time) {
                      selectedDate = selectedDate.copyWith(
                          hour: time.hour, minute: time.minute);
                    },
                  ),
                ),
              ),
              enableDoubleColumn(context) == false
                  ? SizedBox(height: 5)
                  : SizedBox.shrink(),
              HorizontalBreakAbove(
                enabled: enableDoubleColumn(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SelectChips(
                    allowMultipleSelected: false,
                    wrapped: enableDoubleColumn(context),
                    extraWidgetAtBeginning: true,
                    extraWidget: Transform.scale(
                      scale: 1.3,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          appStateSettings["outlinedIcons"]
                              ? Icons.info_outlined
                              : Icons.info_outline_rounded,
                          size: 19,
                        ),
                        onPressed: () {
                          openBottomSheet(
                            context,
                            fullSnap: false,
                            PopupFramework(
                              title: "select-transaction-type".tr(),
                              child: SelectTransactionTypePopup(
                                setTransactionType: (type) {
                                  setSelectedType(
                                    transactionTypeDisplayToEnum[type],
                                  );
                                },
                                selectedTransactionType: selectedType,
                                transactionTypesToShow:
                                    getTransactionSpecialTypesToShowGivenInitialTypeWhenAddingTransaction(
                                  widget.selectedType,
                                  isAddedToLoanObjective,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    items:
                        getTransactionSpecialTypesToShowGivenInitialTypeWhenAddingTransaction(
                            widget.selectedType, isAddedToLoanObjective),
                    getLabel: (item) {
                      if (item is TransactionSpecialType || item == null) {
                        return transactionTypeDisplayToEnum[item]
                                ?.toString()
                                .toLowerCase()
                                .tr() ??
                            "";
                      } else {
                        return "installments".tr();
                      }
                    },
                    onSelected: (item) async {
                      if (item == "installments") {
                        openPopup(
                          context,
                          title: "track-installments".tr(),
                          description: "track-installments-description".tr(),
                          icon: navBarIconsData["goals"]!.iconData,
                          onSubmit: () async {
                            Navigator.pop(context);
                            dynamic result = await startCreatingInstallment(
                                context: context);
                            if (result == true) Navigator.pop(context);
                          },
                          onSubmitLabel: "ok".tr(),
                          onCancel: () {
                            Navigator.pop(context);
                          },
                          onCancelLabel: "cancel".tr(),
                        );
                      } else if (item is TransactionSpecialType ||
                          item == null) {
                        setSelectedType(transactionTypeDisplayToEnum[item]);
                      }
                    },
                    getSelected: (item) {
                      if (item is TransactionSpecialType || item == null) {
                        return selectedType == item;
                      } else {
                        return false;
                      }
                    },
                  ),
                ),
              ),
              AnimatedExpanded(
                expand: selectedType == TransactionSpecialType.repetitive ||
                    selectedType == TransactionSpecialType.subscription,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextFont(
                              text: "repeat-every".tr(),
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TappableTextEntry(
                                  title: selectedPeriodLength.toString(),
                                  placeholder: "0",
                                  showPlaceHolderWhenTextEquals: "0",
                                  onTap: () {
                                    selectPeriodLength(
                                      context: context,
                                      selectedPeriodLength:
                                          selectedPeriodLength,
                                      setSelectedPeriodLength: (period) =>
                                          setSelectedPeriodLength(
                                        period: period,
                                        selectedRecurrence: selectedRecurrence,
                                        setPeriodLength: (selectedPeriodLength,
                                            selectedRecurrenceDisplay) {
                                          this.selectedPeriodLength =
                                              selectedPeriodLength;
                                          this.selectedRecurrenceDisplay =
                                              selectedRecurrenceDisplay;
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  internalPadding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 4),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 3),
                                ),
                                TappableTextEntry(
                                  title: selectedRecurrenceDisplay
                                      .toString()
                                      .toLowerCase()
                                      .tr()
                                      .toLowerCase(),
                                  placeholder: "",
                                  onTap: () {
                                    selectRecurrence(
                                      context: context,
                                      selectedRecurrence: selectedRecurrence,
                                      selectedPeriodLength:
                                          selectedPeriodLength,
                                      onChanged: (selectedRecurrence,
                                          selectedRecurrenceEnum,
                                          selectedRecurrenceDisplay) {
                                        this.selectedRecurrence =
                                            selectedRecurrence;
                                        this.selectedRecurrenceEnum =
                                            selectedRecurrenceEnum;
                                        this.selectedRecurrenceDisplay =
                                            selectedRecurrenceDisplay;
                                        setState(() {});
                                      },
                                    );
                                  },
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  internalPadding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 4),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 3),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedExpanded(
                              expand: selectedEndDate != null,
                              axis: Axis.horizontal,
                              child: TextFont(
                                text: "until".tr(),
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Flexible(
                              child: TappableTextEntry(
                                title: (selectedEndDate == null
                                    ? ""
                                    : getWordedDateShort(
                                        selectedEndDate!,
                                        includeYear: selectedEndDate!.year !=
                                            DateTime.now().year,
                                      )),
                                placeholder: selectedObjectiveLoanPk != null
                                    ? "until-loan-reached".tr()
                                    : selectedObjectivePk != null
                                        ? "until-goal-reached".tr()
                                        : "until-forever".tr(),
                                showPlaceHolderWhenTextEquals: "",
                                onTap: () {
                                  selectEndDate(context);
                                },
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                internalPadding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 4),
                                padding: EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 5),
                              ),
                            ),
                            AnimatedSizeSwitcher(
                              child: selectedEndDate != null
                                  ? Opacity(
                                      key: ValueKey(1),
                                      opacity: 0.5,
                                      child: IconButtonScaled(
                                        tooltip: "clear".tr(),
                                        iconData: Icons.close_rounded,
                                        iconSize: 16,
                                        scale: 1.5,
                                        onTap: () {
                                          setSelectedEndDate(null);
                                        },
                                      ),
                                    )
                                  : Container(
                                      key: ValueKey(2),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Wallet picker is in Select Amount... consider removing?
              Provider.of<AllWallets>(context).list.length <= 1
                  ? SizedBox.shrink()
                  : HorizontalBreakAbove(
                      enabled: enableDoubleColumn(context),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: SelectChips(
                          allowMultipleSelected: false,
                          onLongPress: (TransactionWallet wallet) {
                            pushRoute(
                              context,
                              AddWalletPage(
                                wallet: wallet,
                                routesToPopAfterDelete:
                                    RoutesToPopAfterDelete.PreventDelete,
                              ),
                            );
                          },
                          items: Provider.of<AllWallets>(context).list,
                          getSelected: (TransactionWallet wallet) {
                            return getSelectedWallet(listen: false)?.walletPk ==
                                wallet.walletPk;
                          },
                          onSelected: (TransactionWallet wallet) {
                            setSelectedWalletPk(wallet.walletPk);
                          },
                          getCustomBorderColor: (TransactionWallet item) {
                            return dynamicPastel(
                              context,
                              lightenPastel(
                                HexColor(
                                  item.colour,
                                  defaultColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                amount: 0.3,
                              ),
                              amount: 0.4,
                            );
                          },
                          getLabel: (TransactionWallet wallet) {
                            return wallet.name ==
                                    wallet.currency.toString().toUpperCase()
                                ? wallet.currency.toString().toUpperCase()
                                : wallet.name +
                                    " (" +
                                    wallet.currency.toString().toUpperCase() +
                                    ")";
                          },
                          extraWidget: SelectChipsAddButtonExtraWidget(
                            openPage: AddWalletPage(
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.None,
                            ),
                          ),
                        ),
                      ),
                    ),
              SelectAddedBudget(
                selectedBudgetPk: selectedBudgetPk,
                setSelectedBudget: setSelectedBudgetPk,
                horizontalBreak: true,
              ),
              if (isAddedToLoanObjective == false)
                SelectObjective(
                  setSelectedObjective: setSelectedObjectivePk,
                  selectedObjectivePk: selectedObjectivePk,
                  horizontalBreak: true,
                ),
              AnimatedExpanded(
                expand:
                    selectedBudgetPk != null && selectedBudgetIsShared == true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SelectChips(
                    allowMultipleSelected: false,
                    wrapped: enableDoubleColumn(context),
                    items: <String>[...(selectedBudget?.sharedMembers ?? [])],
                    getLabel: (String item) {
                      return getMemberNickname(item);
                    },
                    onSelected: (String item) {
                      setSelectedPayer(item);
                    },
                    getSelected: (String item) {
                      return selectedPayer == item;
                    },
                    onLongPress: (String item) {
                      memberPopup(context, item);
                    },
                  ),
                ),
              ),
              enableDoubleColumn(context)
                  ? SizedBox.shrink()
                  : transactionTextInput,
              SizedBox(height: 10),
              AnimatedExpanded(
                  expand: showMoreOptions == false &&
                      widget.transaction?.budgetFksExclude != null,
                  child: Column(
                    children: [
                      HorizontalBreakAbove(
                        enabled: enableDoubleColumn(context),
                        child: StickyLabelDivider(
                          info: "exclude-from-budget".tr(),
                        ),
                      ),
                      SelectExcludeBudget(
                        setSelectedExcludedBudgets:
                            setSelectedExcludedBudgetPks,
                        selectedExcludedBudgetPks: selectedExcludedBudgetPks,
                      ),
                    ],
                  )),
              AnimatedSizeSwitcher(
                child: showMoreOptions == false
                    ? Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: LowKeyButton(
                          key: ValueKey(1),
                          onTap: () {
                            setState(() {
                              showMoreOptions = true;
                            });
                          },
                          text: "more-options".tr(),
                        ),
                      )
                    : Column(
                        key: ValueKey(2),
                        children: [
                          if (widget.transaction != null)
                            HorizontalBreakAbove(
                              enabled: enableDoubleColumn(context),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  bottom: 12,
                                  top: 5,
                                ),
                                child: Button(
                                  flexibleLayout: true,
                                  icon: appStateSettings["outlinedIcons"]
                                      ? Icons.file_copy_outlined
                                      : Icons.file_copy_rounded,
                                  label: "duplicate".tr(),
                                  onTap: () async {
                                    bool result = await addTransaction();
                                    if (result) Navigator.of(context).pop();
                                    duplicateTransaction(context,
                                        widget.transaction!.transactionPk);
                                  },
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  textColor: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ),
                          HorizontalBreakAbove(
                            enabled: enableDoubleColumn(context),
                            child: StickyLabelDivider(
                              info: "exclude-from-budget".tr(),
                            ),
                          ),
                          SelectExcludeBudget(
                            setSelectedExcludedBudgets:
                                setSelectedExcludedBudgetPks,
                            selectedExcludedBudgetPks:
                                selectedExcludedBudgetPks,
                          ),
                        ],
                      ),
              ),

              widget.transaction == null ||
                      widget.transaction!.sharedDateUpdated == null
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 28),
                      child: TextFont(
                        text: "synced".tr() +
                            " " +
                            getTimeAgo(
                              widget.transaction!.sharedDateUpdated!,
                            ).toLowerCase() +
                            "\n Created by " +
                            (widget.transaction!
                                    .transactionOriginalOwnerEmail ??
                                ""),
                        fontSize: 13,
                        textColor: getColor(context, "textLight"),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ),
              Container(height: 100),
            ],
          ),
        ),
      ),
    );

    bool enableBalanceTransferTab = isAddedToLoanObjective == false &&
        widget.transaction == null &&
        Provider.of<AllWallets>(context).indexedByPk.keys.length > 1;

    Widget transactionAmountAndCategoryHeader = AnimatedContainer(
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300),
      color: categoryColor,
      child: Column(
        children: [
          GestureDetector(
            onLongPress: () async {
              if (enableBalanceTransferTab) {
                await openBottomSheet(
                  context,
                  PopupFramework(
                    hasPadding: false,
                    child: ShowTransactionsBalanceTransferTabSettingToggle(),
                  ),
                );
                setState(() {});
              }
            },
            child: AnimatedExpanded(
              expand: !(selectedType == TransactionSpecialType.credit ||
                  selectedType == TransactionSpecialType.debt),
              child: appStateSettings["showTransactionsBalanceTransferTab"] ==
                          true &&
                      enableBalanceTransferTab
                  ? IncomeExpenseTransferTabSelector(
                      onTabChanged: (int index) async {
                        if (index == 0) {
                          //resetInitializeBalanceTransfer();
                          setSelectedIncome(false);
                        } else if (index == 1) {
                          //resetInitializeBalanceTransfer();
                          setSelectedIncome(true);
                        } else if (index == 2) {
                          //initializeBalanceTransfer();
                          dynamic result = await openBottomSheet(
                            context,
                            fullSnap: true,
                            TransferBalancePopup(
                              allowEditWallet: true,
                              wallet: Provider.of<AllWallets>(context,
                                          listen: false)
                                      .indexedByPk[
                                  appStateSettings["selectedWalletPk"]]!,
                              showAllEditDetails: true,
                              initialAmount: selectedAmount,
                              initialDate: selectedDate,
                              initialTitle: selectedTitle,
                            ),
                          );
                          if (result == true) {
                            Navigator.pop(context);
                          } else {
                            setSelectedIncome(false);
                          }
                        }
                      },
                      initialTab: selectedIncome ? 1 : 0,
                      // initialTab: isSettingUpBalanceTransfer
                      //     ? 2
                      //     : selectedIncome
                      //         ? 1
                      //         : 0,
                      color: categoryColor,
                      unselectedColor: Colors.black.withOpacity(0.2),
                      unselectedLabelColor: Colors.white.withOpacity(0.3),
                    )
                  : IncomeExpenseTabSelector(
                      hasBorderRadius: false,
                      onTabChanged: setSelectedIncome,
                      initialTabIsIncome: selectedIncome,
                      syncWithInitial: true,
                      color: categoryColor,
                      unselectedColor: Colors.black.withOpacity(0.2),
                      unselectedLabelColor: Colors.white.withOpacity(0.3),
                      incomeLabel: isAddedToLoanObjective
                          ? "collected".tr()
                          : selectedCategory?.categoryPk == "0"
                              ? "transfer-in".tr()
                              : null,
                      expenseLabel: isAddedToLoanObjective
                          ? "paid".tr()
                          : selectedCategory?.categoryPk == "0"
                              ? "transfer-out".tr()
                              : null,
                    ),
            ),
          ),
          Row(
            children: [
              Tappable(
                onLongPress: () async {
                  await pushRoute(
                    context,
                    AddCategoryPage(
                      category: selectedCategory,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  );
                  if (selectedCategory != null) {
                    TransactionCategory category = await database
                        .getCategory(selectedCategory!.categoryPk)
                        .$2;
                    setSelectedCategory(category,
                        setIncome: selectedCategory?.income != category.income);
                  }
                },
                onTap: () async {
                  //resetInitializeBalanceTransfer();
                  await selectCategorySequence(
                    context,
                    selectedCategory: selectedCategory,
                    setSelectedCategory: setSelectedCategory,
                    selectedSubCategory: selectedSubCategory,
                    setSelectedSubCategory: setSelectedSubCategory,
                    skipIfSet: false,
                    selectedIncomeInitial: selectedIncome,
                  );
                },
                color: Colors.transparent,
                child: Container(
                  height: 136,
                  padding: const EdgeInsets.only(left: 17, right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: CategoryIcon(
                          tintEnabled: false,
                          canEditByLongPress: false,
                          noBackground: true,
                          key: ValueKey(selectedCategory?.categoryPk ?? ""),
                          category: selectedCategory,
                          size: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomContextMenu(
                  buttonItems: [
                    ContextMenuButtonItem(
                      type: ContextMenuButtonType.copy,
                      onPressed: () {
                        ContextMenuController.removeAny();
                        copyToClipboard(
                          convertToMoney(
                            Provider.of<AllWallets>(context, listen: false),
                            currencyKey:
                                Provider.of<AllWallets>(context, listen: false)
                                    .indexedByPk[selectedWalletPk]
                                    ?.currency,
                            selectedAmount ?? 0,
                            finalNumber: selectedAmount ?? 0,
                            decimals:
                                getSelectedWallet(listen: false)?.decimals,
                          ),
                        );
                      },
                    ),
                    ContextMenuButtonItem(
                      type: ContextMenuButtonType.paste,
                      onPressed: () async {
                        ContextMenuController.removeAny();
                        String? clipboardText =
                            await readClipboard(showSnackbar: false);
                        double? amount =
                            getAmountFromString(clipboardText ?? "");
                        if (amount != null) {
                          setSelectedAmount(amount, amount.toString());
                          openSnackbar(
                            SnackbarMessage(
                              title: "pasted-from-clipboard".tr(),
                              icon: appStateSettings["outlinedIcons"]
                                  ? Icons.paste_outlined
                                  : Icons.paste_rounded,
                              timeout: Duration(milliseconds: 2500),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  tappableBuilder: (onLongPress) {
                    return Tappable(
                      color: Colors.transparent,
                      onLongPress: onLongPress,
                      onTap: selectAmountPopup,
                      child: Container(
                        padding: const EdgeInsets.only(right: 37),
                        height: 136,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(height: 5),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 350),
                              child: Align(
                                key: ValueKey(selectedWalletPk.toString() +
                                    selectedAmount.toString()),
                                alignment: Alignment.centerRight,
                                child: TextFont(
                                  textAlign: TextAlign.right,
                                  text: convertToMoney(
                                    Provider.of<AllWallets>(context),
                                    selectedAmount ?? 0,
                                    decimals: getSelectedWallet(listen: true)
                                        ?.decimals,
                                    currencyKey: getSelectedWallet(listen: true)
                                        ?.currency,
                                    addCurrencyName:
                                        ((getSelectedWallet(listen: true)
                                                ?.currency) !=
                                            Provider.of<AllWallets>(context)
                                                .indexedByPk[appStateSettings[
                                                    "selectedWalletPk"]]
                                                ?.currency),
                                  ),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 1,
                                  autoSizeText: true,
                                ),
                              ),
                            ),
                            Provider.of<AllWallets>(context).list.length <= 1 ||
                                    selectedWalletPk ==
                                        appStateSettings["selectedWalletPk"] ||
                                    ((getSelectedWallet(listen: true)
                                            ?.currency) ==
                                        Provider.of<AllWallets>(context)
                                            .indexedByPk[appStateSettings[
                                                "selectedWalletPk"]]
                                            ?.currency)
                                ? AnimatedSizeSwitcher(
                                    switcherDuration:
                                        Duration(milliseconds: 350),
                                    child: Container(
                                      key: ValueKey(
                                          selectedCategory?.name ?? ""),
                                      width: double.infinity,
                                      child: TextFont(
                                        textAlign: TextAlign.right,
                                        fontSize: 18,
                                        text: selectedCategory?.name ?? "",
                                        maxLines: 2,
                                      ),
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration: Duration(milliseconds: 350),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextFont(
                                        textAlign: TextAlign.right,
                                        text: convertToMoney(
                                          Provider.of<AllWallets>(context),
                                          (selectedAmount ?? 0) *
                                              (amountRatioToPrimaryCurrencyGivenPk(
                                                  Provider.of<AllWallets>(
                                                      context),
                                                  selectedWalletPk)),
                                        ),
                                        fontSize: 18,
                                        maxLines: 1,
                                        autoSizeText: true,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (selectedCategory != null)
            SelectSubcategoryChips(
              setSelectedSubCategory: (category) {
                setSelectedSubCategory(category, toggle: true);
              },
              selectedCategoryPk: selectedCategory!.categoryPk,
              selectedSubCategoryPk: selectedSubCategory?.categoryPk,
              padding: const EdgeInsets.only(bottom: 6),
            )
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        if (widget.transaction != null) {
          discardChangesPopup(
            context,
            previousObject: addDefaultMissingValues(widget.transaction!),
            currentObject: await createTransaction(),
          );
        } else {
          showDiscardChangesPopupIfNotEditing();
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          //Minimize keyboard when tap non interactive widget
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: PageFramework(
          belowAppBarPaddingWhenCenteredTitleSmall: 0,
          resizeToAvoidBottomInset: true,
          title: widget.transaction == null
              ? isAddedToLoanObjective
                  ? "add-record".tr()
                  : "add-transaction".tr()
              : isAddedToLoanObjective
                  ? "edit-record".tr()
                  : "edit-transaction".tr(),
          dragDownToDismiss: true,
          onBackButton: () async {
            if (widget.transaction != null) {
              discardChangesPopup(
                context,
                previousObject: addDefaultMissingValues(widget.transaction!),
                currentObject: await createTransaction(),
              );
            } else {
              showDiscardChangesPopupIfNotEditing();
            }
          },
          onDragDownToDismiss: () async {
            if (widget.transaction != null) {
              discardChangesPopup(
                context,
                previousObject: addDefaultMissingValues(widget.transaction!),
                currentObject: await createTransaction(),
              );
            } else {
              showDiscardChangesPopupIfNotEditing();
            }
          },
          actions: [
            widget.transaction != null
                ? IconButton(
                    padding: EdgeInsets.all(15),
                    tooltip: "delete-transaction".tr(),
                    onPressed: () async {
                      deleteTransactionPopup(
                        context,
                        transaction: widget.transaction!,
                        category: selectedCategory,
                        routesToPopAfterDelete: widget.routesToPopAfterDelete,
                      );
                    },
                    icon: Icon(appStateSettings["outlinedIcons"]
                        ? Icons.delete_outlined
                        : Icons.delete_rounded),
                  )
                : SizedBox.shrink()
          ],
          overlay: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Expanded(
                  child: selectedCategory == null
                      ? SaveBottomButton(
                          label: "select-category".tr(),
                          onTap: () {
                            selectCategorySequence(
                              context,
                              selectedCategory: selectedCategory,
                              setSelectedCategory: setSelectedCategory,
                              selectedSubCategory: selectedSubCategory,
                              setSelectedSubCategory: setSelectedSubCategory,
                              skipIfSet: false,
                              selectedIncomeInitial: selectedIncome,
                            );
                          },
                        )
                      : selectedAmount == null
                          ? SaveBottomButton(
                              label: "enter-amount".tr(),
                              onTap: () {
                                selectAmountPopup();
                              },
                            )
                          : SaveBottomButton(
                              label: widget.transaction != null
                                  ? "save-changes".tr()
                                  : textAddTransaction ?? "",
                              onTap: () async {
                                bool result = await addTransaction();
                                if (result) Navigator.of(context).pop();
                              },
                            ),
                ),
                AnimatedSizeSwitcher(
                  child: widget.transaction != null && selectedType != null
                      ? WidgetSizeBuilder(
                          // Change the key to re-render the widget when transaction type changed
                          key: ValueKey(widget.transaction != null
                              ? getTransactionActionNameFromType(
                                      createTransaction())
                                  .tr()
                              : ""),
                          widgetBuilder: (Size? size) {
                            return Container(
                              key: ValueKey(1),
                              width: size?.width,
                              child: SaveBottomButton(
                                margin: EdgeInsets.only(left: 5),
                                color: isTransactionActionDealtWith(
                                        createTransaction())
                                    ? Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer
                                    : null,
                                labelColor: isTransactionActionDealtWith(
                                        createTransaction())
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer
                                    : null,
                                label: widget.transaction != null
                                    ? getTransactionActionNameFromType(
                                            createTransaction())
                                        .tr()
                                    : "",
                                onTap: () async {
                                  if (widget.transaction != null &&
                                      selectedType != null) {
                                    dynamic result =
                                        await openTransactionActionFromType(
                                      context,
                                      createTransaction(),
                                      runBefore: () async {
                                        await addTransaction();
                                      },
                                    );
                                    if (result == true) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        )
                      : Container(
                          key: ValueKey(2),
                        ),
                ),
                AnimatedSizeSwitcher(
                  child: notesInputFocused && getPlatform() == PlatformOS.isIOS
                      ? WidgetSizeBuilder(
                          widgetBuilder: (Size? size) {
                            return Container(
                              key: ValueKey(1),
                              width: size?.width,
                              child: SaveBottomButton(
                                margin: EdgeInsets.only(left: 5),
                                color: isTransactionActionDealtWith(
                                        createTransaction())
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                labelColor: isTransactionActionDealtWith(
                                        createTransaction())
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
                                label: "done".tr(),
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              ),
                            );
                          },
                        )
                      : Container(
                          key: ValueKey(2),
                        ),
                ),
              ],
            ),
          ),
          listWidgets: [
            enableDoubleColumn(context) == false
                ? transactionAmountAndCategoryHeader
                : SizedBox.shrink(),
            enableDoubleColumn(context)
                ? SizedBox(height: 50)
                : SizedBox.shrink(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                enableDoubleColumn(context) == false
                    ? SizedBox.shrink()
                    : Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 900),
                          child: FractionallySizedBox(
                            widthFactor: 0.95,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 23),
                                  child: ClipRRect(
                                    child: transactionAmountAndCategoryHeader,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                transactionTextInput,
                              ],
                            ),
                          ),
                        ),
                      ),
                transactionDetailsParameters,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedWalletButton extends StatelessWidget {
  const SelectedWalletButton({
    Key? key,
    required this.onTap,
    required this.selectedWalletName,
  }) : super(key: key);
  final VoidCallback onTap;
  final String selectedWalletName;
  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      borderRadius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            ButtonIcon(
              onTap: onTap,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.account_balance_wallet_outlined
                  : Icons.account_balance_wallet_rounded,
              size: 41,
            ),
            SizedBox(width: 15),
            Expanded(
              child: TextFont(
                text: selectedWalletName,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateButton extends StatefulWidget {
  const DateButton({
    Key? key,
    required this.initialSelectedDate,
    required this.initialSelectedTime,
    required this.setSelectedDate,
    required this.setSelectedTime,
    this.internalPadding =
        const EdgeInsets.only(left: 20, top: 6, bottom: 6, right: 4),
  }) : super(key: key);
  final DateTime initialSelectedDate;
  final TimeOfDay initialSelectedTime;
  final Function(DateTime) setSelectedDate;
  final Function(TimeOfDay) setSelectedTime;
  final EdgeInsets internalPadding;

  @override
  State<DateButton> createState() => _DateButtonState();
}

class _DateButtonState extends State<DateButton> {
  late DateTime selectedDate = widget.initialSelectedDate;
  late TimeOfDay selectedTime = widget.initialSelectedTime;

  @override
  Widget build(BuildContext context) {
    String wordedDate = getWordedDateShortMore(selectedDate);
    String wordedDateShort = getWordedDateShort(selectedDate);

    return Tappable(
      color: Colors.transparent,
      onTap: () async {
        final DateTime picked =
            (await showCustomDatePicker(context, selectedDate) ?? selectedDate);
        setState(() {
          selectedDate = selectedDate.copyWith(
            year: picked.year,
            month: picked.month,
            day: picked.day,
            hour: selectedTime.hour,
            minute: selectedTime.minute,
          );
        });
        widget.setSelectedDate(selectedDate);
      },
      borderRadius: 10,
      child: Padding(
        padding: widget.internalPadding,
        child: Row(
          children: [
            IgnorePointer(
              child: ButtonIcon(
                onTap: () {},
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.calendar_month_outlined
                    : Icons.calendar_month_rounded,
                size: 41,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: TextFont(
                text: wordedDate,
                fontWeight: FontWeight.bold,
                fontSize: 23,
                minFontSize: 15,
                maxLines: 1,
                autoSizeText: true,
                overflowReplacement: TextFont(
                  text: wordedDateShort,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                  minFontSize: 15,
                  maxLines: 1,
                  autoSizeText: true,
                ),
              ),
            ),
            SizedBox(width: 10),
            Tappable(
              color: Colors.transparent,
              onTap: () async {
                TimeOfDay? newTime = await showCustomTimePicker(
                  context,
                  selectedTime,
                );
                if (newTime != null) {
                  setState(() {
                    selectedTime = newTime;
                  });
                }
                widget.setSelectedTime(newTime ?? selectedTime);
              },
              borderRadius: 5,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TimeDigits(
                  timeOfDay: TimeOfDay(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectTitle extends StatefulWidget {
  SelectTitle({
    Key? key,
    required this.setSelectedTitle,
    required this.setSelectedNote,
    this.selectedCategory,
    required this.setSelectedCategory,
    this.selectedTitle,
    required this.setSelectedTags,
    required this.noteInputController,
    this.next,
  }) : super(key: key);
  final Function(String) setSelectedTitle;
  final Function(String) setSelectedNote;
  final TransactionCategory? selectedCategory;
  final Function(TransactionCategory) setSelectedCategory;
  final Function(List<String>) setSelectedTags;
  final String? selectedTitle;
  final TextEditingController noteInputController;
  final VoidCallback? next;

  @override
  _SelectTitleState createState() => _SelectTitleState();
}

class _SelectTitleState extends State<SelectTitle> {
  int selectedIndex = 0;
  String? input = "";
  bool foundFromCategory = false;
  TransactionCategory? selectedCategory;
  TransactionAssociatedTitle? selectedAssociatedTitle;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.selectedCategory;
    input = widget.selectedTitle;
  }

  void selectTitle() {
    widget.setSelectedCategory(selectedCategory!);
    if (foundFromCategory == false)
      widget.setSelectedTitle(selectedAssociatedTitle?.title ?? "");
    else
      widget.setSelectedTitle("");
    Navigator.pop(context);
    if (widget.next != null) {
      widget.next!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "enter-title".tr(),
      hasBottomSafeArea: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: getWidthBottomSheet(context) - 36,
            child: TextInput(
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.title_outlined
                  : Icons.title_rounded,
              initialValue: widget.selectedTitle,
              autoFocus: true,
              onEditingComplete: () {
                //if selected a tag and a category is set, then go to enter amount
                //else enter amount
                if (selectedCategory?.name.toString().trim().toLowerCase() ==
                    input?.toString().trim().toLowerCase()) {
                  widget.setSelectedTitle("");
                } else {
                  widget.setSelectedTitle(
                      selectedAssociatedTitle?.title ?? input ?? "");
                }

                if (selectedCategory != null) {
                  widget.setSelectedCategory(selectedCategory!);
                }
                Navigator.pop(context);
                if (widget.next != null) {
                  widget.next!();
                }
              },
              onChanged: (text) async {
                input = text;
                widget.setSelectedTitle(input!);

                List result = await getRelatingAssociatedTitle(text);
                TransactionAssociatedTitle? selectedTitleLocal = result[0];
                String? categoryFk = result[1];
                bool foundFromCategoryLocal = result[2];

                if (selectedTitleLocal == null) {
                  selectedTitleLocal = await getLikeAssociatedTitle(text);
                  categoryFk = selectedTitleLocal?.categoryFk;
                  foundFromCategoryLocal = false;
                }

                if (categoryFk != null) {
                  TransactionCategory? foundCategory =
                      await database.getCategoryInstance(categoryFk);
                  // Update the size of the bottom sheet
                  Future.delayed(Duration(milliseconds: 100), () {
                    bottomSheetControllerGlobal.snapToExtent(0);
                  });
                  setState(() {
                    selectedCategory = foundCategory;
                    selectedAssociatedTitle = selectedTitleLocal;
                    foundFromCategory = foundFromCategoryLocal;
                  });
                } else {
                  setState(() {
                    selectedCategory = null;
                    selectedAssociatedTitle = null;
                    foundFromCategory = foundFromCategoryLocal;
                  });
                  // Update the size of the bottom sheet
                  Future.delayed(Duration(milliseconds: 300), () {
                    bottomSheetControllerGlobal.snapToExtent(0);
                  });
                }
              },
              labelText: "title-placeholder".tr(),
              padding: EdgeInsets.zero,
            ),
          ),
          AnimatedSizeSwitcher(
            sizeDuration: Duration(milliseconds: 400),
            sizeCurve: Curves.easeInOut,
            child: selectedCategory == null
                ? Container(
                    key: ValueKey(0),
                    width: getWidthBottomSheet(context) - 36,
                  )
                : Container(
                    key: ValueKey(selectedCategory!.categoryPk),
                    width: getWidthBottomSheet(context) - 36,
                    padding: EdgeInsets.only(top: 13),
                    child: Tappable(
                      borderRadius: 15,
                      color: Colors.transparent,
                      onTap: () {
                        selectTitle();
                      },
                      child: Row(
                        children: [
                          CategoryIcon(
                            categoryPk: "-1",
                            size: 40,
                            category: selectedCategory,
                            margin: EdgeInsets.zero,
                            onTap: () {
                              selectTitle();
                            },
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFont(
                                text: selectedCategory?.name ?? "",
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              !foundFromCategory
                                  ? TextFont(
                                      text:
                                          selectedAssociatedTitle?.title ?? "",
                                      fontSize: 16,
                                    )
                                  : Container(),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
          ),
          getIsFullScreen(context) ||
                  appStateSettings["askForTransactionNoteWithTitle"]
              ? Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Container(
                    width: getWidthBottomSheet(context) - 36,
                    child: TransactionNotesTextInput(
                      noteInputController: widget.noteInputController,
                      setNotesInputFocused: (isFocused) {},
                      setSelectedNoteController: (note, {setInput = true}) {
                        // Adding this line jumps cursor to the end when editing,
                        // we don't need because the noteInputController is already passed in!
                        // widget.setSelectedNote(note);

                        // Update the size of the bottom sheet
                        // Need to do it slowly because the link container size is animated slowly
                        Future.delayed(Duration(milliseconds: 200), () {
                          bottomSheetControllerGlobal.scrollTo(0);
                        });
                      },
                    ),
                  ),
                )
              : SizedBox.shrink(),
          // AnimatedSwitcher(
          //   duration: Duration(milliseconds: 300),
          //   child: CategoryIcon(
          //     key: ValueKey(selectedCategory?.categoryPk ?? ""),
          //     margin: EdgeInsets.zero,
          //     categoryPk: selectedCategory?.categoryPk ?? 0,
          //     size: 55,
          //     onTap: () {
          //       openBottomSheet(
          //         context,
          //         PopupFramework(
          //           title: "select-category".tr(),
          //           child: SelectCategory(
          //             setSelectedCategory: (TransactionCategory category) {
          //               widget.setSelectedCategory(category);
          //               setState(() {
          //                 selectedCategory = category;
          //               });
          //             },
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          Container(height: 20),
          widget.next != null
              ? Button(
                  label: "select-category".tr(),
                  width: getWidthBottomSheet(context),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.next != null) {
                      widget.next!();
                    }
                  },
                )
              : SizedBox.shrink(),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

// class SelectTag extends StatefulWidget {
//   SelectTag({Key? key, this.setSelectedCategory}) : super(key: key);
//   final Function(TransactionCategoryOld)? setSelectedCategory;

//   @override
//   _SelectTagState createState() => _SelectTagState();
// }

// class _SelectTagState extends State<SelectTag> {
//   int selectedIndex = 0;
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Center(
//         child: Wrap(
//           alignment: WrapAlignment.center,
//           spacing: 10,
//           children: listTag()
//               .asMap()
//               .map(
//                 (index, tag) => MapEntry(
//                   index,
//                   TagIcon(
//                     tag: tag,
//                     size: 17,
//                     onTap: () {},
//                   ),
//                 ),
//               )
//               .values
//               .toList(),
//         ),
//       ),
//     );
//   }
// }

class SelectText extends StatefulWidget {
  SelectText({
    Key? key,
    required this.setSelectedText,
    this.selectedText,
    this.labelText = "",
    this.next,
    this.nextWithInput,
    this.placeholder,
    this.icon,
    this.autoFocus = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.requestLateAutoFocus = false,
    this.popContext = true,
    this.popContextWhenSet = false,
    this.inputFormatters,
    this.backgroundColor,
    this.margin = const EdgeInsets.only(bottom: 14),
  }) : super(key: key);
  final Function(String) setSelectedText;
  final String? selectedText;
  final VoidCallback? next;
  final Function(String)? nextWithInput;
  final String labelText;
  final String? placeholder;
  final IconData? icon;
  final bool autoFocus;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final bool requestLateAutoFocus;
  final bool popContext;
  final bool popContextWhenSet;
  final List<TextInputFormatter>? inputFormatters;
  final Color? backgroundColor;
  final EdgeInsets margin;

  @override
  _SelectTextState createState() => _SelectTextState();
}

class _SelectTextState extends State<SelectText> {
  String? input = "";
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    input = widget.selectedText;
    _focusNode = new FocusNode();
    if (widget.requestLateAutoFocus)
      Future.delayed(Duration(milliseconds: 250), () {
        _focusNode.requestFocus();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.margin,
      width: getWidthBottomSheet(context) - 36,
      child: TextInput(
        backgroundColor: widget.backgroundColor,
        inputFormatters: widget.inputFormatters,
        focusNode: _focusNode,
        textCapitalization: widget.textCapitalization,
        icon: widget.icon != null
            ? widget.icon
            : appStateSettings["outlinedIcons"]
                ? Icons.title_outlined
                : Icons.title_rounded,
        initialValue: widget.selectedText,
        autoFocus: widget.autoFocus,
        readOnly: widget.readOnly,
        onEditingComplete: () {
          widget.setSelectedText(input ?? "");
          if (widget.popContext) {
            Navigator.pop(context);
          }
          if (widget.next != null) {
            widget.next!();
          }
          if (widget.nextWithInput != null) {
            widget.nextWithInput!(input ?? "");
          }
        },
        onChanged: (text) {
          input = text;
          widget.setSelectedText(input!);
          if (widget.popContextWhenSet) {
            Navigator.pop(context);
          }
        },
        labelText: widget.placeholder ?? widget.labelText,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class EnterTextButton extends StatefulWidget {
  const EnterTextButton({
    Key? key,
    required this.title,
    required this.placeholder,
    this.defaultValue,
    required this.setSelectedText,
    this.icon,
  }) : super(key: key);

  final String title;
  final String placeholder;
  final String? defaultValue;
  final Function(String) setSelectedText;
  final IconData? icon;

  @override
  State<EnterTextButton> createState() => _EnterTextButtonState();
}

class _EnterTextButtonState extends State<EnterTextButton> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    if (widget.defaultValue != null) {
      _textController = new TextEditingController(text: widget.defaultValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Tappable(
        color: getColor(context, "canvasContainer"),
        onTap: () {
          openBottomSheet(
            context,
            PopupFramework(
              title: widget.title,
              child: SelectText(
                setSelectedText: (text) {
                  setTextInput(_textController, text);
                  widget.setSelectedText(text);
                },
                labelText: widget.title,
                selectedText: _textController.text,
                placeholder: widget.placeholder,
              ),
            ),
          );
        },
        borderRadius: 15,
        child: IgnorePointer(
          child: TextInput(
            padding: EdgeInsets.zero,
            readOnly: true,
            labelText: widget.placeholder,
            icon: widget.icon,
            controller: _textController,
          ),
        ),
      ),
    );
  }
}

getRelatingAssociatedTitleLimited(String text) async {
  String? categoryFk;
  bool foundFromCategoryLocal = false;
  TransactionAssociatedTitle? selectedTitleLocal;

  TransactionAssociatedTitle relatingTitle;
  try {
    relatingTitle = await database.getRelatingAssociatedTitle(text);
    categoryFk = relatingTitle.categoryFk;
    selectedTitleLocal = relatingTitle;
  } catch (e) {
    print("No relating titles found!");
  }

  if (categoryFk == null) {
    TransactionCategory relatingCategory;
    try {
      relatingCategory = await database.getRelatingCategory(text);
    } catch (e) {
      print("No category names found!");
      return [selectedTitleLocal, categoryFk, foundFromCategoryLocal];
    }

    TransactionCategory category = relatingCategory;
    categoryFk = category.categoryPk;
    selectedTitleLocal = TransactionAssociatedTitle(
      associatedTitlePk: "-1",
      title: category.name,
      categoryFk: category.categoryPk,
      dateCreated: category.dateCreated,
      dateTimeModified: null,
      order: category.order,
      isExactMatch: false,
    );
    foundFromCategoryLocal = true;
  }
  return [selectedTitleLocal, categoryFk, foundFromCategoryLocal];
}

Future<TransactionAssociatedTitle?> getLikeAssociatedTitle(String text) async {
  if (text.trim() == "" || text.trim().length < 2) {
    return null;
  }
  List<TransactionAssociatedTitle> similarTitles =
      await database.getSimilarAssociatedTitles(title: text);
  return similarTitles.isEmpty ? null : similarTitles[0];
}

getRelatingAssociatedTitle(String text) async {
  String? categoryFk = null;
  TransactionAssociatedTitle? selectedTitleLocal;

  // getLikeAssociatedTitle is more efficient since it uses queries
  //
  // Alternative:
  // be more efficient when finding
  // lookup if title matches exactly category name in database
  // then get list of all associated titles that contain that title in database
  // then loop through those to see which match
  // instead of getting all then looping

  // List<TransactionAssociatedTitle> allTitles =
  //     (await database.getAllAssociatedTitles());

  // for (TransactionAssociatedTitle title in allTitles) {
  //   if (text.toLowerCase().contains(title.title.toLowerCase())) {
  //     categoryFk = title.categoryFk;
  //     selectedTitleLocal = title;
  //     break;
  //   }
  // }

  bool foundFromCategoryLocal = false;
  // if (categoryFk != null) {
  // print("SEARCHING");
  List<TransactionCategory> allCategories = (await database.getAllCategories());
  // print(allCategories);
  for (TransactionCategory category in allCategories) {
    if (text.toLowerCase().contains(category.name.toLowerCase())) {
      categoryFk = category.categoryPk;
      selectedTitleLocal = TransactionAssociatedTitle(
        associatedTitlePk: "-1",
        title: category.name,
        categoryFk: category.categoryPk,
        dateCreated: category.dateCreated,
        dateTimeModified: null,
        order: category.order,
        isExactMatch: false,
      );
      foundFromCategoryLocal = true;

      break;
    }
  }
  // }

  return [selectedTitleLocal, categoryFk, foundFromCategoryLocal];
}

Future<bool> addAssociatedTitles(
    String selectedTitle, TransactionCategory selectedCategory) async {
  if (appStateSettings["autoAddAssociatedTitles"]) {
    List result = await getRelatingAssociatedTitle(selectedTitle);
    TransactionAssociatedTitle? foundTitle = result[0];
    int length = await database.getAmountOfAssociatedTitles();

    try {
      // Should this check be moved directly into createOrUpdateAssociatedTitle?
      TransactionAssociatedTitle checkIfAlreadyExists =
          await database.getRelatingAssociatedTitleWithCategory(
              selectedTitle, selectedCategory.categoryPk);
      // This is more efficient than shifting the associated title since this uses batching
      await database.deleteAssociatedTitle(
          checkIfAlreadyExists.associatedTitlePk, checkIfAlreadyExists.order);
      int length = await database.getAmountOfAssociatedTitles();
      await database.createOrUpdateAssociatedTitle(
          checkIfAlreadyExists.copyWith(order: length));
      print("already has this title, moved to top");
      return true;
    } catch (e) {
      print(e.toString());
    }

    if (foundTitle == null ||
        (foundTitle.categoryFk != selectedCategory.categoryPk ||
                foundTitle.title.trim() != selectedTitle.trim()) &&
            !(foundTitle.categoryFk == selectedCategory.categoryPk &&
                foundTitle.title.trim() == selectedTitle.trim())) {
      //Should just add to the end but be sorted in opposite direction on edit titles page
      //Also when it loops through getRelatingAssociatedTitle it should reverse the order
      // It's way faster to avoid pushing elements all down by 1 spot
      // I think it also fixes race conditions when writing quickly to the db
      // print("successfully added title " + selectedTitle);
      //it makes sense to add a new title if the exisitng one is from a different category, it will bump this one down and take priority

      await database.createOrUpdateAssociatedTitle(
        insert: true,
        TransactionAssociatedTitle(
          associatedTitlePk: "-1",
          categoryFk: selectedCategory.categoryPk,
          isExactMatch: false,
          title: selectedTitle.trim(),
          dateCreated: DateTime.now(),
          dateTimeModified: null,
          order: length,
        ),
      );
    }
  }
  return true;
}

class SelectAddedBudget extends StatefulWidget {
  const SelectAddedBudget({
    required this.setSelectedBudget,
    this.selectedBudgetPk,
    this.extraHorizontalPadding,
    this.wrapped,
    this.horizontalBreak,
    super.key,
  });
  final Function(Budget?, {bool isSharedBudget}) setSelectedBudget;
  final String? selectedBudgetPk;
  final double? extraHorizontalPadding;
  final bool? wrapped;
  final bool? horizontalBreak;

  @override
  State<SelectAddedBudget> createState() => _SelectAddedBudgetState();
}

class _SelectAddedBudgetState extends State<SelectAddedBudget> {
  late String? selectedBudgetPk = widget.selectedBudgetPk;

  @override
  void didUpdateWidget(covariant SelectAddedBudget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedBudgetPk != widget.selectedBudgetPk) {
      setState(() {
        selectedBudgetPk = widget.selectedBudgetPk;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: database.watchAllAddableBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0) return Container();
          return HorizontalBreakAbove(
            enabled:
                enableDoubleColumn(context) && widget.horizontalBreak == true,
            child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: SelectChips(
                  allowMultipleSelected: false,
                  wrapped: widget.wrapped ?? enableDoubleColumn(context),
                  extraHorizontalPadding: widget.extraHorizontalPadding,
                  onLongPress: (Budget? item) {
                    pushRoute(
                      context,
                      AddBudgetPage(
                        budget: item,
                        routesToPopAfterDelete:
                            RoutesToPopAfterDelete.PreventDelete,
                      ),
                    );
                  },
                  extraWidget: SelectChipsAddButtonExtraWidget(
                    openPage: AddBudgetPage(
                      isAddedOnlyBudget: true,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  ),
                  items: [null, ...snapshot.data!],
                  getLabel: (Budget? item) {
                    return item?.name ?? "no-budget".tr();
                  },
                  onSelected: (Budget? item) {
                    widget.setSelectedBudget(
                      item,
                      isSharedBudget: item?.sharedKey != null,
                    );
                    setState(() {
                      selectedBudgetPk = item?.budgetPk;
                    });
                  },
                  getSelected: (Budget? item) {
                    return selectedBudgetPk == item?.budgetPk;
                  },
                  getCustomBorderColor: (Budget? item) {
                    return dynamicPastel(
                      context,
                      lightenPastel(
                        HexColor(
                          item?.colour,
                          defaultColor: Theme.of(context).colorScheme.primary,
                        ),
                        amount: 0.3,
                      ),
                      amount: 0.4,
                    );
                  },
                )),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SelectObjective extends StatefulWidget {
  const SelectObjective({
    required this.setSelectedObjective,
    this.selectedObjectivePk,
    this.extraHorizontalPadding,
    this.wrapped,
    this.horizontalBreak = false,
    super.key,
  });
  final Function(String?) setSelectedObjective;
  final String? selectedObjectivePk;
  final double? extraHorizontalPadding;
  final bool? wrapped;
  final bool horizontalBreak;

  @override
  State<SelectObjective> createState() => _SelectObjectiveState();
}

class _SelectObjectiveState extends State<SelectObjective> {
  late String? selectedObjectivePk = widget.selectedObjectivePk;

  @override
  void didUpdateWidget(covariant SelectObjective oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedObjectivePk != widget.selectedObjectivePk) {
      setState(() {
        selectedObjectivePk = widget.selectedObjectivePk;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Objective>>(
      stream: database.watchAllObjectives(
          objectiveType: ObjectiveType.goal, archivedLast: true),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0) return Container();
          return HorizontalBreakAbove(
            enabled:
                enableDoubleColumn(context) && widget.horizontalBreak == true,
            child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: SelectChips(
                  allowMultipleSelected: false,
                  wrapped: widget.wrapped ?? enableDoubleColumn(context),
                  extraHorizontalPadding: widget.extraHorizontalPadding,
                  onLongPress: (Objective? item) {
                    pushRoute(
                      context,
                      AddObjectivePage(
                        objective: item,
                        routesToPopAfterDelete:
                            RoutesToPopAfterDelete.PreventDelete,
                      ),
                    );
                  },
                  extraWidget: SelectChipsAddButtonExtraWidget(
                    openPage: AddObjectivePage(
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  ),
                  items: [null, ...snapshot.data!],
                  getLabel: (Objective? item) {
                    return item?.name ?? "no-goal".tr();
                  },
                  onSelected: (Objective? item) {
                    widget.setSelectedObjective(
                      item?.objectivePk,
                    );
                    setState(() {
                      selectedObjectivePk = item?.objectivePk;
                    });
                  },
                  getSelected: (Objective? item) {
                    return selectedObjectivePk == item?.objectivePk;
                  },
                  getCustomBorderColor: (Objective? item) {
                    return dynamicPastel(
                      context,
                      lightenPastel(
                        HexColor(
                          item?.colour,
                          defaultColor: Theme.of(context).colorScheme.primary,
                        ),
                        amount: 0.3,
                      ),
                      amount: 0.4,
                    );
                  },
                )),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SelectExcludeBudget extends StatefulWidget {
  const SelectExcludeBudget({
    required this.setSelectedExcludedBudgets,
    this.selectedExcludedBudgetPks,
    this.extraHorizontalPadding,
    this.wrapped,
    super.key,
  });
  final Function(List<String>?) setSelectedExcludedBudgets;
  final List<String>? selectedExcludedBudgetPks;
  final double? extraHorizontalPadding;
  final bool? wrapped;

  @override
  State<SelectExcludeBudget> createState() => _SelectExcludeBudgetState();
}

class _SelectExcludeBudgetState extends State<SelectExcludeBudget> {
  late List<String> selectedExcludedBudgetPks =
      widget.selectedExcludedBudgetPks ?? [];

  @override
  void didUpdateWidget(covariant SelectExcludeBudget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedExcludedBudgetPks != widget.selectedExcludedBudgetPks) {
      setState(() {
        selectedExcludedBudgetPks = widget.selectedExcludedBudgetPks ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: database.watchAllNonAddableBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0)
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: TextFont(
                text: "no-budgets-found".tr(),
                fontSize: 16,
                textAlign: TextAlign.center,
              ),
            );
          return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SelectChips(
                wrapped: widget.wrapped ?? enableDoubleColumn(context),
                extraHorizontalPadding: widget.extraHorizontalPadding,
                onLongPress: (Budget item) {
                  pushRoute(
                    context,
                    AddBudgetPage(
                      budget: item,
                      routesToPopAfterDelete:
                          RoutesToPopAfterDelete.PreventDelete,
                    ),
                  );
                },
                extraWidget: SelectChipsAddButtonExtraWidget(
                  openPage: AddBudgetPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                  ),
                ),
                items: snapshot.data!,
                getLabel: (Budget item) {
                  return item.name;
                },
                onSelected: (Budget item) {
                  // widget.setSelectedBudget(
                  //   item,
                  //   isSharedBudget: item?.sharedKey != null,
                  // );
                  // setState(() {
                  //   selectedBudgetPk = item?.budgetPk;
                  // });
                  if (selectedExcludedBudgetPks.contains(item.budgetPk)) {
                    selectedExcludedBudgetPks.remove(item.budgetPk);
                  } else {
                    selectedExcludedBudgetPks.add(item.budgetPk);
                  }
                  widget.setSelectedExcludedBudgets(selectedExcludedBudgetPks);
                },
                getSelected: (Budget item) {
                  return (selectedExcludedBudgetPks).contains(item.budgetPk);
                },
                getCustomBorderColor: (Budget? item) {
                  return dynamicPastel(
                    context,
                    lightenPastel(
                      HexColor(
                        item?.colour,
                        defaultColor: Theme.of(context).colorScheme.primary,
                      ),
                      amount: 0.3,
                    ),
                    amount: 0.4,
                  );
                },
              ));
        } else {
          return Container();
        }
      },
    );
  }
}

class HorizontalBreakAbove extends StatelessWidget {
  const HorizontalBreakAbove({
    required this.child,
    this.enabled = true,
    super.key,
  });
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled == false) return child;
    return Column(
      children: [
        // Divider(indent: 10, endIndent: 10),
        HorizontalBreak(),
        child,
      ],
    );
  }
}

class HorizontalBreak extends StatelessWidget {
  const HorizontalBreak(
      {this.padding = const EdgeInsets.symmetric(vertical: 10),
      this.color,
      super.key});
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding,
      height: 2,
      decoration: BoxDecoration(
        color: color ?? getColor(context, "dividerColor"),
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    );
  }
}

void deleteTransactionPopup(
  BuildContext context, {
  required Transaction transaction,
  required TransactionCategory? category,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  String? transactionName =
      await getTransactionLabel(transaction, category: category);
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-transaction-question".tr(),
    subtitle: transactionName,
  );
  if (action == DeletePopupAction.Delete) {
    await checkToDeleteCloselyRelatedBalanceCorrectionTransaction(context,
        transaction: transaction);
    if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
      Navigator.of(context).pop();
    }
    openLoadingPopupTryCatch(() async {
      await database.deleteTransaction(transaction.transactionPk);
      openSnackbar(
        SnackbarMessage(
          title: "deleted-transaction".tr(),
          icon: Icons.delete,
          description: transactionName,
        ),
      );
    });
  }
}

Future checkToDeleteCloselyRelatedBalanceCorrectionTransaction(
  BuildContext context, {
  required Transaction transaction,
}) async {
  if (transaction.categoryFk == "0") {
    Transaction? closelyRelatedTransferCorrectionTransaction = await database
        .getCloselyRelatedBalanceCorrectionTransaction(transaction);
    if (closelyRelatedTransferCorrectionTransaction != null) {
      await openPopup(
        context,
        title: "delete-both-transfers-question".tr(),
        description: "delete-both-transfers-question-description".tr(),
        descriptionWidget: IgnorePointer(
          child: Column(
            children: [
              HorizontalBreak(padding: EdgeInsets.only(top: 15, bottom: 10)),
              TransactionEntry(
                useHorizontalPaddingConstrained: false,
                openPage: Container(),
                transaction: transaction,
                containerColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.4),
                customPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 5),
              TransactionEntry(
                useHorizontalPaddingConstrained: false,
                openPage: Container(),
                transaction: closelyRelatedTransferCorrectionTransaction,
                containerColor: Colors.transparent,
                customPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        onCancel: () {
          Navigator.pop(context);
        },
        onCancelLabel: "only-current".tr(),
        onSubmit: () async {
          openLoadingPopupTryCatch(() async {
            await database.deleteTransaction(
                closelyRelatedTransferCorrectionTransaction.transactionPk);
          });
          Navigator.pop(context);
        },
        onSubmitLabel: "delete-both".tr(),
      );
    }
  }
}

Future deleteTransactionsPopup(
  BuildContext context, {
  required List<String> transactionPks,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-selected-transactions".tr(),
    subtitle: transactionPks.length.toString() +
        " " +
        (transactionPks.length == 1
            ? "transaction".tr().toLowerCase()
            : "transactions".tr().toLowerCase()),
  );
  if (action == DeletePopupAction.Delete) {
    if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
      Navigator.of(context).pop();
    }
    openLoadingPopupTryCatch(() async {
      await database.deleteTransactions(transactionPks);
      openSnackbar(
        SnackbarMessage(
          title: "deleted-transactions".tr(),
          icon: Icons.delete,
          description: transactionPks.length.toString() +
              " " +
              (transactionPks.length == 1
                  ? "transaction".tr().toLowerCase()
                  : "transactions".tr().toLowerCase()),
        ),
      );
    });
  }
  return action;
}

class SelectTransactionTypePopup extends StatelessWidget {
  const SelectTransactionTypePopup({
    required this.setTransactionType,
    this.selectedTransactionType,
    this.onlyShowOneTransactionType,
    this.transactionTypesToShow,
    super.key,
  });
  final Function(TransactionSpecialType? transactionType) setTransactionType;
  final TransactionSpecialType? selectedTransactionType;
  final TransactionSpecialType? onlyShowOneTransactionType;
  final List<dynamic>? transactionTypesToShow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onlyShowOneTransactionType == null)
          TransactionTypeInfoEntry(
            selectedTransactionType: selectedTransactionType,
            setTransactionType: setTransactionType,
            transactionTypesToShow: transactionTypesToShow,
            transactionType: null,
            title: "default".tr(),
            onTap: () {
              setTransactionType(null);
              Navigator.pop(context);
            },
            icon: appStateSettings["outlinedIcons"]
                ? Icons.check_circle_outlined
                : Icons.check_circle_rounded,
          ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.upcoming,
          title: "upcoming".tr(),
          childrenDescription: [
            ListItem(
              "upcoming-transaction-type-description-1".tr(),
            ),
            ListItem(
              "upcoming-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.subscription,
          title: "subscription".tr(),
          childrenDescription: [
            ListItem(
              "subscription-transaction-type-description-1".tr(),
            ),
            ListItem(
              "subscription-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.repetitive,
          title: "repetitive".tr(),
          childrenDescription: [
            ListItem(
              "repetitive-transaction-type-description-1".tr(),
            ),
            ListItem(
              "repetitive-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.credit,
          title: "lent".tr(),
          childrenDescription: [
            ListItem(
              "lent-transaction-type-description-1".tr(),
            ),
            ListItem(
              "lent-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.debt,
          title: "borrowed".tr(),
          childrenDescription: [
            ListItem(
              "borrowed-transaction-type-description-1".tr(),
            ),
            ListItem(
              "borrowed-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        SizedBox(height: 13),
        Tappable(
          color: dynamicPastel(
            context,
            Theme.of(context).colorScheme.secondaryContainer,
            amount: 0.5,
          ),
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              children: [
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextFont(
                    maxLines: 5,
                    fontSize: 16,
                    textAlign: TextAlign.center,
                    text: "mark-transaction-help-description".tr(),
                  ),
                ),
                SizedBox(height: 18),
                IgnorePointer(
                  child: TransactionEntry(
                    highlightActionButton: true,
                    useHorizontalPaddingConstrained: false,
                    openPage: Container(),
                    transaction: Transaction(
                      transactionPk: "-1",
                      name: "",
                      amount: 100,
                      note: "",
                      categoryFk: "-1",
                      walletFk: appStateSettings["selectedWalletPk"],
                      dateCreated: DateTime.now(),
                      income: false,
                      paid: false,
                      skipPaid: false,
                      type: TransactionSpecialType.upcoming,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (TransactionSpecialType type
                        in TransactionSpecialType.values)
                      IgnorePointer(
                        child: TransactionEntryActionButton(
                          allowOpenIntoObjectiveLoanPage: false,
                          transaction: Transaction(
                            transactionPk: "-1",
                            name: "",
                            amount: 0,
                            note: "",
                            categoryFk: "-1",
                            subCategoryFk: null,
                            walletFk: "",
                            dateCreated: DateTime.now(),
                            income: false,
                            paid: [
                              TransactionSpecialType.credit,
                              TransactionSpecialType.debt
                            ].contains(type)
                                ? true
                                : false,
                            skipPaid: false,
                            type: type,
                          ),
                          iconColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionTypeInfoEntry extends StatelessWidget {
  final Function(TransactionSpecialType? transactionType) setTransactionType;
  final TransactionSpecialType? selectedTransactionType;
  final List<Widget>? childrenDescription;
  final String title;
  final IconData? icon;
  final TransactionSpecialType? transactionType;
  final TransactionSpecialType? onlyShowOneTransactionType;
  final VoidCallback? onTap;
  final List<dynamic>? transactionTypesToShow;

  TransactionTypeInfoEntry({
    Key? key,
    required this.setTransactionType,
    required this.selectedTransactionType,
    this.childrenDescription,
    required this.title,
    this.icon,
    required this.transactionType,
    this.onlyShowOneTransactionType,
    this.onTap,
    this.transactionTypesToShow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactionTypesToShow?.contains(transactionType) == false)
      return SizedBox.shrink();
    if (onlyShowOneTransactionType == null ||
        onlyShowOneTransactionType == transactionType) {
      return Padding(
        padding: const EdgeInsets.only(top: 13),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButtonStacked(
                filled: selectedTransactionType == transactionType,
                alignLeft: true,
                alignBeside: true,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                text: title,
                iconData: icon ?? getTransactionTypeIcon(transactionType),
                onTap: onTap ??
                    () {
                      setTransactionType(transactionType);
                      Navigator.pop(context);
                    },
                afterWidget: childrenDescription == null
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: childrenDescription ?? [],
                      ),
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

class MainAndSubcategory {
  MainAndSubcategory(
      {this.main, this.sub, this.ignoredSubcategorySelection = false});

  TransactionCategory? main;
  TransactionCategory? sub;
  bool ignoredSubcategorySelection;

  @override
  String toString() {
    return 'main: $main, sub: $sub, ignoredSubcategorySelection: $ignoredSubcategorySelection';
  }
}

// ignoredSubcategorySelection is true if the subcategory is skipped
Future<MainAndSubcategory> selectCategorySequence(
  BuildContext context, {
  Widget? extraWidgetAfter,
  bool? skipIfSet,
  required TransactionCategory? selectedCategory,
  required Function(TransactionCategory)? setSelectedCategory,
  required TransactionCategory? selectedSubCategory,
  required Function(TransactionCategory?)? setSelectedSubCategory,
  Function(bool?)? setSelectedIncome,
  required bool?
      selectedIncomeInitial, // if this is null, always show all categories
  String? subtitle,
}) async {
  MainAndSubcategory mainAndSubcategory = MainAndSubcategory();
  dynamic result = await openBottomSheet(
    context,
    SelectCategoryWithIncomeExpenseSelector(
      subtitle: subtitle,
      extraWidgetAfter: extraWidgetAfter,
      skipIfSet: skipIfSet,
      selectedCategory: selectedCategory,
      setSelectedCategory: setSelectedCategory,
      selectedSubCategory: selectedSubCategory,
      setSelectedSubCategory: setSelectedSubCategory,
      setSelectedIncome: setSelectedIncome,
      selectedIncomeInitial: selectedIncomeInitial,
    ),
  );
  if (result != null && result is TransactionCategory) {
    mainAndSubcategory.main = result;
    int subCategoriesOfMain = await database
        .getAmountOfSubCategories(mainAndSubcategory.main!.categoryPk);
    if (subCategoriesOfMain > 0) {
      dynamic result2 = await openBottomSheet(
        context,
        PopupFramework(
          title: "select-subcategory".tr(),
          child: SelectCategory(
            skipIfSet: skipIfSet,
            selectedCategory: selectedSubCategory,
            setSelectedCategory: setSelectedSubCategory,
            mainCategoryPks: [mainAndSubcategory.main!.categoryPk],
            allowRearrange: false,
            header: [
              LayoutBuilder(builder: (context, constraints) {
                return Column(
                  children: [
                    Tappable(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      onTap: () {
                        if (setSelectedSubCategory != null)
                          setSelectedSubCategory(null);
                        Navigator.pop(context, false);
                      },
                      borderRadius: 18,
                      child: Container(
                        height: constraints.maxWidth < 70
                            ? constraints.maxWidth
                            : 66,
                        width: constraints.maxWidth < 70
                            ? constraints.maxWidth
                            : 66,
                        child: Center(
                          child: Icon(
                            appStateSettings["outlinedIcons"]
                                ? Icons.block_outlined
                                : Icons.block_rounded,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      child: Center(
                        child: TextFont(
                          textAlign: TextAlign.center,
                          text: "none".tr(),
                          fontSize: 10,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
      if (result2 is TransactionCategory) {
        mainAndSubcategory.sub = result2;
      }
      if (result2 == null) {
        mainAndSubcategory.ignoredSubcategorySelection = true;
      }
      if (result2 == false) {
        return mainAndSubcategory;
      }
    }
  }
  return mainAndSubcategory;
}

class SelectCategoryWithIncomeExpenseSelector extends StatefulWidget {
  const SelectCategoryWithIncomeExpenseSelector({
    required this.extraWidgetAfter,
    required this.skipIfSet,
    required this.selectedCategory,
    required this.setSelectedCategory,
    required this.selectedSubCategory,
    required this.setSelectedSubCategory,
    required this.setSelectedIncome,
    required this.selectedIncomeInitial,
    this.subtitle,
    super.key,
  });

  final Widget? extraWidgetAfter;
  final bool? skipIfSet;
  final TransactionCategory? selectedCategory;
  final Function(TransactionCategory)? setSelectedCategory;
  final TransactionCategory? selectedSubCategory;
  final Function(TransactionCategory?)? setSelectedSubCategory;
  final Function(bool?)? setSelectedIncome;
  final bool? selectedIncomeInitial;
  final String? subtitle;

  @override
  State<SelectCategoryWithIncomeExpenseSelector> createState() =>
      _SelectCategoryWithIncomeExpenseSelectorState();
}

class _SelectCategoryWithIncomeExpenseSelectorState
    extends State<SelectCategoryWithIncomeExpenseSelector> {
  late bool? selectedIncome =
      appStateSettings["showAllCategoriesWhenSelecting"] == true
          ? null
          : widget.selectedIncomeInitial;

  void setSelectedIncome(bool? value) {
    if (widget.setSelectedIncome != null) widget.setSelectedIncome!(value);
    setState(() {
      selectedIncome = value;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      bottomSheetControllerGlobal.snapToExtent(0,
          duration: Duration(milliseconds: 400));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: widget.setSelectedIncome == null ? "select-category".tr() : null,
      subtitle: widget.subtitle,
      hasPadding: false,
      outsideExtraWidget: widget.setSelectedIncome != null
          // Hide option to rearrange because income/expense selector is shown
          ? null
          : CustomPopupMenuButton(
              showButtons: false,
              keepOutFirst: false,
              buttonPadding: getPlatform() == PlatformOS.isIOS ? 15 : 20,
              items: [
                if (widget.selectedIncomeInitial != null)
                  DropdownItemMenu(
                    id: "toggle-selected-income",
                    label: selectedIncome == null
                        ? (widget.selectedIncomeInitial == true
                            ? "only-income-categories".tr()
                            : "only-expense-categories".tr())
                        : "show-all-categories".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.grid_on_outlined
                        : Icons.grid_on_rounded,
                    action: () {
                      if (selectedIncome == null) {
                        setSelectedIncome(widget.selectedIncomeInitial);
                        updateSettings("showAllCategoriesWhenSelecting", false,
                            updateGlobalState: false);
                      } else {
                        setSelectedIncome(null);
                        updateSettings("showAllCategoriesWhenSelecting", true,
                            updateGlobalState: false);
                      }
                    },
                  ),
                DropdownItemMenu(
                  id: "reorder-categories",
                  label: "reorder-categories".tr(),
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.flip_to_front_outlined
                      : Icons.flip_to_front_rounded,
                  action: () async {
                    Navigator.pop(context);
                    openBottomSheet(context, ReorderCategoriesPopup());
                  },
                ),
              ],
            ),
      child: Column(
        children: [
          if (widget.setSelectedIncome != null)
            IncomeExpenseButtonSelector(setSelectedIncome: (value) {
              setSelectedIncome(value);
            }),
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18),
            child: SelectCategory(
              skipIfSet: widget.skipIfSet,
              selectedCategory: widget.selectedCategory,
              setSelectedCategory: widget.setSelectedCategory,
              selectedIncome: selectedIncome,
              allowRearrange: false,
              // selectedIncome == null && widget.selectedIncomeInitial == null,
            ),
          ),
          if (widget.extraWidgetAfter != null) widget.extraWidgetAfter!,
        ],
      ),
    );
  }
}

class ReorderCategoriesPopup extends StatelessWidget {
  const ReorderCategoriesPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "reorder-categories".tr(),
      subtitle: "drag-and-drop-categories-to-rearrange".tr(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SelectCategory(
              skipIfSet: false,
              selectedIncome: null, // needs to be null
              addButton: false,
            ),
          ),
          Button(
            label: "done".tr(),
            onTap: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}

class LinkInNotes extends StatelessWidget {
  const LinkInNotes({
    required this.link,
    required this.onTap,
    this.onLongPress,
    this.iconData,
    this.iconDataAfter,
    this.color,
    this.extraWidget,
    super.key,
  });
  final String link;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? iconData;
  final IconData? iconDataAfter;
  final Color? color;
  final Widget? extraWidget;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      onLongPress: onLongPress,
      color: color ??
          darkenPastel(
            (appStateSettings["materialYou"]
                ? Theme.of(context).colorScheme.secondaryContainer
                : getColor(context, "canvasContainer")),
            amount:
                Theme.of(context).brightness == Brightness.light ? 0.07 : 0.25,
          ),
      child: Padding(
        padding: EdgeInsets.only(
            left: 15, right: extraWidget == null ? 15 : 0, top: 10, bottom: 10),
        child: Row(
          children: [
            Icon(
              iconData ??
                  (appStateSettings["outlinedIcons"]
                      ? Icons.link_outlined
                      : Icons.link_rounded),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFont(
                text: getDomainNameFromURL(link),
                fontSize: 16,
                maxLines: 1,
              ),
            ),
            if (iconDataAfter != null) Icon(iconDataAfter),
            if (extraWidget != null) extraWidget!,
          ],
        ),
      ),
    );
  }
}

class TransactionNotesTextInput extends StatefulWidget {
  const TransactionNotesTextInput({
    required this.noteInputController,
    required this.setNotesInputFocused,
    required this.setSelectedNoteController,
    super.key,
  });
  final TextEditingController noteInputController;
  final Function(bool) setNotesInputFocused;
  final Function(String note, {bool setInput}) setSelectedNoteController;

  @override
  State<TransactionNotesTextInput> createState() =>
      _TransactionNotesTextInputState();
}

class _TransactionNotesTextInputState extends State<TransactionNotesTextInput> {
  bool notesInputFocused = false;
  late List<String> extractedLinks =
      extractLinks(widget.noteInputController.text);

  void addAttachmentLinkToNote(String? link) {
    if (link == null) return;
    String noteUpdated = widget.noteInputController.text +
        (widget.noteInputController.text == "" ? "" : "\n") +
        (link) +
        " ";

    widget.setSelectedNoteController(noteUpdated);
    updateExtractedLinks(noteUpdated);
  }

  void removeLinkFromNote(String link) {
    String originalText = widget.noteInputController.text;
    String noteUpdated =
        widget.noteInputController.text.replaceAll(link + " ", "");
    if (noteUpdated == originalText) {
      noteUpdated = widget.noteInputController.text.replaceAll(link + "\n", "");
    }
    widget.setSelectedNoteController(noteUpdated);
    updateExtractedLinks(noteUpdated);
  }

  void updateExtractedLinks(String text) {
    List<String> newlyExtractedLinks = extractLinks(text);
    if (newlyExtractedLinks.toString() != extractedLinks.toString()) {
      setState(() {
        extractedLinks = newlyExtractedLinks;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.noteInputController.addListener(_printLatestValue);
  }

  @override
  void dispose() {
    widget.noteInputController.removeListener(_printLatestValue);
    super.dispose();
  }

  void _printLatestValue() {
    updateExtractedLinks(widget.noteInputController.text);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(getPlatform() == PlatformOS.isIOS ? 8 : 15),
      child: Column(
        children: [
          Focus(
            child: TextInput(
              borderRadius: BorderRadius.zero,
              padding: EdgeInsets.zero,
              labelText: "notes-placeholder".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.sticky_note_2_outlined
                  : Icons.sticky_note_2_rounded,
              controller: widget.noteInputController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
              onChanged: (text) async {
                widget.setSelectedNoteController(text, setInput: false);
                updateExtractedLinks(text);
              },
            ),
            onFocusChange: (hasFocus) {
              if (hasFocus == false && notesInputFocused == true) {
                notesInputFocused = false;
                widget.setNotesInputFocused(false);
              } else if (hasFocus == true && notesInputFocused == false) {
                notesInputFocused = true;
                widget.setNotesInputFocused(true);
              }
            },
          ),
          HorizontalBreak(
            padding: EdgeInsets.zero,
            color: dynamicPastel(
              context,
              Theme.of(context).colorScheme.secondaryContainer,
              amount: 0.1,
              inverse: true,
            ),
          ),
          LinkInNotes(
            color: (appStateSettings["materialYou"]
                ? Theme.of(context).colorScheme.secondaryContainer
                : getColor(context, "canvasContainer")),
            link: "add-attachment".tr(),
            iconData: appStateSettings["outlinedIcons"]
                ? Icons.attachment_outlined
                : Icons.attachment_rounded,
            iconDataAfter: appStateSettings["outlinedIcons"]
                ? Icons.add_outlined
                : Icons.add_rounded,
            onTap: () async {
              openBottomSheet(
                context,
                // We need to use the custom controller because the ask for title popup uses the default controller
                // Which we need to control separately
                useCustomController: true,
                reAssignBottomSheetControllerGlobal: false,
                PopupFramework(
                  title: "add-attachment".tr().capitalizeFirstofEach,
                  subtitle: "add-attachment-description".tr(),
                  child: Column(
                    children: [
                      if (kIsWeb == false)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButtonStacked(
                                  filled: false,
                                  alignLeft: true,
                                  alignBeside: true,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 20),
                                  text: "take-photo".tr(),
                                  iconData: appStateSettings["outlinedIcons"]
                                      ? Icons.camera_alt_outlined
                                      : Icons.camera_alt_rounded,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    if (await checkLockedFeatureIfInDemoMode(
                                            context) ==
                                        true) {
                                      String? result = await getPhotoAndUpload(
                                          source: ImageSource.camera);
                                      addAttachmentLinkToNote(result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (kIsWeb == false)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButtonStacked(
                                  filled: false,
                                  alignLeft: true,
                                  alignBeside: true,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 20),
                                  text: "select-photo".tr(),
                                  iconData: appStateSettings["outlinedIcons"]
                                      ? Icons.photo_library_outlined
                                      : Icons.photo_library_rounded,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    if (await checkLockedFeatureIfInDemoMode(
                                            context) ==
                                        true) {
                                      String? result = await getPhotoAndUpload(
                                          source: ImageSource.gallery);
                                      addAttachmentLinkToNote(result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButtonStacked(
                                filled: false,
                                alignLeft: true,
                                alignBeside: true,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 20),
                                text: "select-file".tr(),
                                iconData: appStateSettings["outlinedIcons"]
                                    ? Icons.file_open_outlined
                                    : Icons.file_open_rounded,
                                onTap: () async {
                                  Navigator.pop(context);
                                  if (await checkLockedFeatureIfInDemoMode(
                                          context) ==
                                      true) {
                                    String? result = await getFileAndUpload();
                                    addAttachmentLinkToNote(result);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedSizeSwitcher(
            child: extractedLinks.length <= 0
                ? Container(
                    key: ValueKey(1),
                  )
                : Column(
                    children: [
                      for (String link in extractedLinks)
                        LinkInNotes(
                          link: link,
                          onLongPress: () {
                            copyToClipboard(link);
                          },
                          onTap: () {
                            openUrl(link);
                          },
                          extraWidget: Padding(
                            padding: const EdgeInsets.only(right: 11, left: 5),
                            child: IconButtonScaled(
                              iconData: appStateSettings["outlinedIcons"]
                                  ? Icons.remove_outlined
                                  : Icons.remove_rounded,
                              iconSize: 16,
                              scale: 1.6,
                              onTap: () {
                                openPopup(
                                  context,
                                  icon: appStateSettings["outlinedIcons"]
                                      ? Icons.link_off_outlined
                                      : Icons.link_off_rounded,
                                  title: "remove-link-question".tr(),
                                  description: "remove-link-description".tr(),
                                  onCancel: () {
                                    Navigator.pop(context);
                                  },
                                  onCancelLabel: "cancel".tr(),
                                  onSubmit: () {
                                    removeLinkFromNote(link);
                                    Navigator.pop(context);
                                  },
                                  onSubmitLabel: "remove".tr(),
                                );
                              },
                            ),
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

Future<void> selectPeriodLength({
  required BuildContext context,
  required int selectedPeriodLength,
  required setSelectedPeriodLength(double period),
}) async {
  openBottomSheet(
    context,
    PopupFramework(
      title: "enter-period-length".tr(),
      child: SelectAmountValue(
        amountPassed: selectedPeriodLength.toString(),
        setSelectedAmount: (amount, _) {
          setSelectedPeriodLength(amount);
        },
        next: () async {
          Navigator.pop(context);
        },
        nextLabel: "set-amount".tr(),
      ),
    ),
  );
}

Future<void> selectRecurrence(
    {required BuildContext context,
    required String selectedRecurrence,
    required int selectedPeriodLength,
    required onChanged(
      String selectedRecurrence,
      BudgetReoccurence selectedRecurrenceEnum,
      String selectedRecurrenceDisplay,
    )}) async {
  openBottomSheet(
    context,
    PopupFramework(
      title: "select-period".tr(),
      child: RadioItems(
        items: ["Daily", "Weekly", "Monthly", "Yearly"],
        initial: selectedRecurrence,
        displayFilter: (item) {
          return item.toString().toLowerCase().tr();
        },
        onChanged: (value) {
          String selectedRecurrence = value;
          BudgetReoccurence selectedRecurrenceEnum = enumRecurrence[value];
          String selectedRecurrenceDisplay;
          if (selectedPeriodLength == 1) {
            selectedRecurrenceDisplay = nameRecurrence[value].toString().tr();
          } else {
            selectedRecurrenceDisplay = namesRecurrence[value].toString().tr();
          }
          onChanged(selectedRecurrence, selectedRecurrenceEnum,
              selectedRecurrenceDisplay);
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

void setSelectedPeriodLength({
  required double period,
  required String selectedRecurrence,
  required setPeriodLength(
    int selectedPeriodLength,
    String selectedRecurrenceDisplay,
  ),
}) {
  int selectedPeriodLength;
  String selectedRecurrenceDisplay;
  try {
    selectedPeriodLength = period.toInt();

    if (selectedPeriodLength == 1) {
      selectedRecurrenceDisplay = nameRecurrence[selectedRecurrence];
    } else {
      selectedRecurrenceDisplay = namesRecurrence[selectedRecurrence];
    }
    setPeriodLength(selectedPeriodLength, selectedRecurrenceDisplay);
  } catch (e) {
    selectedPeriodLength = 0;
    if (selectedPeriodLength == 1) {
      selectedRecurrenceDisplay = nameRecurrence[selectedRecurrence];
    } else {
      selectedRecurrenceDisplay = namesRecurrence[selectedRecurrence];
    }
    setPeriodLength(selectedPeriodLength, selectedRecurrenceDisplay);
  }
  return;
}

class SelectSubcategoryChips extends StatelessWidget {
  const SelectSubcategoryChips(
      {required this.selectedCategoryPk,
      required this.selectedSubCategoryPk,
      required this.setSelectedSubCategory,
      this.padding = EdgeInsets.zero,
      super.key});
  final String selectedCategoryPk;
  final String? selectedSubCategoryPk;
  final Function(TransactionCategory category) setSelectedSubCategory;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionCategory>>(
      stream: database.watchAllSubCategoriesOfMainCategory(selectedCategoryPk),
      builder: (context, snapshot) {
        List<TransactionCategory> subCategories = snapshot.data ?? [];
        return AnimatedSizeSwitcher(
          child: (subCategories.length <= 0)
              ? Container()
              : Column(
                  children: [
                    Padding(
                      padding: padding,
                      child: SelectChips(
                        allowMultipleSelected: false,
                        selectedColor:
                            Theme.of(context).canvasColor.withOpacity(0.6),
                        onLongPress: (category) {
                          pushRoute(
                            context,
                            AddCategoryPage(
                              category: category,
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.One,
                            ),
                          );
                        },
                        items: subCategories,
                        getSelected: (TransactionCategory category) {
                          return selectedSubCategoryPk == category.categoryPk;
                        },
                        onSelected: (TransactionCategory category) {
                          setSelectedSubCategory(category);
                        },
                        getCustomSelectedColor: (TransactionCategory category) {
                          return dynamicPastel(
                            context,
                            lightenPastel(
                              HexColor(
                                category.colour,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              amount: 0.3,
                            ),
                            amount: 0.5,
                          ).withOpacity(0.7);
                        },
                        getCustomBorderColor: (TransactionCategory category) {
                          return dynamicPastel(
                            context,
                            lightenPastel(
                              HexColor(
                                category.colour,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              amount: 0.3,
                            ),
                            amount: 0.4,
                          );
                        },
                        getLabel: (TransactionCategory category) {
                          return category.name;
                        },
                        extraWidget: SelectChipsAddButtonExtraWidget(
                          openPage: AddCategoryPage(
                            routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                            mainCategoryPkWhenSubCategory: selectedCategoryPk,
                          ),
                        ),
                        getAvatar: (TransactionCategory category) {
                          return LayoutBuilder(builder: (context, constraints) {
                            return CategoryIcon(
                              categoryPk: "-1",
                              category: category,
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
                    ),
                  ],
                ),
        );
      },
    );
  }
}

List<dynamic>
    getTransactionSpecialTypesToShowGivenInitialTypeWhenAddingTransaction(
        TransactionSpecialType? transactionType, bool isAddedToLoanObjective) {
  List<dynamic> defaultList = [
    null,
    ...TransactionSpecialType.values,
    "installments"
  ];
  if (isAddedToLoanObjective)
    return [
      null,
      TransactionSpecialType.upcoming,
      TransactionSpecialType.repetitive,
      TransactionSpecialType.subscription,
    ];
  else if (transactionType == null)
    return defaultList;
  else if ([TransactionSpecialType.credit, TransactionSpecialType.debt]
      .contains(transactionType))
    return [TransactionSpecialType.credit, TransactionSpecialType.debt];
  else if ([
    TransactionSpecialType.subscription,
  ].contains(transactionType))
    return [TransactionSpecialType.subscription];
  else if ([
    TransactionSpecialType.upcoming,
    TransactionSpecialType.repetitive,
    TransactionSpecialType.subscription,
  ].contains(transactionType))
    return [
      TransactionSpecialType.upcoming,
      TransactionSpecialType.repetitive,
      TransactionSpecialType.subscription
    ];
  return defaultList;
}
