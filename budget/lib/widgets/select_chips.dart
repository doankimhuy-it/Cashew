import 'package:budget/pages/add_category_page.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/linear_gradient_faded_edges.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'util/widget_size.dart';

class SelectChips<T> extends StatefulWidget {
  const SelectChips({
    super.key,
    required this.items,
    required this.getSelected,
    required this.onSelected,
    required this.getLabel,
    this.getCustomBorderColor,
    this.getCustomSelectedColor,
    this.extraWidgetBefore,
    this.extraWidgetAfter,
    this.onLongPress,
    this.wrapped = false,
    this.extraHorizontalPadding,
    this.getAvatar,
    this.selectedColor,
    this.scrollablePositionedList = true,
    this.padding,
    // If allowMultipleSelected, we use check marks
    this.allowMultipleSelected = true,
    this.extraWidgetBeforeSticky = false,
  });
  final List<T> items;
  final bool Function(T) getSelected;
  final Function(T) onSelected;
  final String Function(T) getLabel;
  final Color? Function(T)? getCustomBorderColor;
  final Color? Function(T)? getCustomSelectedColor;
  final Widget? extraWidgetBefore;
  final Widget? extraWidgetAfter;
  final Function(T)? onLongPress;
  final bool wrapped;
  final double? extraHorizontalPadding;
  final Widget Function(T)? getAvatar;
  final Color? selectedColor;
  final scrollablePositionedList;
  final EdgeInsets? padding;
  final bool allowMultipleSelected;
  final bool extraWidgetBeforeSticky;

  @override
  State<SelectChips<T>> createState() => _SelectChipsState<T>();
}

class _SelectChipsState<T> extends State<SelectChips<T>> {
  double heightOfScroll = 0;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  bool isDoneAnimation = false;

  @override
  void initState() {
    if (widget.wrapped == false) {
      Future.delayed(const Duration(milliseconds: 0), () {
        int? scrollToIndex;
        int currentIndex = 0;
        for (T item in widget.items) {
          if (widget.getSelected(item)) {
            scrollToIndex = currentIndex;
            break;
          }
          currentIndex++;
        }
        // Extra widget at beginning
        if (widget.extraWidgetBefore != null &&
            scrollToIndex != null &&
            scrollToIndex > 0) {
          scrollToIndex = scrollToIndex + 1;
        }
        if (scrollToIndex != null && scrollToIndex != 0) {
          itemScrollController.scrollTo(
            index: scrollToIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubicEmphasized,
            alignment: widget.extraWidgetBeforeSticky &&
                    widget.extraWidgetBefore != null
                ? 0.4
                : 0.06,
          );
        }
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            isDoneAnimation = true;
          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      if (widget.extraWidgetBefore != null &&
          widget.extraWidgetBeforeSticky == false)
        widget.extraWidgetBefore ?? const SizedBox.shrink(),
      ...List<Widget>.generate(
        widget.items.length,
        (int index) {
          T item = widget.items[index];
          bool selected = widget.getSelected(item);
          String label = widget.getLabel(item);
          Widget? avatar =
              widget.getAvatar == null ? null : widget.getAvatar!(item);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Material(
              color: Colors.transparent,
              child: Tappable(
                onLongPress: () {
                  if (widget.onLongPress != null) widget.onLongPress!(item);
                },
                color: Colors.transparent,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(canvasColor: Colors.transparent),
                  child: ChoiceChip(
                    avatar: avatar == null
                        ? null
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              avatar,
                            ],
                          ),
                    labelPadding: avatar == null
                        ? null
                        : const EdgeInsets.only(
                            left: 5, right: 10, top: 1, bottom: 1),
                    padding: avatar == null
                        ? null
                        : const EdgeInsets.only(left: 10, top: 7, bottom: 7),
                    showCheckmark:
                        widget.allowMultipleSelected == true && avatar == null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    selectedColor: widget.getCustomSelectedColor != null &&
                            widget.getCustomSelectedColor!(item) != null
                        ? widget.getCustomSelectedColor!(item)
                        : widget.selectedColor ??
                            (appStateSettings["materialYou"]
                                ? null
                                : getColor(context, "lightDarkAccentHeavy")),
                    side: widget.getCustomBorderColor == null ||
                            widget.getCustomBorderColor!(item) == null
                        ? null
                        : BorderSide(
                            color: widget.getCustomBorderColor!(item)!,
                          ),
                    label: TextFont(
                      text: label,
                      fontSize: 15,
                    ),
                    selected: selected,
                    onSelected: (bool selected) {
                      widget.onSelected(item);
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
      if (widget.extraWidgetAfter != null)
        widget.extraWidgetAfter ?? const SizedBox.shrink(),
    ];

    EdgeInsets scrollPadding = widget.padding ??
        EdgeInsets.only(
          left: widget.extraWidgetBeforeSticky == true &&
                  widget.extraWidgetBefore != null
              ? (widget.extraHorizontalPadding ?? 0) + 3
              : (widget.extraHorizontalPadding ?? 0) + 18,
          right: (widget.extraHorizontalPadding ?? 0) + 18,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          children.isNotEmpty
              ? IgnorePointer(
                  child: Visibility(
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Opacity(
                      opacity: 0,
                      child: WidgetSize(
                        onChange: (Size size) {
                          setState(() {
                            heightOfScroll = size.height;
                          });
                        },
                        child: widget.extraWidgetBefore == null &&
                                widget.extraWidgetBeforeSticky == false
                            ? children[0]
                            : children[1],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          Row(
            children: [
              if (widget.extraWidgetBefore != null &&
                  widget.extraWidgetBeforeSticky)
                SizedBox(
                  height: heightOfScroll,
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: (widget.extraHorizontalPadding ?? 0) + 18),
                    child: widget.extraWidgetBefore ?? const SizedBox.shrink(),
                  ),
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: widget.wrapped
                      ? Padding(
                          padding: widget.padding ??
                              EdgeInsets.symmetric(
                                  horizontal:
                                      (widget.extraHorizontalPadding ?? 0) +
                                          18),
                          child: Wrap(
                            runSpacing: 10,
                            children: [
                              for (Widget child in children)
                                SizedBox(height: heightOfScroll, child: child)
                            ],
                          ),
                        )
                      : LinearGradientFadedEdges(
                          enableBottom: false,
                          enableRight: false,
                          enableTop: false,
                          enableLeft: widget.extraWidgetBeforeSticky &&
                              widget.extraWidgetBefore != null,
                          child: SizedBox(
                            height: heightOfScroll,
                            child: widget.scrollablePositionedList == false
                                ? SingleChildScrollView(
                                    padding: scrollPadding,
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: children,
                                    ),
                                  )
                                : ScrollablePositionedList.builder(
                                    itemCount: children.length,
                                    itemBuilder: (context, index) =>
                                        children[index],
                                    itemScrollController: itemScrollController,
                                    scrollOffsetController:
                                        scrollOffsetController,
                                    padding: scrollPadding,
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    // physics:
                                    //     isDoneAnimation ? ScrollPhysics() : BouncingScrollPhysics(),
                                  ),
                          ),
                        ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class SelectChipsAddButtonExtraWidget extends StatelessWidget {
  const SelectChipsAddButtonExtraWidget({
    required this.openPage,
    this.onTap,
    this.iconData,
    super.key,
  });
  final Widget? openPage;
  final IconData? iconData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AddButton(
      icon: iconData,
      onTap: onTap ?? () {},
      width: 40,
       padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      openPage: openPage,
      borderRadius: 8,
    );
  }
}
