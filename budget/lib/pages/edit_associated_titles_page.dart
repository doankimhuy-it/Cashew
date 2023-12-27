import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_associated_title_page.dart';
import 'package:budget/pages/edit_budget_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/category_icon.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fade_in.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/widgets/no_results.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/settings_containers.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/widgets/edit_row_entry.dart';
import 'package:budget/modified/reorderable_list.dart';

class EditAssociatedTitlesPage extends StatefulWidget {
  const EditAssociatedTitlesPage({
    super.key,
  });

  @override
  _EditAssociatedTitlesPageState createState() =>
      _EditAssociatedTitlesPageState();
}

class _EditAssociatedTitlesPageState extends State<EditAssociatedTitlesPage> {
  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;
  String searchValue = "";
  bool isFocused = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      database.fixOrderAssociatedTitles();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (searchValue != "") {
          setState(() {
            searchValue = "";
          });
          return false;
        } else {
          return true;
        }
      },
      child: PageFramework(
        horizontalPadding: getHorizontalPaddingConstrained(context),
        dragDownToDismiss: true,
        dragDownToDismissEnabled: dragDownToDismissEnabled,
        title: "edit-titles".tr(),
        scrollToTopButton: true,
        floatingActionButton: AnimateFABDelayed(
          fab: FAB(
            tooltip: "add-title".tr(),
            openPage: const SizedBox.shrink(),
            onTap: () {
              openBottomSheet(
                context,
                fullSnap: true,
                const AddAssociatedTitlePage(),
              );
              Future.delayed(const Duration(milliseconds: 100), () {
                // Fix over-scroll stretch when keyboard pops up quickly
                bottomSheetControllerGlobal.scrollTo(0,
                    duration: const Duration(milliseconds: 100));
              });
            },
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.all(15),
            tooltip: "add-title".tr(),
            onPressed: () {
              openBottomSheet(
                context,
                fullSnap: true,
                const AddAssociatedTitlePage(),
              );
              Future.delayed(const Duration(milliseconds: 100), () {
                // Fix over-scroll stretch when keyboard pops up quickly
                bottomSheetControllerGlobal.scrollTo(0,
                    duration: const Duration(milliseconds: 100));
              });
            },
            icon: Icon(appStateSettings["outlinedIcons"]
                ? Icons.add_outlined
                : Icons.add_rounded),
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Focus(
                onFocusChange: (value) {
                  setState(() {
                    isFocused = value;
                  });
                },
                child: TextInput(
                  labelText: "search-titles-placeholder".tr(),
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.search_outlined
                      : Icons.search_rounded,
                  onSubmitted: (value) {
                    setState(() {
                      searchValue = value;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      searchValue = value;
                    });
                  },
                  autoFocus: false,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedExpanded(
              expand: hideIfSearching(searchValue, isFocused, context) == false,
              child: const AskForTitlesToggle(),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedExpanded(
              expand: hideIfSearching(searchValue, isFocused, context) == false,
              child: const AutoTitlesToggle(),
            ),
          ),
          StreamBuilder<Map<String, TransactionCategory>>(
              stream: database.watchAllCategoriesMapped(),
              builder: (context, mappedCategoriesSnapshot) {
                return StreamBuilder<List<TransactionAssociatedTitle>>(
                  stream: database.watchAllAssociatedTitles(
                      searchFor: searchValue == "" ? null : searchValue),
                  builder: (context, snapshot) {
                    // print(snapshot.data);
                    if (snapshot.hasData && (snapshot.data ?? []).isEmpty) {
                      return SliverToBoxAdapter(
                        child: NoResults(
                          message: "no-titles-found".tr(),
                        ),
                      );
                    }
                    if (snapshot.hasData && (snapshot.data ?? []).isNotEmpty) {
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
                          TransactionAssociatedTitle associatedTitle =
                              snapshot.data![index];
                          return EditRowEntry(
                            canReorder: searchValue == "" &&
                                (snapshot.data ?? []).length != 1,
                            onTap: () {
                              openBottomSheet(
                                context,
                                fullSnap: true,
                                AddAssociatedTitlePage(
                                  associatedTitle: associatedTitle,
                                ),
                              );
                              Future.delayed(const Duration(milliseconds: 100), () {
                                // Fix over-scroll stretch when keyboard pops up quickly
                                bottomSheetControllerGlobal.scrollTo(0,
                                    duration: const Duration(milliseconds: 100));
                              });
                            },
                            padding: EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal:
                                    getPlatform() == PlatformOS.isIOS ? 17 : 7),
                            currentReorder:
                                currentReorder != -1 && currentReorder != index,
                            index: index,
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(width: 3),
                                CategoryIcon(
                                  categoryPk: associatedTitle.categoryFk,
                                  size: 25,
                                  margin: EdgeInsets.zero,
                                  sizePadding: 20,
                                  borderRadius: 1000,
                                  category: mappedCategoriesSnapshot
                                      .data![associatedTitle.categoryFk],
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: TextFont(
                                    text: associatedTitle.title
                                    // +
                                    //     " - " +
                                    //     associatedTitle.order.toString()
                                    ,
                                    fontSize: 16,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                            onDelete: () async {
                              return (await deleteAssociatedTitlePopup(
                                    context,
                                    title: associatedTitle,
                                    routesToPopAfterDelete:
                                        RoutesToPopAfterDelete.None,
                                  )) ==
                                  DeletePopupAction.Delete;
                            },
                            openPage: Container(),
                            key: ValueKey(associatedTitle.associatedTitlePk),
                          );
                        },
                        itemCount: snapshot.data!.length,
                        onReorder: (intPrevious, intNew) async {
                          TransactionAssociatedTitle oldTitle =
                              snapshot.data![intPrevious];
                          intNew = snapshot.data!.length - intNew;
                          intPrevious = snapshot.data!.length - intPrevious;
                          if (intNew > intPrevious) {
                            await database.moveAssociatedTitle(
                                oldTitle.associatedTitlePk,
                                intNew - 1,
                                oldTitle.order);
                          } else {
                            await database.moveAssociatedTitle(
                                oldTitle.associatedTitlePk,
                                intNew,
                                oldTitle.order);
                          }

                          return true;
                        },
                      );
                    }
                    return SliverToBoxAdapter(
                      child: Container(),
                    );
                  },
                );
              }),
          const SliverToBoxAdapter(
            child: SizedBox(height: 85),
          ),
        ],
      ),
    );
  }
}

