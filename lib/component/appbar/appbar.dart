import 'package:flutter/material.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:flutter/services.dart';

class DRAppBar extends StatelessWidget implements PreferredSizeWidget {
  ///
  /// AppBar Component
  ///
  /// - [title] (optional / Widget type) : 앱바의 타이틀
  /// - [center] (optional / boolean type / default = true) : 앱바의 타이틀 센터정렬
  /// - [leading] (optional / Widget type) : 앱바의 좌측 버튼 또는 widget
  /// - [actions] (optional / List<Widget> type) : 앱바의 우측 버튼 또는 widget
  /// - [backgroundColor] (optional / Color type / default = ColorsConfig.defaultAppBarColor) : 앱바의 백그라운드 색상
  /// - [elevation] (optional / double type / default = 0.0) : 앱바의 그림자(음영) 크기
  /// - [bottom] (optional / PreferredSizeWidget type) : 앱바를 확장할 때 사용
  /// - [leadingWidth] (optional / double type) : 앱바 좌측 버튼의 width size (주로 [center]를 false 값으로 사용할 때 좌측의 공간을 없애주기 위해 사용)
  /// - [systemUiOverlayStyle] (optional / SystemUiOverlayStyle type) : AppBar 시스템 UI 설정
  /// - [toolbarHeight] (optional / double type) : 앱바의 높이를 설정할 때 사용
  ///
  const DRAppBar({
    Key? key,
    this.title,
    this.center = true,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation = 0.0,
    this.bottom,
    this.leadingWidth,
    this.systemUiOverlayStyle,
    this.toolbarHeight,
  }) : super(key: key);

  final Widget? title;
  final bool? center;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double? elevation;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;
  final SystemUiOverlayStyle? systemUiOverlayStyle;
  final double? toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(bottom == null
      ? toolbarHeight != null
          ? toolbarHeight!
          : AppBar().preferredSize.height
      : AppBar().preferredSize.height + bottom!.preferredSize.height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      centerTitle: center,
      title: title,
      elevation: elevation,
      backgroundColor: backgroundColor ?? ColorsConfig().subBackground1(),
      actions: actions,
      bottom: bottom,
      leadingWidth: leadingWidth,
      systemOverlayStyle: systemUiOverlayStyle,
      toolbarHeight: toolbarHeight,
    );
  }
}
