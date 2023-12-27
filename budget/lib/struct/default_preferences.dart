import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/home_page/home_page_line_graph.dart';
import 'package:budget/widgets/notifications_settings.dart';
import 'package:budget/widgets/period_cycle_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// default settings, defaultSettings, initial settings
Future<Map<String, dynamic>> getDefaultPreferences() async {
  return {
    "databaseJustImported": false,
    "backupLimit": 20,
    "backupSync": true,
    "syncEveryChange": kIsWeb,
    "devicesHaveBeenSynced": 1,
    "numBackups": 1,
    "theme": "system",
    "selectedWalletPk": "0",
    "selectedSubscriptionType": 0,
    "accentColor": toHexString(Color(0xFF1B447A)),
    "accentSystemColor": await systemColorByDefault(),
    // FullScreen is added if the section has its own preference when full screen (double column)
    "showWalletSwitcher": true,
    "showWalletSwitcherFullScreen": true,
    "showWalletList": false,
    "showWalletListFullScreen": false,
    "showPinnedBudgets": true,
    "showPinnedBudgetsFullScreen": true,
    "showObjectives": false,
    "showObjectivesFullScreen": true,
    "showAllSpendingSummary": false,
    "showAllSpendingSummaryFullScreen": false,
    "showNetWorth": false,
    "showNetWorthFullScreen": false,
    "showOverdueUpcoming": false,
    "showOverdueUpcomingFullScreen": true,
    "showObjectiveLoans": false,
    "showObjectiveLoansFullScreen": true,
    "showCreditDebt": false,
    "showCreditDebtFullScreen": true,
    "showSpendingGraph": true,
    "showSpendingGraphFullScreen": true,
    "showPieChart": false,
    "showPieChartFullScreen": false,
    "showHeatMap": false,
    "showHeatMapFullScreen": true,
    "showTransactionsList": true,
    "showTransactionsListFullScreen": true,
    "showUsernameWelcomeBanner": true,
    "showUsernameWelcomeBannerFullScreen": true,
    "homePageOrder": [
      "wallets",
      "walletsList",
      "budgets",
      "objectives",
      "allSpendingSummary",
      "netWorth",
      "overdueUpcoming",
      "creditDebts",
      "objectiveLoans",
      "spendingGraph",
      "pieChart",
      "heatMap",
      "transactionsList",
    ],
    "homePageOrderFullScreen": [
      "wallets",
      "walletsList",
      "budgets",
      "ORDER:LEFT",
      "objectives",
      "allSpendingSummary",
      "netWorth",
      "overdueUpcoming",
      "creditDebts",
      "objectiveLoans",
      "spendingGraph",
      "pieChart",
      "heatMap",
      "ORDER:RIGHT",
      "transactionsList",
    ],
    // Values for customNavBarShortcuts are the keys of navBarIconsData
    "customNavBarShortcut1": "transactions",
    "customNavBarShortcut2": "budgets",
    "showTotalSpentForBudget": false,
    "showTotalSpentForObjective": true,
    "showCumulativeSpending": true,
    "removeZeroTransactionEntries": true,
    "ignorePastAmountSpent": false,
    "askForTransactionTitle": true,
    "askForTransactionNoteWithTitle": false,
    // "batterySaver": kIsWeb,
    "automaticallyPayUpcoming": true,
    "automaticallyPayRepetitive": true,
    "automaticallyPaySubscriptions": true,
    "markAsPaidOnOriginalDay": false,
    "batterySaver": false,
    "username": "",
    "hasOnboarded": false,
    "autoAddAssociatedTitles": true,
    "AutoTransactions-canReadEmails": false,
    "currencyIcon": "\$",
    "EmailAutoTransactions-amountOfEmails": 10,
    "autoBackups": true,
    "autoBackupsFrequency": 3, //in days
    "hasSignedIn": false,
    "lastBackup": DateTime.now().subtract(Duration(days: 1)).toString(),
    "lastLoginVersion": "",
    "numLogins": 0,
    "openedStoreRating": false,
    "dismissedStoreRating": false,
    "submittedFeedback": false,
    "canShowBackupReminderPopup": true,
    "canShowTransactionActionButtonTip": true,
    "autoLoginDisabledOnWebTip": true,
    "notifications": true,
    "notificationHour": 20,
    "notificationMinute": 0,
    "notificationsUpcomingTransactions": true,
    "notificationsReminderType": ReminderNotificationType.IfAppNotOpened.index,
    "appOpenedHour": DateTime.now().hour,
    "appOpenedMinute": DateTime.now().minute,
    "materialYou": supportsSystemColor(),
    "colorTintCategoryIcon": false,
    "sendTransactionsToServerQueue": {},
    "currentUserEmail": "",
    "usersNicknames": {},
    "requireAuth": false,
    "cachedCurrencyExchange": {},
    "customCurrencies": [],
    "lineGraphReferenceBudgetPk": null,
    "lineGraphDisplayType": LineGraphDisplay.Default30Days.index,
    "lineGraphStartDate": DateTime.now().toString(),
    "pieChartTotal": "all", // all, outgoing, incoming
    "netWorthAllWallets": true,
    "allSpendingSummaryAllWallets": true,
    "showPastSpendingTrajectory": false,
    "lastSynced": null,
    "font": "Avenir",
    "forceSmallHeader": false,
    "animationSpeed": 1.0,
    "sharedBudgets": false,
    "emailScanning": false,
    "emailScanningPullToRefresh": false,
    "massEditSelectedTransactions": false,
    "incognitoKeyboard": false,
    // the key is the budgetPk (in String!)
    // Should be of type Map<String, List<String>>
    "watchedCategoriesOnBudget": {},
    "showCompressedViewBudgetGraph": false,
    "showAllSubcategories": true,
    // Should be of type Map<String, double>
    "customCurrencyAmounts": {},
    "iOSNavigation": false,
    "iOSEmulate": false,
    "iOSAnimatedGoo": false,
    "expandedNavigationSidebar": true,
    "locale": "System",
    "disableShadows": false,
    "showTransactionPk": false,
    "showBackupLimit": false,
    "outlinedIcons": false,
    "premiumPopupAddTransactionCount": -5,
    "premiumPopupAddTransactionLastShown": DateTime.now().toString(),
    "premiumPopupFreeSeen": false,
    "previewDemo": false,
    "purchaseID": null,
    "showAccountLabelTagInTransactionEntry": false,
    "showTransactionsMonthlySpendingSummary": true,
    "showTransactionsBalanceTransferTab": true,
    //Show all categories or only income/expense
    "showAllCategoriesWhenSelecting": true,
    // Search filters strings
    "searchTransactionsSetFiltersString": null,
    "allSpendingSetFiltersString": null,
    "transactionsListPageSetFiltersString": null,
    "increaseTextContrast": false,
    "numberFormatLocale": null,
    "netAllSpendingTotal": false,
    "netSpendingDayTotal": false,
    "extraZerosButton": null, //will be null, 00 or 000
    "allSpendingLastPage": 0, //index of the last tab on the all spending page
    "loansLastPage": 0, //index of the last tab on the loans page
    "readDismissedNotificationsToCreateTransaction": false,
    "readDismissedNotificationsToCreateTransactionPackageName": "",
    // *********************************************************** //
    // For showing information within a certain cycle for all spending wallet details page
    // cycleSettingsExtension = ""
    "selectedPeriodCycleType": CycleType.allTime.index,
    "cyclePeriodLength": 1,
    "cycleReoccurrence": BudgetReoccurence.monthly.index,
    "cycleStartDate":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodStartDate":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodEndDate": null,
    "customPeriodPastDays": 30,
    // For showing information within a certain cycle for pie chart
    // cycleSettingsExtension = "PieChart"
    "selectedPeriodCycleTypePieChart": CycleType.allTime.index,
    "cyclePeriodLengthPieChart": 1,
    "cycleReoccurrencePieChart": BudgetReoccurence.monthly.index,
    "cycleStartDatePieChart":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodStartDatePieChart":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodEndDatePieChart": null,
    "customPeriodPastDaysPieChart": 30,
    // For showing information within a certain cycle for net worth
    // cycleSettingsExtension = "NetWorth"
    "selectedPeriodCycleTypeNetWorth": CycleType.allTime.index,
    "cyclePeriodLengthNetWorth": 1,
    "cycleReoccurrenceNetWorth": BudgetReoccurence.monthly.index,
    "cycleStartDateNetWorth":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodStartDateNetWorth":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodEndDateNetWorth": null,
    "customPeriodPastDaysNetWorth": 30,
    // For showing information within a certain cycle for income and expenses (allSpendingSummary)
    // cycleSettingsExtension = "AllSpendingSummary"
    "selectedPeriodCycleTypeAllSpendingSummary": CycleType.allTime.index,
    "cyclePeriodLengthAllSpendingSummary": 1,
    "cycleReoccurrenceAllSpendingSummary": BudgetReoccurence.monthly.index,
    "cycleStartDateAllSpendingSummary":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodStartDateAllSpendingSummary":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodEndDateAllSpendingSummary": null,
    "customPeriodPastDaysAllSpendingSummary": 30,
    // For showing information within a certain cycle for overdue and upcoming (overdueUpcoming)
    // cycleSettingsExtension = "OverdueUpcoming"
    "selectedPeriodCycleTypeOverdueUpcoming": CycleType.allTime.index,
    "cyclePeriodLengthOverdueUpcoming": 1,
    "cycleReoccurrenceOverdueUpcoming": BudgetReoccurence.monthly.index,
    "cycleStartDateOverdueUpcoming":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodStartDateOverdueUpcoming":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodEndDateOverdueUpcoming": null,
    "customPeriodPastDaysOverdueUpcoming": 30,
    // For showing information within a certain cycle for credits and debts (loans) (creditDebts)
    // cycleSettingsExtension = "CreditDebts"
    "selectedPeriodCycleTypeCreditDebts": CycleType.allTime.index,
    "cyclePeriodLengthCreditDebts": 1,
    "cycleReoccurrenceCreditDebts": BudgetReoccurence.monthly.index,
    "cycleStartDateCreditDebts":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodStartDateCreditDebts":
        DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    "customPeriodEndDateCreditDebts": null,
    "customPeriodPastDaysCreditDebts": 30,
    // // For showing information within a certain cycle for wallets homepage section
    // // cycleSettingsExtension = "Wallets"
    // "selectedPeriodCycleTypeWallets": CycleType.allTime.index,
    // "cyclePeriodLengthWallets": 1,
    // "cycleReoccurrenceWallets": BudgetReoccurence.monthly.index,
    // "cycleStartDateWallets":
    //     DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    // "customPeriodStartDateWallets":
    //     DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    // "customPeriodEndDateWallets": null,
    // "customPeriodPastDaysWallets": 30,
    // // For showing information within a certain cycle for walletsList homepage section
    // // cycleSettingsExtension = "WalletsList"
    // "selectedPeriodCycleTypeWalletsList": CycleType.allTime.index,
    // "cyclePeriodLengthWalletsList": 1,
    // "cycleReoccurrenceWalletsList": BudgetReoccurence.monthly.index,
    // "cycleStartDateWalletsList":
    //     DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    // "customPeriodStartDateWalletsList":
    //     DateTime(DateTime.now().year, DateTime.now().month, 1).toString(),
    // "customPeriodEndDateWalletsList": null,
    // "customPeriodPastDaysWalletsList": 30,
    // *********************************************************** //
  };
}

