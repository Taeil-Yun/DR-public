import 'package:DRPublic/conf/enumerated.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class SvgAssets extends StatelessWidget {
  SvgAssets({
    Key? key,
    required this.image,
    this.type = SvgType.asset,
    this.matchTextDirection = false,
    this.bundle,
    this.package,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.cacheColorFilter = false,
  }) : super(key: key);

  String image;
  bool matchTextDirection;
  AssetBundle? bundle;
  String? package;
  double? width;
  double? height;
  BoxFit fit;
  AlignmentGeometry alignment;
  bool allowDrawingOutsideViewBox;
  Widget Function(BuildContext)? placeholderBuilder;
  Color? color;
  BlendMode colorBlendMode;
  String? semanticsLabel;
  bool excludeFromSemantics;
  Clip clipBehavior;
  bool cacheColorFilter;
  SvgType type;

  @override
  Widget build(BuildContext context) {
    if (type == SvgType.network) {
      return SvgPicture.network(
        image,
        matchTextDirection: matchTextDirection,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
        placeholderBuilder: placeholderBuilder,
        color: color,
        colorBlendMode: colorBlendMode,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
        clipBehavior: clipBehavior,
        cacheColorFilter: cacheColorFilter,
      );
    }
    return SvgPicture.asset(
      image,
      matchTextDirection: matchTextDirection,
      bundle: bundle,
      package: package,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      color: color,
      colorBlendMode: colorBlendMode,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }
}
