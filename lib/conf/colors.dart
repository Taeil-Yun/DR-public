import 'package:DRPublic/main.dart';
import 'package:flutter/material.dart';

class ColorsConfig {
  final _theme = DRPublicApp.themeNotifier.value;

  ///
  /// 메인 Color
  /// Color Code
  /// [dark] = #00cc00
  /// [light] = #00cc00
  ///
  Color primary({double opacity = 1}) {
    Color _primary = _theme == ThemeMode.dark
        ? const Color(0xFF00cc00).withOpacity(opacity)
        : const Color(0xFF00cc00).withOpacity(opacity);

    return _primary;
  }

  ///
  /// 투표 테두리 Color
  /// Color Code
  /// [dark] = #1ba873
  /// [light] = #1ba873
  ///
  Color voteBorder({double? opacity}) {
    opacity = opacity ?? 1;
    Color _voteBorder = _theme == ThemeMode.dark
        ? const Color(0xFF1ba873).withOpacity(opacity)
        : const Color(0xFF1ba873).withOpacity(opacity);

    return _voteBorder;
  }

  ///
  /// 차트 배경 Color
  /// Color Code = #181818
  ///
  Color chartBackground({double opacity = 1}) {
    Color _chartBackground = _theme == ThemeMode.dark
        ? const Color(0xFF181818).withOpacity(opacity)
        : const Color(0xFFff0000).withOpacity(opacity);

    return _chartBackground;
  }

  ///
  /// 그래프 라인1 Color
  /// Color Code
  /// [dark] = #1F694D
  /// [light] = #63d3a8
  ///
  Color graphColor1({double opacity = 1}) {
    Color _graphColor1 = _theme == ThemeMode.dark
        ? const Color(0xFF1F694D).withOpacity(opacity)
        : const Color(0xFF63d3a8).withOpacity(opacity);

    return _graphColor1;
  }

  ///
  /// 그래프 라인2 Color
  /// Color Code
  /// [dark] = #707070
  /// [light] = #707070
  ///
  Color graphColor2({double opacity = 0.4}) {
    Color _graphColor2 = _theme == ThemeMode.dark
        ? const Color(0xFF707070).withOpacity(opacity)
        : const Color(0xFF707070).withOpacity(opacity);

    return _graphColor2;
  }

  ///
  /// 링크 아이콘 배경 Color
  /// Color Code
  /// [dark] = #000000
  /// [light] = #000000
  /// opacity = 0.16
  ///
  Color linkIconBackground({double opacity = 0.16}) {
    Color _linkIconBackground = _theme == ThemeMode.dark
        ? const Color(0xFF000000).withOpacity(opacity)
        : const Color(0xFF000000).withOpacity(opacity);

    return _linkIconBackground;
  }

  ///
  /// 배경 Color
  /// Color Code
  /// [dark] = #000000
  /// [light] = #f2f2f2
  ///
  Color background({double opacity = 1}) {
    Color _background = _theme == ThemeMode.dark
        ? const Color(0xFF000000).withOpacity(opacity)
        : const Color(0xFFf2f2f2).withOpacity(opacity);

    return _background;
  }

  ///
  /// 서브 배경1 Color
  /// Color Code
  /// [dark] = #141414
  /// [light] = #fafafa
  ///
  Color subBackground1({double opacity = 1}) {
    Color _subBackground = _theme == ThemeMode.dark
        ? const Color(0xFF141414).withOpacity(opacity)
        : const Color(0xFFfafafa).withOpacity(opacity);

    return _subBackground;
  }

  ///
  /// border1 Color
  /// Color Code
  /// [dark] = #404040
  /// [light] = #cccccc
  ///
  Color border1({double opacity = 1}) {
    Color _border = _theme == ThemeMode.dark
        ? const Color(0xFF404040).withOpacity(opacity)
        : const Color(0xFFcccccc).withOpacity(opacity);

    return _border;
  }

  ///
  /// border2 Color
  /// Color Code
  /// [dark] = #404040
  /// [light] = #cccccc
  ///
  Color border2({double opacity = 1}) {
    Color _border = _theme == ThemeMode.dark
        ? const Color(0xFF404040).withOpacity(opacity)
        : const Color(0xFFcccccc).withOpacity(opacity);

    return _border;
  }

