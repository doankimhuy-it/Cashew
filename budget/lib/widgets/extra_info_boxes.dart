import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animated_expanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TipBox extends StatefulWidget {
  const TipBox({
    required this.onTap,
    required this.text,
    required this.settingsString,
    this.richTextSpan,
    super.key,
  });
  final VoidCallback onTap;
  final String text;
  final List<TextSpan>? richTextSpan;
  final String? settingsString;

  @override
  State<TipBox> createState() => _TipBoxState();
}

class _TipBoxState extends State<TipBox> {
  late bool isVisible =
      widget.settingsString == null || appStateSettings[widget.settingsString];

  @override
  Widget build(BuildContext context) {
    return AnimatedExpanded(
      axis: Axis.vertical,
      expand: isVisible,
      child: Tappable(
        onTap: widget.onTap,
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: getIsFullScreen(context) ? 15 : 10,
        child: Padding(
          padding: EdgeInsets.only(
              left: 15,
              right: widget.settingsString == null ? 15 : 2,
              top: 2,
              bottom: 2),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  appStateSettings["outlinedIcons"]
                      ? Icons.lightbulb_outlined
                      : Icons.lightbulb_outline_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 31,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFont(
                    textColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    text: widget.text,
                    richTextSpan: widget.richTextSpan,
                    maxLines: 15,
                    fontSize: getIsFullScreen(context) ? 15 : 14,
                  ),
                ),
              ),
              if (widget.settingsString != null)
                IconButton(
                  padding: const EdgeInsets.all(15),
                  tooltip: "remove-tip".tr(),
                  onPressed: () async {
                    setState(() {
                      isVisible = false;
                    });
                    updateSettings(widget.settingsString!, false,
                        updateGlobalState: false);
                  },
                  icon: Icon(
                    appStateSettings["outlinedIcons"]
                        ? Icons.close_outlined
                        : Icons.close_rounded,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtraInfoButton extends StatelessWidget {
  const ExtraInfoButton(
      {required this.onTap,
      required this.color,
      required this.icon,
      required this.text,
      this.buttonIconColor,
      this.buttonIconColorIcon,
      super.key});
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String text;
  final Color? buttonIconColor;
  final Color? buttonIconColorIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Tappable(
        borderRadius: 15,
        color: color,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ButtonIcon(
                onTap: onTap,
                icon: icon,
                color: buttonIconColor,
                iconColor: buttonIconColorIcon,
                size: 38,
                iconPadding: 18,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: TextFont(
                  text: text,
                  fontSize: 17,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
      ),
    );
  }
}
