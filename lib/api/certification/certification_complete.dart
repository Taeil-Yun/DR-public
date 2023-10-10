import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class PhoneCertificationCompleteAPI {
  Future<PhoneCertificationCompleteAPIResponseModel> complete({
    required String accessToken,
    required String merchantUid,
    required String impUid,
  }) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}user/completeCertification');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accessToken,
          },
          body: json.encode({
            "merchant_uid": merchantUid,
            "imp_uid": impUid,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return PhoneCertificationCompleteAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return PhoneCertificationCompleteAPI().complete(
          accessToken: _prefs.getString('AccessToken')!,
          merchantUid: merchantUid,
          impUid: impUid);
    } else {
      throw Exception(response.body);
    }
  }
}

class PhoneCertificationCompleteAPIResponseModel {
  dynamic result;

  PhoneCertificationCompleteAPIResponseModel({
    this.result,
  });

  factory PhoneCertificationCompleteAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return PhoneCertificationCompleteAPIResponseModel(
      result: data,
    );
  }
}
