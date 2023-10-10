import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class PhoneCertificationCancelAPI {
  Future<PhoneCertificationCancelAPIResponseModel> cancel({
    required String accessToken,
    required String merchantUid,
  }) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}user/cancelCertification');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accessToken,
          },
          body: json.encode({
            "merchant_uid": merchantUid,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return PhoneCertificationCancelAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return PhoneCertificationCancelAPI().cancel(
          accessToken: _prefs.getString('AccessToken')!,
          merchantUid: merchantUid);
    } else {
      throw Exception(response.body);
    }
  }
}

class PhoneCertificationCancelAPIResponseModel {
  dynamic result;

  PhoneCertificationCancelAPIResponseModel({
    this.result,
  });

  factory PhoneCertificationCancelAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return PhoneCertificationCancelAPIResponseModel(
      result: data,
    );
  }
}
