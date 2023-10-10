import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetRecommendDataList {
  Future<GetRecommendDataListAPIResponseModel> recommands(
      {required String accesToken}) async {
    dynamic baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}search/getRecommendList');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetRecommendDataListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetRecommendDataList()
          .recommands(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetRecommendDataListAPIResponseModel {
  dynamic result;

  GetRecommendDataListAPIResponseModel({
    this.result,
  });

  factory GetRecommendDataListAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return GetRecommendDataListAPIResponseModel(
      result: data,
    );
  }
}
