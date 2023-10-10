import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class NotificationDeleteAllAPI {
  Future<NotificationDeleteAllAPIResponseModel> notificationDeleteAll(
      {required String accesToken}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}alarm/deleteAlarm');

    final response = await InterceptorHelper().client.delete(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return NotificationDeleteAllAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return NotificationDeleteAllAPI()
          .notificationDeleteAll(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class NotificationDeleteAllAPIResponseModel {
  dynamic result;

  NotificationDeleteAllAPIResponseModel({
    this.result,
  });

  factory NotificationDeleteAllAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return NotificationDeleteAllAPIResponseModel(
      result: data,
    );
  }
}
