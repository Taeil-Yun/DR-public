import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class LiveGiftDataSendAPI {
  Future<LiveGiftDataSendAPIResponseModel> giftSend(
      {required String accesToken,
      required int itemIndex,
      required int roomIndex}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}item/sendRoomItem');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "item_index": itemIndex,
            "room_index": roomIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return LiveGiftDataSendAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return LiveGiftDataSendAPI().giftSend(
          accesToken: _prefs.getString('AccessToken')!,
          itemIndex: itemIndex,
          roomIndex: roomIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class LiveGiftDataSendAPIResponseModel {
  dynamic result;

  LiveGiftDataSendAPIResponseModel({
    this.result,
  });

  factory LiveGiftDataSendAPIResponseModel.fromJson(Map<String, dynamic> data) {
    return LiveGiftDataSendAPIResponseModel(
      result: data,
    );
  }
}
