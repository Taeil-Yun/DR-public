import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class AddLiveNoticeAPI {
  Future<AddLiveNoticeAPIResponseModel> notice({
    required String accesToken,
    required String notice,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}live/updateNotice');

    final response = await InterceptorHelper().client.patch(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "notice": notice,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddLiveNoticeAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddLiveNoticeAPI()
          .notice(accesToken: _prefs.getString('AccessToken')!, notice: notice);
    } else {
      throw Exception(response.body);
    }
  }
}

class AddLiveNoticeAPIResponseModel {
  dynamic result;

  AddLiveNoticeAPIResponseModel({
    this.result,
  });

  factory AddLiveNoticeAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddLiveNoticeAPIResponseModel(
      result: data,
    );
  }
}