  ///
  /// only use border from light theme Color
  /// Color Code
  /// [dark] = transparent
  /// [light] = #cccccc
  ///
  Color lightOnlyBorder({double opacity = 1}) {
    Color _border = _theme != ThemeMode.dark
        ? Colors.transparent
        : const Color(0xFFcccccc).withOpacity(opacity);

    return _border;
  }

  ///
  /// subBackground3 Color
  /// Color Code
  /// [dark] = #393939
  /// [light] = #e8e8e8
  ///
  Color subBackground3({double opacity = 1}) {
    Color _subBackground3 = _theme == ThemeMode.dark
        ? const Color(0xFF393939).withOpacity(opacity)
        : const Color(0xFFe8e8e8).withOpacity(opacity);

    return _subBackground3;
  }

  ///
  /// subBackground4 Color
  /// Color Code
  /// [dark] = #393939
  /// [light] = #f2f2f2
  ///
  Color subBackground4({double opacity = 1}) {
    Color _subBackground4 = _theme == ThemeMode.dark
        ? const Color(0xFF393939).withOpacity(opacity)
        : const Color(0xFFf2f2f2).withOpacity(opacity);

    return _subBackground4;
  }

  ///
  /// textBlack1 Color
  /// Color Code
  /// [dark] = #cccccc
  /// [light] = #666666
  ///
  Color textBlack1({double opacity = 1}) {
    Color _textBlack1 = _theme == ThemeMode.dark
        ? const Color(0xFFcccccc).withOpacity(opacity)
        : const Color(0xFF666666).withOpacity(opacity);

    return _textBlack1;
  }

  ///
  /// text1 Color
  /// Color Code
  /// [dark] = #1e1e1e
  /// [light] = #fafafa
  ///
  Color text1({double opacity = 1}) {
    Color _text1 = _theme == ThemeMode.dark
        ? const Color(0xFF1e1e1e).withOpacity(opacity)
        : const Color(0xFFfafafa).withOpacity(opacity);

    return _text1;
  }

  ///
  /// textWhite1 Color
  /// Color Code
  /// [dark] = #ffffff
  /// [light] = #313131
  ///
  Color textWhite1({double opacity = 1}) {
    Color _textWhite1 = _theme == ThemeMode.dark
        ? const Color(0xFFffffff).withOpacity(opacity)
        : const Color(0xFF313131).withOpacity(opacity);

    return _textWhite1;
  }

  ///
  /// All Theme Text Color
  /// Color Code
  /// [dark] = #1e1e1e
  /// [light] = #313131
  ///
  Color textAllBlack1({double opacity = 1}) {
    Color _textAllBlack1 = _theme == ThemeMode.dark
        ? const Color(0xFF1e1e1e).withOpacity(opacity)
        : const Color(0xFF313131).withOpacity(opacity);

    return _textAllBlack1;
  }

  ///
  /// primarySub1 Color
  /// Color Code
  /// [dark] = #4bea87
  /// [light] = #22af57
  ///
  Color primarySub1({double opacity = 1}) {
    Color _primarySub1 = _theme == ThemeMode.dark
        ? const Color(0xFF4bea87).withOpacity(opacity)
        : const Color(0xFF22af57).withOpacity(opacity);

    return _primarySub1;
  }

  ///
  /// textRed1 Color
  /// Color Code
  /// [dark] = #e25a5a
  /// [light] = #e87a7a
  ///
  Color textRed1({double opacity = 1}) {
    Color _textRed1 = _theme == ThemeMode.dark
        ? const Color(0xFFe25a5a).withOpacity(opacity)
        : const Color(0xFFe87a7a).withOpacity(opacity);

    return _textRed1;
  }

  ///
  /// textRed2 Color
  /// Color Code
  /// [dark] = #e25a5a
  /// [light] = #e25a5a
  ///
  Color textRed2({double opacity = 1}) {
    Color _textRed2 = _theme == ThemeMode.dark
        ? const Color(0xFFe25a5a).withOpacity(opacity)
        : const Color(0xFFe25a5a).withOpacity(opacity);

    return _textRed2;
  }

