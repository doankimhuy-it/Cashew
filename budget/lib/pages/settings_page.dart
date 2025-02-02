import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/pages/about_page.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/bill_splitter.dart';
import 'package:budget/pages/budgets_list_page.dart';
import 'package:budget/pages/credit_debt_transactions_page.dart';
import 'package:budget/pages/edit_home_page.dart';
import 'package:budget/pages/edit_objectives_page.dart';
import 'package:budget/pages/exchange_rates_page.dart';
import 'package:budget/pages/home_page/home_page_net_worth.dart';
import 'package:budget/pages/objectives_list_page.dart';
import 'package:budget/pages/transactions_list_page.dart';
import 'package:budget/pages/upcoming_overdue_transactions_page.dart';
import 'package:budget/struct/language_map.dart';
import 'package:budget/struct/nav_bar_icons_data.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/export_db.dart';
import 'package:budget/widgets/import_csv.dart';
import 'package:budget/widgets/export_csv.dart';
import 'package:budget/pages/auto_transactions_page_email.dart';
import 'package:budget/pages/edit_associated_titles_page.dart';
import 'package:budget/pages/edit_budget_page.dart';
import 'package:budget/pages/edit_categories_page.dart';
import 'package:budget/pages/edit_wallets_page.dart';
import 'package:budget/pages/notifications_page.dart';
import 'package:budget/pages/subscriptions_page.dart';
import 'package:budget/widgets/account_and_backup.dart';
import 'package:budget/widgets/import_db.dart';
import 'package:budget/widgets/navigation_framework.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/radio_tems.dart';
import 'package:budget/widgets/restart_app.dart';
import 'package:budget/widgets/select_color.dart';
import 'package:budget/widgets/settings_containers.dart';
import 'package:budget/pages/wallet_details_page.dart';
import 'package:budget/struct/initialize_biometrics.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:budget/widgets/util/check_widget_launch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/main.dart';
import 'package:provider/provider.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:app_settings/app_settings.dart';
import 'package:universal_io/io.dart';

class MoreActionsPage extends StatefulWidget {
  const MoreActionsPage({
    super.key,
  });

  @override
  State<MoreActionsPage> createState() => MoreActionsPageState();
}

class MoreActionsPageState extends State<MoreActionsPage>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<PageFrameworkState> pageState = GlobalKey();

  void refreshState() {
    print("refresh settings");
    setState(() {});
  }

  void scrollToTop() {
    pageState.currentState!.scrollToTop();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, _) {
      return PageFramework(
        key: pageState,
        title: "more-actions".tr(),
        backButton: false,
        horizontalPadding: getHorizontalPaddingConstrained(context),
        listWidgets: const [MorePages()],
      );
    });
  }
}

