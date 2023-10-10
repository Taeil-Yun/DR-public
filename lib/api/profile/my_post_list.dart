import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetMyPostListAPI {
  Future<GetMyPostListAPIResponseModel> post(
      {required String accesToken, int? type, int? cursor}) async {
    dynamic baseUri;

    if (type == null && cursor == null) {
      baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}my/getMyPost');
    } else if (type != null && cursor == null) {
      baseUri =
          Uri.parse('${ApiBaseUrlConfig().baseUri}my/getMyPost?type=$type');
    } else if (type == null && cursor != null) {
      baseUri =
          Uri.parse('${ApiBaseUrlConfig().baseUri}my/getMyPost?cursor=$cursor');
    } else if (type != null && cursor != null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}my/getMyPost?type=$type&cursor=$cursor');
    }

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetMyPostListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetMyPostListAPI().post(
          accesToken: _prefs.getString('AccessToken')!,
          type: type,
          cursor: cursor);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetMyPostListAPIResponseModel {
  dynamic result;

  GetMyPostListAPIResponseModel({
    this.result,
  });

  factory GetMyPostListAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetMyPostListAPIResponseModel(
      result: data,
    );
  }
}
