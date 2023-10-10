import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class DataReportAPI {
  Future<DataReportAPIResponseModel> report({
    required String accesToken,
    required int category,
    required int type,
    required int targetIndex,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}report/sendReport');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "category": category,
            "type": type,
            "target_index": targetIndex,
            "device": Platform.isAndroid ? 4 : 5,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return DataReportAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return DataReportAPI().report(
          accesToken: _prefs.getString('AccessToken')!,
          category: category,
          type: type,
          targetIndex: targetIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class DataReportAPIResponseModel {
  dynamic result;

  DataReportAPIResponseModel({
    this.result,
  });

  factory DataReportAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return DataReportAPIResponseModel(
      result: data,
    );
  }
}