class MorePages extends StatelessWidget {
  const MorePages({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const AboutPage(),
                  title: "about-app".tr(namedArgs: {"app": globalAppName}),
                  icon: navBarIconsData["about"]!.iconData,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SettingsContainerOpenPage(
                  openPage: SettingsPageFramework(
                    key: settingsPageFrameworkStateKey,
                  ),
                  title: navBarIconsData["settings"]!.labelLong.tr(),
                  icon: navBarIconsData["settings"]!.iconData,
                  description: "settings-and-customization-description".tr(),
                  isOutlined: true,
                  isWideOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const WalletDetailsPage(wallet: null),
                  title: navBarIconsData["allSpending"]!.labelLong.tr(),
                  icon: navBarIconsData["allSpending"]!.iconData,
                  description: "all-spending-description".tr(),
                  isOutlined: true,
                  isWideOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const NotificationsPage(),
                  title: navBarIconsData["notifications"]!.label.tr(),
                  icon: navBarIconsData["notifications"]!.iconData,
                  isOutlined: true,
                ),
              ),
              const Expanded(child: GoogleAccountLoginButton()),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const SubscriptionsPage(),
                  title: navBarIconsData["subscriptions"]!.label.tr(),
                  icon: navBarIconsData["subscriptions"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const UpcomingOverdueTransactions(
                      overdueTransactions: null),
                  title: navBarIconsData["scheduled"]!.label.tr(),
                  icon: navBarIconsData["scheduled"]!.iconData,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const ObjectivesListPage(
                    backButton: true,
                  ),
                  title: navBarIconsData["goals"]!.label.tr(),
                  icon: navBarIconsData["goals"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const CreditDebtTransactions(isCredit: null),
                  title: navBarIconsData["loans"]!.label.tr(),
                  icon: navBarIconsData["loans"]!.iconData,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: SettingsContainerOpenPage(
                  isOutlinedColumn: true,
                  openPage: const EditWalletsPage(),
                  title: navBarIconsData["accountDetails"]!.label.tr(),
                  icon: navBarIconsData["accountDetails"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                flex: 1,
                child: SettingsContainerOpenPage(
                  isOutlinedColumn: true,
                  // If budget page not pinned to home, open budget list page
                  openPage: appStateSettings["customNavBarShortcut1"] !=
                              "budgets" &&
                          appStateSettings["customNavBarShortcut2"] != "budgets"
                      ? const BudgetsListPage(enableBackButton: true)
                      : const EditBudgetPage(),
                  title: navBarIconsData["budgetDetails"]!.label.tr(),
                  icon: navBarIconsData["budgetDetails"]!.iconData,
                  iconScale: navBarIconsData["budgetDetails"]!.iconScale,
                  isOutlined: true,
                ),
              ),
              Expanded(
                flex: 1,
                child: SettingsContainerOpenPage(
                  isOutlinedColumn: true,
                  openPage: const EditCategoriesPage(),
                  title: navBarIconsData["categoriesDetails"]!.label.tr(),
                  icon: navBarIconsData["categoriesDetails"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                flex: 1,
                child: SettingsContainerOpenPage(
                  isOutlinedColumn: true,
                  openPage: const EditAssociatedTitlesPage(),
                  title: navBarIconsData["titlesDetails"]!.label.tr(),
                  icon: navBarIconsData["titlesDetails"]!.iconData,
                  isOutlined: true,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class EnterName extends StatelessWidget {
  const EnterName({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "username".tr(),
      icon: Icons.edit,
      onTap: () {
        enterNameBottomSheet(context);
        // Fix over-scroll stretch when keyboard pops up quickly
        Future.delayed(const Duration(milliseconds: 100), () {
          bottomSheetControllerGlobal.scrollTo(0,
              duration: const Duration(milliseconds: 100));
        });
      },
    );
  }
}

Future enterNameBottomSheet(context) async {
  return await openBottomSheet(
    context,
    fullSnap: true,
    PopupFramework(
      title: "enter-name".tr(),
      child: Column(
        children: [
          SelectText(
            icon: appStateSettings["outlinedIcons"]
                ? Icons.person_outlined
                : Icons.person_rounded,
            setSelectedText: (_) {},
            nextWithInput: (text) {
              updateSettings("username", text.trim(),
                  pagesNeedingRefresh: [0], updateGlobalState: false);
            },
            selectedText: appStateSettings["username"],
            placeholder: "nickname".tr(),
            autoFocus: false,
            requestLateAutoFocus: true,
          ),
        ],
      ),
    ),
  );
}

class SettingsPageFramework extends StatefulWidget {
  const SettingsPageFramework({super.key});

  @override
  State<SettingsPageFramework> createState() => SettingsPageFrameworkState();
}

class SettingsPageFrameworkState extends State<SettingsPageFramework> {
  void refreshState() {
    print("refresh settings framework");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "settings".tr(),
      dragDownToDismiss: true,
      listWidgets: const [SettingsPageContent()],
    );
  }
}

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsHeader(title: "theme".tr()),
        Builder(
          builder: (context) {
            late Color? selectedColor =
                HexColor(appStateSettings["accentColor"]);

            return SettingsContainer(
              onTap: () {
                openBottomSheet(
                  context,
                  PopupFramework(
                    title: "select-color".tr(),
                    child: Column(
                      children: [
                        getPlatform() == PlatformOS.isIOS
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: SettingsContainerSwitch(
                                  title: "colorful-interface".tr(),
                                  onSwitched: (value) {
                                    updateSettings("materialYou", value,
                                        updateGlobalState: true);
                                  },
                                  initialValue: appStateSettings["materialYou"],
                                  icon: appStateSettings["outlinedIcons"]
                                      ? Icons.brush_outlined
                                      : Icons.brush_rounded,
                                  enableBorderRadius: true,
                                ),
                              )
                            : const SizedBox.shrink(),
                        SelectColor(
                          includeThemeColor: false,
                          selectedColor: selectedColor,
                          setSelectedColor: (color) {
                            selectedColor = color;
                            updateSettings("accentColor", toHexString(color),
                                updateGlobalState: true);
                            updateSettings("accentSystemColor", false,
                                updateGlobalState: true);
                            generateColors();
                            updateWidgetColorsAndText(context);
                          },
                          useSystemColorPrompt: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
              title: "accent-color".tr(),
              description: "accent-color-description".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.color_lens_outlined
                  : Icons.color_lens_rounded,
            );
          },
        ),
        getPlatform() == PlatformOS.isIOS
            ? const SizedBox.shrink()
            : SettingsContainerSwitch(
                title: "material-you".tr(),
                description: "material-you-description".tr(),
                onSwitched: (value) {
                  updateSettings("materialYou", value, updateGlobalState: true);
                },
                initialValue: appStateSettings["materialYou"],
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.brush_outlined
                    : Icons.brush_rounded,
              ),
        SettingsContainerDropdown(
          title: "theme-mode".tr(),
          icon: Theme.of(context).brightness == Brightness.light
              ? appStateSettings["outlinedIcons"]
                  ? Icons.lightbulb_outlined
                  : Icons.lightbulb_rounded
              : appStateSettings["outlinedIcons"]
                  ? Icons.dark_mode_outlined
                  : Icons.dark_mode_rounded,
          initial: appStateSettings["theme"].toString().capitalizeFirst,
          items: const ["Light", "Dark", "System"],
          onChanged: (value) async {
            if (value == "Light") {
              await updateSettings("theme", "light", updateGlobalState: true);
            } else if (value == "Dark") {
              await updateSettings("theme", "dark", updateGlobalState: true);
            } else if (value == "System") {
              await updateSettings("theme", "system", updateGlobalState: true);
            }
            updateWidgetColorsAndText(context);
          },
          getLabel: (item) {
            return item.toLowerCase().tr();
          },
        ),

        // EnterName(),
        SettingsHeader(title: "preferences".tr()),

        SettingsContainerOpenPage(
          openPage: const EditHomePage(),
          title: "edit-home-page".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.home_outlined
              : Icons.home_rounded,
        ),

        getIsFullScreen(context) == false
            ? SettingsContainerOpenPage(
                openPage: const NotificationsPage(),
                title: "notifications".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.notifications_outlined
                    : Icons.notifications_rounded,
              )
            : const SizedBox.shrink(),

        const BiometricsSettingToggle(),

        SettingsContainer(
          title: "language".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.language_outlined
              : Icons.language_rounded,
          afterWidget: Tappable(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextFont(
                text: languageDisplayFilter(
                    appStateSettings["locale"].toString()),
                fontSize: 14,
              ),
            ),
          ),
          onTap: () {
            openLanguagePicker(context);
          },
        ),

        SettingsContainerOpenPage(
          openPage: const MoreOptionsPagePreferences(),
          title: "more-options".tr(),
          description: "more-options-description".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.app_registration_outlined
              : Icons.app_registration_rounded,
        ),

        SettingsHeader(title: "automation".tr()),
        // SettingsContainerOpenPage(
        //   openPage: AutoTransactionsPage(),
        //   title: "Auto Transactions",
        //   icon: appStateSettings["outlinedIcons"] ? Icons.auto_fix_high_outlined : Icons.auto_fix_high_rounded,
        // ),

        SettingsContainer(
          title: "auto-mark-transactions".tr(),
          description: "auto-mark-transactions-description".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.check_circle_outlined
              : Icons.check_circle_rounded,
          onTap: () {
            openBottomSheet(
              context,
              const PopupFramework(
                hasPadding: false,
                child: UpcomingOverdueSettings(),
              ),
            );
          },
        ),

        appStateSettings["emailScanning"]
            ? SettingsContainerOpenPage(
                openPage: const AutoTransactionsPageEmail(),
                title: "auto-email-transactions".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.mark_email_unread_outlined
                    : Icons.mark_email_unread_rounded,
              )
            : const SizedBox.shrink(),

        SettingsContainerOpenPage(
          openPage: const BillSplitter(),
          title: "bill-splitter".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.summarize_outlined
              : Icons.summarize_rounded,
        ),

        SettingsHeader(title: "import-and-export".tr()),

        const ExportCSV(),

        const ImportCSV(),

        SettingsHeader(title: "backups".tr()),

        const ExportDB(),

        const ImportDB(),

        GoogleAccountLoginButton(
          isOutlinedButton: false,
          forceButtonName: "google-drive".tr(),
        ),
      ],
    );
  }
}

class MoreOptionsPagePreferences extends StatelessWidget {
  const MoreOptionsPagePreferences({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "more".tr(),
      dragDownToDismiss: true,
      horizontalPadding: getHorizontalPaddingConstrained(context),
      listWidgets: [
        SettingsHeader(title: "style".tr()),
        const HeaderHeightSetting(),
        const OutlinedIconsSetting(),
        const FontPickerSetting(),
        const IncreaseTextContrastSetting(),
        SettingsHeader(title: "transactions".tr()),
        const TransactionsSettings(),
        SettingsHeader(title: "accounts".tr()),
        const ShowAccountLabelSettingToggle(),
        SettingsContainerOpenPage(
          onOpen: () {
            checkIfExchangeRateChangeBefore();
          },
          onClosed: () {
            checkIfExchangeRateChangeAfter();
          },
          openPage: const ExchangeRates(),
          title: "exchange-rates".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.account_balance_wallet_outlined
              : Icons.account_balance_wallet_rounded,
        ),
        SettingsHeader(title: "budgets".tr()),
        const BudgetSettings(),
        SettingsHeader(title: "goals".tr()),
        const ObjectiveSettings(),
        SettingsHeader(title: "titles".tr()),
        const AskForTitlesToggle(),
        const AutoTitlesToggle(),
        if (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid)
          SettingsHeader(title: "widgets".tr()),
        if (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid)
          const NetWorthWidgetSetting(),
        SettingsHeader(title: "formatting".tr()),
        const NumberFormattingSetting(),
        const ExtraZerosButtonSetting(),
      ],
    );
  }
}

class BiometricsSettingToggle extends StatefulWidget {
  const BiometricsSettingToggle({super.key});

  @override
  State<BiometricsSettingToggle> createState() =>
      _BiometricsSettingToggleState();
}

class _BiometricsSettingToggleState extends State<BiometricsSettingToggle> {
  bool isLocked = appStateSettings["requireAuth"];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        biometricsAvailable
            ? SettingsContainerSwitch(
                title: "biometric-lock".tr(),
                description: "biometric-lock-description".tr(),
                onSwitched: (value) async {
                  try {
                    bool result = await checkBiometrics(
                      checkAlways: true,
                      message: "verify-identity".tr(),
                    );
                    if (result) {
                      updateSettings("requireAuth", value,
                          updateGlobalState: false);
                      setState(() {
                        isLocked = value;
                      });
                    }

                    return result;
                  } catch (e) {
                    openPopup(
                      context,
                      icon: appStateSettings["outlinedIcons"]
                          ? Icons.warning_outlined
                          : Icons.warning_rounded,
                      title: getPlatform() == PlatformOS.isIOS
                          ? "biometrics-disabled".tr()
                          : "biometrics-error".tr(),
                      description: getPlatform() == PlatformOS.isIOS
                          ? "biometrics-disabled-description".tr()
                          : "biometrics-error-description".tr(),
                      onCancelLabel:
                          getPlatform() == PlatformOS.isIOS ? "ok".tr() : null,
                      onCancel: () {
                        Navigator.pop(context);
                      },
                      onSubmitLabel: getPlatform() == PlatformOS.isIOS
                          ? "open-settings".tr()
                          : "ok".tr(),
                      onSubmit: () {
                        Navigator.pop(context);
                        // On iOS the notification app settings page also has
                        // the permission for biometrics
                        if (getPlatform() == PlatformOS.isIOS) {
                          AppSettings.openNotificationSettings();
                        }
                      },
                    );
                  }
                },
                initialValue: appStateSettings["requireAuth"],
                icon: isLocked
                    ? appStateSettings["outlinedIcons"]
                        ? Icons.lock_outlined
                        : Icons.lock_rounded
                    : appStateSettings["outlinedIcons"]
                        ? Icons.lock_open_outlined
                        : Icons.lock_open_rounded,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class HeaderHeightSetting extends StatelessWidget {
  const HeaderHeightSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedExpanded(
      // Indicates if it is enabled by default per device height
      expand: MediaQuery.sizeOf(context).height > MIN_HEIGHT_FOR_HEADER &&
          getPlatform() != PlatformOS.isIOS,
      child: SettingsContainerDropdown(
        title: "header-height".tr(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.subtitles_outlined
            : Icons.subtitles_rounded,
        initial: appStateSettings["forceSmallHeader"].toString(),
        items: const ["true", "false"],
        onChanged: (value) async {
          bool boolValue = false;
          if (value == "true") {
            boolValue = true;
          } else if (value == "false") {
            boolValue = false;
          }
          await updateSettings(
            "forceSmallHeader",
            boolValue,
            updateGlobalState: false,
            setStateAllPageFrameworks: true,
            pagesNeedingRefresh: [0],
          );
        },
        getLabel: (item) {
          if (item == "true") return "short".tr();
          if (item == "false") return "tall".tr();
        },
      ),
    );
  }
}

// Changing this setting needs to update the UI, that's not something that happens when setting global state
class OutlinedIconsSetting extends StatelessWidget {
  const OutlinedIconsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      items: const ["rounded", "outlined"],
      onChanged: (value) async {
        if (value == "rounded") {
          await updateSettings("outlinedIcons", false,
              updateGlobalState: false);
        } else {
          await updateSettings(
            "outlinedIcons",
            true,
            updateGlobalState: false,
          );
        }
        navBarIconsData = getNavBarIconsData();
        RestartApp.restartApp(context);
      },
      getLabel: (value) {
        return value.tr();
      },
      initial:
          appStateSettings["outlinedIcons"] == true ? "outlined" : "rounded",
      title: "icon-style".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.star_outline
          : Icons.star_rounded,
    );
  }
}

class IncreaseTextContrastSetting extends StatelessWidget {
  const IncreaseTextContrastSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "increase-text-contrast".tr(),
      description: "increase-text-contrast-description".tr(),
      onSwitched: (value) async {
        await updateSettings("increaseTextContrast", value,
            updateGlobalState: true);
      },
      initialValue: appStateSettings["increaseTextContrast"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.exposure_outlined
          : Icons.exposure_rounded,
      descriptionColor: appStateSettings["increaseTextContrast"]
          ? getColor(context, "black").withOpacity(0.84)
          : Theme.of(context).colorScheme.secondary.withOpacity(0.45),
    );
  }
}

class FontPickerSetting extends StatelessWidget {
  const FontPickerSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "font".tr().capitalizeFirst,
      icon: appStateSettings["outlinedIcons"]
          ? Icons.font_download_outlined
          : Icons.font_download_rounded,
      afterWidget: Tappable(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Builder(builder: (context) {
            String displayFontName =
                fontNameDisplayFilter(appStateSettings["font"].toString());
            return TextFont(
              text: displayFontName,
              fontSize: 14,
            );
          }),
        ),
      ),
      onTap: () {
        openFontPicker(context);
      },
    );
  }
}

void openFontPicker(BuildContext context) {
  openBottomSheet(
    context,
    PopupFramework(
      title: "font".tr(),
      child: RadioItems(
        itemsAreFonts: true,
        items: const [
          // These values match that of pubspec font family
          "Avenir",
          "DMSans",
          "Metropolis",
          // SF Pro removed - users on iOS can just select Platform font
          // Inter is the font family fallback
          "RobotoCondensed",
          "(Platform)",
        ],
        initial: appStateSettings["font"].toString(),
        displayFilter: fontNameDisplayFilter,
        onChanged: (value) async {
          updateSettings("font", value, updateGlobalState: true);
          await Future.delayed(const Duration(milliseconds: 50));
          Navigator.pop(context);
        },
      ),
    ),
  );
}

String fontNameDisplayFilter(String value) {
  if (value == "Avenir") {
    return "default".tr().capitalizeFirst;
  } else if (value == "(Platform)") {
    return "platform".tr().capitalizeFirst;
  } else if (value == "DMSans") {
    return "DM Sans";
  } else if (value == "RobotoCondensed") {
    return "Roboto Condensed";
  }
  return value.toString();
}

class NumberFormattingSetting extends StatelessWidget {
  const NumberFormattingSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "number-format".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.one_x_mobiledata_outlined
          : Icons.one_x_mobiledata_rounded,
      afterWidget: IgnorePointer(
        child: Tappable(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextFont(
              text: convertToMoney(
                Provider.of<AllWallets>(context, listen: true),
                1000.23,
              ),
              fontSize: 14,
            ),
          ),
        ),
      ),
      onTap: () async {
        await openBottomSheet(
          context,
          fullSnap: true,
          const SetNumberFormatPopup(),
        );
      },
    );
  }
}

class SetNumberFormatPopup extends StatefulWidget {
  const SetNumberFormatPopup({super.key});

