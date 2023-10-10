import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetFeedListAPI {
  Future<GetFeedListAPIResponseModel> feed(
      {required String accesToken, String? q, int? cursor}) async {
    dynamic baseUri;

    if (q == null && cursor == null) {
      baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getFeedList');
    } else if (q != null && cursor == null) {
      baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getFeedList?q=$q');
    } else if (q == null && cursor != null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}post/getFeedList?cursor=$cursor');
    } else if (q != null && cursor != null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}post/getFeedList?q=$q&cursor=$cursor');
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

      return GetFeedListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetFeedListAPI()
          .feed(accesToken: _prefs.getString('AccessToken')!, cursor: cursor);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetFeedListAPIResponseModel {
  dynamic result;

  GetFeedListAPIResponseModel({
    this.result,
  });

  factory GetFeedListAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetFeedListAPIResponseModel(
      result: data,
    );
  }
}
