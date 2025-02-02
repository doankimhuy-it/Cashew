import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/fade_in.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class NoResults extends StatelessWidget {
  const NoResults({
    super.key,
    required this.message,
    this.tintColor,
    this.padding,
    this.noSearchResultsVariation = false,
  });
  final String message;
  final Color? tintColor;
  final EdgeInsets? padding;
  final bool noSearchResultsVariation;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 200),
      child: Opacity(
        opacity: Theme.of(context).brightness == Brightness.light ? 1 : 0.8,
        child: Center(
          child: Padding(
            padding: padding ??
                EdgeInsets.only(
                  top: MediaQuery.sizeOf(context).height * 0.4 > 400 ? 100 : 35,
                  right: 30,
                  left: 30,
                ),
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).height <=
                              MediaQuery.sizeOf(context).width
                          ? MediaQuery.sizeOf(context).height * 0.4 > 400
                              ? 400
                              : MediaQuery.sizeOf(context).height * 0.4
                          : 270),
                  child: appStateSettings["materialYou"]
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            !appStateSettings["materialYou"]
                                ? getColor(context, "black").withOpacity(0.1)
                                : tintColor == null
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.7)
                                    : tintColor!.withOpacity(0.7),
                            BlendMode.srcATop,
                          ),
                          child: ColorFiltered(
                            colorFilter: greyScale,
                            child: Opacity(
                              opacity: 1,
                              child: Image(
                                image: noSearchResultsVariation
                                    ? const AssetImage(
                                        "assets/images/no-search-filter.png")
                                    : const AssetImage(
                                        "assets/images/empty-filter.png"),
                              ),
                            ),
                          ),
                        )
                      : Image(
                          image: noSearchResultsVariation
                              ? const AssetImage("assets/images/no-search.png")
                              : const AssetImage("assets/images/empty.png"),
                        ),
                ),
                const SizedBox(height: 30),
                TextFont(
                  maxLines: 4,
                  fontSize: 15,
                  text: message,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
                // Lottie.asset('assets/animations/search-animation.json'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
