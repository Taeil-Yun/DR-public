import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddQuestionDataAPI {
  Future<AddQuestionDataAPIResponseModel> addQuestion(
      {required String accessToken,
      required int type,
      required String subject,
      required String content,
      XFile? file}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}question/addQuestion');

    final request = http.MultipartRequest('POST', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }
    request.fields['type'] = '$type';
    request.fields['subject'] = subject;
    request.fields['content'] = content;

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddQuestionDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddQuestionDataAPI().addQuestion(
        accessToken: _prefs.getString('AccessToken')!,
        type: type,
        subject: subject,
        content: content,
        file: file,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class AddQuestionDataAPIResponseModel {
  dynamic result;

  AddQuestionDataAPIResponseModel({
    this.result,
  });

  factory AddQuestionDataAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return AddQuestionDataAPIResponseModel(
      result: data,
    );
  }
}
