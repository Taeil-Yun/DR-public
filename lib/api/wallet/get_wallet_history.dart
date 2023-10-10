import 'dart:convert';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetWalletHistoryDataAPI {
  Future<GetWalletHistoryAPIResponseModel> history(
      {required String accesToken,
      required int year,
      required int month}) async {
    String baseUri =
        '${ApiBaseUrlConfig().baseUri}wallet/getWalletList?year=$year&month=$month';

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetWalletHistoryAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      return GetWalletHistoryDataAPI()
          .history(accesToken: accesToken, year: year, month: month);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetWalletHistoryAPIResponseModel {
  dynamic result;

  GetWalletHistoryAPIResponseModel({
    this.result,
  });

  factory GetWalletHistoryAPIResponseModel.fromJson(List<dynamic> data) {
    return GetWalletHistoryAPIResponseModel(
      result: data,
    );
  }
}
