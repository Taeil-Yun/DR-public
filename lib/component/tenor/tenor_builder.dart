part of tenor_custom;

class TenorCustomBuilder {
  ///
  /// [search] (required) : 검색어
  ///
  /// [limit] (optional / default = 20개) : 검색될 GIF 개수
  ///
  /// [pos] (optional) : 최초 실행시 [limit] 개수만큼 데이터를 받아온 후 다음 데이터를 받아올 시작 index 값
  /// 
  /// [langueges] (optional / default = TenorCustomLanguages.korean) : 검색어를 해석할 기본 언어 설정
  ///
  Future getTenorDatas(String search, {int limit = 20, dynamic pos, String langueges = TenorCustomLanguages.korean}) async {
    var rst = pos!=null
      ? await GetTenorSearchApi().tenorSearch(search, limit: limit, languages: langueges, pos: pos)
      : await GetTenorSearchApi().tenorSearch(search, limit: limit, languages: langueges);

    return tenorResponseData(rst.results, rst.next);
  }

  Map<String, dynamic> tenorResponseData(dynamic res, dynamic next) {
    Map<String, dynamic> _datas = {
      'next' : next,
      'media' : [],
    };

    _datas['next'] = next;
    for (var tenorResult in res) {
      _datas['media'].add(tenorResult['media'][0]['gif']['url']);
    }

    return _datas;
  }
}