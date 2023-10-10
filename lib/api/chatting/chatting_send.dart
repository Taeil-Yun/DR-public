import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';

class SendChattingDataAPI {
  ///
  /// [type] = 0: message, 1: iamge
  ///
  Future<SendChattingDataAPIResponseModel> send({
    required String accessToken,
    required int type,
    required int userIndex,
    String? message,
    XFile? image,
  }) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}chatting/sendChatting');

    final request = http.MultipartRequest('PUT', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });
    if (message == null && image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
    if (image == null && message != null) {
      request.fields['message'] = message;
    }
    request.fields['type'] = '$type';
    request.fields['user_index'] = '$userIndex';

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return SendChattingDataAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return SendChattingDataAPI().send(
          accessToken: _prefs.getString('AccessToken')!,
          type: type,
          userIndex: userIndex,
          message: message,
          image: image);
    } else {
      throw Exception(response.body);
    }
  }
}

class SendChattingDataAPIResponseModel {
  dynamic result;

  SendChattingDataAPIResponseModel({
    this.result,
  });

  factory SendChattingDataAPIResponseModel.fromJson(dynamic data) {
    return SendChattingDataAPIResponseModel(
      result: data,
    );
  }
}
