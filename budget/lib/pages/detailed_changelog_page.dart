import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/about_page.dart';
import 'package:budget/struct/currency_functions.dart';
import 'package:budget/widgets/no_results.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/show_changelog.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/main.dart';
import 'package:provider/provider.dart';
import '../functions.dart';
import 'package:budget/struct/settings.dart';

class DetailedChangelogPage extends StatefulWidget {
  const DetailedChangelogPage({super.key});

  @override
  State<DetailedChangelogPage> createState() => _DetailedChangelogPageState();
}

class _DetailedChangelogPageState extends State<DetailedChangelogPage> {
  String searchCurrenciesText = "";

  @override
  Widget build(BuildContext context) {
    List<Widget>? changelogWidgets = getChangelogPointsWidgets(
          context,
          forceShow: true,
          majorChangesOnly: false,
        ) ??
        [];

    return PageFramework(
      dragDownToDismiss: true,
      title: "changelog".tr(),
      horizontalPadding: 20,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return changelogWidgets[index];
            },
            childCount: changelogWidgets.length,
          ),
        ),
      ],
    );
  }
}
