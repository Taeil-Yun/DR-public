import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class AddReplyDataAPI {
  Future<AddReplyDataAPIResponseModel> addReply({
    required String accesToken,
    required int type,
    required int postIndex,
    int? replyIndex,
    int? parentUserIndex,
    int? topIndex,
    String? message,
    String? gif,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}reply/addReply');

    dynamic _body;

    if (type == 0) {
      _body = json.encode({
        "type": type,
        "post_index": postIndex,
        "reply_index": replyIndex,
        "parent_user_index": parentUserIndex,
        "top_index": topIndex,
        "message": message,
      });
    } else if (type == 1) {
      _body = json.encode({
        "type": type,
        "post_index": postIndex,
        "reply_index": replyIndex,
        "parent_user_index": parentUserIndex,
        "top_index": topIndex,
        "gif": gif,
      });
    }

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: _body,
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddReplyDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddReplyDataAPI().addReply(
          accesToken: _prefs.getString('AccessToken')!,
          type: type,
          postIndex: postIndex,
          replyIndex: replyIndex,
          parentUserIndex: parentUserIndex,
          message: message,
          gif: gif);
    } else {
      throw Exception(response.body);
    }
  }
}

class AddReplyDataAPIResponseModel {
  dynamic result;

  AddReplyDataAPIResponseModel({
    this.result,
  });

  factory AddReplyDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddReplyDataAPIResponseModel(
      result: data,
    );
  }
}
