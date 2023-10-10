import 'dart:convert';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetBalanceDataAPI {
  Future<GetBalanceDataAPIResponseModel> balance(
      {required String accesToken}) async {
    String baseUri = '${ApiBaseUrlConfig().baseUri}wallet/getBalance';

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetBalanceDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      return GetBalanceDataAPI().balance(accesToken: accesToken);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetBalanceDataAPIResponseModel {
  dynamic result;

  GetBalanceDataAPIResponseModel({
    this.result,
  });

  factory GetBalanceDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetBalanceDataAPIResponseModel(
      result: data,
    );
  }
}
