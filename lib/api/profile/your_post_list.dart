import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetYourPostListAPI {
  Future<GetYourPostListAPIResponseModel> post(
      {required String accesToken,
      required String nickname,
      required int type,
      int? cursor}) async {
    dynamic baseUri;

    if (cursor == null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}my/getYourPost?nick=$nickname&type=$type');
    } else {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}my/getYourPost?nick=$nickname&type=$type&cursor=$cursor');
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

      return GetYourPostListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetYourPostListAPI().post(
          accesToken: _prefs.getString('AccessToken')!,
          nickname: nickname,
          type: type,
          cursor: cursor);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetYourPostListAPIResponseModel {
  dynamic result;

  GetYourPostListAPIResponseModel({
    this.result,
  });

  factory GetYourPostListAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetYourPostListAPIResponseModel(
      result: data,
    );
  }
}
