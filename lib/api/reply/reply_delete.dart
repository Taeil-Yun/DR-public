import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class DeleteReplyDataAPI {
  Future<DeleteReplyDataAPIResponseModel> deleteReply({
    required String accesToken,
    required int replyIndex,

    /// 0 = child
    /// 1 = parent
    required int isParent,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}reply/deleteReply');

    final response = await InterceptorHelper().client.delete(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "reply_index": replyIndex,
            "isParent": isParent,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return DeleteReplyDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return DeleteReplyDataAPI().deleteReply(
          accesToken: _prefs.getString('AccessToken')!,
          replyIndex: replyIndex,
          isParent: isParent);
    } else {
      throw Exception(response.body);
    }
  }
}

class DeleteReplyDataAPIResponseModel {
  dynamic result;

  DeleteReplyDataAPIResponseModel({
    this.result,
  });

  factory DeleteReplyDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return DeleteReplyDataAPIResponseModel(
      result: data,
    );
  }
}
