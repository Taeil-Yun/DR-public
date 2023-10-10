import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class SelectedVoteCancleAPI {
  Future<SelectedVoteCancleAPIResponseModel> cancel(
      {required String accesToken,
      required int postIndex,
      required int voteIndex}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/cancleVote');

    final response = await InterceptorHelper().client.delete(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "vote_index": voteIndex,
            "post_index": postIndex,
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return SelectedVoteCancleAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return SelectedVoteCancleAPI().cancel(
          accesToken: _prefs.getString('AccessToken')!,
          postIndex: postIndex,
          voteIndex: voteIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class SelectedVoteCancleAPIResponseModel {
  dynamic result;

  SelectedVoteCancleAPIResponseModel({
    this.result,
  });

  factory SelectedVoteCancleAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return SelectedVoteCancleAPIResponseModel(
      result: data,
    );
  }
}
