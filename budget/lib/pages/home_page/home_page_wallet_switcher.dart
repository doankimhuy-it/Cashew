import 'package:budget/colors.dart';
import 'package:budget/database/initialize_default_database.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_category_page.dart';
import 'package:budget/pages/add_wallet_page.dart';
import 'package:budget/pages/edit_budget_page.dart';
import 'package:budget/pages/edit_wallets_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/util/keep_alive_client_mixin.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/select_items.dart';
import 'package:budget/widgets/wallet_entry.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePageWalletSwitcher extends StatelessWidget {
  const HomePageWalletSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return KeepAliveClientMixin(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13.0),
        child: StreamBuilder<List<WalletWithDetails>>(
          stream: database.watchAllWalletsWithDetails(
              homePageWidgetDisplay: HomePageWidgetDisplay.WalletSwitcher),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (WalletWithDetails walletDetails in snapshot.data!)
                      WalletEntry(
                        selected: appStateSettings["selectedWalletPk"] ==
                            walletDetails.wallet.walletPk,
                        walletWithDetails: walletDetails,
                      ),
                    Stack(
                      children: [
                        SizedBox(
                          width: 130,
                          child: IgnorePointer(
                            child: Visibility(
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Opacity(
                                opacity: 0,
                                child: WalletEntry(
                                  selected: false,
                                  walletWithDetails: WalletWithDetails(
                                    wallet: defaultWallet(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6, right: 6),
                            child: AddButton(
                              onTap: () {
                                openBottomSheet(
                                  context,
                                  const EditHomePagePinnedWalletsPopup(
                                    homePageWidgetDisplay:
                                        HomePageWidgetDisplay.WalletSwitcher,
                                  ),
                                  useCustomController: true,
                                );
                              },
                              // icon: Icons.format_list_bulleted_add,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}

class EditHomePagePinnedWalletsPopup extends StatelessWidget {
  const EditHomePagePinnedWalletsPopup({
    super.key,
    required this.homePageWidgetDisplay,
    this.includeFramework = true,
    this.highlightSelected = false,
    this.useCheckMarks = false,
    this.onAnySelected,
    this.allSelected = false,
    this.showCyclePicker = false,
  });

  final HomePageWidgetDisplay homePageWidgetDisplay;
  final bool includeFramework;
  final bool highlightSelected;
  final bool useCheckMarks;
  final Function? onAnySelected;
  final bool allSelected;
  final bool showCyclePicker;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionWallet>>(
      stream: database.getAllPinnedWallets(homePageWidgetDisplay).$1,
      builder: (context, snapshot2) {
        Map<String, TransactionWallet> walletsIndexedByPk =
            Provider.of<AllWallets>(context).indexedByPk;
        List<String> allWalletsPks = walletsIndexedByPk.keys.toList();
        List<TransactionWallet> allPinnedWallets = snapshot2.data ?? [];
        Widget child = Column(
          children: [
            if (allWalletsPks.isEmpty)
              NoResultsCreate(
                message: "no-accounts-found".tr(),
                buttonLabel: "create-account".tr(),
                route: const AddWalletPage(
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                ),
              ),
            if (snapshot2.hasData)
              SelectItems(
                allSelected: allSelected,
                highlightSelected: highlightSelected,
                syncWithInitial: true,
                checkboxCustomIconSelected:
                    useCheckMarks ? null : Icons.push_pin_rounded,
                checkboxCustomIconUnselected:
                    useCheckMarks ? null : Icons.push_pin_outlined,
                items: allWalletsPks,
                getColor: (walletPk, selected) {
                  TransactionWallet? wallet = walletsIndexedByPk[walletPk];
                  return HexColor(wallet?.colour,
                          defaultColor: Theme.of(context).colorScheme.primary)
                      .withOpacity(selected == true ? 0.7 : 0.5);
                },
                displayFilter: (walletPk) {
                  TransactionWallet? wallet = walletsIndexedByPk[walletPk];
                  return wallet?.name;
                },
                initialItems: [
                  for (TransactionWallet wallet in allPinnedWallets)
                    wallet.walletPk.toString()
                ],
                onChangedSingleItem: (walletPk) async {
                  TransactionWallet? wallet = walletsIndexedByPk[walletPk];
                  if (wallet != null) {
                    List<HomePageWidgetDisplay> currentList =
                        wallet.homePageWidgetDisplay ?? [];
                    if (currentList.contains(homePageWidgetDisplay)) {
                      currentList.remove(homePageWidgetDisplay);
                    } else {
                      currentList.add(homePageWidgetDisplay);
                    }
                    await database.createOrUpdateWallet(
                      wallet.copyWith(
                          homePageWidgetDisplay: Value(currentList)),
                    );
                  }
                  if (onAnySelected != null) onAnySelected!();
                },
                onLongPress: (String walletPk) async {
                  TransactionWallet? wallet = walletsIndexedByPk[walletPk];
                  pushRoute(
                    context,
                    AddWalletPage(
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                      wallet: wallet,
                    ),
                  );
                },
              ),
            if (allWalletsPks.isNotEmpty && includeFramework == true)
              AddButton(
                onTap: () {},
                height: 50,
                width: null,
                padding: const EdgeInsets.only(
                  left: 13,
                  right: 13,
                  bottom: 13,
                  top: 13,
                ),
                openPage: const AddWalletPage(
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                ),
                afterOpenPage: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    bottomSheetControllerGlobalCustomAssigned?.snapToExtent(0);
                  });
                },
              ),
            // if (showCyclePicker &&
            //         homePageWidgetDisplay ==
            //             HomePageWidgetDisplay.WalletSwitcher ||
            //     homePageWidgetDisplay == HomePageWidgetDisplay.WalletList)
            //   HorizontalBreakAbove(
            //     enabled: true,
            //     child: Column(
            //       children: [
            //         Padding(
            //           padding: const EdgeInsets.only(
            //               bottom: 10, left: 15, right: 15, top: 4),
            //           child: TextFont(
            //             text: "customize-period-for-account-totals".tr(),
            //             textAlign: TextAlign.center,
            //             fontSize: 16,
            //             textColor: getColor(context, "black").withOpacity(0.8),
            //           ),
            //         ),
            //         PeriodCyclePicker(
            //           cycleSettingsExtension: homePageWidgetDisplay ==
            //                   HomePageWidgetDisplay.WalletSwitcher
            //               ? "Wallets"
            //               : homePageWidgetDisplay ==
            //                       HomePageWidgetDisplay.WalletList
            //                   ? "WalletsList"
            //                   : "",
            //         ),
            //       ],
            //     ),
            //   ),
          ],
        );
        if (includeFramework) {
          return PopupFramework(
            title: "select-accounts".tr(),
            outsideExtraWidget: IconButton(
              iconSize: 25,
              padding:
                  EdgeInsets.all(getPlatform() == PlatformOS.isIOS ? 15 : 20),
              icon: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.edit_outlined
                    : Icons.edit_rounded,
              ),
              onPressed: () async {
                pushRoute(context, const EditWalletsPage());
              },
            ),
            child: child,
          );
        } else {
          return child;
        }
      },
    );
  }
}
