import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetHotLiveRoomListAPI {
  Future<GetHotLiveRoomListAPIResponseModel> hotList(
      {required String accesToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}live/getHotRoomList');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      return GetHotLiveRoomListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetHotLiveRoomListAPI()
          .hotList(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetHotLiveRoomListAPIResponseModel {
  dynamic result;

  GetHotLiveRoomListAPIResponseModel({
    this.result,
  });

  factory GetHotLiveRoomListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetHotLiveRoomListAPIResponseModel(
      result: data,
    );
  }
}
