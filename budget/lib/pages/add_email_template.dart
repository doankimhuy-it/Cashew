import 'package:budget/database/tables.dart';
import 'package:budget/pages/auto_transactions_page_email.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/save_bottom_button.dart';
import 'package:budget/widgets/select_category.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:googleapis/gmail/v1.dart' as gMail;

class AddEmailTemplate extends StatefulWidget {
  const AddEmailTemplate({
    super.key,
    required this.messagesList,
    this.scannerTemplate,
  });
  final List<gMail.Message> messagesList;
  //When a transaction is passed in, we are editing that transaction
  final ScannerTemplate? scannerTemplate;

  @override
  _AddEmailTemplateState createState() => _AddEmailTemplateState();
}

class _AddEmailTemplateState extends State<AddEmailTemplate> {
  int characterPadding = 8;

  bool? canAddTemplate;

  TransactionCategory? selectedCategory;
  String? selectedMessageString;
  String? selectedName;
  String? selectedSubject;
  String? amountTransactionBefore;
  String? amountTransactionAfter;
  String? selectedAmount;
  String? titleTransactionBefore;
  String? titleTransactionAfter;
  String? selectedTitle;

  @override
  void initState() {
    super.initState();
    if (widget.scannerTemplate != null) {
      selectedName = widget.scannerTemplate!.templateName;
      selectedSubject = widget.scannerTemplate!.contains;
      amountTransactionBefore = widget.scannerTemplate!.amountTransactionBefore;
      amountTransactionAfter = widget.scannerTemplate!.amountTransactionAfter;
      titleTransactionBefore = widget.scannerTemplate!.titleTransactionBefore;
      titleTransactionAfter = widget.scannerTemplate!.titleTransactionAfter;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateInitial();
    });
  }

  updateInitial() async {
    if (widget.scannerTemplate != null) {
      TransactionCategory? getSelectedCategory = await database
          .getCategoryInstance(widget.scannerTemplate!.defaultCategoryFk);
      setState(() {
        selectedCategory = getSelectedCategory;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  determineBottomButton() {
    if (double.tryParse(selectedAmount ?? "") == null &&
        selectedMessageString != null) {
      setState(() {
        canAddTemplate = false;
      });
      return;
    }
    if (selectedTitle == null && selectedMessageString != null) {
      setState(() {
        canAddTemplate = false;
      });
      return;
    }

    if (selectedName == null) return;
    if (selectedCategory == null) return;
    if (amountTransactionBefore == null) return;
    if (amountTransactionAfter == null) return;
    if (titleTransactionBefore == null) return;
    if (titleTransactionAfter == null) return;

    setState(() {
      canAddTemplate = true;
    });
    return true;
  }

  void setMessageString(String messageString) {
    setState(() {
      selectedMessageString = messageString;
    });
    determineBottomButton();
    return;
  }

  void setSelectedName(String title) {
    setState(() {
      selectedName = title;
    });
    determineBottomButton();
    return;
  }

  void setSelectedCategory(TransactionCategory category) {
    setState(() {
      selectedCategory = category;
    });
    determineBottomButton();
    return;
  }

  Widget selectSubjectText(String messageString, VoidCallback next) {
    return PopupFramework(
      title: "Select Subject Text",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "Only these emails that contain this text will be scanned.",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 5),
          const TextFont(
            text:
                "Long press/double tap to select text. Press the 'Done' button at the bottom after selected",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              color: getColor(context, "lightDarkAccentHeavy"),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: SelectableText(
                messageString,
                toolbarOptions: const ToolbarOptions(
                    copy: false, cut: false, paste: false, selectAll: false),
                onSelectionChanged: (selection, changeCause) {
                  selectedSubject = messageString.substring(
                      selection.baseOffset, selection.extentOffset);
                  determineBottomButton();
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Button(
            label: "done".tr(),
            onTap: () {
              determineBottomButton();
              setState(() {});
              Navigator.pop(context);
              next();
            },
          )
        ],
      ),
    );
  }

  Widget selectAmountText(String messageString, VoidCallback next) {
    return PopupFramework(
      title: "Select Amount",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "Select the amount of the transaction.",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            maxLines: 10,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 5),
          const TextFont(
            text:
                "Long press/double tap to select text. Press the 'Done' button at the bottom after selected",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              color: getColor(context, "lightDarkAccentHeavy"),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: SelectableText(
                messageString,
                toolbarOptions: const ToolbarOptions(
                    copy: false, cut: false, paste: false, selectAll: false),
                onSelectionChanged: (selection, changeCause) {
                  if (selection.baseOffset - characterPadding < 0) {
                    amountTransactionBefore =
                        messageString.substring(0, selection.baseOffset);
                  } else {
                    amountTransactionBefore = messageString.substring(
                        selection.baseOffset - characterPadding,
                        selection.baseOffset);
                  }
                  if (selection.extentOffset + characterPadding >
                      messageString.length - 1) {
                    amountTransactionAfter = messageString.substring(
                        selection.extentOffset, messageString.length);
                  } else {
                    amountTransactionAfter = messageString.substring(
                        selection.extentOffset,
                        selection.extentOffset + characterPadding);
                  }
                  selectedAmount = messageString.substring(
                      selection.baseOffset, selection.extentOffset);
                  determineBottomButton();
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Button(
            label: "done".tr(),
            onTap: () {
              determineBottomButton();
              Navigator.pop(context);
              setState(() {});
              next();
            },
          )
        ],
      ),
    );
  }

  Widget selectTitleText(String messageString, VoidCallback next) {
    return PopupFramework(
      title: "Select Title",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "Select the title of the transaction.",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            maxLines: 10,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 5),
          const TextFont(
            text:
                "Long press/double tap to select text. Press the 'Done' button at the bottom after selected",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              color: getColor(context, "lightDarkAccentHeavy"),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: SelectableText(
                messageString,
                toolbarOptions: const ToolbarOptions(
                    copy: false, cut: false, paste: false, selectAll: false),
                onSelectionChanged: (selection, changeCause) {
                  if (selection.baseOffset - characterPadding < 0) {
                    titleTransactionBefore =
                        messageString.substring(0, selection.baseOffset);
                  } else {
                    titleTransactionBefore = messageString.substring(
                        selection.baseOffset - characterPadding,
                        selection.baseOffset);
                  }

                  if (selection.extentOffset + characterPadding >
                      messageString.length - 1) {
                    titleTransactionAfter = messageString.substring(
                        selection.extentOffset, messageString.length);
                  } else {
                    titleTransactionAfter = messageString.substring(
                        selection.extentOffset,
                        selection.extentOffset + characterPadding);
                  }
                  selectedTitle = messageString.substring(
                      selection.baseOffset, selection.extentOffset);
                  determineBottomButton();
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Button(
            label: "done".tr(),
            onTap: () {
              determineBottomButton();
              next();
              setState(() {});
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  Future addTemplate() async {
    print("Added template");
    await database.createOrUpdateScannerTemplate(
      insert: widget.scannerTemplate == null,
      createTemplate(),
    );
    Navigator.pop(context);
  }

  ScannerTemplate createTemplate() {
    return ScannerTemplate(
      scannerTemplatePk: widget.scannerTemplate != null
          ? widget.scannerTemplate!.scannerTemplatePk
          : "-1",
      dateCreated: widget.scannerTemplate != null
          ? widget.scannerTemplate!.dateCreated
          : DateTime.now(),
      dateTimeModified: null,
      amountTransactionAfter: amountTransactionAfter ?? "",
      amountTransactionBefore: amountTransactionBefore ?? "",
      contains: selectedSubject ?? "",
      defaultCategoryFk: selectedCategory!.categoryPk,
      templateName: selectedName ?? "",
      titleTransactionAfter: titleTransactionAfter ?? "",
      titleTransactionBefore: titleTransactionBefore ?? "",
      walletFk: "0",
      ignore: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.scannerTemplate != null) {
          discardChangesPopup(
            context,
            previousObject: widget.scannerTemplate,
            currentObject: createTemplate(),
          );
        } else {
          discardChangesPopup(context);
        }
        return false;
      },
      child: Scaffold(
        // resizeToAvoidBottomInset: false,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () {
            //Minimize keyboard when tap non interactive widget
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: Stack(
            children: [
              PageFramework(
                dragDownToDismiss: true,
                title: widget.scannerTemplate == null
                    ? "Add Template"
                    : "Edit Template",
                onBackButton: () async {
                  if (widget.scannerTemplate != null) {
                    discardChangesPopup(
                      context,
                      previousObject: widget.scannerTemplate,
                      currentObject: createTemplate(),
                    );
                  } else {
                    discardChangesPopup(context);
                  }
                },
                onDragDownToDismiss: () async {
                  if (widget.scannerTemplate != null) {
                    discardChangesPopup(
                      context,
                      previousObject: widget.scannerTemplate,
                      currentObject: createTemplate(),
                    );
                  } else {
                    discardChangesPopup(context);
                  }
                },
                listWidgets: [
                  Container(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextInput(
                      labelText: "name-placeholder".tr(),
                      bubbly: false,
                      initialValue: selectedName,
                      onChanged: (text) {
                        setSelectedName(text);
                      },
                      padding: const EdgeInsets.only(left: 7, right: 7),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      topContentPadding: 20,
                    ),
                  ),
                  Container(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFont(
                      text: "Default Category",
                      textColor: getColor(context, "textLight"),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFont(
                      text:
                          "Categories are also automatically set based on the Associated Title.",
                      textColor: getColor(context, "textLight"),
                      fontSize: 11,
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SelectCategory(
                    horizontalList: true,
                    selectedCategory: selectedCategory,
                    setSelectedCategory: setSelectedCategory,
                    popRoute: false,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Button(
                        label: "Select Email",
                        onTap: () {
                          openBottomSheet(
                            context,
                            PopupFramework(
                              title: "Select Email",
                              hasPadding: false,
                              child: EmailsList(
                                backgroundColor: getColor(context, "white"),
                                messagesList: widget.messagesList,
                                onTap: (messageString) {
                                  setMessageString(messageString);
                                  Navigator.pop(context);
                                  openBottomSheet(
                                    context,
                                    selectSubjectText(
                                      selectedMessageString ?? "",
                                      () {
                                        openBottomSheet(
                                          context,
                                          selectAmountText(
                                            selectedMessageString ?? "",
                                            () {
                                              openBottomSheet(
                                                context,
                                                selectTitleText(
                                                  selectedMessageString ?? "",
                                                  () {},
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: selectedMessageString == null
                        ? Container()
                        : Column(
                            children: [
                              TemplateInfoBox(
                                onTap: () {
                                  openBottomSheet(
                                    context,
                                    selectSubjectText(
                                      selectedMessageString ?? "",
                                      () {},
                                    ),
                                  );
                                },
                                selectedText: selectedSubject ?? "",
                                label: "Subject: ",
                                secondaryLabel:
                                    "All emails containing this text will be checked.",
                              ),
                              const SizedBox(height: 10),
                              TemplateInfoBox(
                                onTap: () {
                                  openBottomSheet(
                                    context,
                                    selectAmountText(
                                      selectedMessageString ?? "",
                                      () {},
                                    ),
                                  );
                                },
                                selectedText: selectedAmount ?? "",
                                label: "Amount: ",
                                secondaryLabel:
                                    "The selected amount from this email. Surrounding text will be used to find this amount in new emails.",
                                extraCheck: (input) {
                                  return double.tryParse(input) != null;
                                },
                                extraCheckMessage:
                                    "Please select a valid number!",
                              ),
                              const SizedBox(height: 10),
                              TemplateInfoBox(
                                onTap: () {
                                  openBottomSheet(
                                    context,
                                    selectTitleText(
                                      selectedMessageString ?? "",
                                      () {},
                                    ),
                                  );
                                },
                                selectedText: selectedTitle ?? "",
                                label: "Title: ",
                                secondaryLabel:
                                    "The selected title from this email. Surrounding text will be used to find this title in new emails.",
                              ),
                            ],
                          ),
                  ),
                  widget.scannerTemplate == null &&
                          selectedMessageString == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: getColor(context, "lightDarkAccentHeavy"),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const TextFont(
                                  text: "Sample",
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                TextFont(
                                  text: (selectedSubject ?? "")
                                      .replaceAll("\n", ""),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 10,
                                  textColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 2),
                                TextFont(
                                  text: "${(amountTransactionBefore ?? "")
                                          .replaceAll("\n", "")}... [Amount] ...${(amountTransactionAfter ?? "")
                                          .replaceAll("\n", "")}",
                                  fontSize: 16,
                                  maxLines: 10,
                                  textColor:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 2),
                                TextFont(
                                  text: "${(titleTransactionBefore ?? "")
                                          .replaceAll("\n", "")}... [Title] ...${(titleTransactionAfter ?? "")
                                          .replaceAll("\n", "")}",
                                  fontSize: 16,
                                  maxLines: 10,
                                  textColor:
                                      Theme.of(context).colorScheme.tertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 70),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SaveBottomButton(
                  label: widget.scannerTemplate == null
                      ? "Add Template"
                      : "save-changes".tr(),
                  onTap: () {
                    addTemplate();
                  },
                  disabled: !(canAddTemplate ?? false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplateInfoBox extends StatelessWidget {
  const TemplateInfoBox(
      {required this.onTap,
      required this.selectedText,
      required this.label,
      required this.secondaryLabel,
      this.extraCheck,
      this.extraCheckMessage,
      super.key});

  final Function() onTap;
  final String selectedText;
  final String label;
  final String secondaryLabel;
  final Function(String)? extraCheck;
  final String? extraCheckMessage;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      color: selectedText == "" ||
              (extraCheck != null && extraCheck!(selectedText) == false)
          ? Theme.of(context).colorScheme.selectableColorRed.withOpacity(0.5)
          : getColor(context, "lightDarkAccent"),
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18.0,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFont(
                  text: label,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                Expanded(
                  child: TextFont(
                    text: selectedText,
                    fontSize: 17,
                    textColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    maxLines: 10,
                  ),
                )
              ],
            ),
            (extraCheck != null &&
                    extraCheck!(selectedText) == false &&
                    extraCheckMessage != null)
                ? TextFont(
                    fontSize: 14,
                    text: extraCheckMessage ?? "",
                    textColor: getColor(context, "black").withOpacity(0.9),
                    maxLines: 10,
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 3),
            TextFont(
              fontSize: 14,
              text: secondaryLabel,
              textColor: selectedText == "" ||
                      (extraCheck != null && extraCheck!(selectedText) == false)
                  ? getColor(context, "black").withOpacity(0.5)
                  : getColor(context, "textLight"),
              maxLines: 10,
            )
          ],
        ),
      ),
    );
  }
}
