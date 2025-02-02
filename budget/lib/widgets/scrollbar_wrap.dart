import 'package:budget/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScrollbarWrap extends StatelessWidget {
  const ScrollbarWrap({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Disable in debug mode because of scroll controller warnings
    if (kDebugMode) {
      return child;
    }
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: RawScrollbar(
        thumbColor: dynamicPastel(
          context,
          Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.3),
          amountDark: 0.3,
        ),
        radius: const Radius.circular(20),
        thickness: 3,
        child: child,
      ),
    );
  }
}
