import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class DeletePostDataAPI {
  Future<DeletePostDataAPIResponseModel> deletePost(
      {required String accesToken, required int postIndex}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/deletePost');

    final response = await InterceptorHelper().client.delete(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "post_index": postIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return DeletePostDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return DeletePostDataAPI().deletePost(
          accesToken: _prefs.getString('AccessToken')!, postIndex: postIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class DeletePostDataAPIResponseModel {
  dynamic result;

  DeletePostDataAPIResponseModel({
    this.result,
  });

  factory DeletePostDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return DeletePostDataAPIResponseModel(
      result: data,
    );
  }
}
