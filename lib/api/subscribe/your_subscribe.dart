import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetYourSubScribeListAPI {
  Future<GetYourSubScribeListAPIResponseModel> subscribe(
      {required String accesToken, required String nickname}) async {
    dynamic baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}subscribe/getMySubscribeList?nick=$nickname');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetYourSubScribeListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetYourSubScribeListAPI().subscribe(
          accesToken: _prefs.getString('AccessToken')!, nickname: nickname);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetYourSubScribeListAPIResponseModel {
  dynamic result;

  GetYourSubScribeListAPIResponseModel({
    this.result,
  });

  factory GetYourSubScribeListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetYourSubScribeListAPIResponseModel(
      result: data,
    );
  }
}
