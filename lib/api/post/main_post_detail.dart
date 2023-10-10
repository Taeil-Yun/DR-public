import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class PostDetailDataAPI {
  Future<PostDetailDataAPIResponseModel> detail(
      {required String accesToken, required int postIndex}) async {
    dynamic baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}post/getDetailPost?post_index=$postIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return PostDetailDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return PostDetailDataAPI().detail(
          accesToken: _prefs.getString('AccessToken')!, postIndex: postIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class PostDetailDataAPIResponseModel {
  dynamic result;

  PostDetailDataAPIResponseModel({
    this.result,
  });

  factory PostDetailDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return PostDetailDataAPIResponseModel(
      result: data,
    );
  }
}
