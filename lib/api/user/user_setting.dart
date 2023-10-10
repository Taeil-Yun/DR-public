import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class UserSettingAPI {
  Future<UserSettingAPIResponseModel> getSetting(
      {required String accesToken}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}user/getSetting');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return UserSettingAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return UserSettingAPI()
          .getSetting(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }

  ///
  /// [settingReply] = 댓글 알림 (0 : false, 1 : true)
  ///
  /// [settingMessage] = 메시지 알림 (0 : false, 1 : true)
  ///
  /// [settingFollow] = 신규 구독 알림 (0 : false, 1 : true)
  ///
  /// [settingNews] = DR-Public 소식 / 뉴스레터 (0 : false, 1 : true)
  ///
  /// [settingRecommend] = 추천/인기글 (0 : false, 1 : true)
  ///
  Future<UserSettingAPIResponseModel> setSetting({
    required String accesToken,
    required int settingReply,
    required int settingMessage,
    required int settingFollow,
    required int settingNews,
    required int settingRecommend,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}user/setSetting');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "replys": settingReply,
            "message": settingMessage,
            "follow": settingFollow,
            "news": settingNews,
            "recommend": settingRecommend,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return UserSettingAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return UserSettingAPI().setSetting(
        accesToken: _prefs.getString('AccessToken')!,
        settingReply: settingReply,
        settingMessage: settingMessage,
        settingFollow: settingFollow,
        settingNews: settingNews,
        settingRecommend: settingRecommend,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class UserSettingAPIResponseModel {
  dynamic result;

  UserSettingAPIResponseModel({
    this.result,
  });

  factory UserSettingAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return UserSettingAPIResponseModel(
      result: data,
    );
  }
}
