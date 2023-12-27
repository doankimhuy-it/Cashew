import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/edit_objectives_page.dart';
import 'package:budget/pages/premium_page.dart';
import 'package:budget/struct/currency_functions.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/category_icon.dart';
import 'package:budget/widgets/dropdown_select.dart';
import 'package:budget/widgets/extra_info_boxes.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/widgets/income_expense_tab_selector.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/save_bottom_button.dart';
import 'package:budget/widgets/select_amount.dart';
import 'package:budget/widgets/select_category.dart';
import 'package:budget/widgets/select_category_image.dart';
import 'package:budget/widgets/select_color.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/util/show_date_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/list_item.dart';
import 'package:budget/widgets/outlined_button_stacked.dart';
import 'package:budget/widgets/select_date_range.dart';
import 'package:budget/widgets/tappable_text_entry.dart';

class AddObjectivePage extends StatefulWidget {
  const AddObjectivePage({
    super.key,
    this.objective,
    required this.routesToPopAfterDelete,
    this.objectiveType = ObjectiveType.goal,
    this.selectedIncome,
  });

  //When a wallet is passed in, we are editing that wallet
  final Objective? objective;
  final RoutesToPopAfterDelete routesToPopAfterDelete;
  final ObjectiveType objectiveType;
  final bool? selectedIncome;

  @override
  _AddObjectivePageState createState() => _AddObjectivePageState();
}

