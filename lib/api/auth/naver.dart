import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';

class NaverSignInAPI {
  Future<NaverSignInAPIResponseModel> naver(
      {required String accessToken, required String fcmToken}) async {
    final baseUri = Uri.parse(
        '${ApiBaseUrlConfig().baseUri}auth/naver/${Platform.isAndroid ? 'android' : 'ios'}');

    final response = await http.post(baseUri,
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "access_token": accessToken,
          "fcm_token": fcmToken,
        }));

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return NaverSignInAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else {
      throw Exception(response.body);
    }
  }
}

class NaverSignInAPIResponseModel {
  dynamic result;

  NaverSignInAPIResponseModel({
    this.result,
  });

  factory NaverSignInAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return NaverSignInAPIResponseModel(
      result: data,
    );
  }
}
