import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class StatusBox extends StatelessWidget {
  const StatusBox({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
    this.forceDark,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Function()? onTap;
  final bool? forceDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        border: Border.all(color: color, width: 2),
      ),
      margin: const EdgeInsets.all(10),
      child: Tappable(
        borderRadius: 12,
        onTap: onTap,
        color: color.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 35),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: title,
                      maxLines: 10,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      textColor: forceDark == true ? Colors.black : null,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    TextFont(
                      text: description,
                      maxLines: 10,
                      fontSize: 14,
                      textColor: forceDark == true ? Colors.black : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
