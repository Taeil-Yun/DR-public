import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/main.dart';

class DRPublicThemes {
  getDartTheme() async {
    DRPublicApp.themeNotifier.value =
        DRPublicApp.themeNotifier.value == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;

    final _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('AppThemeColor') != null) {
      await _prefs.setString(
          'AppThemeColor',
          DRPublicApp.themeNotifier.value == ThemeMode.light
              ? 'light'
              : 'dark');
    } else {
      await _prefs.setString('AppThemeColor', 'dark');
    }

    return DRPublicApp.themeNotifier.value;
  }
}
