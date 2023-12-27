import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_category_page.dart';
import 'package:budget/pages/home_page/home_page_wallet_switcher.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/util/keep_alive_client_mixin.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/wallet_entry.dart';
import 'package:flutter/material.dart';

class HomePageWalletList extends StatelessWidget {
  const HomePageWalletList({super.key});

  @override
  Widget build(BuildContext context) {
    return KeepAliveClientMixin(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13, left: 13, right: 13),
        child: Container(
          decoration: BoxDecoration(
            color: getColor(context, "lightDarkAccentHeavyLight"),
            boxShadow: boxShadowCheck(boxShadowGeneral(context)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: StreamBuilder<List<WalletWithDetails>>(
              stream: database.watchAllWalletsWithDetails(
                  homePageWidgetDisplay: HomePageWidgetDisplay.WalletList),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (snapshot.hasData && snapshot.data!.isNotEmpty)
                        const SizedBox(height: 8),
                      for (WalletWithDetails walletDetails in snapshot.data!)
                        WalletEntryRow(
                          selected: appStateSettings["selectedWalletPk"] ==
                              walletDetails.wallet.walletPk,
                          walletWithDetails: walletDetails,
                        ),
                      if (snapshot.hasData && snapshot.data!.isNotEmpty)
                        const SizedBox(height: 8),
                      if (snapshot.hasData && snapshot.data!.isEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: AddButton(
                                onTap: () {
                                  openBottomSheet(
                                    context,
                                    const EditHomePagePinnedWalletsPopup(
                                      homePageWidgetDisplay:
                                          HomePageWidgetDisplay.WalletList,
                                    ),
                                    useCustomController: true,
                                  );
                                },
                                height: 40,
                                // icon: Icons.format_list_bulleted_add,
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                }
                return Container();
              },
            ),
          ),
        ),
      ),
    );
  }
}
