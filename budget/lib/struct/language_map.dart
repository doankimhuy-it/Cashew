import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String globalAppName = "Budget Tracker";

Map<String, Locale> supportedLocales = {
  "en": const Locale("en"),
  "vi": const Locale("vi"),
};

class RootBundleAssetLoaderCustomLocaleLoader extends RootBundleAssetLoader {
  const RootBundleAssetLoaderCustomLocaleLoader();

  @override
  String getLocalePath(String basePath, Locale locale) {
    locale = Locale(locale.languageCode);
    return '$basePath/${locale.toStringWithSeparator(separator: "-")}.json';
  }
}

// Language names can be found in
// /budget/assets/static/language-names.json
