import 'package:budget/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class ListItem extends StatelessWidget {
  const ListItem(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "• ",
            maxLines: 1,
            fontSize: 15.5,
          ),
          Expanded(
            child: TextFont(
              text: text,
              maxLines: 50,
              fontSize: 15.5,
            ),
          ),
        ],
      ),
    );
  }
}
