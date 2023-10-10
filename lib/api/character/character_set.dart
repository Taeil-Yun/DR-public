import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetUserCharacterAPI {
  Future<SetUserCharacterAPIResponseModel> setCharacter({
    required String accessToken,
    required int body,
    required int hair,
    required int face,
    required int top,
    required int bottom,
    required int foot,
    required int item,
    required File image,
  }) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}character/setUserCharacter');

    final request = http.MultipartRequest('POST', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    request.fields['body'] = '$body';
    request.fields['hair'] = '$hair';
    request.fields['face'] = '$face';
    request.fields['top'] = '$top';
    request.fields['bottom'] = '$bottom';
    request.fields['foot'] = '$foot';
    request.fields['item'] = '$item';

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return SetUserCharacterAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return SetUserCharacterAPI().setCharacter(
          accessToken: _prefs.getString('AccessToken')!,
          body: body,
          face: face,
          hair: hair,
          top: top,
          bottom: bottom,
          foot: foot,
          item: item,
          image: image);
    } else {
      throw Exception(response.body);
    }
  }
}

class SetUserCharacterAPIResponseModel {
  dynamic result;

  SetUserCharacterAPIResponseModel({
    this.result,
  });

  factory SetUserCharacterAPIResponseModel.fromJson(dynamic data) {
    return SetUserCharacterAPIResponseModel(
      result: data,
    );
  }
}
