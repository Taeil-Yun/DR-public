import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class PatchNewsDataAPI {
  Future<PatchNewsDataAPIResponseModel> patchNews(
      {required String accesToken,
      required int postIndex,
      required String title,
      required String link,
      required String tag}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/changeNews');

    final response = await InterceptorHelper().client.patch(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "post_index": postIndex,
            "title": title,
            "link": link,
            "tag": tag,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return PatchNewsDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return PatchNewsDataAPI().patchNews(
        accesToken: _prefs.getString('AccessToken')!,
        postIndex: postIndex,
        title: title,
        link: link,
        tag: tag,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class PatchNewsDataAPIResponseModel {
  dynamic result;

  PatchNewsDataAPIResponseModel({
    this.result,
  });

  factory PatchNewsDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return PatchNewsDataAPIResponseModel(
      result: data,
    );
  }
}
