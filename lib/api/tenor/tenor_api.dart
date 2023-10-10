import 'dart:convert';

import 'package:DRPublic/conf/enumerated.dart';
import 'package:http/http.dart' as http;

import 'package:DRPublic/component/tenor/tenor.dart';
import 'package:DRPublic/conf/keys.dart';

class GetTenorSearchApi {
  Future<GetTenorSearchApiResponseModel> tenorSearch(
    String search, {
    int? limit,
    dynamic pos,
    String languages = TenorCustomLanguages.korean,
    String? contentFilter,
    MediaFilter? mediaFilter,
  }) async {
    String url =
        'https://g.tenor.com/v1/search?key=${KeysConfig.tenorApiKey}&locale=$languages&q=$search';

    if (limit != null && limit > 0) {
      url += '&limit=${limit.clamp(1, 50)}';
    } else {
      url += '&limit=20';
    }

    if (pos != null) {
      url += '&pos=$pos';
    }

    if (contentFilter != null) {
      url += '&contentfilter=$contentFilter';
    }

    if (mediaFilter != null) {
      url += '&media_filter=$mediaFilter';
    }

    final baseUri = Uri.parse(url);

    final response = await http.get(
      baseUri,
    );

    if (response.statusCode == 200) {
      return GetTenorSearchApiResponseModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes.toList())));
    } else {
      throw Exception(response.body);
    }
  }
}

class GetTenorSearchApiResponseModel {
  dynamic results, next;

  GetTenorSearchApiResponseModel({
    this.results,
    this.next,
  });

  factory GetTenorSearchApiResponseModel.fromJson(Map<dynamic, dynamic> data) {
    return GetTenorSearchApiResponseModel(
      results: data['results'],
      next: data['next'],
    );
  }
}
