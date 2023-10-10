import 'dart:ui';

import 'package:DRPublic/widget/text_overflow_widget.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomTextBuilder extends StatelessWidget {
  CustomTextBuilder(
      {Key? key,

      /// text parameters
      required this.text,
      this.style,
      this.strutStyle,
      this.textAlign,
      this.textDirection,
      this.textLocale,
      this.softWrap,
      this.textOverflow,
      this.textScaleFactor = 1.0,
      this.maxLines,
      this.semanticsLabel,
      this.textWidthBasis,
      this.textHeightBehavior,
      this.textOverflowWidgetBuilder,

      /// text style
      this.fontColor,
      this.fontSize,
      this.fontWeight,
      this.fontFamily,
      this.height,
      this.styleOverflow,
      this.fontStyle,
      this.decoration,
      this.decorationColor,
      this.decorationStyle,
      this.decorationThickness,
      this.background,
      this.backgroundColor,
      this.foreground,
      this.letterSpacing,
      this.wordSpacing,
      this.inherit = true,
      this.textBaseline,
      this.leadingDistribution,
      this.styleLocale,
      this.shadows,
      this.fontFeatures,
      this.debugLabel,
      this.fontFamilyFallback,
      this.package})
      : super(key: key);

  // text parameters
  TextStyle? style;
  StrutStyle? strutStyle;
  TextAlign? textAlign;
  TextDirection? textDirection;
  Locale? textLocale;
  bool? softWrap;
  TextOverflow? textOverflow;
  double textScaleFactor;
  int? maxLines;
  String? semanticsLabel;
  TextWidthBasis? textWidthBasis;
  TextHeightBehavior? textHeightBehavior;
  TextOverflowWidgetBuilder? textOverflowWidgetBuilder;

  // text style
  String text;
  Color? fontColor;
  double? fontSize;
  FontWeight? fontWeight;
  String? fontFamily;
  double? height;
  TextOverflow? styleOverflow;
  FontStyle? fontStyle;
  TextDecoration? decoration;
  Color? decorationColor;
  TextDecorationStyle? decorationStyle;
  double? decorationThickness;
  Paint? background;
  Color? backgroundColor;
  Paint? foreground;
  double? letterSpacing;
  double? wordSpacing;
  bool inherit;
  TextBaseline? textBaseline;
  TextLeadingDistribution? leadingDistribution;
  Locale? styleLocale;
  List<Shadow>? shadows;
  List<FontFeature>? fontFeatures;
  String? debugLabel;
  List<String>? fontFamilyFallback;
  String? package;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ??
          TextStyle(
              color: fontColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontFamily: 'AppleSDGothicNeo',
              height: height,
              overflow: styleOverflow,
              fontStyle: fontStyle,
              decoration: decoration,
              decorationColor: decorationColor,
              decorationStyle: decorationStyle,
              decorationThickness: decorationThickness,
              background: background,
              backgroundColor: backgroundColor,
              foreground: foreground,
              letterSpacing: letterSpacing,
              wordSpacing: wordSpacing,
              inherit: inherit,
              textBaseline: textBaseline,
              leadingDistribution: leadingDistribution,
              locale: styleLocale,
              shadows: shadows,
              fontFeatures: fontFeatures,
              debugLabel: debugLabel,
              fontFamilyFallback: fontFamilyFallback,
              package: package),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: textLocale,
      softWrap: softWrap,
      overflow: textOverflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}