  @override
  State<SetNumberFormatPopup> createState() => _SetNumberFormatPopupState();
}

class _SetNumberFormatPopupState extends State<SetNumberFormatPopup> {
  @override
  Widget build(BuildContext context) {
    List<String?> items = [
      null,
      "en",
      "tr",
      "af",
      "de",
      "fr",
    ];
    return PopupFramework(
      title: "number-format".tr(),
      child: Column(
        children: [
          RadioItems(
            items: items,
            initial: appStateSettings["numberFormatLocale"],
            displayFilter: (item) {
              if (item == null) {
                return "${"default".tr()} (${convertToMoney(Provider.of<AllWallets>(context, listen: true), 1000.23, customLocale: Platform.localeName)})";
              }
              return convertToMoney(
                  Provider.of<AllWallets>(context, listen: true), 1000.23,
                  customLocale: item);
            },
            onChanged: (value) {
              updateSettings("numberFormatLocale", value,
                  updateGlobalState: true);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextFont(
              text: "decimal-precision-edit-account-info".tr(),
              fontSize: 14,
              maxLines: 5,
              textAlign: TextAlign.center,
              textColor: getColor(context, "textLight"),
            ),
          ),
        ],
      ),
    );
  }
}

class ExtraZerosButtonSetting extends StatelessWidget {
  const ExtraZerosButtonSetting({this.enableBorderRadius = false, super.key});
  final bool enableBorderRadius;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      enableBorderRadius: enableBorderRadius,
      title: "extra-zeros-button".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.check_box_outline_blank_outlined
          : Icons.check_box_outline_blank_rounded,
      initial: appStateSettings["extraZerosButton"].toString(),
      items: const ["", "00", "000"],
      onChanged: (value) async {
        updateSettings(
          "extraZerosButton",
          value == "" ? null : value,
          updateGlobalState: false,
        );
      },
      getLabel: (item) {
        if (item == "") return "none".tr().capitalizeFirst;
        return item;
      },
    );
  }
}

class NetWorthWidgetSetting extends StatelessWidget {
  const NetWorthWidgetSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "net-worth-total-widget".tr(),
      description: "select-accounts-and-time-period".tr(),
      onTap: () {
        openNetWorthSettings(context);
      },
      icon: appStateSettings["outlinedIcons"]
          ? Icons.area_chart_outlined
          : Icons.area_chart_rounded,
    );
  }
}
