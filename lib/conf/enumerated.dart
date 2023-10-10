/// Tenor 메소드 타입
/// 
/// values: (autoComplete | search | trendSearch | random | searchSuggest)
enum TenorType {
  /// [autoComplete] = 부분 검색어가 제공된 경우 완료된 검색어 목록
  autoComplete,
  /// [search] = 검색어에 대한 GIF 목록
  search,
  /// [trendSearch] = 현재 인기 검색어 목록
  trendSearch,
  /// [random] = 검색어에 대한 무작위 GIF 목록
  random,
  /// [searchSuggest] = 사용자가 검색 범위를 좁히거나 관련 검색어를 검색하여 정확한 GIF를 찾음
  searchSuggest
}

/// 콘텐츠 안전 필터 수준
/// 
/// values: (off | low | medium | high)
enum ContentFilter {off, low, medium, high}

/// GIF_OBJECT 목록에서 반환되는 GIF 형식의 수
/// 
/// values: (minimal | basic)
enum MediaFilter {
  /// [minimal] -> tinygif, gif, and mp4
  minimal,
  /// [basic] -> nanomp4, tinygif, tinymp4, gif, mp4, and nanogif
  basic
}

/// 레이아웃 타입
/// 
/// values: (card | headline | gallery)
enum LayoutType {card, headline, gallery}

/// 글쓰기 종류
/// 
/// values: (post | analytics | debate | news | vote)
enum WritingType {post, analytics, debate, news, vote}

/// 스위치 종류
/// 
/// values: (material | cupertino)
enum SwitchType {material, cupertino}

/// SVG 타입
/// 
/// values: (asset | network | file | memory | string)
enum SvgType {asset, network, file, memory, string}

/// 계정 상태 체크
/// 
/// values: (suspension | withdrawal | normal)
enum AccountState {suspension, withdrawal, normal}