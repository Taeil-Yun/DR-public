import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class AddVoteAPI {
  Future<AddVoteAPIResponseModel> addVote({
    required String accesToken,
    required String title,
    required List<String> votes,
    required String tag,
    required int days,
    required int hours,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/addVote');

    final response = await InterceptorHelper().client.post(
          baseUri,
          headers: {
            "Content-Type": "application/json",
            "authorization": "Bearer " + accesToken,
          },
          body: json.encode({
            "title": title,
            "vote": votes,
            "tag": tag,
            "day": days.toString(),
            "hour": hours.toString(),
          }),
        );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddVoteAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddVoteAPI().addVote(
        accesToken: _prefs.getString('AccessToken')!,
        title: title,
        votes: votes,
        tag: tag,
        days: days,
        hours: hours,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class AddVoteAPIResponseModel {
  dynamic result;

  AddVoteAPIResponseModel({
    this.result,
  });

  factory AddVoteAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddVoteAPIResponseModel(
      result: data,
    );
  }
}
