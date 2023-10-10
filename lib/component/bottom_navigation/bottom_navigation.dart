import 'package:flutter/material.dart';

import 'package:DRPublic/conf/colors.dart';

class DRBottomNavigationBar {
  ///
  /// Bottom NavigationBar Component
  ///
  /// - [itemLength] (required) : [BottomNavigationBar]를 사용할 때 화면의 개수 ([items]의 개수와 [itemLength]의 개수는 동일해야함)
  ///
  /// - [items] (required) : [BottomNavigationBarItem]의 리스트
  ///
  /// - [onTap] (required) : item을 클릭시에 호출될 이벤트
  ///
  /// - [currentIndex] (optional / default = 0) : 현재 활성화된 [BottomNavigationBarItem]의 [items]에 대한 인덱스
  ///
  /// - [elevation] (optional / default = 8.0) : [BottomNavigationBar]의 그림자(음영)
  ///
  /// - [type] (optional / default = [BottomNavigationBarType.fixed]) : 레이아웃과 동작
  ///   type의 종류 (enum)
  ///     1. fixed = 선택된 아이템만 icon과 label을 보여주는 것이 아닌 모든 icon과 label을 보여주기 위한 타입
  ///     2. shifting = 선택된 아이템만 icon과 label을 보여주는 타입
  ///
  /// - [backgroundColor] (optional / default = [ColorsConfig.defaultBottomNavBarBgColor]) : [BottomNavigationBar]의 배경색
  ///
  /// - [iconSize] (optional / default = 24) : [BottomNavigationBarItem]의 아이콘 크기
  ///
  /// - [selectedItemColor] (optional / default = [ColorsConfig.bottomNavBarActiveColor]) : 선택된 아이템의 색
  ///
  /// - [unselectedItemColor] (optional / default = [ColorsConfig.bottomNavBarDisabledColor]) : 선택되지 않은 아이템의 색
  ///
  /// - [selectedFontSize] (optional / default = 10) : 선택된 글자(label)의 크기
  ///
  /// - [unselectedFontSize] (optional / default = 10) : 선택되지않은 글자(label)의 크기
  ///
  /// - [selectedLabelStyle] (optional / default = 폰트굵기 bold) : 선택된 글자(label)의 text style
  ///
  /// - [unselectedLabelStyle] (optional / default = 폰트굵기 bold) : 선택되지 않은 글자(label)의 text style
  ///
  /// - [showSelectedLabels] (optional) : 선택된 글자(label)를 보여줌
  ///
  /// - [showUnselectedLabels] (optional) : 선택되지 않은 글자(label)를 보여줌
  ///
  /// - [mouseCursor] (optional) : 마우스 포인터나 클릭이 되었을 때
  ///
  /// - [enableFeedback] (optional) : 감지된 제스처가 음향 및/또는 촉각 피드백을 제공해야 하는지 여부
  ///   ex) Android에서 탭하면 딸깍 소리가 나며, 피드백이 활성화되면 길게 누르면 짧은 진동이 발생
  ///
  /// - [landscapeLayout] (optional) : 묶을 때 막대의 [items] 배열
  /// [MediaQueryData.orientation]은 [Orientation.landscape]
  ///
  /// [landscapeLayout]의 list
  /// * [BottomNavigationBarLandscapeLayout.spread] = 균일한 간격과 사용 가능한 너비에 걸쳐 퍼지며, 각 항목의 레이블과 아이콘은 열에 정렬
  /// * [BottomNavigationBarLandscapeLayout.center] = 행에 균등한 간격으로 배치되지만 너비만큼만 소비되며, 세로 방향, 항목 행이 중앙에 있음
  /// * [BottomNavigationBarLandscapeLayout.linear] = 균등한 간격으로 각 항목의 아이콘과 레이블이 정렬
  /// #### 이 속성이 null이면 둘러싸는 값
  /// * [BottomNavigationBarThemeData.landscapeLayout]을 사용 만약 이 속성도 null이면 [BottomNavigationBarLandscapeLayout.spread]를 사용
  /// * [ThemeData.bottomNavigationBarTheme] = theme를 지정하는데 사용
  /// * [BottomNavigationBarTheme] - [ThemeData]를 사용할 때 사용
  /// * [MediaQuery.of] - 현재를 확인하는 데 사용
  ///
  Widget? bottomNavigation(BuildContext context,
      {required int itemLength,
      required List<BottomNavigationBarItem> items,
      required void Function(int) onTap,
      int? currentIndex,
      double? elevation,
      BottomNavigationBarType? type,
      Color? backgroundColor,
      double? iconSize,
      Color? selectedItemColor,
      Color? unselectedItemColor,
      double? selectedFontSize,
      double? unselectedFontSize,
      TextStyle? selectedLabelStyle,
      TextStyle? unselectedLabelStyle,
      bool? showSelectedLabels,
      bool? showUnselectedLabels,
      MouseCursor? mouseCursor,
      bool? enableFeedback,
      BottomNavigationBarLandscapeLayout? landscapeLayout}) {
    if (items.length != itemLength) {
      throw Exception(
          'The number of items cannot be greater than the number of items.');
    }
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex ?? 0,
        items: items,
        onTap: onTap,
        elevation: elevation ?? 8.0,
        type: type ?? BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor ?? ColorsConfig().subBackground1(),
        iconSize: iconSize ?? 24.0,
        selectedItemColor: selectedItemColor ?? ColorsConfig().primary(),
        unselectedItemColor: unselectedItemColor ?? ColorsConfig().textBlack2(),
        selectedFontSize: selectedFontSize ?? 10.0,
        unselectedFontSize: unselectedFontSize ?? 10.0,
        selectedLabelStyle: selectedLabelStyle ??
            const TextStyle(
              fontWeight: FontWeight.w400,
            ),
        unselectedLabelStyle: unselectedLabelStyle ??
            const TextStyle(
              fontWeight: FontWeight.w400,
            ),
        showSelectedLabels: showSelectedLabels ?? true,
        showUnselectedLabels: showUnselectedLabels ?? true,
        mouseCursor: mouseCursor,
        enableFeedback: enableFeedback,
        landscapeLayout: landscapeLayout,
      ),
    );
  }
}
