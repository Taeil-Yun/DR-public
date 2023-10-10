import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetSubscribePostListAPI {
  Future<GetSubscribePostListAPIResponseModel> subscribePostList({
    required String accesToken,
    int? userIndex,
    int? cursor,
    bool? isFeed,
  }) async {
    String baseUri =
        '${ApiBaseUrlConfig().baseUri}subscribe/getSubscribePostList?';

    if (userIndex != null) {
      baseUri += '&user_index=$userIndex';
    }

    if (cursor != null) {
      baseUri += '&cursor=$cursor';
    }

    if (isFeed != null) {
      baseUri += '&is_feed=$isFeed';
    }

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetSubscribePostListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetSubscribePostListAPI().subscribePostList(
          accesToken: _prefs.getString('AccessToken')!,
          userIndex: userIndex,
          cursor: cursor);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetSubscribePostListAPIResponseModel {
  dynamic result;

  GetSubscribePostListAPIResponseModel({
    this.result,
  });

  factory GetSubscribePostListAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return GetSubscribePostListAPIResponseModel(
      result: data,
    );
  }
}
