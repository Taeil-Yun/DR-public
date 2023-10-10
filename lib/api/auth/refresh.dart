import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';

class RefreshTokenAPI {
  Future<RefreshTokenAPIResponseModel> refresh(
      {required String accesToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}auth/refresh_token');

    final response = await http.post(
      baseUri,
      headers: {
        // "Content-Type" : "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return RefreshTokenAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else {
      throw Exception(response.body);
    }
  }
}

class RefreshTokenAPIResponseModel {
  dynamic result;

  RefreshTokenAPIResponseModel({
    this.result,
  });

  factory RefreshTokenAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return RefreshTokenAPIResponseModel(
      result: data,
    );
  }
}