dynamic attemptToMigrateCyclePreferences(
    dynamic currentUserSettings, String key) {
  try {
    if (
        // This is a setting we need to find a value for
        migrateCyclePreferencesKeys.keys.contains(key) &&
            // The current setting does not have a value
            currentUserSettings[key] == null &&
            // We have a current setting for the previous associated value
            currentUserSettings[migrateCyclePreferencesKeys[key]] != null) {
      print("Migrating cycle setting " +
          key.toString() +
          " to the value of " +
          currentUserSettings[migrateCyclePreferencesKeys[key]].toString() +
          " from key " +
          migrateCyclePreferencesKeys[key].toString());
      currentUserSettings[key] =
          currentUserSettings[migrateCyclePreferencesKeys[key]];
    }
  } catch (e) {
    print("Error migrating cycle preferences " + e.toString());
  }

  return currentUserSettings;
}

Map<String, String> migrateCyclePreferencesKeys = {
  "selectedPeriodCycleTypePieChart": "selectedPeriodCycleType",
  "cyclePeriodLengthPieChart": "cyclePeriodLength",
  "cycleReoccurrencePieChart": "cycleReoccurrence",
  "cycleStartDatePieChart": "customPeriodStartDate",
  "customPeriodStartDatePieChart": "customPeriodStartDate",
  "customPeriodPastDaysPieChart": "customPeriodPastDays",
  //
  "selectedPeriodCycleTypeNetWorth": "selectedPeriodCycleType",
  "cyclePeriodLengthNetWorth": "cyclePeriodLength",
  "cycleReoccurrenceNetWorth": "cycleReoccurrence",
  "cycleStartDateNetWorth": "customPeriodStartDate",
  "customPeriodStartDateNetWorth": "customPeriodStartDate",
  "customPeriodPastDaysNetWorth": "customPeriodPastDays",
  //
  "selectedPeriodCycleTypeAllSpendingSummary": "selectedPeriodCycleType",
  "cyclePeriodLengthAllSpendingSummary": "cyclePeriodLength",
  "cycleReoccurrenceAllSpendingSummary": "cycleReoccurrence",
  "cycleStartDateAllSpendingSummary": "customPeriodStartDate",
  "customPeriodStartDateAllSpendingSummary": "customPeriodStartDate",
  "customPeriodPastDaysAllSpendingSummary": "customPeriodPastDays",
};
