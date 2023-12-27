import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/modified/reorderable_list.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/edit_associated_titles_page.dart';
import 'package:budget/pages/edit_categories_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/category_icon.dart';
import 'package:budget/widgets/edit_row_entry.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/widgets/icon_button_scaled.dart';
import 'package:budget/widgets/income_expense_tab_selector.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_container_navigation.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/outlined_button_stacked.dart';
import 'package:budget/widgets/save_bottom_button.dart';
import 'package:budget/widgets/select_category.dart';
import 'package:budget/widgets/select_category_image.dart';
import 'package:budget/widgets/select_color.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/widgets/extra_info_boxes.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({
    super.key,
    this.category,
    required this.routesToPopAfterDelete,
    this.mainCategoryPkWhenSubCategory,
    this.initiallyIsExpense = true,
  });

  //When a category is passed in, we are editing that category
  final TransactionCategory? category;
  final RoutesToPopAfterDelete routesToPopAfterDelete;
  final String?
      mainCategoryPkWhenSubCategory; //When this is null, it is a main category not a sub category
  final bool initiallyIsExpense;
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage>
    with SingleTickerProviderStateMixin {
  bool isMainCategoryWhenCreating = true;
  String? mainCategoryPkForSubcategoryWhenCreating;
  String? selectedTitle;
  late String? selectedImage = widget.category == null ? "image.png" : null;
  String? selectedEmoji;
  Color? selectedColor;
  late bool selectedIncome = widget.initiallyIsExpense == false;
  bool? canAddCategory;
  TransactionCategory? widgetCategory;
  List<String>? selectedMembers;
  final TextEditingController _titleController = TextEditingController();
  bool userAttemptedToChangeTitle = false;
  final FocusNode _titleFocusNode = FocusNode();
  late final TabController _incomeTabController =
      TabController(length: 2, vsync: this);
  late bool isSubCategory = widget.mainCategoryPkWhenSubCategory != null ||
      widget.category?.mainCategoryPk != null;

  void setSelectedColor(Color? color) {
    setState(() {
      selectedColor = color;
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

  void setSelectedTitle(String title,
      {bool userAttemptedToChangeTitlePassed = false,
      bool modifyControllerValue = false}) {
    setState(() {
      selectedTitle = title;
      userAttemptedToChangeTitle =
          title == "" ? false : userAttemptedToChangeTitlePassed;
    });
    if (modifyControllerValue) _titleController.text = title;
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

  void setSelectedMembers(List<String>? members) {
    if (selectedMembers != null) {
      determineBottomButton();
    }
    setState(() {
      selectedMembers = members;
    });
    return;
  }

  determineBottomButton() {
    if (selectedTitle != null) {
      if (canAddCategory != true) {
        setState(() {
          canAddCategory = true;
        });
      }
    } else {
      if (canAddCategory != false) {
        setState(() {
          canAddCategory = false;
        });
      }
    }
  }

  Future addCategory() async {
    TransactionCategory createdCategory = await createTransactionCategory();
    await database.createOrUpdateCategory(
      insert: widget.category == null,
      createdCategory,
    );
    if (canSelectIfSubCategoryOrMainCategory() &&
        mainCategoryPkForSubcategoryWhenCreating != null) {
      TransactionCategory categoryMain = await database
          .getCategoryInstance(mainCategoryPkForSubcategoryWhenCreating!);
      openSnackbar(
        SnackbarMessage(
          title: "subcategory-created".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.move_to_inbox_outlined
              : Icons.move_to_inbox_rounded,
          description: "${selectedTitle ?? ""} → ${categoryMain.name}",
        ),
      );
    }
    Navigator.pop(context);
  }

  Future<TransactionCategory> createTransactionCategory() async {
    TransactionCategory? currentInstance;
    if (widget.category != null) {
      currentInstance =
          await database.getCategoryInstance(widget.category!.categoryPk);
    }
    return TransactionCategory(
      categoryPk: widget.category != null ? widget.category!.categoryPk : "-1",
      name: (selectedTitle ?? "").trim(),
      dateCreated: widget.category != null
          ? widget.category!.dateCreated
          : DateTime.now(),
      dateTimeModified: null,
      income: selectedIncome,
      order: widget.category != null
          ? widget.category!.order
          : canSelectIfSubCategoryOrMainCategory() &&
                  mainCategoryPkForSubcategoryWhenCreating != null
              ? await database.getAmountOfSubCategories(
                  mainCategoryPkForSubcategoryWhenCreating!)
              : widget.mainCategoryPkWhenSubCategory != null
                  ? await database.getAmountOfSubCategories(
                      widget.mainCategoryPkWhenSubCategory!)
                  : await database.getAmountOfCategories(),
      colour: toHexString(selectedColor),
      iconName: selectedImage,
      emojiIconName: selectedEmoji,
      methodAdded:
          widget.category != null ? widget.category!.methodAdded : null,
      mainCategoryPk: canSelectIfSubCategoryOrMainCategory() &&
              mainCategoryPkForSubcategoryWhenCreating != null
          ? mainCategoryPkForSubcategoryWhenCreating
          : widget.mainCategoryPkWhenSubCategory ?? widget.category?.mainCategoryPk,
    );
  }

  TransactionCategory? categoryInitial;

  void showDiscardChangesPopupIfNotEditing() async {
    TransactionCategory categoryCreated = await createTransactionCategory();
    categoryCreated = categoryCreated.copyWith(
      dateCreated: categoryInitial?.dateCreated,
      mainCategoryPk: Value(categoryInitial?.mainCategoryPk),
    );
    if (categoryCreated != categoryInitial && widget.category == null) {
      discardChangesPopup(context, forceShow: true);
    } else {
      Navigator.pop(context);
    }
  }

  bool canSelectIfSubCategoryOrMainCategory() {
    return widget.category == null &&
        widget.mainCategoryPkWhenSubCategory == null &&
        isSubCategory == false;
  }

  @override
  void initState() {
    super.initState();
    widgetCategory = widget.category;
    selectedColor = widget.category != null
        ? (widget.category!.colour == null
            ? null
            : HexColor(widget.category!.colour))
        : null;
    if (widget.category != null) {
      setState(() {
        selectedTitle = widget.category?.name;
        selectedImage = widget.category?.iconName;
        selectedEmoji = widget.category?.emojiIconName;
        selectedIncome = widget.category!.income;
        userAttemptedToChangeTitle = true;
      });
      Future.delayed(Duration.zero, () async {
        _titleController.text = selectedTitle ?? "";
        _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: _titleController.text.length));
        await database.fixOrderCategories(
            mainCategoryPkIfSubCategoryOrderFixing:
                widget.category!.categoryPk);
      });
    }

    if (selectedIncome == true) {
      _incomeTabController.animateTo(1);
    } else {
      _incomeTabController.animateTo(0);
    }

    //Set to false because we can't save until we made some changes
    setState(() {
      canAddCategory = false;
    });
    if (widget.category == null) {
      Future.delayed(Duration.zero, () async {
        categoryInitial = await createTransactionCategory();
      });
    }
  }

  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.category != null) {
          discardChangesPopup(context,
              previousObject: widget.category!,
              currentObject: await createTransactionCategory());
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
          dragDownToDismissEnabled: dragDownToDismissEnabled,
          horizontalPadding: getHorizontalPaddingConstrained(context),
          resizeToAvoidBottomInset: true,
          dragDownToDismiss: true,
          subtitle: widget.mainCategoryPkWhenSubCategory == null
              ? null
              : StreamBuilder<TransactionCategory>(
                  stream: database
                      .watchCategory(widget.mainCategoryPkWhenSubCategory!),
                  builder: (context, snapshot) {
                    return TextFont(
                      text: "${"for".tr().capitalizeFirst} ${snapshot.data?.name ?? ""}",
                      fontSize: getCenteredTitle(
                                      context: context,
                                      backButtonEnabled: true) ==
                                  true &&
                              getCenteredTitleSmall(
                                      context: context,
                                      backButtonEnabled: true) ==
                                  false
                          ? 30
                          : 22,
                      maxLines: 5,
                      fontWeight: FontWeight.bold,
                    );
                  }),
          subtitleSize:
              widget.mainCategoryPkWhenSubCategory == null ? null : 10,
          subtitleAlignment: Alignment.bottomLeft,
          title: widget.category == null
              ? "add-category".tr()
              : "edit-category".tr(),
          onBackButton: () async {
            if (widget.category != null) {
              discardChangesPopup(context,
                  previousObject: widget.category!,
                  currentObject: await createTransactionCategory());
            } else {
              showDiscardChangesPopupIfNotEditing();
            }
          },
          onDragDownToDismiss: () async {
            if (widget.category != null) {
              discardChangesPopup(context,
                  previousObject: widget.category!,
                  currentObject: await createTransactionCategory());
            } else {
              showDiscardChangesPopupIfNotEditing();
            }
          },
          actions: [
            widget.category != null &&
                    widget.routesToPopAfterDelete !=
                        RoutesToPopAfterDelete.PreventDelete
                ? IconButton(
                    padding: const EdgeInsets.all(15),
                    tooltip: "delete-category".tr(),
                    onPressed: () {
                      deleteCategoryPopup(
                        context,
                        category: widgetCategory!,
                        routesToPopAfterDelete: widget.routesToPopAfterDelete,
                      );
                    },
                    icon: Icon(appStateSettings["outlinedIcons"]
                        ? Icons.delete_outlined
                        : Icons.delete_rounded),
                  )
                : const SizedBox.shrink()
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
                : canSelectIfSubCategoryOrMainCategory() &&
                        mainCategoryPkForSubcategoryWhenCreating == null &&
                        isMainCategoryWhenCreating == false
                    ? SaveBottomButton(
                        label: "select-main-category".tr(),
                        onTap: () async {
                          openBottomSheet(
                            context,
                            PopupFramework(
                              title: "select-category".tr(),
                              subtitle:
                                  "select-the-main-category-for-this-subcategory"
                                      .tr(),
                              child: SelectCategory(
                                setSelectedCategory:
                                    (TransactionCategory category) {
                                  mainCategoryPkForSubcategoryWhenCreating =
                                      category.categoryPk;
                                },
                                next: () async {
                                  await addCategory();
                                },
                                addButton: false,
                              ),
                            ),
                          );
                        },
                        disabled: !(canAddCategory ?? false),
                      )
                    : SaveBottomButton(
                        label: widget.category == null
                            ? "add-category".tr()
                            : "save-changes".tr(),
                        onTap: () async {
                          await addCategory();
                        },
                        disabled: !(canAddCategory ?? false),
                      ),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (isSubCategory == false &&
                      widget.category?.categoryPk != "0")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: IncomeExpenseTabSelector(
                        onTabChanged: setSelectedIncome,
                        initialTabIsIncome: selectedIncome,
                        hasBorderRadius: true,
                      ),
                    ),
                  Row(
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
                                selectedImage: "assets/categories/$selectedImage",
                                setSelectedTitle:
                                    (String? titleRecommendation) {
                                  if (titleRecommendation != null &&
                                      (userAttemptedToChangeTitle == false ||
                                          selectedTitle == "" ||
                                          selectedTitle == null)) {
                                    setSelectedTitle(
                                        titleRecommendation
                                            .capitalizeFirstofEach,
                                        modifyControllerValue: true);
                                  }
                                },
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
                            padding: const EdgeInsets.only(right: 20),
                            child: Builder(builder: (context) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextInput(
                                    focusNode: _titleFocusNode,
                                    labelText: "name-placeholder".tr(),
                                    bubbly: false,
                                    controller: _titleController,
                                    onChanged: (text) {
                                      setSelectedTitle(text,
                                          userAttemptedToChangeTitlePassed:
                                              true);
                                    },
                                    padding: EdgeInsets.zero,
                                    fontSize:
                                        getIsFullScreen(context) ? 34 : 27,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  if (widget.category?.categoryPk != "0")
                                    const SizedBox(height: 17),
                                  if (widget.category?.categoryPk == "0")
                                    AnimatedOpacity(
                                      opacity: selectedTitle !=
                                                  "balance-correction".tr() &&
                                              selectedTitle !=
                                                  "balance-correction"
                                                      .tr()
                                                      .capitalizeFirstofEach
                                          ? 1
                                          : 0,
                                      duration: const Duration(milliseconds: 500),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: TextFont(
                                          text: "balance-correction".tr(),
                                          fontSize: 15,
                                          textColor:
                                              getColor(context, "textLight"),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.category?.categoryPk == "0")
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 15),
                      child: TipBox(
                        onTap: () {},
                        text: "balance-correction-category-info".tr(),
                        settingsString: null,
                      ),
                    ),
                  SizedBox(
                    height: 65,
                    child: SelectColor(
                      horizontalList: true,
                      selectedColor: selectedColor,
                      setSelectedColor: setSelectedColor,
                    ),
                  ),
                  widget.category?.categoryPk == "0" ||
                          widgetCategory == null ||
                          widget.routesToPopAfterDelete ==
                              RoutesToPopAfterDelete.PreventDelete
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                          ),
                          child: Button(
                            flexibleLayout: true,
                            icon: appStateSettings["outlinedIcons"]
                                ? Icons.merge_outlined
                                : Icons.merge_rounded,
                            label: isSubCategory
                                ? "merge-subcategory".tr()
                                : "merge-category".tr(),
                            onTap: () async {
                              if (widget.category != null) {
                                if (isSubCategory) {
                                  mergeSubcategoryPopup(context,
                                      subcategoryOriginal: widget.category!,
                                      routesToPopAfterDelete:
                                          widget.routesToPopAfterDelete);
                                } else {
                                  mergeCategoryPopup(
                                    context,
                                    categoryOriginal: widget.category!,
                                    routesToPopAfterDelete:
                                        widget.routesToPopAfterDelete,
                                  );
                                }
                              }
                            },
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                  widgetCategory == null ||
                          widget.routesToPopAfterDelete ==
                              RoutesToPopAfterDelete.PreventDelete ||
                          isSubCategory == false
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 10,
                          ),
                          child: Button(
                            flexibleLayout: true,
                            icon: appStateSettings["outlinedIcons"]
                                ? Icons.inbox_outlined
                                : Icons.inbox_rounded,
                            label: "make-main-category".tr(),
                            onTap: () async {
                              makeMainCategoryPopup(context,
                                  subcategoryOriginal: widget.category!,
                                  routesToPopAfterDelete:
                                      widget.routesToPopAfterDelete);
                            },
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                  widget.category?.categoryPk == "0" || widgetCategory == null
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 20),
                  widget.category?.categoryPk == "0" ||
                          widgetCategory == null ||
                          isSubCategory
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFont(
                            text: "subcategories".tr(),
                            textColor: getColor(context, "textLight"),
                            fontSize: 16,
                          ),
                        ),
                  widget.category?.categoryPk == "0" || widgetCategory == null
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 5),
                ],
              ),
            ),
            if (canSelectIfSubCategoryOrMainCategory())
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SelectIsSubcategory(
                  isMainCategoryWhenCreating: isMainCategoryWhenCreating,
                  onTap: (value) {
                    setState(() {
                      isMainCategoryWhenCreating = value;
                    });
                  },
                  setMainCategoryPkForSubcategoryWhenCreating: (value) {
                    mainCategoryPkForSubcategoryWhenCreating = value;
                  },
                ),
              )),
            if ((widget.category?.categoryPk == "0" ||
                    widgetCategory == null ||
                    isSubCategory) ==
                false)
              StreamBuilder<List<TransactionCategory>>(
                stream: database.watchAllSubCategoriesOfMainCategory(
                    widget.category!.categoryPk),
                builder: (context, snapshot) {
                  List<TransactionCategory> subCategories = snapshot.data ?? [];
                  if (subCategories.isEmpty &&
                      widget.routesToPopAfterDelete !=
                          RoutesToPopAfterDelete.PreventDelete) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 10,
                          bottom: 8,
                        ),
                        child: Button(
                          flexibleLayout: true,
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.move_to_inbox_outlined
                              : Icons.move_to_inbox_rounded,
                          label: "make-subcategory".tr(),
                          onTap: () async {
                            if (widget.category != null) {
                              makeSubCategoryPopup(
                                context,
                                categoryOriginal: widget.category!,
                                routesToPopAfterDelete:
                                    widget.routesToPopAfterDelete,
                              );
                            }
                          },
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          textColor: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    );
                  }
                  return SliverReorderableList(
                    onReorderStart: (index) {
                      HapticFeedback.heavyImpact();
                      setState(() {
                        dragDownToDismissEnabled = false;
                        currentReorder = index;
                      });
                    },
                    onReorderEnd: (_) {
                      setState(() {
                        dragDownToDismissEnabled = true;
                        currentReorder = -1;
                      });
                    },
                    itemBuilder: (context, index) {
                      TransactionCategory category = subCategories[index];
                      return EditRowEntry(
                        index: index,
                        canReorder: subCategories.length != 1,
                        currentReorder:
                            currentReorder != -1 && currentReorder != index,
                        padding: EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal:
                              getPlatform() == PlatformOS.isIOS ? 17 : 7,
                        ),
                        canDelete: widget.routesToPopAfterDelete !=
                            RoutesToPopAfterDelete.PreventDelete,
                        key: ValueKey(category.categoryPk),
                        content: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 3),
                            CategoryIcon(
                              categoryPk: category.categoryPk,
                              size: 25,
                              margin: EdgeInsets.zero,
                              sizePadding: 20,
                              borderRadius: 1000,
                              category: category,
                              onLongPress: null,
                              onTap: null,
                              canEditByLongPress: false,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFont(
                                    text: category.name
                                    // +
                                    //     " - " +
                                    //     category.order.toString()
                                    ,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  StreamBuilder<List<int?>>(
                                    stream: database
                                        .watchTotalCountOfTransactionsInSubCategory(
                                            category.categoryPk),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return TextFont(
                                          textAlign: TextAlign.left,
                                          text: "${snapshot.data![0]} ${snapshot.data![0] == 1
                                                  ? "transaction"
                                                      .tr()
                                                      .toLowerCase()
                                                  : "transactions"
                                                      .tr()
                                                      .toLowerCase()}",
                                          fontSize: 14,
                                          textColor: getColor(context, "black")
                                              .withOpacity(0.65),
                                        );
                                      } else {
                                        return TextFont(
                                          textAlign: TextAlign.left,
                                          text: "/ transactions",
                                          fontSize: 14,
                                          textColor: getColor(context, "black")
                                              .withOpacity(0.65),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onDelete: () async {
                          return (await deleteCategoryPopup(
                                context,
                                category: category,
                                routesToPopAfterDelete:
                                    RoutesToPopAfterDelete.None,
                              )) ==
                              DeletePopupAction.Delete;
                        },
                        openPage: AddCategoryPage(
                          category: category,
                          routesToPopAfterDelete: widget.routesToPopAfterDelete,
                          mainCategoryPkWhenSubCategory:
                              widget.category!.categoryPk,
                        ),
                      );
                    },
                    itemCount: subCategories.length,
                    onReorder: (intPrevious, intNew) async {
                      TransactionCategory oldCategory =
                          subCategories[intPrevious];

                      if (intNew > intPrevious) {
                        await database.moveCategory(
                          oldCategory.categoryPk,
                          intNew - 1,
                          oldCategory.order,
                          mainCategoryPk: oldCategory.mainCategoryPk,
                        );
                      } else {
                        await database.moveCategory(
                          oldCategory.categoryPk,
                          intNew,
                          oldCategory.order,
                          mainCategoryPk: oldCategory.mainCategoryPk,
                        );
                      }
                      return true;
                    },
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.category?.categoryPk == "0" ||
                          widgetCategory == null ||
                          isSubCategory
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            Expanded(
                              child: AddButton(
                                openPage: AddCategoryPage(
                                  routesToPopAfterDelete:
                                      RoutesToPopAfterDelete.None,
                                  mainCategoryPkWhenSubCategory:
                                      widget.category!.categoryPk,
                                ),
                                padding: const EdgeInsets.only(
                                  left: 13,
                                  right: 13,
                                  bottom: 6,
                                  top: 5,
                                ),
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                  widgetCategory == null
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 20),
                  widget.category == null || isSubCategory
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFont(
                            text: "associated-titles".tr(),
                            textColor: getColor(context, "textLight"),
                            fontSize: 16,
                          ),
                        ),
                  widget.category == null || isSubCategory
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 5),
                  widget.category == null || isSubCategory
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFont(
                            text: "associated-titles-description".tr(),
                            textColor: getColor(context, "textLight"),
                            fontSize: 13,
                            maxLines: 10,
                          ),
                        ),
                  widget.category == null || isSubCategory
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 10),
                  widget.category == null || isSubCategory
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            Expanded(
                              child: AddButton(
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                    bottom: 9,
                                    top: 4,
                                  ),
                                  onTap: () {
                                    openBottomSheet(
                                      context,
                                      fullSnap: true,
                                      PopupFramework(
                                        title: "set-title".tr(),
                                        child: SelectText(
                                          setSelectedText: (_) {},
                                          labelText: "set-title".tr(),
                                          placeholder: "title-placeholder".tr(),
                                          nextWithInput: (text) async {
                                            int length = await database
                                                .getAmountOfAssociatedTitles();

                                            await database
                                                .createOrUpdateAssociatedTitle(
                                              insert: true,
                                              TransactionAssociatedTitle(
                                                associatedTitlePk: "-1",
                                                categoryFk:
                                                    widget.category == null
                                                        ? "-1"
                                                        : widget.category!
                                                            .categoryPk,
                                                isExactMatch: false,
                                                title: text.trim(),
                                                dateCreated: DateTime.now(),
                                                dateTimeModified: null,
                                                order: length,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                    // Fix over-scroll stretch when keyboard pops up quickly
                                    Future.delayed(const Duration(milliseconds: 100),
                                        () {
                                      bottomSheetControllerGlobal.scrollTo(0,
                                          duration:
                                              const Duration(milliseconds: 100));
                                    });
                                  }),
                            ),
                          ],
                        ),
                  widget.category == null
                      ? const SizedBox.shrink()
                      : StreamBuilder<List<TransactionAssociatedTitle>>(
                          stream: database.watchAllAssociatedTitlesInCategory(
                            widget.category == null
                                ? "-1"
                                : widget.category!.categoryPk,
                            limit: 30,
                          ),
                          builder: (context, snapshot) {
                            // print(snapshot.data);
                            if (snapshot.hasData &&
                                (snapshot.data ?? []).isNotEmpty) {
                              return Column(
                                children: [
                                  for (int i = 0;
                                      i < snapshot.data!.length;
                                      i++)
                                    Builder(builder: (context) {
                                      TransactionAssociatedTitle
                                          associatedTitle = snapshot.data![i];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: AssociatedTitleContainer(
                                          title: associatedTitle,
                                          setTitle: (text) async {
                                            await database
                                                .createOrUpdateAssociatedTitle(
                                              TransactionAssociatedTitle(
                                                associatedTitlePk:
                                                    associatedTitle
                                                        .associatedTitlePk,
                                                categoryFk:
                                                    widget.category == null
                                                        ? "-1"
                                                        : widget.category!
                                                            .categoryPk,
                                                isExactMatch: associatedTitle
                                                    .isExactMatch,
                                                title: text.trim(),
                                                dateCreated: DateTime.now(),
                                                dateTimeModified: null,
                                                order: associatedTitle.order,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                ],
                              );
                            }
                            return const SizedBox();
                          }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssociatedTitleContainer extends StatelessWidget {
  const AssociatedTitleContainer({
    super.key,
    required this.title,
    required this.setTitle,
  });

  final TransactionAssociatedTitle title;
  final Function(String) setTitle;

  @override
  Widget build(BuildContext context) {
    String titleName = title.title;
    Color backgroundColor = appStateSettings["materialYou"]
        ? dynamicPastel(
            context, Theme.of(context).colorScheme.secondaryContainer,
            amountLight: 0, amountDark: 0.6)
        : getColor(context, "lightDarkAccent");

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Tappable(
        onTap: () {
          openBottomSheet(
            context,
            fullSnap: true,
            PopupFramework(
              title: "set-title".tr(),
              child: SelectText(
                setSelectedText: (text) {
                  titleName = text;
                  setTitle(text);
                },
                labelText: "set-title".tr(),
                selectedText: titleName,
                placeholder: "title-placeholder".tr(),
              ),
            ),
          );
          // Fix over-scroll stretch when keyboard pops up quickly
          Future.delayed(const Duration(milliseconds: 100), () {
            bottomSheetControllerGlobal.scrollTo(0,
                duration: const Duration(milliseconds: 100));
          });
        },
        borderRadius: 15,
        color: backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: TextFont(
                  text: title.title,
                  fontSize: 16.5,
                ),
              ),
            ),
            Tappable(
              onTap: () async {
                deleteAssociatedTitlePopup(
                  context,
                  title: title,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                );
              },
              borderRadius: 15,
              color: backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  appStateSettings["outlinedIcons"]
                      ? Icons.close_outlined
                      : Icons.close_rounded,
                  size: 25,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.width = 110,
    this.height = 52,
    this.openPage,
    this.borderRadius = 15,
    this.icon,
    this.afterOpenPage,
    this.onOpenPage,
  });

  final VoidCallback onTap;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? openPage;
  final IconData? icon;
  final Function? afterOpenPage;
  final Function? onOpenPage;

  @override
  Widget build(BuildContext context) {
    Color color = appStateSettings["materialYou"]
        ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
        : getColor(context, "lightDarkAccentHeavy");
    Widget getButton(onTap) {
      return Tappable(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.5,
              color: color,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          width: width,
          height: height,
          child: Center(
            child: Icon(
              icon ??
                  (appStateSettings["outlinedIcons"]
                      ? Icons.add_outlined
                      : Icons.add_rounded),
              size: 22,
              color: color,
            ),
          ),
        ),
        onTap: () {
          onTap();
        },
      );
    }

    if (openPage != null) {
      return Padding(
        padding: padding,
        child: OpenContainerNavigation(
          openPage: openPage!,
          button: (openPage) {
            return getButton(openPage);
          },
          borderRadius: borderRadius,
          onClosed: () {
            if (afterOpenPage != null) afterOpenPage!();
          },
          onOpen: () {
            if (onOpenPage != null) onOpenPage!();
          },
        ),
      );
    }
    Widget button = getButton(onTap);
    return Padding(
      padding: padding,
      child: button,
    );
  }
}

// class IncomeTypeButton extends StatelessWidget {
//   const IncomeTypeButton(
//       {Key? key, required this.onTap, required this.selectedIncome})
//       : super(key: key);
//   final VoidCallback onTap;
//   final bool selectedIncome;
//   @override
//   Widget build(BuildContext context) {
//     return Tappable(
//       onTap: onTap,
//       borderRadius: 10,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//         child: Row(
//           children: [
//             ButtonIcon(
//               onTap: onTap,
//               icon: selectedIncome
//                   ? appStateSettings["outlinedIcons"] ? Icons.exit_to_app_outlined : Icons.exit_to_app_rounded
//                   : appStateSettings["outlinedIcons"] ? Icons.logout_outlined : Icons.logout_rounded,
//               size: 41,
//             ),
//             SizedBox(width: 15),
//             Expanded(
//               child: TextFont(
//                 text: selectedIncome == false ? "expense".tr() : "income".tr(),
//                 fontWeight: FontWeight.bold,
//                 fontSize: 26,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class SelectIsSubcategory extends StatelessWidget {
  const SelectIsSubcategory(
      {required this.isMainCategoryWhenCreating,
      required this.onTap,
      required this.setMainCategoryPkForSubcategoryWhenCreating,
      super.key});
  final bool isMainCategoryWhenCreating;
  final Function(bool isMainCategoryWhenCreating) onTap;
  final Function(String mainCategoryPkForSubcategoryWhenCreating)
      setMainCategoryPkForSubcategoryWhenCreating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  filled: isMainCategoryWhenCreating,
                  alignLeft: true,
                  alignBeside: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  text: "main-category".tr(),
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.category_outlined
                      : Icons.category_rounded,
                  onTap: () {
                    onTap(true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  filled: !isMainCategoryWhenCreating,
                  transitionWhenFilled: false,
                  alignLeft: true,
                  alignBeside: true,
                  padding: const EdgeInsets.only(left: 20, right: 12, top: 15),
                  text: "subcategory".tr(),
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.move_to_inbox_outlined
                      : Icons.move_to_inbox_rounded,
                  infoButton: IconButtonScaled(
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.info_outlined
                        : Icons.info_outline_rounded,
                    iconSize: 16,
                    scale: 1.6,
                    onTap: () {
                      openBottomSheet(
                        context,
                        const SampleSubcategoriesPopup(),
                      );
                    },
                  ),
                  onTap: () {
                    onTap(false);
                  },
                  afterWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: ClipRRect(
                          child: SelectCategory(
                            horizontalList: true,
                            listPadding: const EdgeInsets.symmetric(horizontal: 10),
                            addButton: false,
                            setSelectedCategory: (category) {
                              setMainCategoryPkForSubcategoryWhenCreating(
                                  category.categoryPk);
                              onTap(false);
                            },
                            popRoute: false,
                          ),
                        ),
                      )
                    ],
                  ),
                  afterWidgetPadding: const EdgeInsets.only(bottom: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SampleSubcategoriesPopup extends StatelessWidget {
  const SampleSubcategoriesPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "subcategories".tr(),
      subtitle: "subcategories-description".tr(),
      child: Column(
        children: [
          TextFont(
            text: "examples".tr(),
            fontSize: 16,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "coffee.png",
                    categoryName: "drinks".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "coffee-cup.png",
                        categoryName: "coffee".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "bubble-tea.png",
                        categoryName: "bubble-tea".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "orange-juice.png",
                        categoryName: "soda".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "theatre.png",
                    categoryName: "entertainment".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "popcorn.png",
                        categoryName: "movies".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "music.png",
                        categoryName: "music".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "bowling.png",
                        categoryName: "activities".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "car.png",
                    categoryName: "car".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "gas-station.png",
                        categoryName: "gas".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "gears.png",
                        categoryName: "maintenance".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "bill.png",
                        categoryName: "insurance".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "flower.png",
                    categoryName: "beauty".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "barber.png",
                        categoryName: "haircut".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "makeup(1).png",
                        categoryName: "touchups".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "tshirt.png",
                        categoryName: "clothing".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FakeCategoryEntryPlaceholder extends StatelessWidget {
  const FakeCategoryEntryPlaceholder({
    required this.iconName,
    required this.categoryName,
    this.showAsSubcategory = true,
    super.key,
  });

  final String iconName;
  final String categoryName;
  final bool showAsSubcategory;

  @override
  Widget build(BuildContext context) {
    Widget categoryIcon = CategoryIcon(
      categoryPk: "-1",
      noBackground: true,
      category: TransactionCategory(
        categoryPk: "-1",
        name: "",
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        order: 0,
        income: false,
        iconName: iconName,
        colour: toHexString(Colors.red),
        emojiIconName: null,
      ),
      size: 40,
      sizePadding: showAsSubcategory ? 0 : 20,
      canEditByLongPress: false,
    );
    if (showAsSubcategory) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
          left: 5,
          right: 5,
        ),
        child: Tappable(
          color:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
          borderRadius: 10,
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                categoryIcon,
                TextFont(
                  text: categoryName,
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        categoryIcon,
        TextFont(
          text: categoryName,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ],
    );
  }
}
