import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';

class CreateLiveRoomAPI {
  Future<CreateLiveRoomAPIResponseModel> createRoom({
    required String accessToken,
    required String title,
    required String description,
    required String tag,
    required XFile image,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}live/addRoom');

    final request = http.MultipartRequest('POST', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });

    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    request.fields['title'] = title;
    request.fields['post_category'] = '1';
    request.fields['description'] = description;
    request.fields['tag'] = tag;

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return CreateLiveRoomAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return CreateLiveRoomAPI().createRoom(
        accessToken: _prefs.getString('AccessToken')!,
        title: title,
        description: description,
        tag: tag,
        image: image,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class CreateLiveRoomAPIResponseModel {
  dynamic result;

  CreateLiveRoomAPIResponseModel({
    this.result,
  });

  factory CreateLiveRoomAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return CreateLiveRoomAPIResponseModel(
      result: data,
    );
  }
}
