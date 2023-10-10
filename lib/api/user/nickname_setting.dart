import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class NicknameSettingAPI {
  Future<NicknameSettingAPIResponseModel> nickname({
    required String accesToken,
    required String nickname,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}user/setNickName');

    final response = await InterceptorHelper().client.patch(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "nickname": nickname,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return NicknameSettingAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return NicknameSettingAPI().nickname(
          accesToken: _prefs.getString('AccessToken')!, nickname: nickname);
    } else {
      throw Exception(response.body);
    }
  }
}

class NicknameSettingAPIResponseModel {
  dynamic result;

  NicknameSettingAPIResponseModel({
    this.result,
  });

  factory NicknameSettingAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return NicknameSettingAPIResponseModel(
      result: data,
    );
  }
}
