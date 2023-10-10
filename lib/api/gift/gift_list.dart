import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetGiftListDataAPI {
  Future<GetGiftListDataAPIResponseModel> gift(
      {required String accesToken}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}item/getItemList');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetGiftListDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetGiftListDataAPI()
          .gift(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetGiftListDataAPIResponseModel {
  dynamic result;

  GetGiftListDataAPIResponseModel({
    this.result,
  });

  factory GetGiftListDataAPIResponseModel.fromJson(List<dynamic> data) {
    return GetGiftListDataAPIResponseModel(
      result: data,
    );
  }
}
