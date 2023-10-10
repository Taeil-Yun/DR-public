import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetGiftHistoryListDataAPI {
  Future<GetGiftHistoryListDataAPIResponseModel> giftHistory(
      {required String accesToken, required int postIndex}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}item/getGiftPostList?post_index=$postIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetGiftHistoryListDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetGiftHistoryListDataAPI().giftHistory(
          accesToken: _prefs.getString('AccessToken')!, postIndex: postIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetGiftHistoryListDataAPIResponseModel {
  dynamic result;

  GetGiftHistoryListDataAPIResponseModel({
    this.result,
  });

  factory GetGiftHistoryListDataAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return GetGiftHistoryListDataAPIResponseModel(
      result: data,
    );
  }
}
