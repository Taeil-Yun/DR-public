import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';

class AppleSignInAPI {
  Future<AppleSignInAPIResponseModel> apple(
      {String? idToken, required String fcmToken}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}auth/apple/${Platform.isAndroid ? 'android' : 'ios'}');

    final response = await http.post(baseUri,
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "id_token": idToken,
          "fcm_token": fcmToken,
        }));

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AppleSignInAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else {
      throw Exception(response.body);
    }
  }
}

class AppleSignInAPIResponseModel {
  dynamic result;

  AppleSignInAPIResponseModel({
    this.result,
  });

  factory AppleSignInAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AppleSignInAPIResponseModel(
      result: data,
    );
  }
}
