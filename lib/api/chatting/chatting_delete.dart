import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class ChattingDeleteAPI {
  Future<ChattingDeleteAPIResponseModel> delete(
      {required String accesToken, required int userIndex}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}chatting/deleteChatting');

    final response = await InterceptorHelper().client.delete(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "user_index": userIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return ChattingDeleteAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return ChattingDeleteAPI().delete(
          accesToken: _prefs.getString('AccessToken')!, userIndex: userIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class ChattingDeleteAPIResponseModel {
  dynamic result;

  ChattingDeleteAPIResponseModel({
    this.result,
  });

  factory ChattingDeleteAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return ChattingDeleteAPIResponseModel(
      result: data,
    );
  }
}
