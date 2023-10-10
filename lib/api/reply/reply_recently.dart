import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetRecentlyReplyAPI {
  Future<GetRecentlyReplyAPIResponseModel> recentlyReply(
      {required String accesToken, required int postIndex, int? cursor}) async {
    dynamic baseUri;

    if (cursor != null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}reply/getRecentlyReply?post_index=$postIndex&cursor=$cursor');
    } else {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}reply/getRecentlyReply?post_index=$postIndex');
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

      return GetRecentlyReplyAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetRecentlyReplyAPI().recentlyReply(
          accesToken: _prefs.getString('AccessToken')!,
          postIndex: postIndex,
          cursor: cursor);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetRecentlyReplyAPIResponseModel {
  dynamic result;

  GetRecentlyReplyAPIResponseModel({
    this.result,
  });

  factory GetRecentlyReplyAPIResponseModel.fromJson(List<dynamic> data) {
    return GetRecentlyReplyAPIResponseModel(
      result: data,
    );
  }
}
