import 'package:flutter/material.dart';

import 'package:oktoast/oktoast.dart';

class ToastBuilder {
  ToastFuture toast(Widget child) {
    return showToastWidget(
      child,
      position: ToastPosition.bottom,
      // backgroundColor: ColorsConfig().colorPicker(color: ColorsConfig.defaultBlack, opacity: 0.8),
      // textStyle: TextStyle(
      //   color: ColorsConfig.defaultWhite,
      //   fontSize: 14.0.sp,
      //   fontFamily: 'AppleSDGothicNeo',
      // ),
      dismissOtherToast: true,
      // textPadding: const EdgeInsets.all(14.0),
    );
  }
}
