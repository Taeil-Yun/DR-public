import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class SelectVoteAPI {
  Future<SelectVoteAPIResponseModel> addVote({
    required String accesToken,
    required int postIndex,
    required int voteIndex,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/addVote');

    final response = await InterceptorHelper().client.patch(
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

      return SelectVoteAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return SelectVoteAPI().addVote(
          accesToken: _prefs.getString('AccessToken')!,
          postIndex: postIndex,
          voteIndex: voteIndex);
    } else {
      throw Exception(response.body);
    }
  }
}

class SelectVoteAPIResponseModel {
  dynamic result;

  SelectVoteAPIResponseModel({
    this.result,
  });

  factory SelectVoteAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return SelectVoteAPIResponseModel(
      result: data,
    );
  }
}
