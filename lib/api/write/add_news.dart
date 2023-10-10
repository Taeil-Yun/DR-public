import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class AddNewsAPI {
  Future<AddNewsAPIResponseModel> addNews(
      {required String accesToken,
      required String title,
      required String link,
      required String tag}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/addNews');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "title": title,
            "link": link,
            "tag": tag,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddNewsAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddNewsAPI().addNews(
          accesToken: _prefs.getString('AccessToken')!,
          title: title,
          link: link,
          tag: tag);
    } else {
      throw Exception(response.body);
    }
  }
}

class AddNewsAPIResponseModel {
  dynamic result;

  AddNewsAPIResponseModel({
    this.result,
  });

  factory AddNewsAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddNewsAPIResponseModel(
      result: data,
    );
  }
}
