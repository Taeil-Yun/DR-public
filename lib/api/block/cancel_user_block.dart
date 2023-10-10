import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class CancelUserBlockAPI {
  Future<CancelUserBlockAPIResponseModel> cancelBlock(
      {required String accesToken, required int targetIndex}) async {
    dynamic baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}block/unblockUser');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "target_index": targetIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return CancelUserBlockAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return CancelUserBlockAPI().cancelBlock(
          accesToken: _prefs.getString('AccessToken')!,
          targetIndex: targetIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class CancelUserBlockAPIResponseModel {
  dynamic result;

  CancelUserBlockAPIResponseModel({
    this.result,
  });

  factory CancelUserBlockAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return CancelUserBlockAPIResponseModel(
      result: data,
    );
  }
}
