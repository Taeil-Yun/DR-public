import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetLiveRoomDetailAPI {
  Future<GetLiveRoomDetailAPIResponseModel> liveDetail(
      {required String accesToken, required int roomIndex}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}live/getRoom?room_index=$roomIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      return GetLiveRoomDetailAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetLiveRoomDetailAPI().liveDetail(
          accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetLiveRoomDetailAPIResponseModel {
  dynamic result;

  GetLiveRoomDetailAPIResponseModel({
    this.result,
  });

  factory GetLiveRoomDetailAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return GetLiveRoomDetailAPIResponseModel(
      result: data,
    );
  }
}
