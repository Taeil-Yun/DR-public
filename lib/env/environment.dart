import 'package:DRPublic/main.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

enum BuildType {
  development,
  production,
}

class Environment {
  static Environment? _instance;

  static Environment get instance => _instance!;

  final BuildType _buildType;

  static BuildType get buildType => instance._buildType;

  const Environment._internal(this._buildType);

  factory Environment.newInstance(BuildType buildType) {
    // ignore: unnecessary_null_comparison
    assert(buildType != null);

    _instance ??= Environment._internal(buildType);

    return _instance!;
  }

  bool get isDebugMode => _buildType == BuildType.development;

  void run(
      {ThemeMode? theme,
      required bool hasNickname,
      required bool hasAvatar,
      String? hasAccessToken}) {
    runApp(OKToast(
        child: DRPublicApp(
            themes: theme,
            hasNickname: hasNickname,
            hasAvatar: hasAvatar,
            hasAccessToken: hasAccessToken)));
  }
}