class _AddObjectivePageState extends State<AddObjectivePage>
    with SingleTickerProviderStateMixin {
  bool? canAddObjective;

  String? selectedTitle;
  Color? selectedColor;
  late String? selectedImage = widget.objective == null ? "image.png" : null;
  String? selectedEmoji;
  double selectedAmount = 0;
  DateTime selectedStartDate = DateTime.now();
  DateTime? selectedEndDate;
  late bool selectedIncome = widget.selectedIncome ?? true;
  bool selectedPin = true;
  String selectedWalletPk = appStateSettings["selectedWalletPk"];

  final FocusNode _titleFocusNode = FocusNode();
  late final TabController _incomeTabController =
      TabController(length: 2, vsync: this);

  late ObjectiveType objectiveType =
      widget.objective?.type ?? widget.objectiveType;

  setSelectedWalletPk(String walletPkPassed) {
    setState(() {
      selectedWalletPk = walletPkPassed;
    });
  }

  void setSelectedTitle(String title) {
    setState(() {
      selectedTitle = title;
    });
    determineBottomButton();
    return;
  }

  void setSelectedImage(String? image) {
    setState(() {
      selectedImage = (image ?? "").replaceFirst("assets/categories/", "");
    });
    determineBottomButton();
    return;
  }

  void setSelectedEmoji(String? emoji) {
    setState(() {
      selectedEmoji = emoji;
    });
    determineBottomButton();
    return;
  }

  void setSelectedColor(Color? color) {
    setState(() {
      selectedColor = color;
    });
    determineBottomButton();
    return;
  }

  void setSelectedAmount(double amount) {
    setState(() {
      selectedAmount = amount;
    });
    determineBottomButton();
    return;
  }

  void setSelectedIncome(bool income) {
    setState(() {
      selectedIncome = income;
    });
    determineBottomButton();
    return;
  }

  Future<void> selectAmount(BuildContext context) async {
    openBottomSheet(
      context,
      fullSnap: true,
      PopupFramework(
        title: "enter-amount".tr(),
        underTitleSpace: false,
        hasPadding: false,
        child: SelectAmount(
          hideWalletPickerIfOneCurrency: true,
          onlyShowCurrencyIcon: true,
          amountPassed: selectedAmount.toString(),
          setSelectedAmount: (amount, calculation) {
            setSelectedAmount(amount.abs());
            setState(() {
              selectedAmount = amount.abs();
            });
            determineBottomButton();
          },
          next: () async {
            Navigator.pop(context);
          },
          nextLabel: "set-amount".tr(),
          enableWalletPicker: true,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          setSelectedWalletPk: (walletPk) {
            setState(() {
              selectedWalletPk = walletPk;
            });
          },
          walletPkForCurrency: selectedWalletPk,
          selectedWalletPk: selectedWalletPk,
        ),
      ),
    );
  }

  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked =
        await showCustomDatePicker(context, selectedStartDate);
    setSelectedStartDate(picked);
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked =
        await showCustomDatePicker(context, selectedEndDate ?? DateTime.now());
    if (picked != null) setSelectedEndDate(picked);
  }

  setSelectedStartDate(DateTime? date) {
    if (date != null && date != selectedStartDate) {
      setState(() {
        selectedStartDate = date;
      });
    }
    determineBottomButton();
  }

  setSelectedEndDate(DateTime? date) {
    if (date != selectedEndDate) {
      setState(() {
        selectedEndDate = date;
      });
    }
    determineBottomButton();
  }

  Future addObjective() async {
    MainAndSubcategory? mainAndSubcategory;
    if (widget.objective == null &&
        widget.objectiveType == ObjectiveType.loan) {
      mainAndSubcategory = await selectCategorySequence(
        context,
        selectedCategory: null,
        setSelectedCategory: (_) {},
        selectedSubCategory: null,
        setSelectedSubCategory: (_) {},
        selectedIncomeInitial: null,
        subtitle: "select-first-transaction-category".tr(),
      );
      if (mainAndSubcategory.main == null) {
        return;
      }
    }

    print("Added objective");
    int rowId = await database.createOrUpdateObjective(
        insert: widget.objective == null, await createObjective());

    // Create the initial transaction if it is a loan
    if (widget.objective == null &&
        widget.objectiveType == ObjectiveType.loan) {
      final Objective objectiveJustAdded =
          await database.getObjectiveFromRowId(rowId);
      if (mainAndSubcategory?.main != null) {
        await database.createOrUpdateTransaction(
          insert: true,
          Transaction(
            transactionPk: "-1",
            name: "initial-record".tr(),
            note: "",
            amount: selectedAmount.abs() * (!selectedIncome ? 1 : -1),
            categoryFk: mainAndSubcategory!.main!.categoryPk,
            subCategoryFk: mainAndSubcategory.sub?.categoryPk,
            walletFk: selectedWalletPk,
            dateCreated: DateTime.now(),
            income: !selectedIncome,
            paid: true,
            skipPaid: false,
            type: null,
            objectiveLoanFk: objectiveJustAdded.objectivePk,
          ),
        );
      }
    }
    Navigator.pop(context);
  }

  Future<Objective> createObjective() async {
    int numberOfObjectives = (await database.getTotalCountOfObjectives(
            objectiveType:
                widget.objective?.type ?? widget.objectiveType))[0] ??
        0;
    if (selectedEndDate != null &&
        selectedStartDate.isAfter(selectedEndDate!)) {
      selectedEndDate = null;
    }
    return Objective(
      objectivePk:
          widget.objective != null ? widget.objective!.objectivePk : "-1",
      name: selectedTitle ?? "",
      colour: toHexString(selectedColor),
      dateCreated: selectedStartDate,
      endDate: selectedEndDate,
      dateTimeModified: null,
      order: widget.objective != null
          ? widget.objective!.order
          : numberOfObjectives,
      emojiIconName: selectedEmoji,
      iconName: selectedImage,
      amount: selectedAmount,
      income: selectedIncome,
      pinned: selectedPin,
      walletFk: selectedWalletPk,
      archived: widget.objective?.archived ?? false,
      type: widget.objective?.type ?? widget.objectiveType,
    );
  }

  Objective? objectiveInitial;

  void showDiscardChangesPopupIfNotEditing() async {
    Objective objectiveCreated = await createObjective();
    objectiveCreated =
        objectiveCreated.copyWith(dateCreated: objectiveInitial?.dateCreated);
    if (objectiveCreated != objectiveInitial && widget.objective == null) {
      discardChangesPopup(context, forceShow: true);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.objective != null) {
      //We are editing an objective
      //Fill in the information from the passed in objective
      //Outside of future.delayed because of textinput when in web mode initial value
      selectedTitle = widget.objective!.name;

      selectedColor = widget.objective!.colour == null
          ? null
          : HexColor(widget.objective!.colour);
      selectedImage = widget.objective!.iconName;
      selectedEmoji = widget.objective!.emojiIconName;
      selectedStartDate = widget.objective!.dateCreated;
      selectedEndDate = widget.objective!.endDate;
      selectedAmount = widget.objective!.amount;
      selectedPin = widget.objective!.pinned;
      selectedWalletPk = widget.objective!.walletFk;

      selectedIncome = widget.objective!.income;
      if (widget.objective?.income == false) {
        _incomeTabController.animateTo(1);
      } else {
        _incomeTabController.animateTo(0);
      }
    } else {
      Future.delayed(Duration.zero, () async {
        if (widget.objective == null) {
          bool result = await premiumPopupObjectives(context,
              objectiveType: objectiveType);
          if (result == true && objectiveType != ObjectiveType.loan) {
            openBottomSheet(
              context,
              fullSnap: false,
              SelectObjectiveTypePopup(
                setObjectiveIncome: setSelectedIncome,
              ),
            );
          }
        }
      });
    }
    if (widget.objective == null) {
      Future.delayed(Duration.zero, () async {
        objectiveInitial = await createObjective();
      });
    }
  }


  determineBottomButton() {
    if (selectedTitle != null) {
      if (canAddObjective != true) {
        setState(() {
          canAddObjective = true;
        });
      }
    } else {
      if (canAddObjective != false) {
        setState(() {
          canAddObjective = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.objective != null) {
          discardChangesPopup(
            context,
            previousObject: widget.objective,
            currentObject: await createObjective(),
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
          horizontalPadding: getHorizontalPaddingConstrained(context),
          resizeToAvoidBottomInset: true,
          dragDownToDismiss: true,
          title: objectiveType == ObjectiveType.goal
              ? (widget.objective == null ? "add-goal".tr() : "edit-goal".tr())
              : objectiveType == ObjectiveType.loan
                  ? (widget.objective == null
                      ? "add-loan".tr()
                      : "edit-loan".tr())
                  : "",
          onBackButton: () async {
            if (widget.objective != null) {
              discardChangesPopup(
                context,
                previousObject: widget.objective,
                currentObject: await createObjective(),
              );
            } else {
              showDiscardChangesPopupIfNotEditing();
            }
          },
          onDragDownToDismiss: () async {
            if (widget.objective != null) {
              discardChangesPopup(
                context,
                previousObject: widget.objective,
                currentObject: await createObjective(),
              );
            } else {
              showDiscardChangesPopupIfNotEditing();
            }
          },
          actions: [
            CustomPopupMenuButton(
              showButtons:
                  widget.objective == null || enableDoubleColumn(context),
              keepOutFirst: true,
              items: [
                if (widget.objective != null &&
                    widget.routesToPopAfterDelete !=
                        RoutesToPopAfterDelete.PreventDelete)
                  DropdownItemMenu(
                    id: "delete-goal",
                    label: widget.objective?.type == ObjectiveType.loan
                        ? "delete-loan".tr()
                        : "delete-goal".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.delete_outlined
                        : Icons.delete_rounded,
                    action: () {
                      deleteObjectivePopup(
                        context,
                        objective: widget.objective!,
                        routesToPopAfterDelete: widget.routesToPopAfterDelete,
                      );
                    },
                  ),
              ],
            ),
          ],
          overlay: Align(
            alignment: Alignment.bottomCenter,
            child: selectedTitle == "" || selectedTitle == null
                ? SaveBottomButton(
                    label: "set-name".tr(),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _titleFocusNode.requestFocus();
                      });
                    },
                    disabled: false,
                  )
                : selectedAmount == 0
                    ? SaveBottomButton(
                        label: "set-amount".tr(),
                        onTap: () async {
                          selectAmount(context);
                        },
                        disabled: false,
                      )
                    : SaveBottomButton(
                        label: widget.objective == null
                            ? objectiveType == ObjectiveType.loan
                                ? "add-loan".tr()
                                : "add-goal".tr()
                            : "save-changes".tr(),
                        onTap: () async {
                          await addObjective();
                        },
                        disabled: !(canAddObjective ?? false),
                      ),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                // Flip the order if ObjectiveType.loan
                child: IncomeExpenseTabSelector(
                  hasBorderRadius: true,
                  onTabChanged: (isIncome) {
                    if (objectiveType == ObjectiveType.loan) {
                      setSelectedIncome(!isIncome);
                    } else {
                      setSelectedIncome(isIncome);
                    }
                  },
                  initialTabIsIncome: objectiveType == ObjectiveType.loan
                      ? !selectedIncome
                      : selectedIncome,
                  syncWithInitial: true,
                  expenseLabel: objectiveType == ObjectiveType.goal
                      ? "expense-goal".tr()
                      : objectiveType == ObjectiveType.loan
                          ? "lent".tr()
                          : "",
                  incomeLabel: objectiveType == ObjectiveType.goal
                      ? "savings-goal".tr()
                      : objectiveType == ObjectiveType.loan
                          ? "borrowed".tr()
                          : "",
                  showIcons: objectiveType != ObjectiveType.loan,
                  expenseCustomIcon: objectiveType == ObjectiveType.goal
                      ? null
                      : Icon(
                          getTransactionTypeIcon(TransactionSpecialType.credit),
                        ),
                  incomeCustomIcon: objectiveType == ObjectiveType.goal
                      ? null
                      : Icon(
                          getTransactionTypeIcon(TransactionSpecialType.debt),
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Tappable(
                    onTap: () {
                      openBottomSheet(
                        context,
                        PopupFramework(
                          title: "select-icon".tr(),
                          child: SelectCategoryImage(
                            setSelectedImage: setSelectedImage,
                            setSelectedEmoji: setSelectedEmoji,
                            selectedImage:
                                "assets/categories/$selectedImage",
                            setSelectedTitle: (String? titleRecommendation) {},
                          ),
                        ),
                        showScrollbar: true,
                      );
                    },
                    color: Colors.transparent,
                    child: Container(
                      height: 126,
                      padding: const EdgeInsets.only(left: 13, right: 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: CategoryIcon(
                              key: ValueKey((selectedImage ?? "") +
                                  selectedColor.toString()),
                              categoryPk: "-1",
                              category: TransactionCategory(
                                categoryPk: "-1",
                                name: "",
                                dateCreated: DateTime.now(),
                                dateTimeModified: null,
                                order: 0,
                                income: false,
                                iconName: selectedImage,
                                colour: toHexString(selectedColor),
                                emojiIconName: selectedEmoji,
                              ),
                              size: 50,
                              sizePadding: 30,
                              canEditByLongPress: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: IntrinsicWidth(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 40),
                        child: TextInput(
                          focusNode: _titleFocusNode,
                          labelText: "name-placeholder".tr(),
                          bubbly: false,
                          onChanged: (text) {
                            setSelectedTitle(text);
                          },
                          padding: EdgeInsets.zero,
                          fontSize: getIsFullScreen(context) ? 34 : 27,
                          fontWeight: FontWeight.bold,
                          topContentPadding: 40,
                          initialValue: selectedTitle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 65,
                child: SelectColor(
                  horizontalList: true,
                  selectedColor: selectedColor,
                  setSelectedColor: setSelectedColor,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 10,
              ),
            ),
            widget.objective != null && objectiveType == ObjectiveType.loan
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      child: TipBox(
                        onTap: () {
                          pushRoute(
                            context,
                            AddTransactionPage(
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.None,
                              selectedObjective: widget.objective,
                              selectedIncome: !selectedIncome,
                            ),
                          );
                        },
                        text: selectedIncome
                            ? "change-loan-amount-tip-lent".tr()
                            : "change-loan-amount-tip-borrowed".tr(),
                        settingsString: null,
                      ),
                    ),
                  )
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: AnimatedSizeSwitcher(
                              child: TextFont(
                                key: ValueKey(selectedIncome.toString()),
                                text: objectiveType == ObjectiveType.loan
                                    ? selectedIncome
                                        ? "lent".tr()
                                        : "borrowed".tr()
                                    : "${"goal".tr()} ",
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: TappableTextEntry(
                              title: convertToMoney(
                                Provider.of<AllWallets>(context),
                                selectedAmount,
                                currencyKey: Provider.of<AllWallets>(context,
                                        listen: true)
                                    .indexedByPk[selectedWalletPk]
                                    ?.currency,
                              ),
                              placeholder: convertToMoney(
                                Provider.of<AllWallets>(context),
                                0,
                                currencyKey: Provider.of<AllWallets>(context,
                                        listen: true)
                                    .indexedByPk[selectedWalletPk]
                                    ?.currency,
                              ),
                              showPlaceHolderWhenTextEquals: convertToMoney(
                                Provider.of<AllWallets>(context),
                                0,
                                currencyKey: Provider.of<AllWallets>(context,
                                        listen: true)
                                    .indexedByPk[selectedWalletPk]
                                    ?.currency,
                              ),
                              onTap: () {
                                selectAmount(context);
                              },
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              internalPadding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 10),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: SelectDateRange(
                  initialStartDate: selectedStartDate,
                  initialEndDate: selectedEndDate,
                  onSelectedStartDate: setSelectedStartDate,
                  onSelectedEndDate: setSelectedEndDate,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 65)),
            // SliverToBoxAdapter(
            //   child: KeyboardHeightAreaAnimated(),
            // ),
          ],
        ),
      ),
    );
  }
}

class SelectObjectiveTypePopup extends StatelessWidget {
  const SelectObjectiveTypePopup({required this.setObjectiveIncome, super.key});
  final Function(bool isIncome) setObjectiveIncome;

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "select-goal-type".tr(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  alignLeft: true,
                  alignBeside: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  text: "savings-goal".tr(),
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.savings_outlined
                      : Icons.savings_rounded,
                  onTap: () {
                    setObjectiveIncome(true);
                    Navigator.pop(context);
                  },
                  afterWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListItem(
                        "savings-goal-description-1".tr(),
                      ),
                      ListItem(
                        "savings-goal-description-2".tr(),
                      ),
                      Opacity(
                        opacity: 0.34,
                        child: ListItem(
                          "savings-goal-description-3".tr(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  alignLeft: true,
                  alignBeside: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  text: "expense-goal".tr(),
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.request_quote_outlined
                      : Icons.request_quote_rounded,
                  onTap: () async {
                    setObjectiveIncome(false);
                    Navigator.pop(context);
                  },
                  afterWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListItem(
                        "expense-goal-description-1".tr(),
                      ),
                      ListItem(
                        "expense-goal-description-2".tr(),
                      ),
                      Opacity(
                        opacity: 0.34,
                        child: ListItem("expense-goal-description-3".tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool> startCreatingInstallment(
    {required BuildContext context, Objective? initialObjective}) async {
  dynamic objective = initialObjective ??
      await selectObjectivePopup(context,
          canSelectNoGoal: false, includeAmount: true, showAddButton: true);
  if (objective is Objective) {
    dynamic result = await openBottomSheet(
      context,
      fullSnap: true,
      InstallmentObjectivePopup(objective: objective),
    );
    if (result == true) return true;
  }
  return false;
}

class InstallmentObjectivePopup extends StatefulWidget {
  const InstallmentObjectivePopup({required this.objective, super.key});
  final Objective objective;

  @override
  State<InstallmentObjectivePopup> createState() =>
      _InstallmentObjectivePopupState();
}

class _InstallmentObjectivePopupState extends State<InstallmentObjectivePopup> {
  bool isNegative = false;
  TimeOfDay? selectedTime;
  DateTime? selectedDateTime;
  String selectedTitle = "";
  String selectedWalletPk = appStateSettings["selectedWalletPk"];
  TransactionCategory? selectedCategory;
  TransactionCategory? selectedSubCategory;

  int selectedPeriodLength = 1;
  String selectedRecurrence = "Monthly";
  String selectedRecurrenceDisplay = "month";
  BudgetReoccurence selectedRecurrenceEnum = BudgetReoccurence.monthly;

  int? numberOfInstallmentPayments;
  double? amountPerInstallmentPayment;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      selectedCategory = (await database.getAllCategories()).firstOrNull;
      setState(() {});
    });
  }

  Future<void> selectAmountPerInstallment(BuildContext context) async {
    openBottomSheet(
      context,
      PopupFramework(
        title: "enter-payment-amount".tr(),
        hasPadding: false,
        underTitleSpace: false,
        child: SelectAmount(
          enableWalletPicker: true,
          hideWalletPickerIfOneCurrency: true,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          onlyShowCurrencyIcon: true,
          amountPassed: (amountPerInstallmentPayment ?? 0).toString(),
          setSelectedAmount: (amount, _) {
            setState(() {
              numberOfInstallmentPayments = null;
              amountPerInstallmentPayment = amount == 0 ? null : amount;
            });
          },
          selectedWalletPk: selectedWalletPk,
          setSelectedWalletPk: (walletPk) {
            setState(() {
              selectedWalletPk = walletPk;
            });
          },
          next: () {
            Navigator.pop(context);
          },
          nextLabel: "set-amount".tr(),
        ),
      ),
    );
  }

  Future<void> selectInstallmentLength(BuildContext context) async {
    openBottomSheet(
      context,
      PopupFramework(
        title: "enter-payment-period".tr(),
        child: SelectAmountValue(
          amountPassed: (numberOfInstallmentPayments ?? 0).toString(),
          setSelectedAmount: (amount, _) {
            setState(() {
              amountPerInstallmentPayment = null;
              selectedWalletPk = appStateSettings["selectedWalletPk"];
              numberOfInstallmentPayments =
                  amount.toInt() == 0 ? null : amount.toInt();
            });
          },
          next: () async {
            Navigator.pop(context);
          },
          nextLabel: "set-amount".tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget editTransferDetails = Column(
      children: [
        SizedBox(
          width: getWidthBottomSheet(context) - 36,
          child: TextInput(
            icon: appStateSettings["outlinedIcons"]
                ? Icons.title_outlined
                : Icons.title_rounded,
            autoFocus: false,
            onChanged: (text) async {
              selectedTitle = text;
            },
            initialValue: selectedTitle,
            labelText: "title-placeholder".tr(),
            padding: const EdgeInsets.only(bottom: 13),
          ),
        ),
        DateButton(
          internalPadding: const EdgeInsets.only(right: 5),
          initialSelectedDate: selectedDateTime ?? DateTime.now(),
          initialSelectedTime: TimeOfDay(
              hour: selectedDateTime?.hour ?? TimeOfDay.now().hour,
              minute: selectedDateTime?.minute ?? TimeOfDay.now().minute),
          setSelectedDate: (date) {
            selectedDateTime = date;
          },
          setSelectedTime: (time) {
            selectedDateTime = (selectedDateTime ?? DateTime.now())
                .copyWith(hour: time.hour, minute: time.minute);
          },
        ),
      ],
    );

    return PopupFramework(
      title: "installment".tr(),
      subtitle: "${widget.objective.name} (${convertToMoney(
              Provider.of<AllWallets>(context),
              objectiveAmountToPrimaryCurrency(
                      Provider.of<AllWallets>(context), widget.objective) *
                  ((widget.objective.income) ? 1 : -1))})",
      underTitleSpace: false,
      hasPadding: false,
      child: Column(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Builder(
                  builder: (context) {
                    List<double> results = getInstallmentPaymentCalculations(
                      allWallets: Provider.of<AllWallets>(context),
                      objective: widget.objective,
                      numberOfInstallmentPayments: numberOfInstallmentPayments,
                      amountPerInstallmentPayment: amountPerInstallmentPayment,
                      amountPerInstallmentPaymentWalletPk: selectedWalletPk,
                    );
                    double numberOfInstallmentPaymentsDisplay = results[0];
                    double amountPerInstallmentPaymentDisplay = results[1];

                    String displayNumberOfInstallmentPaymentsDisplay =
                        numberOfInstallmentPaymentsDisplay == double.infinity
                            ? "0"
                            : removeTrailingZeroes(
                                numberOfInstallmentPaymentsDisplay
                                    .toStringAsFixed(3));
                    String displayAmountPerInstallmentPaymentDisplay =
                        convertToMoney(
                      Provider.of<AllWallets>(context),
                      amountPerInstallmentPaymentDisplay == double.infinity
                          ? 0
                          : amountPerInstallmentPaymentDisplay,
                      currencyKey: Provider.of<AllWallets>(context)
                          .indexedByPk[selectedWalletPk]
                          ?.currency,
                    );
                    return Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TappableTextEntry(
                              title: displayNumberOfInstallmentPaymentsDisplay,
                              placeholder: numberOfInstallmentPayments == null
                                  ? displayNumberOfInstallmentPaymentsDisplay
                                  : "",
                              showPlaceHolderWhenTextEquals:
                                  numberOfInstallmentPayments == null
                                      ? displayNumberOfInstallmentPaymentsDisplay
                                      : "",
                              onTap: () {
                                selectInstallmentLength(context);
                              },
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              internalPadding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 3),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: TextFont(
                                text: numberOfInstallmentPayments == 1
                                    ? "payment-of".tr()
                                    : "payments-of".tr(),
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TappableTextEntry(
                              title: displayAmountPerInstallmentPaymentDisplay,
                              placeholder: amountPerInstallmentPayment == null
                                  ? displayAmountPerInstallmentPaymentDisplay
                                  : "",
                              showPlaceHolderWhenTextEquals:
                                  amountPerInstallmentPayment == null
                                      ? displayAmountPerInstallmentPaymentDisplay
                                      : "",
                              onTap: () {
                                selectAmountPerInstallment(context);
                              },
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              internalPadding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 3),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: TextFont(
                            text: "until-goal-reached".tr().toLowerCase(),
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
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
                              selectedPeriodLength: selectedPeriodLength,
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
                          internalPadding:
                              const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          padding:
                              const EdgeInsets.symmetric(vertical: 0, horizontal: 3),
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
                              selectedPeriodLength: selectedPeriodLength,
                              onChanged: (selectedRecurrence,
                                  selectedRecurrenceEnum,
                                  selectedRecurrenceDisplay) {
                                this.selectedRecurrence = selectedRecurrence;
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
                          internalPadding:
                              const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          padding:
                              const EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HorizontalBreak(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              if (selectedCategory != null)
                SelectCategory(
                  horizontalList: true,
                  listPadding: const EdgeInsets.symmetric(horizontal: 10),
                  addButton: false,
                  setSelectedCategory: (category) {
                    // Clear the subcategory
                    if (category.categoryPk != selectedCategory?.categoryPk) {
                      setState(() {
                        selectedSubCategory = null;
                      });
                    }

                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  popRoute: false,
                  selectedCategory: selectedCategory,
                ),
              const SizedBox(height: 6),
              if (selectedCategory != null)
                SelectSubcategoryChips(
                  setSelectedSubCategory: (category) {
                    if (selectedSubCategory?.categoryPk ==
                        category.categoryPk) {
                      selectedSubCategory = null;
                    } else {
                      selectedSubCategory = category;
                    }
                    setState(
                      () {},
                    );
                  },
                  selectedCategoryPk: selectedCategory!.categoryPk,
                  selectedSubCategoryPk: selectedSubCategory?.categoryPk,
                ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: editTransferDetails,
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Button(
                  disabled: selectedCategory == null ||
                      (amountPerInstallmentPayment == null &&
                          numberOfInstallmentPayments == null),
                  onDisabled: () {
                    openSnackbar(
                      SnackbarMessage(
                        title: "cannot-create-installment".tr(),
                        description:
                            "missing-installment-period-and-amount".tr(),
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.warning_amber_outlined
                            : Icons.warning_amber_rounded,
                      ),
                    );
                  },
                  label: "add-transaction".tr(),
                  width: MediaQuery.sizeOf(context).width,
                  onTap: () async {
                    Transaction transaction = Transaction(
                      transactionPk: "-1",
                      name: selectedTitle,
                      amount: getInstallmentPaymentCalculations(
                        allWallets:
                            Provider.of<AllWallets>(context, listen: false),
                        objective: widget.objective,
                        numberOfInstallmentPayments:
                            numberOfInstallmentPayments,
                        amountPerInstallmentPayment:
                            amountPerInstallmentPayment,
                        amountPerInstallmentPaymentWalletPk: selectedWalletPk,
                      )[1],
                      note: "",
                      categoryFk: selectedCategory?.categoryPk ?? "-1",
                      subCategoryFk: selectedSubCategory?.categoryPk,
                      walletFk: selectedWalletPk,
                      dateCreated: selectedDateTime ?? DateTime.now(),
                      income: widget.objective.income,
                      paid: false,
                      skipPaid: false,
                      createdAnotherFutureTransaction: false,
                      type: TransactionSpecialType.repetitive,
                      periodLength: selectedPeriodLength,
                      reoccurrence: selectedRecurrenceEnum,
                      objectiveFk: widget.objective.objectivePk,
                    );
                    await database.createOrUpdateTransaction(transaction,
                        insert: true);
                    Navigator.maybePop(context, true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
