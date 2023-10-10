import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class OtherUserProfileInfoAPI {
  Future<OtherUserProfileInfoAPIResponseModel> userProfile(
      {required String accesToken,
      int? userIndex,
      String? userNickname}) async {
    dynamic baseUri;

    if (userIndex != null && userNickname == null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}user/getUserProfile?user_index=$userIndex');
    } else if (userIndex == null && userNickname != null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}user/getUserProfile?user_nick=$userNickname');
    }

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return OtherUserProfileInfoAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return OtherUserProfileInfoAPI().userProfile(
          accesToken: _prefs.getString('AccessToken')!, userIndex: userIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class OtherUserProfileInfoAPIResponseModel {
  dynamic result;

  OtherUserProfileInfoAPIResponseModel({
    this.result,
  });

  factory OtherUserProfileInfoAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return OtherUserProfileInfoAPIResponseModel(
      result: data,
    );
  }
}
