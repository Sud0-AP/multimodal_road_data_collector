import 'package:flutter/material.dart';

/// A widget that displays page indicators for a multi-page flow
class PageIndicator extends StatelessWidget {
  /// The total number of pages
  final int pageCount;

  /// The index of the current page
  final int currentPage;

  /// The color of the active indicator
  final Color activeColor;

  /// The color of the inactive indicators
  final Color inactiveColor;

  /// The size of the indicators
  final double size;

  /// The spacing between indicators
  final double spacing;

  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.size = 10.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentPage ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
