import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/api/interceptor.dart';

class UserProfileInfoAPI {
  Future<UserProfileInfoAPIResponseModel?> getProfile(
      {required String accesToken}) async {
    final baseUri = Uri.parse('${ApiBaseUrlConfig().baseUri}user/getProfile');

    final response = await InterceptorHelper().client.get(
      baseUri,
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer " + accesToken,
      },
    );

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return UserProfileInfoAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return UserProfileInfoAPI()
          .getProfile(accesToken: _prefs.getString('AccessToken')!);
    } else {
      throw Exception(response.body);
    }
  }

  ///
  /// [agreementEmail] = 이메일 수신 동의 여부 (0 : 미동의, 1 : 동의)
  ///
  Future<UserProfileInfoAPIResponseModel> setProfile(
      {required String accesToken,
      String? description,
      int? agreementEmail,
      CroppedFile? image}) async {
    final baseUri =
        Uri.parse('${ApiBaseUrlConfig().baseUri}user/setUserProfile');

    final request = http.MultipartRequest('PUT', baseUri);

    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      "authorization": "Bearer " + accesToken,
    });
    if (image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image_m', image.path));
    }

    if (agreementEmail != null) {
      request.fields['agreement_email'] = '$agreementEmail';
    }

    request.fields['description'] = description!;

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      // print('datas: ${utf8.decode(response.bodyBytes.toList())}');

      return UserProfileInfoAPIResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else if (response.statusCode == 401 &&
        response.body.split(":")[3].split('"')[1] ==
            'Authorization token expired') {
      final _prefs = await SharedPreferences.getInstance();

      return UserProfileInfoAPI().setProfile(
          accesToken: _prefs.getString('AccessToken')!,
          description: description,
          agreementEmail: agreementEmail,
          image: image);
    } else {
      throw Exception(response.body);
    }
  }
}

class UserProfileInfoAPIResponseModel {
  dynamic result;

  UserProfileInfoAPIResponseModel({
    this.result,
  });

  factory UserProfileInfoAPIResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return UserProfileInfoAPIResponseModel(
      result: data,
    );
  }
}
