import 'dart:convert';
import 'dart:io';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetAppVersionCheckAPI {
  Future<GetAppVersionCheckAPIResponseModel> version(
      {required String version}) async {
    String baseUri =
        '${ApiBaseUrlConfig().baseUri}version/getVersion/${Platform.isAndroid ? 'android' : 'ios'}?version=$version';

    final response = await InterceptorHelper().client.get(
          Uri.parse(baseUri),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetAppVersionCheckAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      return GetAppVersionCheckAPI().version(version: version);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetAppVersionCheckAPIResponseModel {
  dynamic result;

  GetAppVersionCheckAPIResponseModel({
    this.result,
  });

  factory GetAppVersionCheckAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return GetAppVersionCheckAPIResponseModel(
      result: data,
    );
  }
}
