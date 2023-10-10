import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';

class AddImageLiveRoomAPI {
  Future<AddImageLiveRoomAPIResponseModel> addImage({
    required String accessToken,
    required int roomIndex,
    required XFile image,
  }) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}live/addRoomImage');

    final request = http.MultipartRequest('POST', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accessToken,
    });

    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    request.fields['room_index'] = 'roomIndex';

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return AddImageLiveRoomAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return AddImageLiveRoomAPI().addImage(
        accessToken: _prefs.getString('AccessToken')!,
        roomIndex: roomIndex,
        image: image,
      );
    } else {
      throw Exception(response.body);
    }
  }
}

class AddImageLiveRoomAPIResponseModel {
  dynamic result;

  AddImageLiveRoomAPIResponseModel({
    this.result,
  });

  factory AddImageLiveRoomAPIResponseModel.fromJson(
      Map<dynamic, dynamic> data) {
    return AddImageLiveRoomAPIResponseModel(
      result: data,
    );
  }
}
