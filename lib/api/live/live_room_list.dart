import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetLiveRoomListAPI {
  Future<GetLiveRoomListAPIResponseModel> list(
      {required String accesToken,
      String? q,
      int? cursor,
      int? postCategory}) async {
    String baseUri = '${ApiBaseUrlConfig().baseUri}live/getRoomList?';

    if (q != null) {
      baseUri += '&q=$q';
    }

    if (cursor != null) {
      baseUri += '&cursor=$cursor';
    }

    if (postCategory != null) {
      baseUri += '&post_category=$postCategory';
    }

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetLiveRoomListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetLiveRoomListAPI().list(
          accesToken: _prefs.getString('AccessToken')!,
          q: q,
          cursor: cursor,
          postCategory: postCategory);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetLiveRoomListAPIResponseModel {
  dynamic result;

  GetLiveRoomListAPIResponseModel({
    this.result,
  });

  factory GetLiveRoomListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetLiveRoomListAPIResponseModel(
      result: data,
    );
  }
}
