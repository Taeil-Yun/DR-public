import 'package:DRPublic/component/scrollbar/scrollbar.dart';
import 'package:flutter/material.dart';

class PopUpModal {
  /// [barrierColor] = 팝업박스 밖의 background color
  ///
  /// [barrierDismissible] = "true"일 경우 팝업박스 밖의 영역을 터치하면 팝업이 닫힘, "false"일 경우 팝업박스 밖의 영역을 터치해도 팝업이 닫히지 않음
  ///
  /// [actions] = 하단부분에 들어갈 버튼 widget들
  ///
  /// [title] = 팝업박스의 제목부분
  ///
  /// [onTitleWidget] = 팝업박스의 제목영역을 widget형태로 사용하여 커스텀할 경우 사용
  ///
  /// [content] = 팝업박스의 내용이 보여질 부분
  ///
  /// [onContentWidget] = 팝업박스의 내용영역을 widget 형태로 사용하여 커스텀할 경우 사용
  ///
  /// [backgroundColor] = 팝업박스의 background color
  ///
  /// [actionsAlignment] = 하단 버튼부분의 위치를 변경할 때 사용
  ///
  /// [scrollable] = 팝업안의 내용이 길어서 스크롤이 필요할 때 사용
  ///
  /// [onlyContentScrollable] = 콘텐츠 내용만 스크롤이 필요할 때 사용
  ///
  /// [actionsPadding] = 하단 버튼부분의 padding
  ///
  /// [contentPadding] = 내용영역의 padding
  ///
  /// [onlyContentPadding] = 콘텐츠 부분만 padding 값을 주고싶을 때 사용
  ///
  /// [titlePadding] = 제목영역의 padding
  ///
  /// [shape] = 팝업박스의 border 또는 borderRadius 부분
  ///
  /// [elevation] = 팝업박스의 box shadow 영역
  ///
  /// [titleTextStyle] = 제목 부분의 TextStyle을 사용할 때 사용
  ///
  /// [titleTextColor] = TextStyle을 사용하지 않고 제목의 텍스트 color를 변경
  ///
  /// [titleFontSize] = TextStyle을 사용하지 않고 제목의 텍스트 크기를 변경
  ///
  /// [titleFontWeight] = TextStyle을 사용하지 않고 제목의 텍스트 굵기를 변경
  ///
  /// [contentTextStyle] = 내용 부분의 TextStyle을 사용할 때 사용
  ///
  /// [contentTextColor] = TextStyle을 사용하지 않고 텍스트 color를 변경
  ///
  /// [contentFontSize] = TextStyle을 사용하지 않고 텍스트 크기를 변경
  ///
  /// [contentFontWeight] = TextStyle을 사용하지 않고 텍스트 굵기를 변경
  ///
  /// [useScrollBar] = 스크롤바 사용할 때 사용
  ///
  /// [scrollBarColor] = 스크롤바 색상 변경할 때 사용
  ///
  /// [scrollBarPadding] = 스크롤바 padding
  ///
  /// [useMaxHeight] = maxHeight값을 설정할 때 사용
  ///
  /// [maxHeight] = maxHeight 값
  ///
  /// [PopUpModal]을 호출시 무조건 [dialog]를 호출해줘야 팝업이 정상 작동됨
  ///
  /// [useAndroidBackButton] = 안드로이드 뒤로가기 버튼 활성화/비활성화
  ///
  /// [align] = 정렬
  ///
  PopUpModal({
    this.barrierColor = Colors.black54,
    this.barrierDismissible = true,
    this.actions,
    required this.title,
    this.onTitleWidget,
    required this.content,
    this.onContentWidget,
    this.backgroundColor = Colors.white,
    this.actionsAlignment,
    this.scrollable = false,
    this.onlyContentScrollable = false,
    this.actionsPadding = const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 20.0),
    this.contentPadding = const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 45.0),
    this.onlyContentPadding,
    this.titlePadding = const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
    this.shape,
    this.elevation,
    this.titleTextStyle,
    this.titleTextColor = Colors.black,
    this.titleFontSize = 20.0,
    this.titleFontWeight = FontWeight.w700,
    this.contentTextStyle,
    this.contentTextColor = Colors.black,
    this.contentFontSize = 16.0,
    this.contentFontWeight = FontWeight.w400,
    this.useScrollBar = false,
    this.scrollBarColor,
    this.scrollBarPadding,
    this.useMaxHeight = false,
    this.maxHeight = 400.0,
    this.useAndroidBackButton = false,
    this.align,
  });

  final Color barrierColor;
  final bool barrierDismissible;
  final List<Widget>? actions;
  final String title;
  final Widget? onTitleWidget;
  final String content;
  final Widget? onContentWidget;
  final Color? backgroundColor;
  final MainAxisAlignment? actionsAlignment;
  final bool? scrollable;
  final bool? onlyContentScrollable;
  final EdgeInsetsGeometry actionsPadding;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry? onlyContentPadding;
  final EdgeInsetsGeometry titlePadding;
  final ShapeBorder? shape;
  final double? elevation;
  final TextStyle? titleTextStyle;
  final Color? titleTextColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final TextStyle? contentTextStyle;
  final Color? contentTextColor;
  final double? contentFontSize;
  final FontWeight? contentFontWeight;
  final Color? scrollBarColor;
  final bool useScrollBar;
  final EdgeInsetsGeometry? scrollBarPadding;
  final bool useMaxHeight;
  final double maxHeight;
  final bool useAndroidBackButton;
  final Alignment? align;

  void dialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        if (useAndroidBackButton) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              actions: actions,
              title: onTitleWidget ??
                  Text(
                    title,
                    style: titleTextStyle ??
                        TextStyle(
                          color: titleTextColor,
                          fontSize: titleFontSize,
                          fontWeight: titleFontWeight,
                        ),
                  ),
              content: onlyContentScrollable!
                  ? useMaxHeight
                      ? ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxHeight,
                          ),
                          child: Container(
                            padding: onlyContentPadding,
                            child: useScrollBar
                                ? ScrollBarModal(
                                    thumbColor: scrollBarColor!,
                                    child: SingleChildScrollView(
                                      child: Container(
                                        padding: scrollBarPadding,
                                        child: onContentWidget ??
                                            Text(
                                              content,
                                              style: contentTextStyle ??
                                                  TextStyle(
                                                    color: contentTextColor,
                                                    fontSize: contentFontSize,
                                                    fontWeight:
                                                        contentFontWeight,
                                                  ),
                                            ),
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Container(
                                      padding: scrollBarPadding,
                                      child: onContentWidget ??
                                          Text(
                                            content,
                                            style: contentTextStyle ??
                                                TextStyle(
                                                  color: contentTextColor,
                                                  fontSize: contentFontSize,
                                                  fontWeight: contentFontWeight,
                                                ),
                                          ),
                                    ),
                                  ),
                          ),
                        )
                      : Container(
                          padding: onlyContentPadding,
                          child: useScrollBar
                              ? ScrollBarModal(
                                  thumbColor: scrollBarColor!,
                                  child: SingleChildScrollView(
                                    child: Container(
                                      padding: scrollBarPadding,
                                      child: onContentWidget ??
                                          Text(
                                            content,
                                            style: contentTextStyle ??
                                                TextStyle(
                                                  color: contentTextColor,
                                                  fontSize: contentFontSize,
                                                  fontWeight: contentFontWeight,
                                                ),
                                          ),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Container(
                                    padding: scrollBarPadding,
                                    child: onContentWidget ??
                                        Text(
                                          content,
                                          style: contentTextStyle ??
                                              TextStyle(
                                                color: contentTextColor,
                                                fontSize: contentFontSize,
                                                fontWeight: contentFontWeight,
                                              ),
                                        ),
                                  ),
                                ),
                        )
                  : onContentWidget ??
                      Text(
                        content,
                        style: contentTextStyle ??
                            TextStyle(
                              color: contentTextColor,
                              fontSize: contentFontSize,
                              fontWeight: contentFontWeight,
                            ),
                      ),
              backgroundColor: backgroundColor,
              actionsAlignment: actionsAlignment ?? MainAxisAlignment.start,
              scrollable: scrollable ?? true,
              titlePadding: titlePadding,
              contentPadding: contentPadding,
              actionsPadding: actionsPadding,
              shape: shape ??
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
              alignment: align,
            ),
          );
        }
        return AlertDialog(
          actions: actions,
          title: onTitleWidget ??
              Text(
                title,
                style: titleTextStyle ??
                    TextStyle(
                      color: titleTextColor,
                      fontSize: titleFontSize,
                      fontWeight: titleFontWeight,
                    ),
              ),
          content: onlyContentScrollable!
              ? useMaxHeight
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                      ),
                      child: Container(
                        padding: onlyContentPadding,
                        child: useScrollBar
                            ? ScrollBarModal(
                                thumbColor: scrollBarColor!,
                                child: SingleChildScrollView(
                                  child: Container(
                                    padding: scrollBarPadding,
                                    child: onContentWidget ??
                                        Text(
                                          content,
                                          style: contentTextStyle ??
                                              TextStyle(
                                                color: contentTextColor,
                                                fontSize: contentFontSize,
                                                fontWeight: contentFontWeight,
                                              ),
                                        ),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Container(
                                  padding: scrollBarPadding,
                                  child: onContentWidget ??
                                      Text(
                                        content,
                                        style: contentTextStyle ??
                                            TextStyle(
                                              color: contentTextColor,
                                              fontSize: contentFontSize,
                                              fontWeight: contentFontWeight,
                                            ),
                                      ),
                                ),
                              ),
                      ),
                    )
                  : Container(
                      padding: onlyContentPadding,
                      child: useScrollBar
                          ? ScrollBarModal(
                              thumbColor: scrollBarColor!,
                              child: SingleChildScrollView(
                                child: Container(
                                  padding: scrollBarPadding,
                                  child: onContentWidget ??
                                      Text(
                                        content,
                                        style: contentTextStyle ??
                                            TextStyle(
                                              color: contentTextColor,
                                              fontSize: contentFontSize,
                                              fontWeight: contentFontWeight,
                                            ),
                                      ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Container(
                                padding: scrollBarPadding,
                                child: onContentWidget ??
                                    Text(
                                      content,
                                      style: contentTextStyle ??
                                          TextStyle(
                                            color: contentTextColor,
                                            fontSize: contentFontSize,
                                            fontWeight: contentFontWeight,
                                          ),
                                    ),
                              ),
                            ),
                    )
              : onContentWidget ??
                  Text(
                    content,
                    style: contentTextStyle ??
                        TextStyle(
                          color: contentTextColor,
                          fontSize: contentFontSize,
                          fontWeight: contentFontWeight,
                        ),
                  ),
          backgroundColor: backgroundColor,
          actionsAlignment: actionsAlignment ?? MainAxisAlignment.start,
          scrollable: scrollable ?? true,
          titlePadding: titlePadding,
          contentPadding: contentPadding,
          actionsPadding: actionsPadding,
          shape: shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          alignment: align,
        );
      },
    );
  }
}
