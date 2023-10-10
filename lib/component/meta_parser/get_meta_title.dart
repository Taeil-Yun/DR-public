part of meta_parser;

class MetaDataParser {
  Future<Map<String, dynamic>?> parser(String url) async {
    var data = await MetadataFetch.extract(url);

    Map<String, dynamic>? _data = data?.toMap();

    return _data;
  }

  Future<bool?> checkUrl(String url) async {
    RegExp _regex = RegExp(r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)");
    if (!_regex.hasMatch(url)) {
      return null;
    } else {
      http.Response _urlResponse =  await http.get(Uri.parse(url));
      if (_urlResponse.statusCode == 200) {
        return true;
      }
      else {
        return false;
      }
    }
  }
}