import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetQuestionList {
  Future<GetQuestionListAPIResponseModel> question(
      {required String accesToken}) async {
    dynamic baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}question/getQuestionList');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetQuestionListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetQuestionList()
          .question(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetQuestionListAPIResponseModel {
  dynamic result;

  GetQuestionListAPIResponseModel({
    this.result,
  });

  factory GetQuestionListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetQuestionListAPIResponseModel(
      result: data,
    );
  }
}
