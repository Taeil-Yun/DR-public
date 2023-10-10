import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class AddLiveLikeSendAPI {
  Future<AddLiveLikeSendAPIResponseModel> addLiveLike(
      {required String accesToken, required int roomIndex}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}live/addRoomLike');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "room_index": roomIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddLiveLikeSendAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddLiveLikeSendAPI().addLiveLike(
          accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class AddLiveLikeSendAPIResponseModel {
  dynamic result;

  AddLiveLikeSendAPIResponseModel({
    this.result,
  });

  factory AddLiveLikeSendAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddLiveLikeSendAPIResponseModel(
      result: data,
    );
  }
}
