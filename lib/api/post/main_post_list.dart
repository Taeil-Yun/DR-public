import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class GetPostListAPI {
  Future<GetPostListAPIResponseModel> list(
      {required String accesToken,
      String? q,
      int? cursor,
      int? category,
      int? postCategory}) async {
    String baseUri = '${ApiBaseUrlConfig().baseUri}post/getPostList?';

    if (q != null) {
      baseUri += '&q=$q';
    }

    if (cursor != null) {
      baseUri += '&cursor=$cursor';
    }

    if (category != null) {
      baseUri += '&category=$category';
    }

    if (postCategory != null) {
      baseUri += '&post_category=$postCategory';
    }

    // if (q == null && cursor == null && category == null && postCategory == null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList');
    // } else if (q != null && cursor == null && category == null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?q=$q');
    // } else if (q == null && cursor != null && category == null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?cursor=$cursor');
    // } else if (q == null && cursor == null && category != null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?category=$category');
    // } else if (q != null && cursor != null && category == null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?q=$q&cursor=$cursor');
    // } else if (q != null && cursor == null && category != null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?q=$q&category=$category');
    // } else if (q == null && cursor != null && category != null) {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?cursor=$cursor&category=$category');
    // } else {
    //   baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/getPostList?q=$q&cursor=$cursor&category=$category');
    // }

    final response = await InterceptorHelper().client.get(
      Uri.parse(baseUri),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return GetPostListAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return GetPostListAPI().list(
          accesToken: _prefs.getString('AccessToken')!, q: q, cursor: cursor);
    } else {
      throw Exception(response.body);
    }
  }
}

class GetPostListAPIResponseModel {
  dynamic result;

  GetPostListAPIResponseModel({
    this.result,
  });

  factory GetPostListAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetPostListAPIResponseModel(
      result: data,
    );
  }
}
