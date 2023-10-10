import 'package:DRPublic/api/live/live_room_list.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/api/post/main_post_list.dart';
import 'package:DRPublic/api/search/search.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class SearchHomeScreen extends StatefulWidget {
  const SearchHomeScreen({Key? key}) : super(key: key);

  @override
  State<SearchHomeScreen> createState() => _SearchHomeScreenState();
}

class _SearchHomeScreenState extends State<SearchHomeScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode textFocusNode = FocusNode();

  List<Color> randomColorsIdea = [
    ColorsConfig().trend1(),
    ColorsConfig().trend2(),
    ColorsConfig().trend3(),
    ColorsConfig().trend4(),
    ColorsConfig().trend5(),
    ColorsConfig().trend6()
  ];
  List<Color> randomColorsTrend = [
    ColorsConfig().trend1(),
    ColorsConfig().trend2(),
    ColorsConfig().trend3(),
    ColorsConfig().trend4(),
    ColorsConfig().trend5(),
    ColorsConfig().trend6()
  ];

  Map<String, dynamic> getRecommendData = {};

  List<String> searchHistories = [];

  @override
  void initState() {
    apiInitialize();
    searchHistoryLoad();

    randomColorsIdea.shuffle();
    randomColorsTrend.shuffle();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    textFocusNode.dispose();

    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetRecommendDataList()
        .recommands(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getRecommendData = value.result;
      });
    });
  }

  Future<void> searchHistoryLoad() async {
    final _prefs = await SharedPreferences.getInstance();

    if (_prefs.getStringList('SearchList') != null) {
      setState(() {
        searchHistories = _prefs.getStringList('SearchList')!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        textFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: DRAppBar(
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          backgroundColor: ColorsConfig().subBackground1(),
          leading: DRAppBarLeading(
            press: () {
              Navigator.pop(context);
            },
          ),
          title: DRAppBarTitle(
            onWidget: true,
            wd: Container(
              width: MediaQuery.of(context).size.width,
              height: 30.0,
              decoration: BoxDecoration(
                color: ColorsConfig().subBackgroundBlack(),
                borderRadius: BorderRadius.circular(14.0),
              ),
              alignment: Alignment.centerLeft,
              child: TextFormField(
                controller: _controller,
                focusNode: textFocusNode,
                keyboardType: TextInputType.text,
                autofocus: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(top: 10.0),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: SvgAssets(
                          image: 'assets/icon/search.svg',
                          color: ColorsConfig().textBlack2(),
                          width: 15.0,
                          height: 15.0,
                        ),
                      ),
                    ],
                  ),
                ),
                textAlignVertical: TextAlignVertical.center,
                cursorHeight: 15.0,
                cursorColor: ColorsConfig().primary(),
                style: TextStyle(
                  color: ColorsConfig().textWhite1(),
                  fontSize: 15.0.sp,
                  fontWeight: FontWeight.w400,
                ),
                onEditingComplete: () async {
                  if (_controller.text.isNotEmpty) {
                    final _prefs = await SharedPreferences.getInstance();

                    bool _flag = false;

                    if (!searchHistories.contains(_controller.text)) {
                      _flag = true;
                      searchHistories.add(_controller.text);
                    }

                    if (_flag) {
                      _prefs.setStringList('SearchList', searchHistories);
                    }

                    Map<String, dynamic> _searchPostData = {};
                    List<dynamic> _searchLiveData = [];

                    Future.wait([
                      GetPostListAPI()
                          .list(
                              accesToken: _prefs.getString('AccessToken')!,
                              q: _controller.text)
                          .then((value) {
                        _searchPostData = value.result;
                      }),
                      GetLiveRoomListAPI()
                          .list(
                              accesToken: _prefs.getString('AccessToken')!,
                              q: _controller.text)
                          .then((value) {
                        _searchLiveData = value.result;
                      }),
                    ]).then((value) {
                      Navigator.pushNamed(context, '/search_result',
                          arguments: {
                            'search': _controller.text,
                            'result': _searchPostData,
                            'result_live': _searchLiveData,
                          });
                    });
                  }
                },
              ),
            ),
          ),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: ColorsConfig().background(),
            border: Border.symmetric(
              horizontal: BorderSide(
                width: 0.5,
                color: ColorsConfig().border1(),
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 최근검색어 표시줄
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextBuilder(
                      text: '최근 검색어',
                      fontColor: ColorsConfig().textWhite1(),
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    InkWell(
                      onTap: () async {
                        final _prefs = await SharedPreferences.getInstance();

                        setState(() {
                          searchHistories.clear();
                        });

                        _prefs.remove('SearchList');
                      },
                      child: SizedBox(
                        height: 20.0,
                        child: CustomTextBuilder(
                          text: '전체삭제',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 12.0.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // 최근 검색어 tags
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 0.0,
                    maxHeight: 210.0,
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Wrap(
                      children: List.generate(searchHistories.length, (index) {
                        return InkWell(
                          onTap: () async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            Map<String, dynamic> _searchPostData = {};
                            List<dynamic> _searchLiveData = [];

                            Future.wait([
                              GetPostListAPI()
                                  .list(
                                      accesToken:
                                          _prefs.getString('AccessToken')!,
                                      q: _prefs
                                          .getStringList('SearchList')![index])
                                  .then((value) {
                                _searchPostData = value.result;
                              }),
                              GetLiveRoomListAPI()
                                  .list(
                                      accesToken:
                                          _prefs.getString('AccessToken')!,
                                      q: _prefs
                                          .getStringList('SearchList')![index])
                                  .then((value) {
                                _searchLiveData = value.result;
                              }),
                            ]).then((value) {
                              Navigator.pushNamed(context, '/search_result',
                                  arguments: {
                                    'search': _prefs
                                        .getStringList('SearchList')![index],
                                    'result': _searchPostData,
                                    'result_live': _searchLiveData,
                                  });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            margin:
                                const EdgeInsets.only(right: 10.0, top: 10.0),
                            decoration: BoxDecoration(
                              color: ColorsConfig().subBackgroundBlack(),
                              border: Border.all(
                                width: 0.5,
                                color: ColorsConfig().border1(),
                              ),
                              borderRadius: BorderRadius.circular(500.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomTextBuilder(
                                  text: searchHistories[index],
                                  fontColor: ColorsConfig().textBlack1(),
                                  fontSize: 14.0.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.0,
                                ),
                                const SizedBox(width: 10.0),
                                InkWell(
                                  onTap: () async {
                                    final _prefs =
                                        await SharedPreferences.getInstance();

                                    setState(() {
                                      searchHistories.removeAt(index);
                                    });

                                    _prefs.setStringList(
                                        'SearchList', searchHistories);
                                  },
                                  child: SvgAssets(
                                    image: 'assets/icon/close_btn.svg',
                                    color: ColorsConfig().textBlack2(),
                                    width: 10.0,
                                    height: 10.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // 추천 아이디어 표시줄, 추천 아이디어 콘텐츠
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 33.0, 0.0, 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 추천 아이디어 표시줄
                        Container(
                          margin: const EdgeInsets.only(bottom: 4.0),
                          child: CustomTextBuilder(
                            text: '추천 아이디어',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 18.0.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        // 추천 아이디어 콘텐츠
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: List.generate(
                                getRecommendData.isNotEmpty
                                    ? getRecommendData['idea'].length < 6
                                        ? getRecommendData['idea'].length
                                        : 6
                                    : 0, (index) {
                              return InkWell(
                                onTap: () async {
                                  final _prefs =
                                      await SharedPreferences.getInstance();

                                  Map<String, dynamic> _searchPostData = {};
                                  List<dynamic> _searchLiveData = [];

                                  Future.wait([
                                    GetPostListAPI()
                                        .list(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            q: getRecommendData['idea'][index]
                                                ['text'])
                                        .then((value) {
                                      _searchPostData = value.result;
                                    }),
                                    GetLiveRoomListAPI()
                                        .list(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            q: getRecommendData['idea'][index]
                                                ['text'])
                                        .then((value) {
                                      _searchLiveData = value.result;
                                    }),
                                  ]).then((value) {
                                    Navigator.pushNamed(
                                        context, '/search_result',
                                        arguments: {
                                          'search': getRecommendData['idea']
                                              [index]['text'],
                                          'result': _searchPostData,
                                          'result_live': _searchLiveData,
                                        });
                                  });
                                },
                                child: Container(
                                  width: (MediaQuery.of(context).size.width -
                                          70.0) /
                                      3,
                                  height: 65.0,
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: randomColorsIdea[index],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Center(
                                    child: CustomTextBuilder(
                                      text:
                                          '${getRecommendData['idea'][index]['text']}',
                                      fontColor: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 최신 트렌드 표시줄, 최신 트렌드 콘텐츠
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 최신 트렌드 표시줄
                        Container(
                          margin: const EdgeInsets.only(bottom: 4.0),
                          child: CustomTextBuilder(
                            text: '최신 트렌드',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 18.0.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        // 최신 트렌드 콘텐츠
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: List.generate(
                                getRecommendData.isNotEmpty
                                    ? getRecommendData['recently'].length < 6
                                        ? getRecommendData['recently'].length
                                        : 6
                                    : 0, (index) {
                              return InkWell(
                                onTap: () async {
                                  final _prefs =
                                      await SharedPreferences.getInstance();

                                  Map<String, dynamic> _searchPostData = {};
                                  List<dynamic> _searchLiveData = [];

                                  Future.wait([
                                    GetPostListAPI()
                                        .list(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            q: getRecommendData['recently']
                                                [index]['text'])
                                        .then((value) {
                                      _searchPostData = value.result;
                                    }),
                                    GetLiveRoomListAPI()
                                        .list(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            q: getRecommendData['recently']
                                                [index]['text'])
                                        .then((value) {
                                      _searchLiveData = value.result;
                                    }),
                                  ]).then((value) {
                                    Navigator.pushNamed(
                                        context, '/search_result',
                                        arguments: {
                                          'search': getRecommendData['recently']
                                              [index]['text'],
                                          'result': _searchPostData,
                                          'result_live': _searchLiveData,
                                        });
                                  });
                                },
                                child: Container(
                                  width: (MediaQuery.of(context).size.width -
                                          70.0) /
                                      3,
                                  height: 65.0,
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: randomColorsTrend[index],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Center(
                                    child: CustomTextBuilder(
                                      text:
                                          '${getRecommendData['recently'][index]['text']}',
                                      fontColor: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}