Future<DeletePopupAction?> deleteAssociatedTitlePopup(
  BuildContext context, {
  required TransactionAssociatedTitle title,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-title-question".tr(),
    subtitle: title.title,
  );
  if (action == DeletePopupAction.Delete) {
    if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
      Navigator.of(context).pop();
    }
    openLoadingPopupTryCatch(() async {
      await database.deleteAssociatedTitle(
          title.associatedTitlePk, title.order);
      openSnackbar(
        SnackbarMessage(
          title: "deleted-title".tr(),
          icon: Icons.delete,
          description: title.title,
        ),
      );
    });
  }
  return action;
}

class AutoTitlesToggle extends StatelessWidget {
  const AutoTitlesToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "auto-add-titles".tr(),
      description: "auto-add-titles-description".tr(),
      onSwitched: (value) {
        updateSettings("autoAddAssociatedTitles", value,
            pagesNeedingRefresh: [], updateGlobalState: false);
      },
      initialValue: appStateSettings["autoAddAssociatedTitles"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.add_box_outlined
          : Icons.add_box_rounded,
    );
  }
}

class AskForTitlesToggle extends StatefulWidget {
  const AskForTitlesToggle({super.key});

  @override
  State<AskForTitlesToggle> createState() => _AskForTitlesToggleState();
}

class _AskForTitlesToggleState extends State<AskForTitlesToggle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainerSwitch(
          title: "ask-for-transaction-title".tr(),
          description: "ask-for-transaction-title-description".tr(),
          onSwitched: (value) {
            updateSettings(
              "askForTransactionTitle",
              value,
              updateGlobalState: false,
            );
            setState(() {});
          },
          initialValue: appStateSettings["askForTransactionTitle"],
          icon: appStateSettings["outlinedIcons"]
              ? Icons.text_fields_outlined
              : Icons.text_fields_rounded,
        ),
        AnimatedExpanded(
          expand: getIsFullScreen(context) == false &&
              appStateSettings["askForTransactionTitle"] == true,
          child: const AskForNotesToggle(),
        ),
      ],
    );
  }
}

class AskForNotesToggle extends StatelessWidget {
  const AskForNotesToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "ask-for-notes-with-title".tr(),
      description: "ask-for-notes-with-title-description".tr(),
      onSwitched: (value) {
        updateSettings(
          "askForTransactionNoteWithTitle",
          value,
          updateGlobalState: false,
        );
      },
      initialValue: appStateSettings["askForTransactionNoteWithTitle"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.sticky_note_2_outlined
          : Icons.sticky_note_2_rounded,
    );
  }
}