  ///
  /// hashTag Color
  /// Color Code
  /// [dark] = #67abe5
  /// [light] = #4292ef
  ///
  Color hashTag({double opacity = 1}) {
    Color _hashTag = _theme == ThemeMode.dark
        ? const Color(0xFF67abe5).withOpacity(opacity)
        : const Color(0xFF4292ef).withOpacity(opacity);

    return _hashTag;
  }

  ///
  /// promotionLabel Color
  /// Color Code
  /// [dark] = #4e5157
  /// [light] = #9ba2b1
  ///
  Color promotionLabel({double opacity = 1}) {
    Color _promotionLabel = _theme == ThemeMode.dark
        ? const Color(0xFF4e5157).withOpacity(opacity)
        : const Color(0xFF9ba2b1).withOpacity(opacity);

    return _promotionLabel;
  }

  ///
  /// debateLabel Color
  /// Color Code
  /// [dark] = #c99535
  /// [light] = #f3b33e
  ///
  Color debateLabel({double opacity = 1}) {
    Color _debateLabel = _theme == ThemeMode.dark
        ? const Color(0xFFc99535).withOpacity(opacity)
        : const Color(0xFFf3b33e).withOpacity(opacity);

    return _debateLabel;
  }

  ///
  /// voteLabel Color
  /// Color Code
  /// [dark] = #8b28bf
  /// [light] = #75147b
  ///
  Color voteLabel({double opacity = 1}) {
    Color _voteLabel = _theme == ThemeMode.dark
        ? const Color(0xFF8b28bf).withOpacity(opacity)
        : const Color(0xFF75147b).withOpacity(opacity);

    return _voteLabel;
  }

  ///
  /// postLabel Color
  /// Color Code
  /// [dark] = #549c52
  /// [light] = #549c52
  ///
  Color postLabel({double opacity = 1}) {
    Color _postLabel = _theme == ThemeMode.dark
        ? const Color(0xFF549c52).withOpacity(opacity)
        : const Color(0xFF549c52).withOpacity(opacity);

    return _postLabel;
  }

  ///
  /// analyticsLabel Color
  /// Color Code
  /// [dark] = #bf3528
  /// [light] = #e93323
  ///
  Color analyticsLabel({double opacity = 1}) {
    Color _analyticsLabel = _theme == ThemeMode.dark
        ? const Color(0xFFbf3528).withOpacity(opacity)
        : const Color(0xFFe93323).withOpacity(opacity);

    return _analyticsLabel;
  }

  ///
  /// newsLabel Color
  /// Color Code
  /// [dark] = #408fc9
  /// [light] = #408fc9
  ///
  Color newsLabel({double opacity = 1}) {
    Color _newsLabel = _theme == ThemeMode.dark
        ? const Color(0xFF408fc9).withOpacity(opacity)
        : const Color(0xFF408fc9).withOpacity(opacity);

    return _newsLabel;
  }

  ///
  /// textBlack2 Color
  /// Color Code
  /// [dark] = #f2f2f2
  /// [light] = #2e2e2e
  ///
  Color textBlack2({double opacity = 1}) {
    Color _textBlack2 = _theme == ThemeMode.dark
        ? const Color(0xFFf2f2f2).withOpacity(opacity)
        : const Color(0xFF2e2e2e).withOpacity(opacity);

    return _textBlack2;
  }

  ///
  /// textBlack3 Color
  /// Color Code
  /// [dark] = #cccccc
  /// [light] = #404040
  ///
  Color textBlack3({double opacity = 1}) {
    Color _textBlack3 = _theme == ThemeMode.dark
        ? const Color(0xFFcccccc).withOpacity(opacity)
        : const Color(0xFF404040).withOpacity(opacity);

    return _textBlack3;
  }

  ///
  /// subBackgroundBlack Color
  /// Color Code
  /// [dark] = #363636
  /// [light] = #ededed
  ///
  Color subBackgroundBlack({double opacity = 1}) {
    Color _subBackgroundBlack = _theme == ThemeMode.dark
        ? const Color(0xFF363636).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _subBackgroundBlack;
  }

