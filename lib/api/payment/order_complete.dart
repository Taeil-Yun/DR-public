import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class OrderCompleteAPI {
  Future<OrderCompleteResponseModel> complete({
    required String accesToken,
    required String impUid,
    required String merchantUid,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}order/complete');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "imp_uid": impUid,
            "merchant_uid": merchantUid,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return OrderCompleteResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return OrderCompleteAPI().complete(
          accesToken: _prefs.getString('AccessToken')!,
          impUid: impUid,
          merchantUid: merchantUid);
    } else {
      throw Exception(response.body);
    }
  }
}

class OrderCompleteResponseModel {
  dynamic result;

  OrderCompleteResponseModel({
    this.result,
  });

  factory OrderCompleteResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return OrderCompleteResponseModel(
      result: data,
    );
  }
}
