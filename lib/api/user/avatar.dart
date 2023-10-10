import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class RandomAvatarAPI {
  Future<RandomAvatarAPIResponseModel> getAvatar(
      {required String accesToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}user/getRandomAvatar');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return RandomAvatarAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return RandomAvatarAPI()
          .getAvatar(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }

  Future<RandomAvatarAPIResponseModel> setAvatar(
      {required String accesToken, required int avatarIndex}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}user/setUserAvatar');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "avatar_index": avatarIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return RandomAvatarAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return RandomAvatarAPI().setAvatar(
          accesToken: _prefs.getString('AccessToken')!,
          avatarIndex: avatarIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class RandomAvatarAPIResponseModel {
  dynamic result;

  RandomAvatarAPIResponseModel({
    this.result,
  });

  factory RandomAvatarAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return RandomAvatarAPIResponseModel(
      result: data,
    );
  }
}
