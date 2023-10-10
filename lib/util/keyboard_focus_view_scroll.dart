import 'package:flutter/material.dart';

class HasKeyboardFocusViewScrolling {
  void jumpToScroll({required bool focus, required ScrollController controller}) {
    bool _keyboardFocusCheck = false;

    // 키보드가 올라왔을 때 화면 밀어 올려주는 코드
    if (!_keyboardFocusCheck) {
      if (focus) {
        controller.jumpTo(controller.position.maxScrollExtent);
        _keyboardFocusCheck = true;
      } else {
        _keyboardFocusCheck = false;
      }
    }
  }
}