import 'package:flutter/widgets.dart';

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late double safeScreenHeight;

  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeBlockVertical;

  static late double keyboardHeight;

  void init(BuildContext context) {
    /// MediaQuery Object
    var _mediaQueryData = MediaQuery.of(context);

    /// Screen Sizes
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    var _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeScreenHeight = screenHeight - _safeAreaVertical;

    /// Screen Blocks / 100
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    /// Keyboard Height
    keyboardHeight = _mediaQueryData.viewInsets.bottom;
  }
}