  ///
  /// naverBackground Color
  /// Color Code
  /// [dark] = #1fc302
  /// [light] = #1fc302
  ///
  Color naverBackground({double opacity = 1}) {
    Color _naverBackground = _theme == ThemeMode.dark
        ? const Color(0xFF1fc302).withOpacity(opacity)
        : const Color(0xFF1fc302).withOpacity(opacity);

    return _naverBackground;
  }

  ///
  /// kakaoBackground Color
  /// Color Code
  /// [dark] = #fae80b
  /// [light] = #fae80b
  ///
  Color kakaoBackground({double opacity = 1}) {
    Color _kakaoBackground = _theme == ThemeMode.dark
        ? const Color(0xFFfae80b).withOpacity(opacity)
        : const Color(0xFFfae80b).withOpacity(opacity);

    return _kakaoBackground;
  }

  ///
  /// appleBackground Color
  /// Color Code
  /// [dark] = #333333
  /// [light] = #333333
  ///
  Color appleBackground({double opacity = 1}) {
    Color _appleBackground = _theme == ThemeMode.dark
        ? const Color(0xFF333333).withOpacity(opacity)
        : const Color(0xFF333333).withOpacity(opacity);

    return _appleBackground;
  }

  ///
  /// kakaoLogo Color
  /// Color Code
  /// [dark] = #2d1516
  /// [light] = #2d1516
  ///
  Color kakaoLogo({double opacity = 1}) {
    Color _kakaoLogo = _theme == ThemeMode.dark
        ? const Color(0xFF2d1516).withOpacity(opacity)
        : const Color(0xFF2d1516).withOpacity(opacity);

    return _kakaoLogo;
  }

  ///
  /// trend1 Color
  /// Color Code
  /// [dark] = #e1523d
  /// [light] = #287a70
  ///
  Color trend1({double opacity = 1}) {
    Color _trends = _theme == ThemeMode.dark
        ? const Color(0xFFe1523d).withOpacity(opacity)
        : const Color(0xFF287a70).withOpacity(opacity);

    return _trends;
  }

  ///
  /// trend2 Color
  /// Color Code
  /// [dark] = #c2bb00
  /// [light] = #7a577a
  ///
  Color trend2({double opacity = 1}) {
    Color _trends = _theme == ThemeMode.dark
        ? const Color(0xFFc2bb00).withOpacity(opacity)
        : const Color(0xFF7a577a).withOpacity(opacity);

    return _trends;
  }

  ///
  /// trend3 Color
  /// Color Code
  /// [dark] = #7a6d31
  /// [light] = #244153
  ///
  Color trend3({double opacity = 1}) {
    Color _trends = _theme == ThemeMode.dark
        ? const Color(0xFF7a6d31).withOpacity(opacity)
        : const Color(0xFF244153).withOpacity(opacity);

    return _trends;
  }

  ///
  /// trend4 Color
  /// Color Code
  /// [dark] = #244153
  /// [light] = #7a6d31
  ///
  Color trend4({double opacity = 1}) {
    Color _trends = _theme == ThemeMode.dark
        ? const Color(0xFF244153).withOpacity(opacity)
        : const Color(0xFF7a6d31).withOpacity(opacity);

    return _trends;
  }

  ///
  /// trend5 Color
  /// Color Code
  /// [dark] = #7a577a
  /// [light] = #e1523d
  ///
  Color trend5({double opacity = 1}) {
    Color _trends = _theme == ThemeMode.dark
        ? const Color(0xFF7a577a).withOpacity(opacity)
        : const Color(0xFFe1523d).withOpacity(opacity);

    return _trends;
  }

  ///
  /// trend6 Color
  /// Color Code
  /// [dark] = #287a70
  /// [light] = #c2bb00
  ///
  Color trend6({double opacity = 1}) {
    Color _trends = _theme == ThemeMode.dark
        ? const Color(0xFF287a70).withOpacity(opacity)
        : const Color(0xFFc2bb00).withOpacity(opacity);

    return _trends;
  }

  ///
  /// 유저 아이콘 배경 Color
  /// Color Code
  /// [dark] = #454545
  /// [light] = #e2e2e2
  ///
  Color userIconBackground({double opacity = 1}) {
    Color _userIconBackground = _theme == ThemeMode.dark
        ? const Color(0xFF454545).withOpacity(opacity)
        : const Color(0xFFe2e2e2).withOpacity(opacity);

    return _userIconBackground;
  }

