import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetLiveSymbolSearchListAPI {
  Future<GetLiveSymbolSearchListAPIResponseModel> search(
      {required String accesToken, required String q, String? type}) async {
    dynamic baseUri;

    if (type != null) {
      baseUri = Uri.parse(
          '${ApiBaseUrlConfig().baseUri}live/getSymbols?q=$q&type=$type');
    } else {
      baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}live/getSymbols?q=$q');
    }

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      return GetLiveSymbolSearchListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetLiveSymbolSearchListAPI().search(
          accesToken: _prefs.getString('AccessToken')!, q: q, type: type);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetLiveSymbolSearchListAPIResponseModel {
  dynamic result;

  GetLiveSymbolSearchListAPIResponseModel({
    this.result,
  });

  factory GetLiveSymbolSearchListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetLiveSymbolSearchListAPIResponseModel(
      result: data,
    );
  }
}
