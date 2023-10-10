import 'dart:convert';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetPaymentListAPI {
  Future<GetPaymentListAPIResponseModel> paymentList(
      {required String accesToken,
      required int year,
      required int month}) async {
    String baseUri =
        '${ApiBaseUrlConfig().baseUri}payment/getPaymentList?year=$year&month=$month';

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetPaymentListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      return GetPaymentListAPI()
          .paymentList(accesToken: accesToken, year: year, month: month);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetPaymentListAPIResponseModel {
  dynamic result;

  GetPaymentListAPIResponseModel({
    this.result,
  });

  factory GetPaymentListAPIResponseModel.fromJson(List<dynamic> data) {
    return GetPaymentListAPIResponseModel(
      result: data,
    );
  }
}
