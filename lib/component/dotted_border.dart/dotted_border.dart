library custom_dotted_border_builder;

import 'package:flutter/material.dart';

import 'package:path_drawing/path_drawing.dart';

import 'package:DRPublic/conf/colors.dart';

part 'dash_paint.dart';

enum BorderType { circle, rrect, rect, oval }

class CustomDottedBorderBuilder extends StatelessWidget {
  CustomDottedBorderBuilder({
    Key? key,
    required this.child,
    this.color = ColorsConfig.defaultBlack,
    this.strokeWidth = 1.0,
    this.borderType = BorderType.rect,
    this.pattern = const <double>[4, 2],
    this.padding = EdgeInsets.zero,
    this.radius = const Radius.circular(0),
    this.strokeCap = StrokeCap.butt,
    this.customPath,
  }) : super(key: key) {
    assert(isValidDashPattern(pattern), 'Invalid dash pattern');
  }

  final Widget child;
  final EdgeInsets padding;
  final double strokeWidth;
  final Color color;
  final List<double> pattern;
  final BorderType borderType;
  final Radius radius;
  final StrokeCap strokeCap;
  final PathBuilder? customPath;

  bool isValidDashPattern(List<double>? dashPattern) {
    Set<double>? _dashSet = dashPattern?.toSet();

    if (_dashSet == null) return false;
    if (_dashSet.length == 1 && _dashSet.elementAt(0) == 0.0) return false;
    if (_dashSet.isEmpty) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: CustomDashPainter(
              strokeWidth: strokeWidth,
              radius: radius,
              color: color,
              borderType: borderType,
              pattern: pattern,
              customPath: customPath,
              strokeCap: strokeCap,
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}
