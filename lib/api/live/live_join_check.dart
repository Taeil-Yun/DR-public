import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class LiveJoinCheckAPI {
  Future<LiveJoinCheckAPIResponseModel> join(
      {required String accesToken, required int roomIndex}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}live/getRoomCheck?room_index=$roomIndex');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      return LiveJoinCheckAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return LiveJoinCheckAPI().join(
          accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class LiveJoinCheckAPIResponseModel {
  dynamic result;

  LiveJoinCheckAPIResponseModel({
    this.result,
  });

  factory LiveJoinCheckAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return LiveJoinCheckAPIResponseModel(
      result: data,
    );
  }
}
