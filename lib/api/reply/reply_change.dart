import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class ChangeReplyAPI {
  Future<ChangeReplyAPIResponseModel> changeReply({
    required String accesToken,
    required int isParent,
    required String message,
    int? replyIndex,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}reply/chageReply');

    final response = await InterceptorHelper().client.patch(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "type": 0.toString(),
            "reply_index": replyIndex,
            "message": message,
            "isParent": isParent,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return ChangeReplyAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return ChangeReplyAPI().changeReply(
          accesToken: _prefs.getString('AccessToken')!,
          isParent: isParent,
          message: message,
          replyIndex: replyIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class ChangeReplyAPIResponseModel {
  dynamic result;

  ChangeReplyAPIResponseModel({
    this.result,
  });

  factory ChangeReplyAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return ChangeReplyAPIResponseModel(
      result: data,
    );
  }
}
