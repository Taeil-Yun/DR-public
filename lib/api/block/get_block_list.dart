import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetBlockListAPI {
  Future<GetBlockListAPIResponseModel> blockList(
      {required String accesToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}block/getBlockList');

    final response = await InterceptorHelper().client.get(baseUri, headers: {
      "Content-Type": "application/json",
      "authorization": "Bearer " + accesToken,
    });

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetBlockListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetBlockListAPI()
          .blockList(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetBlockListAPIResponseModel {
  dynamic result;

  GetBlockListAPIResponseModel({
    this.result,
  });

  factory GetBlockListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetBlockListAPIResponseModel(
      result: data,
    );
  }
}
