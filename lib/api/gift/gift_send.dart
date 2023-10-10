import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class SendGiftDataAPI {
  Future<SendGiftDataAPIResponseModel> gift(
      {required String accesToken,
      required int itemIndex,
      required int postIndex}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}item/sendItem');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "item_index": itemIndex,
            "post_index": postIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return SendGiftDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return SendGiftDataAPI().gift(
          accesToken: _prefs.getString('AccessToken')!,
          itemIndex: itemIndex,
          postIndex: postIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class SendGiftDataAPIResponseModel {
  dynamic result;

  SendGiftDataAPIResponseModel({
    this.result,
  });

  factory SendGiftDataAPIResponseModel.fromJson(Map<String, dynamic> data) {
    return SendGiftDataAPIResponseModel(
      result: data,
    );
  }
}