  ///
  /// 아바타 아이콘 배경 Color
  /// Color Code
  /// [dark] = #ffffff
  /// [light] = #ededed
  ///
  Color avatarIconBackground({double opacity = 1}) {
    Color _avatarIconBackground = _theme == ThemeMode.dark
        ? const Color(0xFFffffff).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _avatarIconBackground;
  }

  ///
  /// 아바타 아이콘 색상 Color
  /// Color Code
  /// [dark] = #000000
  /// [light] = #000000
  ///
  Color avatarIconColor({double opacity = 1}) {
    Color _avatarIconColor = _theme == ThemeMode.dark
        ? const Color(0xFF000000).withOpacity(opacity)
        : const Color(0xFF000000).withOpacity(opacity);

    return _avatarIconColor;
  }

  ///
  /// 아바타 파츠 배경 Color
  /// Color Code
  /// [dark] = #363636
  /// [light] = #ededed
  ///
  Color avatarPartsBackground({double opacity = 1}) {
    Color _avatarPartsBackground = _theme == ThemeMode.dark
        ? const Color(0xFF363636).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _avatarPartsBackground;
  }

  ///
  /// 아바타 파츠 프레임 배경 Color
  /// Color Code
  /// [dark] = #1e1e1e
  /// [light] = #fafafa
  ///
  Color avatarPartsWrapBackground({double opacity = 1}) {
    Color _avatarPartsWrapBackground = _theme == ThemeMode.dark
        ? const Color(0xFF1e1e1e).withOpacity(opacity)
        : const Color(0xFFfafafa).withOpacity(opacity);

    return _avatarPartsWrapBackground;
  }

  ///
  /// radio button Color
  /// Color Code
  /// [dark] = #ffffff
  /// [light] = #fafafa
  ///
  Color radioButtonColor({double opacity = 1}) {
    Color _avatarPartsWrapBackground = _theme == ThemeMode.dark
        ? const Color(0xFFffffff).withOpacity(opacity)
        : const Color(0xFFfafafa).withOpacity(opacity);

    return _avatarPartsWrapBackground;
  }

  ///
  /// profileBackground color
  /// Color Code
  /// [dark] = #1e1e1e
  /// [light] = #fafafa
  ///
  Color profileBackground({double opacity = 1}) {
    Color _profileBackground = _theme == ThemeMode.dark
        ? const Color(0xFF1e1e1e).withOpacity(opacity)
        : const Color(0xFFfafafa).withOpacity(opacity);

    return _profileBackground;
  }

  ///
  /// profileSubscibeBackground color
  /// Color Code
  /// [dark] = #2b2b2b
  /// [light] = #ededed
  ///
  Color profileSubscibeBackground({double opacity = 1}) {
    Color _profileSubscibeBackground = _theme == ThemeMode.dark
        ? const Color(0xFF2b2b2b).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _profileSubscibeBackground;
  }

  ///
  /// avatarButtonBackground1 color
  /// Color Code
  /// [dark] = #29f852
  /// [light] = #4bd665
  ///
  Color avatarButtonBackground1({double opacity = 1}) {
    Color _avatarButtonBackground = _theme == ThemeMode.dark
        ? const Color(0xFF29f852).withOpacity(opacity)
        : const Color(0xFF4bd665).withOpacity(opacity);

    return _avatarButtonBackground;
  }

  ///
  /// avatarButtonBackground2 color
  /// Color Code
  /// [dark] = #25dd96
  /// [light] = #22af57
  ///
  Color avatarButtonBackground2({double opacity = 1}) {
    Color _avatarButtonBackground = _theme == ThemeMode.dark
        ? const Color(0xFF25dd96).withOpacity(opacity)
        : const Color(0xFF22af57).withOpacity(opacity);

    return _avatarButtonBackground;
  }

  ///
  /// profileSendMessageBackground color
  /// Color Code
  /// [dark] = #ffffff
  /// [light] = #666666
  ///
  Color profileSendMessageBackground({double opacity = 1}) {
    Color _profileSendMessageBackground = _theme == ThemeMode.dark
        ? const Color(0xFFffffff).withOpacity(opacity)
        : const Color(0xFF666666).withOpacity(opacity);

    return _profileSendMessageBackground;
  }

