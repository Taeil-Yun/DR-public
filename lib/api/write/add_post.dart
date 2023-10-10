import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPostDataAPI {
  Future<AddPostDataAPIResponseModel> addPost({
    required String accessToken,
    required int type,
    required String title,
    required String tag,
    required String description,
    required int postCategoryType,
    List<dynamic>? file,
    String? category,
    String? subLink,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/addPost');

    final request = http.MultipartRequest('POST', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });
    if (category != null) {
      if (category == 'i') {
        for (int i = 0; i < file!.length; i++) {
          request.files
              .add(await http.MultipartFile.fromPath('image', file[i].path));
        }
      } else {
        if (subLink != null) {
          request.fields['sub_link'] = subLink;
        } else {
          throw Exception(
              'If the category is not "i", then subLink must be used unconditionally');
        }
      }
      request.fields['category'] = category;
    }
    request.fields['post_category'] = '$postCategoryType';
    request.fields['type'] = '$type';
    request.fields['title'] = title;
    request.fields['tag'] = tag;
    request.fields['description'] = description;

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddPostDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddPostDataAPI().addPost(
        accessToken: _prefs.getString('AccessToken')!,
        type: type,
        title: title,
        tag: tag,
        description: description,
        file: file,
        category: category,
        postCategoryType: postCategoryType,
        subLink: subLink,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class AddPostDataAPIResponseModel {
  dynamic result;

  AddPostDataAPIResponseModel({
    this.result,
  });

  factory AddPostDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddPostDataAPIResponseModel(
      result: data,
    );
  }
}
