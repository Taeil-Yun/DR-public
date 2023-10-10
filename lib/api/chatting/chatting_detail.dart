import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetChattingDetailDataAPI {
  Future<GetChattingDetailDataAPIResponseModel> chattingData(
      {required String accesToken, required int userIndex}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}chatting/getChatting?user_index=$userIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetChattingDetailDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetChattingDetailDataAPI().chattingData(
          accesToken: _prefs.getString('AccessToken')!, userIndex: userIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetChattingDetailDataAPIResponseModel {
  dynamic result;

  GetChattingDetailDataAPIResponseModel({
    this.result,
  });

  factory GetChattingDetailDataAPIResponseModel.fromJson(List<dynamic> data) {
    return GetChattingDetailDataAPIResponseModel(
      result: data,
    );
  }
}
