import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class PhoneCertificationRequestAPI {
  Future<PhoneCertificationRequestAPIResponseModel> request(
      {required String accessToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}user/requestCertification');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accessToken,
          },
          body: json.encode({}),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return PhoneCertificationRequestAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return PhoneCertificationRequestAPI()
          .request(accessToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class PhoneCertificationRequestAPIResponseModel {
  dynamic result;

  PhoneCertificationRequestAPIResponseModel({
    this.result,
  });

  factory PhoneCertificationRequestAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return PhoneCertificationRequestAPIResponseModel(
      result: data,
    );
  }
}
