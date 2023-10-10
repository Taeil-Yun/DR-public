import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetCharacterMyAPI {
  Future<GetCharacterMyAPIResponseModel> myAvatar(
      {required String accesToken}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}character/getMyCharacter');

    final response = await InterceptorHelper().client.get(baseUri, headers: {
      "Content-Type": "application/json",
      "authorization": "Bearer " + accesToken,
    });

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetCharacterMyAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetCharacterMyAPI()
          .myAvatar(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetCharacterMyAPIResponseModel {
  dynamic result;

  GetCharacterMyAPIResponseModel({
    this.result,
  });

  factory GetCharacterMyAPIResponseModel.fromJson(List<dynamic> data) {
    return GetCharacterMyAPIResponseModel(
      result: data,
    );
  }
}
