import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';

class GoogleSignInAPI {
  Future<GoogleSignInAPIResponseModel> google(
      {required String idToken, required String fcmToken}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}auth/google/${Platform.isAndroid ? 'android' : 'ios'}');

    final response = await http.post(baseUri,
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "id_token": idToken,
          "fcm_token": fcmToken,
          // "deviceType": deviceType
        }));

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GoogleSignInAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else {
      throw Exception(response.body);
    }
  }
}

class GoogleSignInAPIResponseModel {
  dynamic result;

  GoogleSignInAPIResponseModel({
    this.result,
  });

  factory GoogleSignInAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GoogleSignInAPIResponseModel(
      result: data,
    );
  }
}
