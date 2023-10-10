import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class ChattingSearchUserAPI {
  Future<ChattingSearchUserAPIResponseModel> searchUser(
      {required String accesToken, required String search}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}chatting/searchChatUsers');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "search_nick": search,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return ChattingSearchUserAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return ChattingSearchUserAPI().searchUser(
          accesToken: _prefs.getString('AccessToken')!, search: search);
    } else {
      throw Exception(response.body);
    }
  }
}

class ChattingSearchUserAPIResponseModel {
  dynamic result;

  ChattingSearchUserAPIResponseModel({
    this.result,
  });

  factory ChattingSearchUserAPIResponseModel.fromJson(List<dynamic> data) {
    return ChattingSearchUserAPIResponseModel(
      result: data,
    );
  }
}
