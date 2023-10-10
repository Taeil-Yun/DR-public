import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatchPostDataAPI {
  Future<PatchPostDataAPIResponseModel> patchPost({
    required String accessToken,
    required int postIndex,
    int? type,
    String? title,
    String? tag,
    String? description,
    List<dynamic>? file,
    String? category,
    String? subLink,
    required int postCategoryType,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}post/changePost');

    final request = http.MultipartRequest('PATCH', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });

    if (category != null) {
      request.fields['category'] = category;
      if (category == 'i' && file != null) {
        for (int i = 0; i < file.length; i++) {
          if (file[i].toString().startsWith('https://') ||
              file[i].toString().startsWith('http://')) {
            request.fields['image${i + 1}'] =
                file[i].toString().split('image.DRPublic.co.kr/')[1];
          } else {
            request.files.add(await http.MultipartFile.fromPath(
                'image${i + 1}', file[i].path));
          }
        }
      } else {
        if (subLink != null) {
          request.fields['sub_link'] = subLink;
        }
      }
    }

    request.fields['post_index'] = '$postIndex';
    request.fields['type'] = '$type';
    request.fields['title'] = title!;
    request.fields['tag'] = tag!;
    request.fields['description'] = description!;
    request.fields['post_category'] = '$postCategoryType';

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return PatchPostDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return PatchPostDataAPI().patchPost(
        accessToken: _prefs.getString('AccessToken')!,
        postIndex: postIndex,
        type: type,
        title: title,
        tag: tag,
        description: description,
        file: file,
        category: category,
        subLink: subLink,
        postCategoryType: postCategoryType,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class PatchPostDataAPIResponseModel {
  dynamic result;

  PatchPostDataAPIResponseModel({
    this.result,
  });

  factory PatchPostDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return PatchPostDataAPIResponseModel(
      result: data,
    );
  }
}
