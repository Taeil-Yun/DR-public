import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetHotPostListAPI {
  Future<GetHotPostListAPIResponseModel> hotPost(
      {required String accesToken, required int postCategory}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}post/getHotPostList?post_category=$postCategory');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      return GetHotPostListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetHotPostListAPI().hotPost(
          accesToken: _prefs.getString('AccessToken')!,
          postCategory: postCategory);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetHotPostListAPIResponseModel {
  dynamic result;

  GetHotPostListAPIResponseModel({
    this.result,
  });

  factory GetHotPostListAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetHotPostListAPIResponseModel(
      result: data,
    );
  }
}
