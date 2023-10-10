import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class OrderCancelAPI {
  Future<OrderCancelResponseModel> cancel({
    required String accesToken,
    required String merchantUid,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}order/cancel');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "merchant_uid": merchantUid,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return OrderCancelResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return OrderCancelAPI().cancel(
          accesToken: _prefs.getString('AccessToken')!,
          merchantUid: merchantUid);
    } else {
      throw Exception(response.body);
    }
  }
}

class OrderCancelResponseModel {
  dynamic result;

  OrderCancelResponseModel({
    this.result,
  });

  factory OrderCancelResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return OrderCancelResponseModel(
      result: data,
    );
  }
}
