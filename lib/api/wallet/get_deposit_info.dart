import 'dart:convert';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetDepositInfoDataAPI {
  Future<GetDepositInfoDataAPIResponseModel> deposit(
      {required String accesToken, required String merchantUid}) async {
    String baseUri =
        '${ApiBaseUrlConfig().baseUri}payment/getDepositInfo?merchant_uid=$merchantUid';

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetDepositInfoDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      return GetDepositInfoDataAPI()
          .deposit(accesToken: accesToken, merchantUid: merchantUid);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetDepositInfoDataAPIResponseModel {
  dynamic result;

  GetDepositInfoDataAPIResponseModel({
    this.result,
  });

  factory GetDepositInfoDataAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return GetDepositInfoDataAPIResponseModel(
      result: data,
    );
  }
}
