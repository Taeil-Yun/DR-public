import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetAgreementAPI {
  Future<GetAgreementAPIResponseModel> agreement(
      {required String accesToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}agreement/getAgreement');

    final response = await InterceptorHelper().client.get(baseUri, headers: {
      "Content-Type": "application/json",
      "authorization": "Bearer " + accesToken,
    });

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetAgreementAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetAgreementAPI()
          .agreement(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetAgreementAPIResponseModel {
  dynamic result;

  GetAgreementAPIResponseModel({
    this.result,
  });

  factory GetAgreementAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetAgreementAPIResponseModel(
      result: data,
    );
  }
}
