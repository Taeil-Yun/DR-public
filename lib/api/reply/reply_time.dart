import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetTimeLineReplyAPI {
  Future<GetTimeLineReplyAPIResponseModel> timeLineReply(
      {required String accesToken, required int postIndex}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}reply/getTimeLineReply?post_index=$postIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetTimeLineReplyAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetTimeLineReplyAPI().timeLineReply(
          accesToken: _prefs.getString('AccessToken')!, postIndex: postIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetTimeLineReplyAPIResponseModel {
  dynamic result;

  GetTimeLineReplyAPIResponseModel({
    this.result,
  });

  factory GetTimeLineReplyAPIResponseModel.fromJson(List<dynamic> data) {
    return GetTimeLineReplyAPIResponseModel(
      result: data,
    );
  }
}