  ///
  /// profileButton1 color
  /// Color Code
  /// [dark] = #ffffff
  /// [light] = #ededed
  ///
  Color profileButton1({double opacity = 1}) {
    Color _profileButton1 = _theme == ThemeMode.dark
        ? const Color(0xFFffffff).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _profileButton1;
  }

  ///
  /// button1 color
  /// Color Code
  /// [dark] = #cccccc
  /// [light] = #ededed
  ///
  Color button1({double opacity = 1}) {
    Color _button = _theme == ThemeMode.dark
        ? const Color(0xFFcccccc).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _button;
  }

  ///
  /// button2 color
  /// Color Code
  /// [dark] = #2b2b2b
  /// [light] = #666666
  ///
  Color button2({double opacity = 1}) {
    Color _button = _theme == ThemeMode.dark
        ? const Color(0xFF2b2b2b).withOpacity(opacity)
        : const Color(0xFF666666).withOpacity(opacity);

    return _button;
  }

  ///
  /// button disabled color
  /// Color Code
  /// [dark] = #d9d9d9
  /// [light] = #ededed
  ///
  Color buttonDisabled({double opacity = 1}) {
    Color _button = _theme == ThemeMode.dark
        ? const Color(0xFFd9d9d9).withOpacity(opacity)
        : const Color(0xFFededed).withOpacity(opacity);

    return _button;
  }

  ///
  /// d-coin color
  /// Color Code
  /// [dark] = #fed05a
  /// [light] = #f4be34
  ///
  Color dcoinColors({double opacity = 1}) {
    Color _coin = _theme == ThemeMode.dark
        ? const Color(0xFFfed05a).withOpacity(opacity)
        : const Color(0xFFf4be34).withOpacity(opacity);

    return _coin;
  }

  ///
  /// default white/black color
  /// Color Code
  /// [dark] = #ffffff
  /// [light] = #000000
  ///
  Color defaultWhiteBlackColors({double opacity = 1}) {
    Color _color = _theme == ThemeMode.dark
        ? const Color(0xFFffffff).withOpacity(opacity)
        : const Color(0xFF000000).withOpacity(opacity);

    return _color;
  }

  /// 토스트 기본 색상 / color code = 0xFF5a5a5a
  static const defaultToast = Color(0xFF5a5a5a);

  /// 기본 검은색 / color code = 0xFF000000
  static const defaultBlack = Color(0xFF000000);

  /// 기본 회색 / color code = 0xFF999999
  static const defaultGray = Color(0xFF999999);

  /// 기본 흰색 / color code = 0xFFffffff
  static const defaultWhite = Color(0xFFffffff);

  /// 알림 dots 색상 / color code = 0xFFff4e00
  static const notificationDots = Color(0xFFff4e00);

  /// 구독버튼 색상 / color code = 0xFF00cc00
  static const subscribeBtnPrimary = Color(0xFF00cc00);

  /// 메시지 보내기 버튼 색상 / color code = 0xFF1e1e1e
  static const messageBtnBackground = Color(0xFF1e1e1e);

  /// 버튼 미선택 텍스트 색상 / color code = 0xFF454545
  static const noSelectButtonTextColor = Color(0xFF454545);

  /// 라이브 아이템 받았을 때 배경 색상 / color code = 0xFF485cff
  static const liveItemSendBackground = Color(0xFF485cff);

  /// d-coin charging pg select button 색상 / color code = 0xFFdbeedd
  static const pgSelectBackground1 = Color(0xFFdbeedd);

  /// 투명 / color code = Colors.transparent
  static const transparent = Colors.transparent;

  Color colorPicker({required Color color, double? opacity}) {
    opacity = opacity ?? 1;
    return color.withOpacity(opacity);
  }
}

class ImageConfig {
  final _theme = DRPublicApp.themeNotifier.value;

  ///
  /// 검색결과 없음 이미지
  ///
  String searchNoData() {
    String _image = _theme == ThemeMode.dark
        ? 'assets/img/none_search_dark.png'
        : 'assets/img/none_search_light.png';

    return _image;
  }
}
