import 'package:budget/functions.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/sliver_sticky_label_divider.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';

class DateDivider extends StatelessWidget {
  DateDivider({
    Key? key,
    required this.date,
    this.info,
    this.color,
    this.useHorizontalPaddingConstrained = true,
    this.afterDate = "",
  }) : super(key: key);

  final DateTime date;
  final String? info;
  final Color? color;
  final bool useHorizontalPaddingConstrained;
  final String afterDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: useHorizontalPaddingConstrained == false
            ? 0
            : getHorizontalPaddingConstrained(context),
      ),
      child: StickyLabelDivider(
        info: getWordedDate(date,
                includeMonthDate: true, includeYearIfNotCurrentYear: true) +
            afterDate,
        extraInfo: info,
        color: color,
        fontSize: 14,
      ),
    );
  }
}
