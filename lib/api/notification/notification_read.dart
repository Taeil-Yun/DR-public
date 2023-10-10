import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class NotificationReadDataPatchAPI {
  Future<NotificationReadDataPatchAPIResponseModel> readNotification(
      {required String accesToken, required int index}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}alarm/chageReadAlarm');

    final response = await InterceptorHelper().client.patch(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "alarm_index": index,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return NotificationReadDataPatchAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return NotificationReadDataPatchAPI().readNotification(
          accesToken: _prefs.getString('AccessToken')!, index: index);
    } else {
      throw Exception(response.body);
    }
  }
}

class NotificationReadDataPatchAPIResponseModel {
  dynamic result;

  NotificationReadDataPatchAPIResponseModel({
    this.result,
  });

  factory NotificationReadDataPatchAPIResponseModel.fromJson(
      Map<String, dynamic> data) {
    return NotificationReadDataPatchAPIResponseModel(
      result: data,
    );
  }
}
