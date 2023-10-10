import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class AddLikeSenderAPI {
  Future<AddLikeSenderAPIResponseModel> add(
      {required String accesToken, required int postIndex}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/addLike');

    final response = await InterceptorHelper().client.put(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "post_index": postIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddLikeSenderAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddLikeSenderAPI().add(
          accesToken: _prefs.getString('AccessToken')!, postIndex: postIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class AddLikeSenderAPIResponseModel {
  dynamic result;

  AddLikeSenderAPIResponseModel({
    this.result,
  });

  factory AddLikeSenderAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddLikeSenderAPIResponseModel(
      result: data,
    );
  }
}
