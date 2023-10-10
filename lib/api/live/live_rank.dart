import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetLiveRankListAPI {
  Future<GetLiveRankListAPIResponseModel> rank(
      {required String accesToken, required int roomIndex}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}live/getRoomRank?room_index=$roomIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      return GetLiveRankListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetLiveRankListAPI().rank(
          accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetLiveRankListAPIResponseModel {
  dynamic result;

  GetLiveRankListAPIResponseModel({
    this.result,
  });

  factory GetLiveRankListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetLiveRankListAPIResponseModel(
      result: data,
    );
  }
}
