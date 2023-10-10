import 'package:flutter/material.dart';

const double _kMinThumbExtent = 18.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

class ScrollBarModal extends StatelessWidget {
  /// 사용시에 스크롤바를 넣어줄 부모위젯에다가 감싸주면 스크롤할 때 스크롤바가 보여짐
  /// [ScrollBarModal]의 필요한 속성들을 변경
  const ScrollBarModal({
    Key? key,
    required this.child,
    this.controller,
    this.isAlwaysShown,
    this.radius = const Radius.circular(100.0),
    this.thickness,
    this.thumbColor = const Color(0xFF808080),
    this.minThumbLength = _kMinThumbExtent,
    this.minOverscrollLength,
    this.fadeDuration = _kScrollbarFadeDuration,
    this.timeToFade = _kScrollbarTimeToFade,
    this.pressDuration = Duration.zero,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.interactive,
    this.scrollbarOrientation,
    this.mainAxisMargin = 0.0,
    this.crossAxisMargin = 0.0
  }) : assert(minThumbLength >= 0),
       assert(minOverscrollLength == null || minOverscrollLength <= minThumbLength),
       assert(minOverscrollLength == null || minOverscrollLength >= 0),
       super(key: key);

  final Widget child;
  final ScrollController? controller;
  final bool? isAlwaysShown;
  final Radius radius;
  final double? thickness;
  final Color thumbColor;
  final double minThumbLength;
  final double? minOverscrollLength;
  final Duration fadeDuration;
  final Duration timeToFade;
  final Duration pressDuration;
  final bool Function(ScrollNotification) notificationPredicate;
  final bool? interactive;
  final ScrollbarOrientation? scrollbarOrientation;
  final double mainAxisMargin;
  final double crossAxisMargin;

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      child: child,
      controller: controller,
      thumbVisibility: isAlwaysShown,
      radius: radius,
      thickness: thickness,
      thumbColor: thumbColor,
      minThumbLength: minThumbLength,
      minOverscrollLength: minOverscrollLength,
      fadeDuration: fadeDuration,
      timeToFade: timeToFade,
      pressDuration: pressDuration,
      notificationPredicate: notificationPredicate,
      interactive: interactive,
      scrollbarOrientation: scrollbarOrientation,
      mainAxisMargin: mainAxisMargin,
      crossAxisMargin: crossAxisMargin,
    );
  }
}