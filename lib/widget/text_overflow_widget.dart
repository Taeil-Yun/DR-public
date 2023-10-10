import 'package:flutter/material.dart';

enum TextOverflowAlign {
  left,
  right,
  center,
}

enum TextOverflowPosition {
  start,
  middle,
  end,
}

class TextOverflowWidgetBuilder extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const TextOverflowWidgetBuilder({
    required this.child,
    this.align = TextOverflowAlign.right,
    this.maxHeight,
    this.position = TextOverflowPosition.end,
    this.debugOverflowRectColor,
  });

  final Widget child;
  final TextOverflowAlign align;
  final double? maxHeight;
  final TextOverflowPosition position;
  final Color? debugOverflowRectColor;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}