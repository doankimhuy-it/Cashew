import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/accounts_page.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/pages/debug_page.dart';
import 'package:budget/pages/on_boarding_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/language_map.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:budget/widgets/more_icons.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      dragDownToDismiss: true,
      title: "about".tr(),
      horizontalPadding: getHorizontalPaddingConstrained(context),
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              const Image(
                image: AssetImage("assets/icon/icon-small.png"),
                height: 70,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tappable(
                    borderRadius: 15,
                    onLongPress: () {
                      pushRoute(
                        context,
                        const DebugPage(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3, horizontal: 10),
                      child: TextFont(
                        text: globalAppName,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                      ),
                    ),
                  ),
                  Tappable(
                    borderRadius: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 10),
                      child: TextFont(
                        text: getVersionString(),
                        fontSize: 14,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Tappable(
            onTap: () {
              openUrl("https://github.com/doankimhuy-it/Cashew");
            },
            color: appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent"),
            borderRadius: 15,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(MoreIcons.github),
                      const SizedBox(width: 10),
                      Flexible(
                        child: TextFont(
                          text: "go-to-app-homepage"
                              .tr(namedArgs: {"app": globalAppName}),
                          fontSize: 18,
                          maxLines: 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Button(
            label: "delete-all-data".tr(),
            onTap: () {
              openPopup(
                context,
                title: "erase-everything".tr(),
                description: "erase-everything-description".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.warning_outlined
                    : Icons.warning_rounded,
                onExtraLabel2: "erase-synced-data-and-cloud-backups".tr(),
                onExtra2: () {
                  Navigator.pop(context);
                  openBottomSheet(
                    context,
                    PopupFramework(
                      title: "erase-cloud-data".tr(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 18,
                              left: 5,
                              right: 5,
                            ),
                            child: TextFont(
                              text: "erase-cloud-data-description".tr(),
                              fontSize: 18,
                              textAlign: TextAlign.center,
                              maxLines: 10,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: SyncCloudBackupButton(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    pushRoute(context, const AccountsPage());
                                  },
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: BackupsCloudBackupButton(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    pushRoute(context, const AccountsPage());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onSubmit: () async {
                  Navigator.pop(context);
                  openPopup(
                    context,
                    title: "erase-everything-warning".tr(),
                    description: "erase-everything-warning-description".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.warning_amber_outlined
                        : Icons.warning_amber_rounded,
                    onSubmit: () async {
                      Navigator.pop(context);
                      clearDatabase(context);
                    },
                    onSubmitLabel: "erase".tr(),
                    onCancelLabel: "cancel".tr(),
                    onCancel: () {
                      Navigator.pop(context);
                    },
                  );
                },
                onSubmitLabel: "erase".tr(),
                onCancelLabel: "cancel".tr(),
                onCancel: () {
                  Navigator.pop(context);
                },
              );
            },
            color: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
        const SizedBox(height: 20),
        const HorizontalBreak(),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "graphics".tr(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        AboutInfoBox(
          title: "freepik-credit".tr(),
          link: "https://www.flaticon.com/authors/freepik",
        ),
        AboutInfoBox(
          title: "font-awesome-credit".tr(),
          link: "https://fontawesome.com/",
        ),
        AboutInfoBox(
          title: "pch-vector-credit".tr(),
          link: "https://www.freepik.com/author/pch-vector",
        ),
        Container(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "major-tools".tr(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        const AboutInfoBox(
          title: "Flutter",
          link: "https://flutter.dev/",
        ),
        const AboutInfoBox(
          title: "Google Cloud APIs",
          link: "https://cloud.google.com/",
        ),
        const AboutInfoBox(
          title: "Drift SQL Database",
          link: "https://drift.simonbinder.eu/",
        ),
        const AboutInfoBox(
          title: "FL Charts",
          link: "https://github.com/imaNNeoFighT/fl_chart",
        ),
        AboutInfoBox(
          title: "exchange-rates-api".tr(),
          link: "https://github.com/fawazahmed0/currency-api",
        ),
        Container(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "translations".tr().capitalizeFirst,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: TranslationsHelp(
            showIcon: false,
            backgroundColor: (appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent")),
          ),
        ),
        const AboutInfoBox(
          title: "Italian",
          list: ["Thomas B."],
        ),
        const AboutInfoBox(
          title: "Polish",
          list: ["Michał S."],
        ),
        const AboutInfoBox(
          title: "Serbian",
          list: ["Jovan P."],
        ),
        const AboutInfoBox(
          title: "Swahili",
          list: ["Anthony K."],
        ),
        const AboutInfoBox(
          title: "German",
          list: ["Fabian S."],
        ),
        const AboutInfoBox(
          title: "Arabic",
          list: ["Dorra Y."],
        ),
        const AboutInfoBox(
          title: "Portuguese",
          list: ["Alexander G.", "Jean J.", "João P"],
        ),
        const AboutInfoBox(
          title: "Bulgarian",
          list: ["Денислав С."],
        ),
        const AboutInfoBox(
          title: "Chinese (Simplified)",
          list: ["Clyde"],
        ),
        const AboutInfoBox(
          title: "Chinese (Traditional)",
          list: ["qazlll456"],
        ),
        const AboutInfoBox(
          title: "Hindi",
          list: ["Dikshant S."],
        ),
        const AboutInfoBox(
          title: "Vietnamese",
          list: ["Ngọc A."],
        ),
        const AboutInfoBox(
          title: "French",
          list: ["Antoine C."],
        ),
        const AboutInfoBox(
          title: "Indonesian",
          list: ["Gusairi P."],
        ),
        const AboutInfoBox(
          title: "Ukrainian",
          list: ["Chris M."],
        ),
        const AboutInfoBox(
          title: "Russian",
          list: ["Ilya A."],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Note that this is different than forceDeleteDB()
Future clearDatabase(BuildContext context) async {
  openLoadingPopup(context);
  await Future.wait([database.deleteEverything(), sharedPreferences.clear()]);
  await database.close();
  Navigator.pop(context);
  restartAppPopup(context);
}

class AboutInfoBox extends StatelessWidget {
  const AboutInfoBox({
    super.key,
    required this.title,
    this.link,
    this.list,
    this.color,
    this.padding,
  });

  final String title;
  final String? link;
  final List<String>? list;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Tappable(
        onTap: () async {
          if (link != null) openUrl(link ?? "");
        },
        onLongPress: () {
          if (link != null) copyToClipboard(link ?? "");
        },
        color: color ??
            (appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent")),
        borderRadius: 15,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          child: Column(
            children: [
              TextFont(
                text: title,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
              const SizedBox(height: 6),
              if (link != null)
                TextFont(
                  text: link ?? "",
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
              for (String item in list ?? [])
                TextFont(
                  text: item,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String getVersionString() {
  String version = packageInfoGlobal.version;
  String buildNumber = packageInfoGlobal.buildNumber;
  return "v$version+$buildNumber, db-v1";
}
