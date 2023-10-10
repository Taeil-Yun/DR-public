import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class RequestOrderDataAPI {
  Future<RequestOrderDataResponseModel> order({
    required String accesToken,
    required int coinIndex,
    required int pgMethodIndex,
  }) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}order/requestOrder');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "coin_index": coinIndex,
            "pg_method_index": pgMethodIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return RequestOrderDataResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return RequestOrderDataAPI().order(
          accesToken: _prefs.getString('AccessToken')!,
          coinIndex: coinIndex,
          pgMethodIndex: pgMethodIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class RequestOrderDataResponseModel {
  dynamic result;

  RequestOrderDataResponseModel({
    this.result,
  });

  factory RequestOrderDataResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return RequestOrderDataResponseModel(
      result: data,
    );
  }
}
