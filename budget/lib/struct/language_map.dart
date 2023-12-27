import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String globalAppName = "Cashew";

Map<String, Locale> supportedLocales = {
  "en": const Locale("en"),
  "fr": const Locale("fr"),
  "es": const Locale("es"),
  "zh": const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hans"),
  "zh_Hant": const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant"),
  "hi": const Locale("hi"),
  "ar": const Locale("ar"),
  "pt": const Locale("pt"),
  "ru": const Locale("ru"),
  "ja": const Locale("ja"),
  "de": const Locale("de"),
  "ko": const Locale("ko"),
  "tr": const Locale("tr"),
  "it": const Locale("it"),
  "vi": const Locale("vi"),
  "pl": const Locale("pl"),
  "nl": const Locale("nl"),
  "th": const Locale("th"),
  "cs": const Locale("cs"),
  "bn": const Locale("bn"),
  "da": const Locale("da"),
  "fil": const Locale("fil"),
  "fi": const Locale("fi"),
  "el": const Locale("el"),
  "gu": const Locale("gu"),
  "he": const Locale("he"),
  "hu": const Locale("hu"),
  "id": const Locale("id"),
  "ms": const Locale("ms"),
  "ml": const Locale("ml"),
  "mr": const Locale("mr"),
  "no": const Locale("no"),
  "fa": const Locale("fa"),
  "ro": const Locale("ro"),
  "sv": const Locale("sv"),
  "ta": const Locale("ta"),
  "te": const Locale("te"),
  "uk": const Locale("uk"),
  "ur": const Locale("ur"),
  "sr": const Locale("sr"),
  "sw": const Locale("sw"),
  "bg": const Locale("bg"),
};

// Fix loading of zh_Hant and other special script languages
// Within easy_localization, supported locale checks the codes properly to see if its supported
// ...LocaleExtension on Locale {
//      bool supports(Locale locale) {...
// For e.g. if system was fr_CA it would check the language code, since we support fr it is marked as supported!
// So it is safe to set useOnlyLangCode to false even when we only support language codes
// Since only the logic for RootBundleAssetLoader relies on useOnlyLangCode, no other functionality of easy_localization does!
class RootBundleAssetLoaderCustomLocaleLoader extends RootBundleAssetLoader {
  const RootBundleAssetLoaderCustomLocaleLoader();

  @override
  String getLocalePath(String basePath, Locale locale) {
    //print("Initial Locale: " + locale.toString());

    if (supportedLocales["zh_Hant"] == locale) {
      locale = supportedLocales["zh_Hant"] ?? Locale(locale.languageCode);
    } else {
      // We only support the language code right now
      // This implements EasyLocalization( useOnlyLangCode: true ... )
      locale = Locale(locale.languageCode);
    }

    //print("Set Locale: " + locale.toString());

    return '$basePath/${locale.toStringWithSeparator(separator: "-")}.json';
  }
}

// Language names can be found in
// /budget/assets/static/language-names.json
