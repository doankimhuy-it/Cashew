import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TransactionEntryNote extends StatelessWidget {
  const TransactionEntryNote({
    required this.transaction,
    required this.iconColor,
    super.key,
  });
  final Transaction transaction;
  final Color iconColor;
  @override
  Widget build(BuildContext context) {
    return transaction.note.toString().trim() != ""
        ? Tooltip(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: getColor(context, "lightDarkAccent"),
              boxShadow: boxShadowCheck(
                [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.light
                        ? getColor(context, "shadowColorLight")
                            .withOpacity(0.12)
                        : getColor(context, "shadowColorLight")
                            .withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            textStyle: TextStyle(
              color: getColor(context, "black"),
              fontFamily: appStateSettings["font"],
              fontFamilyFallback: ['Inter'],
            ),
            triggerMode: TooltipTriggerMode.tap,
            showDuration: Duration(milliseconds: 10000),
            message: cleanupNoteStringWithURLs(transaction.note),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 5, right: 3, top: 10, bottom: 10),
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.sticky_note_2_outlined
                    : Icons.sticky_note_2_rounded,
                size: 22,
                color: iconColor,
              ),
            ),
          )
        : SizedBox.shrink();
  }
}
