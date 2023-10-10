import 'package:DRPublic/widget/svg_asset.dart';
import 'package:flutter/material.dart';

import 'package:DRPublic/conf/colors.dart';

class DRAppBarLeading extends StatelessWidget {
  ///
  /// AppBar Leading Component
  ///
  /// - [press] (required / VoidCallback type) : 앱바 좌측 버튼의 액션 (주로 뒤로가기 버튼으로 사용)
  /// - [icon] (optional / Widget type / default = 뒤로가기 아이콘) : 앱바 좌측 버튼의 아이콘
  /// - [using] (optional / boolean type / default = true) : 앱바에서 좌측의 아이콘을 사용하지 않을경우 false로 변경,
  /// true는 사용하겠다는 의미이며 [using]사용시 [icon]을 설정하지않으면 기본값인 뒤로가기 버튼으로 설정
  /// - [iconColor] (optional / Color type / default = ColorsConfig.defaultAppBarLeadingColor) : 앱바 아이콘의 색상
  /// - [iconSize] (optional / double type / default = 22.0) : 앱바 아이콘의 크기
  const DRAppBarLeading({
    Key? key,
    required this.press,
    this.icon,
    this.using = true,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  final VoidCallback press;
  final Widget? icon;
  final bool? using;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: ColorsConfig.transparent,
      highlightColor: ColorsConfig.transparent,
      onTap: press,
      // [using]의 값이 null이 아니며, true일 경우 [icon]을 사용하지만, [icon]의 값이 null일 경우 기본적으로 설정되어있는 뒤로가기 위젯 사용
      child: using!
          ? Center(
              child: icon ??
                  SvgAssets(
                    image: 'assets/icon/arrow_left.svg',
                    width: iconSize ?? 22.0,
                    height: iconSize ?? 22.0,
                    color: iconColor ?? ColorsConfig().textWhite1(),
                  ),
            )
          : Container(),
    );
  }
}
