import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class DeleteReplyLikeDataAPI {
  Future<DeleteReplyLikeDataAPIResponseModel> deleteReplyLike(
      {required String accesToken, required int replyIndex}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}reply/cancleReplyLike');

    final response = await InterceptorHelper().client.delete(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "reply_index": replyIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return DeleteReplyLikeDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return DeleteReplyLikeDataAPI().deleteReplyLike(
          accesToken: _prefs.getString('AccessToken')!, replyIndex: replyIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class DeleteReplyLikeDataAPIResponseModel {
  dynamic result;

  DeleteReplyLikeDataAPIResponseModel({
    this.result,
  });

  factory DeleteReplyLikeDataAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return DeleteReplyLikeDataAPIResponseModel(
      result: data,
    );
  }
}
