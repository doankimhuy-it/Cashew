import 'package:budget/functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/default_categories.dart';

//Initialize default values in database
Future<bool> initializeDefaultDatabase() async {
  //Initialize default categories
  if ((await database.getAllCategories()).isEmpty) {
    await createDefaultCategories();
  }
  if ((await database.getAllWallets()).isEmpty) {
    await database.createOrUpdateWallet(
      defaultWallet(),
      customDateTimeModified: DateTime(0),
    );
  }
  return true;
}

Future<bool> createDefaultCategories() async {
  print("Creating default categories");
  for (TransactionCategory category in defaultCategories()) {
    try {
      await database.getCategory(category.categoryPk).$2;
    } catch (e) {
      print(
          "$e default category does not already exist, creating");
      await database.createOrUpdateCategory(category,
          customDateTimeModified: DateTime(0));
    }
  }
  return true;
}

TransactionWallet defaultWallet() {
  return TransactionWallet(
    walletPk: "0",
    name: "default-account-name".tr(),
    dateCreated: DateTime.now(),
    order: 0,
    currency: getDevicesDefaultCurrencyCode(),
    dateTimeModified: null,
    decimals: 2,
    homePageWidgetDisplay: defaultWalletHomePageWidgetDisplay,
  );
}
