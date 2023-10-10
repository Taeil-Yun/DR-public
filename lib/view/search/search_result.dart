import 'package:DRPublic/component/popup/popup.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/gift/gift_list.dart';
import 'package:DRPublic/api/gift/gift_send.dart';
import 'package:DRPublic/api/gift/gift_send_priced.dart';
import 'package:DRPublic/api/like/add.dart';
import 'package:DRPublic/api/like/cancel.dart';
import 'package:DRPublic/api/live/live_join_check.dart';
import 'package:DRPublic/api/live/live_room_list.dart';
import 'package:DRPublic/api/post/main_post_detail.dart';
import 'package:DRPublic/api/post/main_post_list.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/widget/deep_link.dart';
import 'package:DRPublic/widget/get_youtube_thumbnail.dart';
import 'package:DRPublic/widget/holding_balance.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({Key? key}) : super(key: key);

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _controller = TextEditingController();
  final FocusNode textFocusNode = FocusNode();
  final PageController _pageController = PageController();

  var numberFormat = NumberFormat('###,###,###,###');

  Map<String, dynamic> searchResultData = {};
  Map<String, dynamic> getProfileData = {};

  List<dynamic> searchLiveResultData = [];
  List<bool> getSearchDataMoreBtnState = [];
  List<String> searchHistories = [];

  int addLikeCount = 0;
  int currentPage = 0;
  int _currentTabIndex = 0;

  @override
  void initState() {
    apiInitialize();
    initialSearchText();
    searchHistoryLoad();

    _tabController = TabController(
      length: 2,
      vsync: this, // vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    textFocusNode.dispose();
    _pageController.dispose();

    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    UserProfileInfoAPI()
        .getProfile(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getProfileData = value?.result;
      });
    });
  }

  Future<void> initialSearchText() async {
    Future.delayed(Duration.zero, () {
      setState(() {
        _controller.text = RouteGetArguments().getArgs(context)['search'];
        searchResultData = RouteGetArguments().getArgs(context)['result'];
        searchLiveResultData =
            RouteGetArguments().getArgs(context)['result_live'];

        for (int i = 0; i < searchResultData['data'].length; i++) {
          getSearchDataMoreBtnState.add(false);
        }
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

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  Image themeImage() {
    String _image;

    _image = ImageConfig().searchNoData();

    var result = Image(
      image: AssetImage(_image),
      filterQuality: FilterQuality.high,
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
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
                final _prefs = await SharedPreferences.getInstance();

                if (_controller.text.isNotEmpty) {
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
                    Navigator.pushNamed(context, '/search_result', arguments: {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46.0),
          child: Container(
            height: 46.0,
            decoration: BoxDecoration(
              color: ColorsConfig().subBackground1(),
            ),
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: ColorsConfig.subscribeBtnPrimary,
              unselectedLabelColor: ColorsConfig().textWhite1(),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
              labelColor: ColorsConfig.subscribeBtnPrimary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(
                  child: CustomTextBuilder(
                    text: '포스트',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '라이브',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          searchForPostData(),
          searchForLiveData(),
        ],
      ),
    );
  }

  Widget searchForLiveData() {
    return Container(
      color: ColorsConfig().background(),
      child: searchLiveResultData.isNotEmpty
          ? ListView.builder(
              itemCount: searchLiveResultData.length,
              itemBuilder: (context, index) {
                String _tags = '';

                for (int i = 0;
                    i <
                        searchLiveResultData[index]['tag']
                            .toString()
                            .split(',')
                            .length;
                    i++) {
                  _tags +=
                      '${searchLiveResultData[index]['tag'].toString().split(',')[i].trim().replaceFirst('', '#')} ';
                }

                if (index == 0) {
                  return Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(15.0),
                        child: CustomTextBuilder(
                          text: '‘${_controller.text}’ 검색 결과',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 18.0.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final _prefs = await SharedPreferences.getInstance();

                          LiveJoinCheckAPI()
                              .join(
                                  accesToken: _prefs.getString('AccessToken')!,
                                  roomIndex: searchLiveResultData[index]['idx'])
                              .then((joined) {
                            if (joined.result['status'] == 14007) {
                              Navigator.pushNamed(context, 'live_room',
                                  arguments: {
                                    "room_index": searchLiveResultData[index]
                                        ['idx'],
                                    "user_index": getProfileData['id'],
                                    "nickname": getProfileData['nick'],
                                    "avatar": getProfileData['avatar'],
                                    "is_header": false,
                                  });
                            } else if (joined.result['status'] == 14008) {
                              PopUpModal(
                                title: '',
                                titlePadding: EdgeInsets.zero,
                                onTitleWidget: Container(),
                                content: '',
                                contentPadding: EdgeInsets.zero,
                                backgroundColor: ColorsConfig.transparent,
                                onContentWidget: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 136.0,
                                      decoration: BoxDecoration(
                                        color: ColorsConfig().subBackground1(),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8.0),
                                          topRight: Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Center(
                                        child: CustomTextBuilder(
                                          text:
                                              '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 16.0.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            width: 0.5,
                                            color: ColorsConfig().border1(),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  80.0,
                                              height: 43.0,
                                              decoration: BoxDecoration(
                                                color: ColorsConfig()
                                                    .subBackground1(),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(8.0),
                                                  bottomRight:
                                                      Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Center(
                                                child: CustomTextBuilder(
                                                  text: '확인',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 16.0.sp,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).dialog(context);
                            }
                          });
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10.0),
                          color: ColorsConfig().subBackground1(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이미지
                              Container(
                                width: 120.0,
                                height: 79.0,
                                margin: const EdgeInsets.only(right: 10.0),
                                decoration: BoxDecoration(
                                  color: ColorsConfig().textBlack2(),
                                  borderRadius: BorderRadius.circular(4.0),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        searchLiveResultData[index]
                                            ['thumbnail']),
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 제목
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        160.0,
                                    height: 40.0,
                                    child: CustomTextBuilder(
                                      text:
                                          '${searchLiveResultData[index]['title']}',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 14.0.sp,
                                      fontWeight: FontWeight.w700,
                                      maxLines: 2,
                                      textOverflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // 태그
                                  Container(
                                    width: MediaQuery.of(context).size.width -
                                        160.0,
                                    margin: const EdgeInsets.only(
                                        top: 3.0, bottom: 5.0),
                                    child: CustomTextBuilder(
                                      text: _tags,
                                      fontColor: ColorsConfig().hashTag(),
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w400,
                                      maxLines: 1,
                                      textOverflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // 아바타 이미지
                                      Container(
                                        width: 18.0,
                                        height: 18.0,
                                        decoration: BoxDecoration(
                                          color: ColorsConfig()
                                              .userIconBackground(),
                                          borderRadius:
                                              BorderRadius.circular(9.0),
                                        ),
                                        child: Image(
                                          image: NetworkImage(
                                            searchLiveResultData[index]
                                                ['avatar'],
                                            scale: 11.5,
                                          ),
                                          fit: BoxFit.none,
                                          alignment: const Alignment(0.0, -0.3),
                                        ),
                                      ),
                                      // 닉네임
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 5.0, right: 9.0),
                                        child: CustomTextBuilder(
                                          text:
                                              '${searchLiveResultData[index]['nick']}',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      // 시청자 아이콘
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 5.0),
                                        child: SvgAssets(
                                          image: 'assets/icon/group.svg',
                                          color: ColorsConfig().textBlack2(),
                                          width: 14.0,
                                          height: 14.0,
                                        ),
                                      ),
                                      // 시청자 수
                                      CustomTextBuilder(
                                        text: numberFormat.format(
                                            searchLiveResultData[index]
                                                ['total']),
                                        fontColor: ColorsConfig().textBlack2(),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return InkWell(
                  onTap: () async {
                    final _prefs = await SharedPreferences.getInstance();

                    LiveJoinCheckAPI()
                        .join(
                            accesToken: _prefs.getString('AccessToken')!,
                            roomIndex: searchLiveResultData[index]['idx'])
                        .then((joined) {
                      if (joined.result['status'] == 14007) {
                        Navigator.pushNamed(context, 'live_room', arguments: {
                          "room_index": searchLiveResultData[index]['idx'],
                          "user_index": getProfileData['id'],
                          "nickname": getProfileData['nick'],
                          "avatar": getProfileData['avatar'],
                          "is_header": false,
                        });
                      } else if (joined.result['status'] == 14008) {
                        PopUpModal(
                          title: '',
                          titlePadding: EdgeInsets.zero,
                          onTitleWidget: Container(),
                          content: '',
                          contentPadding: EdgeInsets.zero,
                          backgroundColor: ColorsConfig.transparent,
                          onContentWidget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 136.0,
                                decoration: BoxDecoration(
                                  color: ColorsConfig().subBackground1(),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8.0),
                                    topRight: Radius.circular(8.0),
                                  ),
                                ),
                                child: Center(
                                  child: CustomTextBuilder(
                                    text: '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      width: 0.5,
                                      color: ColorsConfig().border1(),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                80.0,
                                        height: 43.0,
                                        decoration: BoxDecoration(
                                          color:
                                              ColorsConfig().subBackground1(),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(8.0),
                                            bottomRight: Radius.circular(8.0),
                                          ),
                                        ),
                                        child: Center(
                                          child: CustomTextBuilder(
                                            text: '확인',
                                            fontColor:
                                                ColorsConfig().textWhite1(),
                                            fontSize: 16.0.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).dialog(context);
                      }
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 10.0),
                    color: ColorsConfig().subBackground1(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지
                        Container(
                          width: 120.0,
                          height: 79.0,
                          margin: const EdgeInsets.only(right: 10.0),
                          decoration: BoxDecoration(
                            color: ColorsConfig().textBlack2(),
                            borderRadius: BorderRadius.circular(4.0),
                            image: DecorationImage(
                              image: NetworkImage(
                                  searchLiveResultData[index]['thumbnail']),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 160.0,
                              height: 40.0,
                              child: CustomTextBuilder(
                                text: '${searchLiveResultData[index]['title']}',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 태그
                            Container(
                              width: MediaQuery.of(context).size.width - 160.0,
                              margin:
                                  const EdgeInsets.only(top: 3.0, bottom: 5.0),
                              child: CustomTextBuilder(
                                text: _tags,
                                fontColor: ColorsConfig().hashTag(),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w400,
                                maxLines: 1,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                // 아바타 이미지
                                Container(
                                  width: 18.0,
                                  height: 18.0,
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().userIconBackground(),
                                    borderRadius: BorderRadius.circular(9.0),
                                  ),
                                  child: Image(
                                    image: NetworkImage(
                                      searchLiveResultData[index]['avatar'],
                                      scale: 11.5,
                                    ),
                                    fit: BoxFit.none,
                                    alignment: const Alignment(0.0, -0.3),
                                  ),
                                ),
                                // 닉네임
                                Container(
                                  margin: const EdgeInsets.only(
                                      left: 5.0, right: 9.0),
                                  child: CustomTextBuilder(
                                    text:
                                        '${searchLiveResultData[index]['nick']}',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // 시청자 아이콘
                                Container(
                                  margin: const EdgeInsets.only(right: 5.0),
                                  child: Icon(
                                    Icons.group_outlined,
                                    color: ColorsConfig().textBlack2(),
                                    size: 18.0,
                                  ),
                                ),
                                // 시청자 수
                                CustomTextBuilder(
                                  text: numberFormat.format(
                                      searchLiveResultData[index]['total']),
                                  fontColor: ColorsConfig().textBlack2(),
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Container(
              color: ColorsConfig().background(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130.0,
                      height: 130.0,
                      child: themeImage(),
                    ),
                    CustomTextBuilder(
                      text: '검색 결과가 없습니다.',
                      fontColor: ColorsConfig().textWhite1(),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    const SizedBox(height: 65.0),
                  ],
                ),
              ),
            ),
    );
  }

  Widget searchForPostData() {
    return searchResultData.isNotEmpty
        ? searchResultData['data'].isNotEmpty
            ? Container(
                color: ColorsConfig().background(),
                child: ListView.builder(
                  itemCount: searchResultData['data'].isNotEmpty
                      ? searchResultData['data'].length + 1
                      : 0,
                  itemBuilder: (context, index) {
                    if (index < searchResultData['data'].length) {
                      if (index == 0) {
                        return Column(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.all(15.0),
                              child: CustomTextBuilder(
                                text: '‘${_controller.text}’ 검색 결과',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 18.0.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
                                border: index != searchResultData['data'].length
                                    ? Border(
                                        bottom: BorderSide(
                                          width: 0.5,
                                          color: ColorsConfig().border1(),
                                        ),
                                      )
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 유저 이미지, 닉네임, 날짜, 더보기 버튼
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20.0, 13.0, 20.0, 0.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 이미지
                                        InkWell(
                                          onTap: () {
                                            if (searchResultData['data'][index]
                                                ['isMe']) {
                                              Navigator.pushNamed(
                                                  context, '/my_profile',
                                                  arguments: {
                                                    'onNavigator': true,
                                                  });
                                            } else {
                                              Navigator.pushNamed(
                                                  context, '/your_profile',
                                                  arguments: {
                                                    'user_index':
                                                        searchResultData['data']
                                                                [index]
                                                            ['user_index'],
                                                    'user_nickname':
                                                        searchResultData['data']
                                                            [index]['nick'],
                                                  });
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42.0,
                                                height: 42.0,
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .userIconBackground(),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          21.0),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      searchResultData['data']
                                                          [index]['avatar_url'],
                                                      scale: 5.5,
                                                    ),
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    fit: BoxFit.none,
                                                    alignment: const Alignment(
                                                        0.0, -0.3),
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            82.0,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0),
                                                              child:
                                                                  CustomTextBuilder(
                                                                text:
                                                                    '${searchResultData['data'][index]['nick']}',
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textWhite1(),
                                                                fontSize:
                                                                    16.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            CustomTextBuilder(
                                                              text: DateCalculatorWrapper()
                                                                  .daysCalculator(
                                                                      searchResultData['data']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'date']),
                                                              fontColor:
                                                                  ColorsConfig()
                                                                      .textBlack2(),
                                                              fontSize: 12.0.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ],
                                                        ),
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 13.0),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical:
                                                                      3.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: searchResultData['data']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    1
                                                                ? ColorsConfig()
                                                                    .postLabel()
                                                                : searchResultData['data'][index]
                                                                            [
                                                                            'type'] ==
                                                                        2
                                                                    ? ColorsConfig()
                                                                        .analyticsLabel()
                                                                    : searchResultData['data'][index]['type'] ==
                                                                            3
                                                                        ? ColorsConfig()
                                                                            .debateLabel()
                                                                        : searchResultData['data'][index]['type'] ==
                                                                                4
                                                                            ? ColorsConfig().newsLabel()
                                                                            : searchResultData['data'][index]['type'] == 5
                                                                                ? ColorsConfig().voteLabel()
                                                                                : ColorsConfig.defaultWhite,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4.0),
                                                          ),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: searchResultData['data']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    1
                                                                ? '포스트'
                                                                : searchResultData['data'][index]
                                                                            [
                                                                            'type'] ==
                                                                        2
                                                                    ? '분 석'
                                                                    : searchResultData['data'][index]['type'] ==
                                                                            3
                                                                        ? '토 론'
                                                                        : searchResultData['data'][index]['type'] ==
                                                                                4
                                                                            ? '뉴 스'
                                                                            : searchResultData['data'][index]['type'] == 5
                                                                                ? '투 표'
                                                                                : '',
                                                            fontColor:
                                                                ColorsConfig
                                                                    .defaultWhite,
                                                            fontSize: 11.0.sp,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  !getSearchDataMoreBtnState[
                                                          index]
                                                      ? Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 4.0,
                                                                  top: 5.0),
                                                          child:
                                                              SingleChildScrollView(
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: Row(
                                                              children: [
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: List.generate(
                                                                      searchResultData['data'][index]['gift'].length >
                                                                              4
                                                                          ? 4
                                                                          : searchResultData['data'][index]['gift']
                                                                              .length,
                                                                      (giftIndex) {
                                                                    return Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Container(
                                                                            width:
                                                                                24.0,
                                                                            height:
                                                                                24.0,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(9.0),
                                                                            ),
                                                                            child:
                                                                                Image(
                                                                              image: NetworkImage(
                                                                                searchResultData['data'][index]['gift'][giftIndex]['image'],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          CustomTextBuilder(
                                                                            text:
                                                                                '${searchResultData['data'][index]['gift'][giftIndex]['gift_count']}',
                                                                            fontColor:
                                                                                ColorsConfig().textBlack2(),
                                                                            fontSize:
                                                                                12.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  }),
                                                                ),
                                                                !getSearchDataMoreBtnState[
                                                                            index] &&
                                                                        searchResultData['data'][index]['gift'].length >
                                                                            4
                                                                    ? InkWell(
                                                                        onTap:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            getSearchDataMoreBtnState[index] =
                                                                                true;
                                                                          });
                                                                        },
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 8.0),
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '...더보기',
                                                                            fontColor:
                                                                                ColorsConfig().textBlack2(),
                                                                            fontSize:
                                                                                14.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Container(),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 4.0,
                                                                  top: 5.0),
                                                          child: Wrap(
                                                            children: List.generate(
                                                                searchResultData['data']
                                                                            [
                                                                            index]
                                                                        ['gift']
                                                                    .length,
                                                                (giftIndex) {
                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            8.0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Container(
                                                                      width:
                                                                          24.0,
                                                                      height:
                                                                          24.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(9.0),
                                                                      ),
                                                                      child:
                                                                          Image(
                                                                        image:
                                                                            NetworkImage(
                                                                          searchResultData['data'][index]['gift'][giftIndex]
                                                                              [
                                                                              'image'],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    CustomTextBuilder(
                                                                      text:
                                                                          '${searchResultData['data'][index]['gift'][giftIndex]['gift_count']}',
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textBlack2(),
                                                                      fontSize:
                                                                          12.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }),
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 내용 부분
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: InkWell(
                                      onTap: () {
                                        if (searchResultData['data'][index]
                                                ['type'] ==
                                            4) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  NewsDetailScreen(
                                                postIndex:
                                                    searchResultData['data']
                                                        [index]['post_index'],
                                                postType:
                                                    searchResultData['data']
                                                        [index]['type'],
                                              ),
                                            ),
                                          ).then((returns) async {
                                            if (returns != null) {
                                              if (returns['ret']) {
                                                setState(() {
                                                  searchResultData['data']
                                                      .removeAt(index);
                                                  // currentPage.removeAt(index);
                                                });
                                              }
                                            } else {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              PostDetailDataAPI()
                                                  .detail(
                                                      accesToken:
                                                          _prefs.getString(
                                                              'AccessToken')!,
                                                      postIndex:
                                                          searchResultData[
                                                                  'data'][index]
                                                              ['post_index'])
                                                  .then((value) {
                                                setState(() {
                                                  searchResultData['data']
                                                      [index] = value.result;
                                                });
                                              });
                                            }
                                          });
                                        } else if (searchResultData['data']
                                                [index]['type'] ==
                                            5) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VoteDetailScreen(
                                                postIndex:
                                                    searchResultData['data']
                                                        [index]['post_index'],
                                                postType:
                                                    searchResultData['data']
                                                        [index]['type'],
                                              ),
                                            ),
                                          ).then((returns) async {
                                            if (returns != null) {
                                              if (returns['ret']) {
                                                setState(() {
                                                  searchResultData['data']
                                                      .removeAt(index);
                                                  // currentPage.removeAt(index);
                                                });
                                              }
                                            } else {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              PostDetailDataAPI()
                                                  .detail(
                                                      accesToken:
                                                          _prefs.getString(
                                                              'AccessToken')!,
                                                      postIndex:
                                                          searchResultData[
                                                                  'data'][index]
                                                              ['post_index'])
                                                  .then((value) {
                                                setState(() {
                                                  searchResultData['data']
                                                      [index] = value.result;
                                                });
                                              });
                                            }
                                          });
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PostingDetailScreen(
                                                postIndex:
                                                    searchResultData['data']
                                                        [index]['post_index'],
                                                postType:
                                                    searchResultData['data']
                                                        [index]['type'],
                                              ),
                                            ),
                                          ).then((returns) async {
                                            if (returns != null) {
                                              if (returns['ret']) {
                                                setState(() {
                                                  searchResultData['data']
                                                      .removeAt(index);
                                                  // currentPage.removeAt(index);
                                                });
                                              }
                                            } else {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              PostDetailDataAPI()
                                                  .detail(
                                                      accesToken:
                                                          _prefs.getString(
                                                              'AccessToken')!,
                                                      postIndex:
                                                          searchResultData[
                                                                  'data'][index]
                                                              ['post_index'])
                                                  .then((value) {
                                                setState(() {
                                                  searchResultData['data']
                                                      [index] = value.result;
                                                });
                                              });
                                            }
                                          });
                                        }
                                      },
                                      child:
                                          searchResultData['data'][index]
                                                      ['type'] ==
                                                  4
                                              ? Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 6.0),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        height: 75.0,
                                                        child: Column(
                                                          children: [
                                                            SizedBox(
                                                              width: (MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.75) -
                                                                  60.0,
                                                              child:
                                                                  CustomTextBuilder(
                                                                text:
                                                                    '${searchResultData['data'][index]['title']}',
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textWhite1(),
                                                                fontSize:
                                                                    19.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                maxLines: 2,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: (MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.75) -
                                                                  60.0,
                                                              child:
                                                                  CustomTextBuilder(
                                                                text:
                                                                    '${searchResultData['data'][index]['description']}',
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textBlack3(),
                                                                fontSize:
                                                                    17.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        width: (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.3) -
                                                            23.0,
                                                        height: 75.0,
                                                        color: ColorsConfig()
                                                            .textBlack2(),
                                                        child: Image(
                                                          image: NetworkImage(
                                                            searchResultData[
                                                                        'data']
                                                                    [index]
                                                                ['news_image'],
                                                          ),
                                                          fit: BoxFit.cover,
                                                          filterQuality:
                                                              FilterQuality
                                                                  .high,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : searchResultData['data'][index]
                                                              ['type'] ==
                                                          1 ||
                                                      searchResultData['data']
                                                              [index]['type'] ==
                                                          2 ||
                                                      searchResultData['data']
                                                              [index]['type'] ==
                                                          3
                                                  ? Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              top: 6.0),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          SizedBox(
                                                            height: 75.0,
                                                            child: Column(
                                                              children: [
                                                                SizedBox(
                                                                  width: searchResultData['data'][index]
                                                                              [
                                                                              'category'] !=
                                                                          null
                                                                      ? (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          56.0
                                                                      : MediaQuery.of(context)
                                                                              .size
                                                                              .width -
                                                                          40.0,
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text:
                                                                        '${searchResultData['data'][index]['title']}',
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textWhite1(),
                                                                    fontSize:
                                                                        19.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    maxLines: 2,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: searchResultData['data'][index]
                                                                              [
                                                                              'category'] !=
                                                                          null
                                                                      ? (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          56.0
                                                                      : MediaQuery.of(context)
                                                                              .size
                                                                              .width -
                                                                          40.0,
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text:
                                                                        '${searchResultData['data'][index]['description']}',
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textBlack3(),
                                                                    fontSize:
                                                                        17.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              searchResultData['data'][index]
                                                                              [
                                                                              'category'] !=
                                                                          null &&
                                                                      searchResultData['data'][index]
                                                                              [
                                                                              'category'] ==
                                                                          'i'
                                                                  ? SizedBox(
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.3) -
                                                                          23.0,
                                                                      height:
                                                                          75.0,
                                                                      child: searchResultData['data'][index]['image'].length >
                                                                              1
                                                                          ? PageView
                                                                              .builder(
                                                                              controller: _pageController,
                                                                              itemCount: searchResultData['data'][index]['image'].length,
                                                                              onPageChanged: (int page) {
                                                                                setState(() {
                                                                                  currentPage = page;
                                                                                });
                                                                              },
                                                                              itemBuilder: (context, imageIndex) {
                                                                                return Image(
                                                                                    image: NetworkImage(
                                                                                      searchResultData['data'][index]['image'][imageIndex],
                                                                                    ),
                                                                                    fit: BoxFit.cover,
                                                                                    filterQuality: FilterQuality.high,
                                                                                    alignment: Alignment.center);
                                                                              },
                                                                            )
                                                                          : SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                  image: NetworkImage(
                                                                                    searchResultData['data'][index]['image'][0],
                                                                                  ),
                                                                                  fit: BoxFit.cover,
                                                                                  filterQuality: FilterQuality.high,
                                                                                  alignment: Alignment.center),
                                                                            ),
                                                                    )
                                                                  : Container(),
                                                              searchResultData['data'][index]
                                                                              [
                                                                              'category'] !=
                                                                          null &&
                                                                      searchResultData['data'][index]
                                                                              [
                                                                              'category'] ==
                                                                          'g'
                                                                  ? SizedBox(
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.3) -
                                                                          23.0,
                                                                      height:
                                                                          75.0,
                                                                      child:
                                                                          Image(
                                                                        image:
                                                                            NetworkImage(
                                                                          searchResultData['data'][index]
                                                                              [
                                                                              'sub_link'],
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        filterQuality:
                                                                            FilterQuality.high,
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                              searchResultData['data'][index]
                                                                              [
                                                                              'category'] !=
                                                                          null &&
                                                                      searchResultData['data'][index]
                                                                              [
                                                                              'category'] ==
                                                                          'y'
                                                                  ? SizedBox(
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.3) -
                                                                          23.0,
                                                                      height:
                                                                          75.0,
                                                                      child:
                                                                          Image(
                                                                        image: NetworkImage(getYoutubeThumbnail(searchResultData['data'][index]
                                                                            [
                                                                            'sub_link'])),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        filterQuality:
                                                                            FilterQuality.high,
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : searchResultData['data']
                                                              [index]['type'] ==
                                                          5
                                                      ? Container(
                                                          width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 12.0,
                                                                  bottom: 4.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: searchResultData[
                                                                        'data']
                                                                    [index]
                                                                ['title'],
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 19.0.sp,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        )
                                                      : Container(),
                                    ),
                                  ),
                                  // 좋아요, 댓글, 더보기 버튼
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 좋아요
                                      MaterialButton(
                                        onPressed: () async {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          if (searchResultData['data'][index]
                                                  ['isLike'] ==
                                              false) {
                                            AddLikeSenderAPI()
                                                .add(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    postIndex:
                                                        searchResultData['data']
                                                                [index]
                                                            ['post_index'])
                                                .then((res) {
                                              if (res.result['status'] ==
                                                  10800) {
                                                setState(() {
                                                  searchResultData['data']
                                                      [index]['like']++;
                                                  searchResultData['data']
                                                      [index]['isLike'] = true;
                                                });
                                              }
                                            });
                                          } else {
                                            CancelLikeSenderAPI()
                                                .cancel(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    postIndex:
                                                        searchResultData['data']
                                                                [index]
                                                            ['post_index'])
                                                .then((res) {
                                              if (res.result['status'] ==
                                                  10805) {
                                                setState(() {
                                                  searchResultData['data']
                                                      [index]['like']--;
                                                  searchResultData['data']
                                                      [index]['isLike'] = false;
                                                });
                                              }
                                            });
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            SvgAssets(
                                              image: 'assets/icon/like.svg',
                                              color: searchResultData['data']
                                                      [index]['isLike']
                                                  ? ColorsConfig().primary()
                                                  : ColorsConfig().textBlack1(),
                                              width: 18.0,
                                              height: 18.0,
                                            ),
                                            const SizedBox(width: 10.0),
                                            CustomTextBuilder(
                                              text: numberFormat.format(
                                                  searchResultData['data']
                                                          [index]['like'] +
                                                      addLikeCount),
                                              fontColor:
                                                  ColorsConfig().textBlack1(),
                                              fontSize: 13.0.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 댓글
                                      MaterialButton(
                                        onPressed: () {
                                          if (searchResultData['data'][index]
                                                  ['type'] ==
                                              4) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NewsDetailScreen(
                                                  postIndex:
                                                      searchResultData['data']
                                                          [index]['post_index'],
                                                  postType:
                                                      searchResultData['data']
                                                          [index]['type'],
                                                ),
                                              ),
                                            ).then((returns) async {
                                              if (returns != null) {
                                                if (returns['ret']) {
                                                  setState(() {
                                                    searchResultData['data']
                                                        .removeAt(index);
                                                    // currentPage.removeAt(index);
                                                  });
                                                }
                                              } else {
                                                final _prefs =
                                                    await SharedPreferences
                                                        .getInstance();

                                                PostDetailDataAPI()
                                                    .detail(
                                                        accesToken: _prefs
                                                            .getString(
                                                                'AccessToken')!,
                                                        postIndex:
                                                            searchResultData[
                                                                        'data']
                                                                    [index]
                                                                ['post_index'])
                                                    .then((value) {
                                                  setState(() {
                                                    searchResultData['data']
                                                        [index] = value.result;
                                                  });
                                                });
                                              }
                                            });
                                          } else if (searchResultData['data']
                                                  [index]['type'] ==
                                              5) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VoteDetailScreen(
                                                  postIndex:
                                                      searchResultData['data']
                                                          [index]['post_index'],
                                                  postType:
                                                      searchResultData['data']
                                                          [index]['type'],
                                                ),
                                              ),
                                            ).then((returns) async {
                                              if (returns != null) {
                                                if (returns['ret']) {
                                                  setState(() {
                                                    searchResultData['data']
                                                        .removeAt(index);
                                                    // currentPage.removeAt(index);
                                                  });
                                                }
                                              } else {
                                                final _prefs =
                                                    await SharedPreferences
                                                        .getInstance();

                                                PostDetailDataAPI()
                                                    .detail(
                                                        accesToken: _prefs
                                                            .getString(
                                                                'AccessToken')!,
                                                        postIndex:
                                                            searchResultData[
                                                                        'data']
                                                                    [index]
                                                                ['post_index'])
                                                    .then((value) {
                                                  setState(() {
                                                    searchResultData['data']
                                                        [index] = value.result;
                                                  });
                                                });
                                              }
                                            });
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PostingDetailScreen(
                                                  postIndex:
                                                      searchResultData['data']
                                                          [index]['post_index'],
                                                  postType:
                                                      searchResultData['data']
                                                          [index]['type'],
                                                ),
                                              ),
                                            ).then((returns) async {
                                              if (returns != null) {
                                                if (returns['ret']) {
                                                  setState(() {
                                                    searchResultData['data']
                                                        .removeAt(index);
                                                    // currentPage.removeAt(index);
                                                  });
                                                }
                                              } else {
                                                final _prefs =
                                                    await SharedPreferences
                                                        .getInstance();

                                                PostDetailDataAPI()
                                                    .detail(
                                                        accesToken: _prefs
                                                            .getString(
                                                                'AccessToken')!,
                                                        postIndex:
                                                            searchResultData[
                                                                        'data']
                                                                    [index]
                                                                ['post_index'])
                                                    .then((value) {
                                                  setState(() {
                                                    searchResultData['data']
                                                        [index] = value.result;
                                                  });
                                                });
                                              }
                                            });
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgAssets(
                                              image: 'assets/icon/reply.svg',
                                              color:
                                                  ColorsConfig().textBlack1(),
                                              width: 18.0,
                                              height: 18.0,
                                            ),
                                            const SizedBox(width: 10.0),
                                            CustomTextBuilder(
                                              text: numberFormat.format(
                                                  searchResultData['data']
                                                      [index]['reply']),
                                              fontColor:
                                                  ColorsConfig().textBlack1(),
                                              fontSize: 13.0.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 선물
                                      MaterialButton(
                                        onPressed: () async {
                                          if (searchResultData['data'][index]
                                              ['isMe']) {
                                            ToastBuilder().toast(
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                padding:
                                                    const EdgeInsets.all(14.0),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 30.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig
                                                      .defaultToast
                                                      .withOpacity(0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.0),
                                                ),
                                                child: CustomTextBuilder(
                                                  text: '자신에게는 선물할 수 없습니다',
                                                  fontColor:
                                                      ColorsConfig.defaultWhite,
                                                  fontSize: 14.0.sp,
                                                ),
                                              ),
                                            );
                                          } else {
                                            final _prefs =
                                                await SharedPreferences
                                                    .getInstance();

                                            GetGiftListDataAPI()
                                                .gift(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!)
                                                .then((gifts) {
                                              bool _hasClick = false;

                                              showModalBottomSheet(
                                                  context: context,
                                                  backgroundColor:
                                                      ColorsConfig()
                                                          .subBackground1(),
                                                  isScrollControlled: true,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(12.0),
                                                      topRight:
                                                          Radius.circular(12.0),
                                                    ),
                                                  ),
                                                  builder:
                                                      (BuildContext context) {
                                                    int _giftTabIndex = 0;

                                                    List<dynamic> _trophy = [];
                                                    List<dynamic> _reaction =
                                                        [];
                                                    List<dynamic> _neckTrophy =
                                                        [];

                                                    Map<String, dynamic>
                                                        _selectedGift = {};

                                                    var _giftTabController =
                                                        TabController(
                                                      length: 4,
                                                      vsync: this,
                                                    );
                                                    _giftTabController
                                                        .addListener(() {
                                                      if (_giftTabController
                                                              .indexIsChanging ||
                                                          _giftTabController
                                                                  .index !=
                                                              _giftTabIndex) {
                                                        setState(() {
                                                          _giftTabIndex =
                                                              _giftTabController
                                                                  .index;
                                                        });
                                                      }
                                                    });

                                                    for (int i = 0;
                                                        i < gifts.result.length;
                                                        i++) {
                                                      if (gifts.result[i]
                                                              ['item_type'] ==
                                                          0) {
                                                        _trophy.add(
                                                            gifts.result[i]);
                                                      } else if (gifts.result[i]
                                                              ['item_type'] ==
                                                          1) {
                                                        _reaction.add(
                                                            gifts.result[i]);
                                                      } else if (gifts.result[i]
                                                              ['item_type'] ==
                                                          2) {
                                                        _neckTrophy.add(
                                                            gifts.result[i]);
                                                      }
                                                    }

                                                    return StatefulBuilder(
                                                      builder:
                                                          (context, state) {
                                                        return Container(
                                                          height: _hasClick
                                                              ? MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height /
                                                                  1.72
                                                              : MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height /
                                                                  2,
                                                          decoration:
                                                              const BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(
                                                                      12.0),
                                                              topRight: Radius
                                                                  .circular(
                                                                      12.0),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              Container(
                                                                width: 50.0,
                                                                height: 4.0,
                                                                margin: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        8.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: ColorsConfig()
                                                                      .textBlack2(),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              100.0),
                                                                ),
                                                              ),
                                                              // 선물하기 타이틀
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .fromLTRB(
                                                                        20.0,
                                                                        15.0,
                                                                        20.0,
                                                                        10.0),
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text:
                                                                          '선물하기',
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textWhite1(),
                                                                      fontSize:
                                                                          22.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            15.0),
                                                                    child:
                                                                        const HoldingBalanceWidget(),
                                                                  ),
                                                                ],
                                                              ),
                                                              // 탭바
                                                              Container(
                                                                width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border:
                                                                      Border(
                                                                    bottom:
                                                                        BorderSide(
                                                                      width:
                                                                          0.5,
                                                                      color: ColorsConfig()
                                                                          .border1(),
                                                                    ),
                                                                  ),
                                                                ),
                                                                child: TabBar(
                                                                  controller:
                                                                      _giftTabController,
                                                                  isScrollable:
                                                                      true,
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          20.0),
                                                                  indicatorColor:
                                                                      ColorsConfig()
                                                                          .primary(),
                                                                  unselectedLabelColor:
                                                                      ColorsConfig()
                                                                          .textWhite1(),
                                                                  unselectedLabelStyle:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                  labelColor:
                                                                      ColorsConfig()
                                                                          .primary(),
                                                                  labelStyle:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                  onTap: (_) {
                                                                    state(() {
                                                                      _hasClick =
                                                                          false;
                                                                      _selectedGift =
                                                                          {};
                                                                    });
                                                                  },
                                                                  tabs: [
                                                                    Tab(
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '전체',
                                                                      ),
                                                                    ),
                                                                    Tab(
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '트로피',
                                                                      ),
                                                                    ),
                                                                    Tab(
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '리액션',
                                                                      ),
                                                                    ),
                                                                    Tab(
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '메달',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: !_hasClick
                                                                      ? const EdgeInsets
                                                                          .fromLTRB(
                                                                          25.0,
                                                                          25.0,
                                                                          15.0,
                                                                          20.0)
                                                                      : const EdgeInsets
                                                                          .fromLTRB(
                                                                          25.0,
                                                                          25.0,
                                                                          15.0,
                                                                          0.0),
                                                                  child:
                                                                      TabBarView(
                                                                    controller:
                                                                        _giftTabController,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    children: [
                                                                      ListView(
                                                                        children: [
                                                                          Wrap(
                                                                            children:
                                                                                List.generate(gifts.result.length, (index) {
                                                                              return InkWell(
                                                                                splashColor: ColorsConfig.transparent,
                                                                                highlightColor: ColorsConfig.transparent,
                                                                                onTap: () {
                                                                                  state(() {
                                                                                    if (_hasClick && _selectedGift['index'] == index) {
                                                                                      _hasClick = false;
                                                                                      _selectedGift = {};
                                                                                    } else {
                                                                                      _hasClick = true;
                                                                                      _selectedGift = {
                                                                                        "index": index,
                                                                                        "item_index": gifts.result[index]['item_index'],
                                                                                        "item_type": gifts.result[index]['item_type'],
                                                                                        "item_type_name": gifts.result[index]['item_type_name'],
                                                                                        "url": gifts.result[index]['url'],
                                                                                        "description": gifts.result[index]['description'],
                                                                                        "price": gifts.result[index]['price'],
                                                                                      };
                                                                                    }
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  margin: EdgeInsets.only(right: 10.0.w),
                                                                                  decoration: BoxDecoration(
                                                                                    color: _selectedGift['index'] == index && _giftTabIndex == 0 ? ColorsConfig().subBackgroundBlack() : null,
                                                                                    borderRadius: BorderRadius.circular(14.0),
                                                                                  ),
                                                                                  child: Column(
                                                                                    children: [
                                                                                      Image(
                                                                                        image: NetworkImage(
                                                                                          gifts.result[index]['url'],
                                                                                        ),
                                                                                        filterQuality: FilterQuality.high,
                                                                                        width: 65.0.w,
                                                                                        height: 65.0.h,
                                                                                      ),
                                                                                      Container(
                                                                                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '${gifts.result[index]['price']}',
                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                          fontSize: 12.0.sp,
                                                                                          fontWeight: FontWeight.w400,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            }),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      ListView(
                                                                        children: [
                                                                          Wrap(
                                                                            children:
                                                                                List.generate(_trophy.length, (index) {
                                                                              return InkWell(
                                                                                splashColor: ColorsConfig.transparent,
                                                                                highlightColor: ColorsConfig.transparent,
                                                                                onTap: () {
                                                                                  state(() {
                                                                                    if (_hasClick && _selectedGift['index'] == index) {
                                                                                      _hasClick = false;
                                                                                      _selectedGift = {};
                                                                                    } else {
                                                                                      _hasClick = true;
                                                                                      _selectedGift = {
                                                                                        "index": index,
                                                                                        "item_index": _trophy[index]['item_index'],
                                                                                        "item_type": _trophy[index]['item_type'],
                                                                                        "item_type_name": _trophy[index]['item_type_name'],
                                                                                        "url": _trophy[index]['url'],
                                                                                        "description": _trophy[index]['description'],
                                                                                        "price": _trophy[index]['price'],
                                                                                      };
                                                                                    }
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  margin: EdgeInsets.only(right: 10.0.w),
                                                                                  decoration: BoxDecoration(
                                                                                    color: _selectedGift['index'] == index && _giftTabIndex == 1 ? ColorsConfig().subBackgroundBlack() : null,
                                                                                    borderRadius: BorderRadius.circular(14.0),
                                                                                  ),
                                                                                  child: _trophy[index]['item_type'] == 0
                                                                                      ? Column(
                                                                                          children: [
                                                                                            Image(
                                                                                              image: NetworkImage(
                                                                                                _trophy[index]['url'],
                                                                                              ),
                                                                                              filterQuality: FilterQuality.high,
                                                                                              width: 65.0.w,
                                                                                              height: 65.0.h,
                                                                                            ),
                                                                                            Container(
                                                                                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                              child: CustomTextBuilder(
                                                                                                text: '${_trophy[index]['price']}',
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 12.0.sp,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        )
                                                                                      : null,
                                                                                ),
                                                                              );
                                                                            }),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      ListView(
                                                                        children: [
                                                                          Wrap(
                                                                            children:
                                                                                List.generate(_reaction.length, (index) {
                                                                              return InkWell(
                                                                                splashColor: ColorsConfig.transparent,
                                                                                highlightColor: ColorsConfig.transparent,
                                                                                onTap: () {
                                                                                  state(() {
                                                                                    if (_hasClick && _selectedGift['index'] == index) {
                                                                                      _hasClick = false;
                                                                                      _selectedGift = {};
                                                                                    } else {
                                                                                      _hasClick = true;
                                                                                      _selectedGift = {
                                                                                        "index": index,
                                                                                        "item_index": _reaction[index]['item_index'],
                                                                                        "item_type": _reaction[index]['item_type'],
                                                                                        "item_type_name": _reaction[index]['item_type_name'],
                                                                                        "url": _reaction[index]['url'],
                                                                                        "description": _reaction[index]['description'],
                                                                                        "price": _reaction[index]['price'],
                                                                                      };
                                                                                    }
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  margin: EdgeInsets.only(right: 10.0.w),
                                                                                  decoration: BoxDecoration(
                                                                                    color: _selectedGift['index'] == index && _giftTabIndex == 2 ? ColorsConfig().subBackgroundBlack() : null,
                                                                                    borderRadius: BorderRadius.circular(14.0),
                                                                                  ),
                                                                                  child: _reaction[index]['item_type'] == 1
                                                                                      ? Column(
                                                                                          children: [
                                                                                            Image(
                                                                                              image: NetworkImage(
                                                                                                _reaction[index]['url'],
                                                                                              ),
                                                                                              filterQuality: FilterQuality.high,
                                                                                              width: 65.0.w,
                                                                                              height: 65.0.h,
                                                                                            ),
                                                                                            Container(
                                                                                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                              child: CustomTextBuilder(
                                                                                                text: '${_reaction[index]['price']}',
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 12.0.sp,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        )
                                                                                      : null,
                                                                                ),
                                                                              );
                                                                            }),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      ListView(
                                                                        children: [
                                                                          Wrap(
                                                                            children:
                                                                                List.generate(_neckTrophy.length, (index) {
                                                                              return InkWell(
                                                                                splashColor: ColorsConfig.transparent,
                                                                                highlightColor: ColorsConfig.transparent,
                                                                                onTap: () {
                                                                                  state(() {
                                                                                    if (_hasClick && _selectedGift['index'] == index) {
                                                                                      _hasClick = false;
                                                                                      _selectedGift = {};
                                                                                    } else {
                                                                                      _hasClick = true;
                                                                                      _selectedGift = {
                                                                                        "index": index,
                                                                                        "item_index": _neckTrophy[index]['item_index'],
                                                                                        "item_type": _neckTrophy[index]['item_type'],
                                                                                        "item_type_name": _neckTrophy[index]['item_type_name'],
                                                                                        "url": _neckTrophy[index]['url'],
                                                                                        "description": _neckTrophy[index]['description'],
                                                                                        "price": _neckTrophy[index]['price'],
                                                                                      };
                                                                                    }
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  margin: EdgeInsets.only(right: 10.0.w),
                                                                                  decoration: BoxDecoration(
                                                                                    color: _selectedGift['index'] == index && _giftTabIndex == 3 ? ColorsConfig().subBackgroundBlack() : null,
                                                                                    borderRadius: BorderRadius.circular(14.0),
                                                                                  ),
                                                                                  child: _neckTrophy[index]['item_type'] == 2
                                                                                      ? Column(
                                                                                          children: [
                                                                                            Image(
                                                                                              image: NetworkImage(
                                                                                                _neckTrophy[index]['url'],
                                                                                              ),
                                                                                              filterQuality: FilterQuality.high,
                                                                                              width: 65.0.w,
                                                                                              height: 65.0.h,
                                                                                            ),
                                                                                            Container(
                                                                                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                              child: CustomTextBuilder(
                                                                                                text: '${_neckTrophy[index]['price']}',
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 12.0.sp,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        )
                                                                                      : null,
                                                                                ),
                                                                              );
                                                                            }),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              _hasClick == true
                                                                  ? Container(
                                                                      height:
                                                                          157.0,
                                                                      padding: const EdgeInsets
                                                                          .fromLTRB(
                                                                          20.0,
                                                                          10.0,
                                                                          20.0,
                                                                          30.0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: ColorsConfig()
                                                                            .subBackground1(),
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color:
                                                                                ColorsConfig().textWhite1(opacity: 0.16),
                                                                            blurRadius:
                                                                                10.0,
                                                                            offset:
                                                                                const Offset(0.0, -2.0),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Image(
                                                                                image: NetworkImage(
                                                                                  '${_selectedGift['url']}',
                                                                                ),
                                                                                filterQuality: FilterQuality.high,
                                                                                width: 65.0.w,
                                                                                height: 65.0.h,
                                                                              ),
                                                                              const SizedBox(width: 32.0),
                                                                              Column(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  CustomTextBuilder(
                                                                                    text: '${_selectedGift['description']}',
                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                    fontSize: 16.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                  CustomTextBuilder(
                                                                                    text: numberFormat.format(_selectedGift['price']),
                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                    fontSize: 12.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 10.0),
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              if (_selectedGift['price'] == 0) {
                                                                                SendGiftDataAPI().gift(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], postIndex: searchResultData['data'][index]['post_index']).then((value) {
                                                                                  int? _existIndex;

                                                                                  switch (value.result['status']) {
                                                                                    case 10200:
                                                                                      setState(() {
                                                                                        if (searchResultData['data'][index]['gift'].length == 0) {
                                                                                          searchResultData['data'][index]['gift'].add({
                                                                                            "image": _selectedGift['url'],
                                                                                            "gift_count": 1,
                                                                                          });
                                                                                        } else {
                                                                                          for (int i = 0; i < searchResultData['data'][index]['gift'].length; i++) {
                                                                                            if (searchResultData['data'][index]['gift'][i]['image'].contains(_selectedGift['url'])) {
                                                                                              _existIndex = i;
                                                                                              break;
                                                                                            }
                                                                                          }

                                                                                          if (_existIndex != null) {
                                                                                            searchResultData['data'][index]['gift'][_existIndex]['gift_count'] = searchResultData['data'][index]['gift'][_existIndex]['gift_count'] + 1;
                                                                                          } else {
                                                                                            searchResultData['data'][index]['gift'].insert(0, {
                                                                                              "image": _selectedGift['url'],
                                                                                              "gift_count": 1,
                                                                                            });
                                                                                          }
                                                                                        }
                                                                                      });
                                                                                      Navigator.pop(context);
                                                                                      break;
                                                                                    case 10201:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '자신에게는 선물할 수 없습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10202:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '해당 글이 존재하지 않습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10203:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '해당 아이템이 존재하지 않습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10204:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '유료 아이템을 선물할 수 없습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                  }
                                                                                });
                                                                              } else {
                                                                                SendPricedGiftDataAPI().pricedGift(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], postIndex: searchResultData['data'][index]['post_index']).then((value) {
                                                                                  int? _existIndex;

                                                                                  switch (value.result['status']) {
                                                                                    case 10201:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '자신에게는 선물할 수 없습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10202:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '해당 글이 존재하지 않습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10203:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '해당 아이템이 존재하지 않습니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10210:
                                                                                      setState(() {
                                                                                        if (searchResultData['data'][index]['gift'].length == 0) {
                                                                                          searchResultData['data'][index]['gift'].add({
                                                                                            "image": _selectedGift['url'],
                                                                                            "gift_count": 1,
                                                                                          });
                                                                                        } else {
                                                                                          for (int i = 0; i < searchResultData['data'][index]['gift'].length; i++) {
                                                                                            if (searchResultData['data'][index]['gift'][i]['image'].contains(_selectedGift['url'])) {
                                                                                              _existIndex = i;
                                                                                              break;
                                                                                            }
                                                                                          }

                                                                                          if (_existIndex != null) {
                                                                                            searchResultData['data'][index]['gift'][_existIndex]['gift_count'] = searchResultData['data'][index]['gift'][_existIndex]['gift_count'] + 1;
                                                                                          } else {
                                                                                            searchResultData['data'][index]['gift'].insert(0, {
                                                                                              "image": _selectedGift['url'],
                                                                                              "gift_count": 1,
                                                                                            });
                                                                                          }
                                                                                        }
                                                                                      });
                                                                                      Navigator.pop(context);
                                                                                      break;
                                                                                    case 10211:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '유료 아이템이 아닙니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                    case 10212:
                                                                                      ToastBuilder().toast(
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.all(14.0),
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '보유하신 포인트가 부족합니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                  }
                                                                                });
                                                                              }
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              width: MediaQuery.of(context).size.width,
                                                                              height: 42.0,
                                                                              decoration: BoxDecoration(
                                                                                // color: ColorsConfig().primary(),
                                                                                borderRadius: BorderRadius.circular(100.0),
                                                                                gradient: LinearGradient(
                                                                                  colors: [
                                                                                    ColorsConfig().avatarButtonBackground1(),
                                                                                    ColorsConfig().avatarButtonBackground2(),
                                                                                  ],
                                                                                  begin: Alignment.centerLeft,
                                                                                  end: Alignment.centerRight,
                                                                                ),
                                                                              ),
                                                                              child: Center(
                                                                                child: CustomTextBuilder(
                                                                                  text: '보내기',
                                                                                  fontColor: ColorsConfig().background(),
                                                                                  fontSize: 16.0.sp,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  });
                                            });
                                          }
                                        },
                                        child: SvgAssets(
                                          image: 'assets/icon/gift.svg',
                                          color: ColorsConfig().textBlack1(),
                                          width: 18.0,
                                          height: 18.0,
                                        ),
                                      ),
                                      // 공유
                                      MaterialButton(
                                        onPressed: () async {
                                          var shortLink = await DeepLinkBuilder()
                                              .getShortLink(
                                                  'share',
                                                  '${searchResultData['data'][index]['post_index']}',
                                                  searchResultData['data']
                                                      [index]['type']);

                                          Share.share(
                                            '${searchResultData['data'][index]['title']}\n$shortLink',
                                            sharePositionOrigin: Rect.fromLTWH(
                                                0,
                                                0,
                                                MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2),
                                          );
                                        },
                                        child: SvgAssets(
                                          image: 'assets/icon/share.svg',
                                          color: ColorsConfig().textBlack1(),
                                          width: 18.0,
                                          height: 18.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: ColorsConfig().subBackground1(),
                          border: index != searchResultData['data'].length
                              ? Border(
                                  bottom: BorderSide(
                                    width: 0.5,
                                    color: ColorsConfig().border1(),
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 유저 이미지, 닉네임, 날짜, 더보기 버튼
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20.0, 13.0, 20.0, 0.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 이미지
                                  InkWell(
                                    onTap: () {
                                      if (searchResultData['data'][index]
                                          ['isMe']) {
                                        Navigator.pushNamed(
                                            context, '/my_profile',
                                            arguments: {
                                              'onNavigator': true,
                                            });
                                      } else {
                                        Navigator.pushNamed(
                                            context, '/your_profile',
                                            arguments: {
                                              'user_index':
                                                  searchResultData['data']
                                                      [index]['user_index'],
                                              'user_nickname':
                                                  searchResultData['data']
                                                      [index]['nick'],
                                            });
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42.0,
                                          height: 42.0,
                                          decoration: BoxDecoration(
                                            color: ColorsConfig()
                                                .userIconBackground(),
                                            borderRadius:
                                                BorderRadius.circular(21.0),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                searchResultData['data'][index]
                                                    ['avatar_url'],
                                                scale: 5.5,
                                              ),
                                              filterQuality: FilterQuality.high,
                                              fit: BoxFit.none,
                                              alignment:
                                                  const Alignment(0.0, -0.3),
                                            ),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  82.0,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8.0),
                                                        child:
                                                            CustomTextBuilder(
                                                          text:
                                                              '${searchResultData['data'][index]['nick']}',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textWhite1(),
                                                          fontSize: 16.0.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      CustomTextBuilder(
                                                        text: DateCalculatorWrapper()
                                                            .daysCalculator(
                                                                searchResultData[
                                                                            'data']
                                                                        [index]
                                                                    ['date']),
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textBlack2(),
                                                        fontSize: 12.0.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            left: 13.0),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 3.0),
                                                    decoration: BoxDecoration(
                                                      color: searchResultData['data']
                                                                      [index]
                                                                  ['type'] ==
                                                              1
                                                          ? ColorsConfig()
                                                              .postLabel()
                                                          : searchResultData['data']
                                                                          [index][
                                                                      'type'] ==
                                                                  2
                                                              ? ColorsConfig()
                                                                  .analyticsLabel()
                                                              : searchResultData['data']
                                                                              [index][
                                                                          'type'] ==
                                                                      3
                                                                  ? ColorsConfig()
                                                                      .debateLabel()
                                                                  : searchResultData['data'][index]['type'] ==
                                                                          4
                                                                      ? ColorsConfig()
                                                                          .newsLabel()
                                                                      : searchResultData['data'][index]['type'] ==
                                                                              5
                                                                          ? ColorsConfig().voteLabel()
                                                                          : ColorsConfig.defaultWhite,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.0),
                                                    ),
                                                    child: CustomTextBuilder(
                                                      text: searchResultData['data']
                                                                      [index]
                                                                  ['type'] ==
                                                              1
                                                          ? '포스트'
                                                          : searchResultData['data']
                                                                          [index]
                                                                      [
                                                                      'type'] ==
                                                                  2
                                                              ? '분 석'
                                                              : searchResultData['data']
                                                                              [index]
                                                                          [
                                                                          'type'] ==
                                                                      3
                                                                  ? '토 론'
                                                                  : searchResultData['data'][index]
                                                                              ['type'] ==
                                                                          4
                                                                      ? '뉴 스'
                                                                      : searchResultData['data'][index]['type'] == 5
                                                                          ? '투 표'
                                                                          : '',
                                                      fontColor: ColorsConfig
                                                          .defaultWhite,
                                                      fontSize: 11.0.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            !getSearchDataMoreBtnState[index]
                                                ? Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            left: 4.0,
                                                            top: 5.0),
                                                    child:
                                                        SingleChildScrollView(
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: List.generate(
                                                                searchResultData['data'][index]['gift']
                                                                            .length >
                                                                        4
                                                                    ? 4
                                                                    : searchResultData['data'][index]
                                                                            [
                                                                            'gift']
                                                                        .length,
                                                                (giftIndex) {
                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            8.0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Container(
                                                                      width:
                                                                          24.0,
                                                                      height:
                                                                          24.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(9.0),
                                                                      ),
                                                                      child:
                                                                          Image(
                                                                        image:
                                                                            NetworkImage(
                                                                          searchResultData['data'][index]['gift'][giftIndex]
                                                                              [
                                                                              'image'],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    CustomTextBuilder(
                                                                      text:
                                                                          '${searchResultData['data'][index]['gift'][giftIndex]['gift_count']}',
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textBlack2(),
                                                                      fontSize:
                                                                          12.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }),
                                                          ),
                                                          !getSearchDataMoreBtnState[
                                                                      index] &&
                                                                  searchResultData['data'][index]
                                                                              [
                                                                              'gift']
                                                                          .length >
                                                                      4
                                                              ? InkWell(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      getSearchDataMoreBtnState[
                                                                              index] =
                                                                          true;
                                                                    });
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            8.0),
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text:
                                                                          '...더보기',
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textBlack2(),
                                                                      fontSize:
                                                                          14.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            left: 4.0,
                                                            top: 5.0),
                                                    child: Wrap(
                                                      children: List.generate(
                                                          searchResultData[
                                                                      'data'][
                                                                  index]['gift']
                                                              .length,
                                                          (giftIndex) {
                                                        return Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8.0),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Container(
                                                                width: 24.0,
                                                                height: 24.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              9.0),
                                                                ),
                                                                child: Image(
                                                                  image:
                                                                      NetworkImage(
                                                                    searchResultData['data'][index]['gift']
                                                                            [
                                                                            giftIndex]
                                                                        [
                                                                        'image'],
                                                                  ),
                                                                ),
                                                              ),
                                                              CustomTextBuilder(
                                                                text:
                                                                    '${searchResultData['data'][index]['gift'][giftIndex]['gift_count']}',
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textBlack2(),
                                                                fontSize:
                                                                    12.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 내용 부분
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: InkWell(
                                onTap: () {
                                  if (searchResultData['data'][index]['type'] ==
                                      4) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NewsDetailScreen(
                                          postIndex: searchResultData['data']
                                              [index]['post_index'],
                                          postType: searchResultData['data']
                                              [index]['type'],
                                        ),
                                      ),
                                    ).then((returns) async {
                                      if (returns != null) {
                                        if (returns['ret']) {
                                          setState(() {
                                            searchResultData['data']
                                                .removeAt(index);
                                            // currentPage.removeAt(index);
                                          });
                                        }
                                      } else {
                                        final _prefs = await SharedPreferences
                                            .getInstance();

                                        PostDetailDataAPI()
                                            .detail(
                                                accesToken: _prefs
                                                    .getString('AccessToken')!,
                                                postIndex:
                                                    searchResultData['data']
                                                        [index]['post_index'])
                                            .then((value) {
                                          setState(() {
                                            searchResultData['data'][index] =
                                                value.result;
                                          });
                                        });
                                      }
                                    });
                                  } else if (searchResultData['data'][index]
                                          ['type'] ==
                                      5) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VoteDetailScreen(
                                          postIndex: searchResultData['data']
                                              [index]['post_index'],
                                          postType: searchResultData['data']
                                              [index]['type'],
                                        ),
                                      ),
                                    ).then((returns) async {
                                      if (returns != null) {
                                        if (returns['ret']) {
                                          setState(() {
                                            searchResultData['data']
                                                .removeAt(index);
                                            // currentPage.removeAt(index);
                                          });
                                        }
                                      } else {
                                        final _prefs = await SharedPreferences
                                            .getInstance();

                                        PostDetailDataAPI()
                                            .detail(
                                                accesToken: _prefs
                                                    .getString('AccessToken')!,
                                                postIndex:
                                                    searchResultData['data']
                                                        [index]['post_index'])
                                            .then((value) {
                                          setState(() {
                                            searchResultData['data'][index] =
                                                value.result;
                                          });
                                        });
                                      }
                                    });
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PostingDetailScreen(
                                          postIndex: searchResultData['data']
                                              [index]['post_index'],
                                          postType: searchResultData['data']
                                              [index]['type'],
                                        ),
                                      ),
                                    ).then((returns) async {
                                      if (returns != null) {
                                        if (returns['ret']) {
                                          setState(() {
                                            searchResultData['data']
                                                .removeAt(index);
                                            // currentPage.removeAt(index);
                                          });
                                        }
                                      } else {
                                        final _prefs = await SharedPreferences
                                            .getInstance();

                                        PostDetailDataAPI()
                                            .detail(
                                                accesToken: _prefs
                                                    .getString('AccessToken')!,
                                                postIndex:
                                                    searchResultData['data']
                                                        [index]['post_index'])
                                            .then((value) {
                                          setState(() {
                                            searchResultData['data'][index] =
                                                value.result;
                                          });
                                        });
                                      }
                                    });
                                  }
                                },
                                child: searchResultData['data'][index]
                                            ['type'] ==
                                        4
                                    ? Container(
                                        margin: const EdgeInsets.only(top: 6.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              height: 75.0,
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width *
                                                                0.75) -
                                                            60.0,
                                                    child: CustomTextBuilder(
                                                      text:
                                                          '${searchResultData['data'][index]['title']}',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 19.0.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width *
                                                                0.75) -
                                                            60.0,
                                                    child: CustomTextBuilder(
                                                      text:
                                                          '${searchResultData['data'][index]['description']}',
                                                      fontColor: ColorsConfig()
                                                          .textBlack3(),
                                                      fontSize: 17.0.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.3) -
                                                  23.0,
                                              height: 75.0,
                                              color:
                                                  ColorsConfig().textBlack2(),
                                              child: Image(
                                                image: NetworkImage(
                                                  searchResultData['data']
                                                      [index]['news_image'],
                                                ),
                                                fit: BoxFit.cover,
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : searchResultData['data'][index]
                                                    ['type'] ==
                                                1 ||
                                            searchResultData['data'][index]
                                                    ['type'] ==
                                                2 ||
                                            searchResultData['data'][index]
                                                    ['type'] ==
                                                3
                                        ? Container(
                                            margin:
                                                const EdgeInsets.only(top: 6.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  height: 75.0,
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        width: searchResultData[
                                                                            'data']
                                                                        [index][
                                                                    'category'] !=
                                                                null
                                                            ? (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.75) -
                                                                56.0
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width -
                                                                40.0,
                                                        child:
                                                            CustomTextBuilder(
                                                          text:
                                                              '${searchResultData['data'][index]['title']}',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textWhite1(),
                                                          fontSize: 19.0.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: searchResultData[
                                                                            'data']
                                                                        [index][
                                                                    'category'] !=
                                                                null
                                                            ? (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.75) -
                                                                56.0
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width -
                                                                40.0,
                                                        child:
                                                            CustomTextBuilder(
                                                          text:
                                                              '${searchResultData['data'][index]['description']}',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack3(),
                                                          fontSize: 17.0.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    searchResultData['data']
                                                                        [index][
                                                                    'category'] !=
                                                                null &&
                                                            searchResultData[
                                                                            'data']
                                                                        [index][
                                                                    'category'] ==
                                                                'i'
                                                        ? SizedBox(
                                                            width: (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.3) -
                                                                23.0,
                                                            height: 75.0,
                                                            child: searchResultData['data'][index]
                                                                            [
                                                                            'image']
                                                                        .length >
                                                                    1
                                                                ? PageView
                                                                    .builder(
                                                                    controller:
                                                                        _pageController,
                                                                    itemCount: searchResultData['data'][index]
                                                                            [
                                                                            'image']
                                                                        .length,
                                                                    onPageChanged:
                                                                        (int
                                                                            page) {
                                                                      setState(
                                                                          () {
                                                                        currentPage =
                                                                            page;
                                                                      });
                                                                    },
                                                                    itemBuilder:
                                                                        (context,
                                                                            imageIndex) {
                                                                      return Image(
                                                                          image:
                                                                              NetworkImage(
                                                                            searchResultData['data'][index]['image'][imageIndex],
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          filterQuality: FilterQuality
                                                                              .high,
                                                                          alignment:
                                                                              Alignment.center);
                                                                    },
                                                                  )
                                                                : SizedBox(
                                                                    width: (MediaQuery.of(context).size.width *
                                                                            0.3) -
                                                                        23.0,
                                                                    height:
                                                                        75.0,
                                                                    child: Image(
                                                                        image: NetworkImage(
                                                                          searchResultData['data'][index]['image']
                                                                              [
                                                                              0],
                                                                        ),
                                                                        fit: BoxFit.cover,
                                                                        filterQuality: FilterQuality.high,
                                                                        alignment: Alignment.center),
                                                                  ),
                                                          )
                                                        : Container(),
                                                    searchResultData['data']
                                                                        [index][
                                                                    'category'] !=
                                                                null &&
                                                            searchResultData[
                                                                            'data']
                                                                        [index][
                                                                    'category'] ==
                                                                'g'
                                                        ? SizedBox(
                                                            width: (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.3) -
                                                                23.0,
                                                            height: 75.0,
                                                            child: Image(
                                                              image:
                                                                  NetworkImage(
                                                                searchResultData[
                                                                            'data']
                                                                        [index][
                                                                    'sub_link'],
                                                              ),
                                                              fit: BoxFit.cover,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                            ),
                                                          )
                                                        : Container(),
                                                    searchResultData['data']
                                                                        [index][
                                                                    'category'] !=
                                                                null &&
                                                            searchResultData[
                                                                            'data']
                                                                        [index][
                                                                    'category'] ==
                                                                'y'
                                                        ? SizedBox(
                                                            width: (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.3) -
                                                                23.0,
                                                            height: 75.0,
                                                            child: Image(
                                                              image: NetworkImage(
                                                                  getYoutubeThumbnail(
                                                                      searchResultData['data']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'sub_link'])),
                                                              fit: BoxFit.cover,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                            ),
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        : searchResultData['data'][index]
                                                    ['type'] ==
                                                5
                                            ? Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                margin: const EdgeInsets.only(
                                                    top: 12.0, bottom: 4.0),
                                                child: CustomTextBuilder(
                                                  text: searchResultData['data']
                                                      [index]['title'],
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 19.0.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : Container(),
                              ),
                            ),
                            // 좋아요, 댓글, 더보기 버튼
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 좋아요
                                MaterialButton(
                                  onPressed: () async {
                                    final _prefs =
                                        await SharedPreferences.getInstance();

                                    if (searchResultData['data'][index]
                                            ['isLike'] ==
                                        false) {
                                      AddLikeSenderAPI()
                                          .add(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              postIndex:
                                                  searchResultData['data']
                                                      [index]['post_index'])
                                          .then((res) {
                                        if (res.result['status'] == 10800) {
                                          setState(() {
                                            searchResultData['data'][index]
                                                ['like']++;
                                            searchResultData['data'][index]
                                                ['isLike'] = true;
                                          });
                                        }
                                      });
                                    } else {
                                      CancelLikeSenderAPI()
                                          .cancel(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              postIndex:
                                                  searchResultData['data']
                                                      [index]['post_index'])
                                          .then((res) {
                                        if (res.result['status'] == 10805) {
                                          setState(() {
                                            searchResultData['data'][index]
                                                ['like']--;
                                            searchResultData['data'][index]
                                                ['isLike'] = false;
                                          });
                                        }
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      SvgAssets(
                                        image: 'assets/icon/like.svg',
                                        color: searchResultData['data'][index]
                                                ['isLike']
                                            ? ColorsConfig().primary()
                                            : ColorsConfig().textBlack1(),
                                        width: 18.0,
                                        height: 18.0,
                                      ),
                                      const SizedBox(width: 10.0),
                                      CustomTextBuilder(
                                        text: numberFormat.format(
                                            searchResultData['data'][index]
                                                    ['like'] +
                                                addLikeCount),
                                        fontColor: ColorsConfig().textBlack1(),
                                        fontSize: 13.0.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                                // 댓글
                                MaterialButton(
                                  onPressed: () {
                                    if (searchResultData['data'][index]
                                            ['type'] ==
                                        4) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NewsDetailScreen(
                                            postIndex: searchResultData['data']
                                                [index]['post_index'],
                                            postType: searchResultData['data']
                                                [index]['type'],
                                          ),
                                        ),
                                      ).then((returns) async {
                                        if (returns != null) {
                                          if (returns['ret']) {
                                            setState(() {
                                              searchResultData['data']
                                                  .removeAt(index);
                                              // currentPage.removeAt(index);
                                            });
                                          }
                                        } else {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          PostDetailDataAPI()
                                              .detail(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  postIndex:
                                                      searchResultData['data']
                                                          [index]['post_index'])
                                              .then((value) {
                                            setState(() {
                                              searchResultData['data'][index] =
                                                  value.result;
                                            });
                                          });
                                        }
                                      });
                                    } else if (searchResultData['data'][index]
                                            ['type'] ==
                                        5) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              VoteDetailScreen(
                                            postIndex: searchResultData['data']
                                                [index]['post_index'],
                                            postType: searchResultData['data']
                                                [index]['type'],
                                          ),
                                        ),
                                      ).then((returns) async {
                                        if (returns != null) {
                                          if (returns['ret']) {
                                            setState(() {
                                              searchResultData['data']
                                                  .removeAt(index);
                                              // currentPage.removeAt(index);
                                            });
                                          }
                                        } else {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          PostDetailDataAPI()
                                              .detail(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  postIndex:
                                                      searchResultData['data']
                                                          [index]['post_index'])
                                              .then((value) {
                                            setState(() {
                                              searchResultData['data'][index] =
                                                  value.result;
                                            });
                                          });
                                        }
                                      });
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PostingDetailScreen(
                                            postIndex: searchResultData['data']
                                                [index]['post_index'],
                                            postType: searchResultData['data']
                                                [index]['type'],
                                          ),
                                        ),
                                      ).then((returns) async {
                                        if (returns != null) {
                                          if (returns['ret']) {
                                            setState(() {
                                              searchResultData['data']
                                                  .removeAt(index);
                                              // currentPage.removeAt(index);
                                            });
                                          }
                                        } else {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          PostDetailDataAPI()
                                              .detail(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  postIndex:
                                                      searchResultData['data']
                                                          [index]['post_index'])
                                              .then((value) {
                                            setState(() {
                                              searchResultData['data'][index] =
                                                  value.result;
                                            });
                                          });
                                        }
                                      });
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgAssets(
                                        image: 'assets/icon/reply.svg',
                                        color: ColorsConfig().textBlack1(),
                                        width: 18.0,
                                        height: 18.0,
                                      ),
                                      const SizedBox(width: 10.0),
                                      CustomTextBuilder(
                                        text: numberFormat.format(
                                            searchResultData['data'][index]
                                                ['reply']),
                                        fontColor: ColorsConfig().textBlack1(),
                                        fontSize: 13.0.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                                // 선물
                                MaterialButton(
                                  onPressed: () async {
                                    if (searchResultData['data'][index]
                                        ['isMe']) {
                                      ToastBuilder().toast(
                                        Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          padding: const EdgeInsets.all(14.0),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 30.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig.defaultToast
                                                .withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                          child: CustomTextBuilder(
                                            text: '자신에게는 선물할 수 없습니다',
                                            fontColor:
                                                ColorsConfig.defaultWhite,
                                            fontSize: 14.0.sp,
                                          ),
                                        ),
                                      );
                                    } else {
                                      final _prefs =
                                          await SharedPreferences.getInstance();

                                      GetGiftListDataAPI()
                                          .gift(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!)
                                          .then((gifts) {
                                        bool _hasClick = false;

                                        showModalBottomSheet(
                                            context: context,
                                            backgroundColor:
                                                ColorsConfig().subBackground1(),
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(12.0),
                                                topRight: Radius.circular(12.0),
                                              ),
                                            ),
                                            builder: (BuildContext context) {
                                              int _giftTabIndex = 0;

                                              List<dynamic> _trophy = [];
                                              List<dynamic> _reaction = [];
                                              List<dynamic> _neckTrophy = [];

                                              Map<String, dynamic>
                                                  _selectedGift = {};

                                              var _giftTabController =
                                                  TabController(
                                                length: 4,
                                                vsync: this,
                                              );
                                              _giftTabController
                                                  .addListener(() {
                                                if (_giftTabController
                                                        .indexIsChanging ||
                                                    _giftTabController.index !=
                                                        _giftTabIndex) {
                                                  setState(() {
                                                    _giftTabIndex =
                                                        _giftTabController
                                                            .index;
                                                  });
                                                }
                                              });

                                              for (int i = 0;
                                                  i < gifts.result.length;
                                                  i++) {
                                                if (gifts.result[i]
                                                        ['item_type'] ==
                                                    0) {
                                                  _trophy.add(gifts.result[i]);
                                                } else if (gifts.result[i]
                                                        ['item_type'] ==
                                                    1) {
                                                  _reaction
                                                      .add(gifts.result[i]);
                                                } else if (gifts.result[i]
                                                        ['item_type'] ==
                                                    2) {
                                                  _neckTrophy
                                                      .add(gifts.result[i]);
                                                }
                                              }

                                              return StatefulBuilder(
                                                builder: (context, state) {
                                                  return Container(
                                                    height: _hasClick
                                                        ? MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            1.72
                                                        : MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            2,
                                                    decoration:
                                                        const BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                12.0),
                                                        topRight:
                                                            Radius.circular(
                                                                12.0),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          width: 50.0,
                                                          height: 4.0,
                                                          margin:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      8.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ColorsConfig()
                                                                .textBlack2(),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                          ),
                                                        ),
                                                        // 선물하기 타이틀
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      20.0,
                                                                      15.0,
                                                                      20.0,
                                                                      10.0),
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child:
                                                                  CustomTextBuilder(
                                                                text: '선물하기',
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textWhite1(),
                                                                fontSize:
                                                                    22.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          15.0),
                                                              child:
                                                                  const HoldingBalanceWidget(),
                                                            ),
                                                          ],
                                                        ),
                                                        // 탭바
                                                        Container(
                                                          width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border(
                                                              bottom:
                                                                  BorderSide(
                                                                width: 0.5,
                                                                color: ColorsConfig()
                                                                    .border1(),
                                                              ),
                                                            ),
                                                          ),
                                                          child: TabBar(
                                                            controller:
                                                                _giftTabController,
                                                            isScrollable: true,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        20.0),
                                                            indicatorColor:
                                                                ColorsConfig()
                                                                    .primary(),
                                                            unselectedLabelColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            unselectedLabelStyle:
                                                                TextStyle(
                                                              fontSize: 16.0.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                            labelColor:
                                                                ColorsConfig()
                                                                    .primary(),
                                                            labelStyle:
                                                                TextStyle(
                                                              fontSize: 16.0.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            onTap: (_) {
                                                              state(() {
                                                                _hasClick =
                                                                    false;
                                                                _selectedGift =
                                                                    {};
                                                              });
                                                            },
                                                            tabs: [
                                                              Tab(
                                                                child:
                                                                    CustomTextBuilder(
                                                                  text: '전체',
                                                                ),
                                                              ),
                                                              Tab(
                                                                child:
                                                                    CustomTextBuilder(
                                                                  text: '트로피',
                                                                ),
                                                              ),
                                                              Tab(
                                                                child:
                                                                    CustomTextBuilder(
                                                                  text: '리액션',
                                                                ),
                                                              ),
                                                              Tab(
                                                                child:
                                                                    CustomTextBuilder(
                                                                  text: '메달',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding: !_hasClick
                                                                ? const EdgeInsets
                                                                    .fromLTRB(
                                                                    25.0,
                                                                    25.0,
                                                                    15.0,
                                                                    20.0)
                                                                : const EdgeInsets
                                                                    .fromLTRB(
                                                                    25.0,
                                                                    25.0,
                                                                    15.0,
                                                                    0.0),
                                                            child: TabBarView(
                                                              controller:
                                                                  _giftTabController,
                                                              physics:
                                                                  const NeverScrollableScrollPhysics(),
                                                              children: [
                                                                ListView(
                                                                  children: [
                                                                    Wrap(
                                                                      children: List.generate(
                                                                          gifts
                                                                              .result
                                                                              .length,
                                                                          (index) {
                                                                        return InkWell(
                                                                          splashColor:
                                                                              ColorsConfig.transparent,
                                                                          highlightColor:
                                                                              ColorsConfig.transparent,
                                                                          onTap:
                                                                              () {
                                                                            state(() {
                                                                              if (_hasClick && _selectedGift['index'] == index) {
                                                                                _hasClick = false;
                                                                                _selectedGift = {};
                                                                              } else {
                                                                                _hasClick = true;
                                                                                _selectedGift = {
                                                                                  "index": index,
                                                                                  "item_index": gifts.result[index]['item_index'],
                                                                                  "item_type": gifts.result[index]['item_type'],
                                                                                  "item_type_name": gifts.result[index]['item_type_name'],
                                                                                  "url": gifts.result[index]['url'],
                                                                                  "description": gifts.result[index]['description'],
                                                                                  "price": gifts.result[index]['price'],
                                                                                };
                                                                              }
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            margin:
                                                                                EdgeInsets.only(right: 10.0.w),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: _selectedGift['index'] == index && _giftTabIndex == 0 ? ColorsConfig().subBackgroundBlack() : null,
                                                                              borderRadius: BorderRadius.circular(14.0),
                                                                            ),
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                Image(
                                                                                  image: NetworkImage(
                                                                                    gifts.result[index]['url'],
                                                                                  ),
                                                                                  filterQuality: FilterQuality.high,
                                                                                  width: 65.0.w,
                                                                                  height: 65.0.h,
                                                                                ),
                                                                                Container(
                                                                                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                  child: CustomTextBuilder(
                                                                                    text: '${gifts.result[index]['price']}',
                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                    fontSize: 12.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }),
                                                                    ),
                                                                  ],
                                                                ),
                                                                ListView(
                                                                  children: [
                                                                    Wrap(
                                                                      children: List.generate(
                                                                          _trophy
                                                                              .length,
                                                                          (index) {
                                                                        return InkWell(
                                                                          splashColor:
                                                                              ColorsConfig.transparent,
                                                                          highlightColor:
                                                                              ColorsConfig.transparent,
                                                                          onTap:
                                                                              () {
                                                                            state(() {
                                                                              if (_hasClick && _selectedGift['index'] == index) {
                                                                                _hasClick = false;
                                                                                _selectedGift = {};
                                                                              } else {
                                                                                _hasClick = true;
                                                                                _selectedGift = {
                                                                                  "index": index,
                                                                                  "item_index": _trophy[index]['item_index'],
                                                                                  "item_type": _trophy[index]['item_type'],
                                                                                  "item_type_name": _trophy[index]['item_type_name'],
                                                                                  "url": _trophy[index]['url'],
                                                                                  "description": _trophy[index]['description'],
                                                                                  "price": _trophy[index]['price'],
                                                                                };
                                                                              }
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            margin:
                                                                                EdgeInsets.only(right: 10.0.w),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: _selectedGift['index'] == index && _giftTabIndex == 1 ? ColorsConfig().subBackgroundBlack() : null,
                                                                              borderRadius: BorderRadius.circular(14.0),
                                                                            ),
                                                                            child: _trophy[index]['item_type'] == 0
                                                                                ? Column(
                                                                                    children: [
                                                                                      Image(
                                                                                        image: NetworkImage(
                                                                                          _trophy[index]['url'],
                                                                                        ),
                                                                                        filterQuality: FilterQuality.high,
                                                                                        width: 65.0.w,
                                                                                        height: 65.0.h,
                                                                                      ),
                                                                                      Container(
                                                                                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '${_trophy[index]['price']}',
                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                          fontSize: 12.0.sp,
                                                                                          fontWeight: FontWeight.w400,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : null,
                                                                          ),
                                                                        );
                                                                      }),
                                                                    ),
                                                                  ],
                                                                ),
                                                                ListView(
                                                                  children: [
                                                                    Wrap(
                                                                      children: List.generate(
                                                                          _reaction
                                                                              .length,
                                                                          (index) {
                                                                        return InkWell(
                                                                          splashColor:
                                                                              ColorsConfig.transparent,
                                                                          highlightColor:
                                                                              ColorsConfig.transparent,
                                                                          onTap:
                                                                              () {
                                                                            state(() {
                                                                              if (_hasClick && _selectedGift['index'] == index) {
                                                                                _hasClick = false;
                                                                                _selectedGift = {};
                                                                              } else {
                                                                                _hasClick = true;
                                                                                _selectedGift = {
                                                                                  "index": index,
                                                                                  "item_index": _reaction[index]['item_index'],
                                                                                  "item_type": _reaction[index]['item_type'],
                                                                                  "item_type_name": _reaction[index]['item_type_name'],
                                                                                  "url": _reaction[index]['url'],
                                                                                  "description": _reaction[index]['description'],
                                                                                  "price": _reaction[index]['price'],
                                                                                };
                                                                              }
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            margin:
                                                                                EdgeInsets.only(right: 10.0.w),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: _selectedGift['index'] == index && _giftTabIndex == 2 ? ColorsConfig().subBackgroundBlack() : null,
                                                                              borderRadius: BorderRadius.circular(14.0),
                                                                            ),
                                                                            child: _reaction[index]['item_type'] == 1
                                                                                ? Column(
                                                                                    children: [
                                                                                      Image(
                                                                                        image: NetworkImage(
                                                                                          _reaction[index]['url'],
                                                                                        ),
                                                                                        filterQuality: FilterQuality.high,
                                                                                        width: 65.0.w,
                                                                                        height: 65.0.h,
                                                                                      ),
                                                                                      Container(
                                                                                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '${_reaction[index]['price']}',
                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                          fontSize: 12.0.sp,
                                                                                          fontWeight: FontWeight.w400,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : null,
                                                                          ),
                                                                        );
                                                                      }),
                                                                    ),
                                                                  ],
                                                                ),
                                                                ListView(
                                                                  children: [
                                                                    Wrap(
                                                                      children: List.generate(
                                                                          _neckTrophy
                                                                              .length,
                                                                          (index) {
                                                                        return InkWell(
                                                                          splashColor:
                                                                              ColorsConfig.transparent,
                                                                          highlightColor:
                                                                              ColorsConfig.transparent,
                                                                          onTap:
                                                                              () {
                                                                            state(() {
                                                                              if (_hasClick && _selectedGift['index'] == index) {
                                                                                _hasClick = false;
                                                                                _selectedGift = {};
                                                                              } else {
                                                                                _hasClick = true;
                                                                                _selectedGift = {
                                                                                  "index": index,
                                                                                  "item_index": _neckTrophy[index]['item_index'],
                                                                                  "item_type": _neckTrophy[index]['item_type'],
                                                                                  "item_type_name": _neckTrophy[index]['item_type_name'],
                                                                                  "url": _neckTrophy[index]['url'],
                                                                                  "description": _neckTrophy[index]['description'],
                                                                                  "price": _neckTrophy[index]['price'],
                                                                                };
                                                                              }
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            margin:
                                                                                EdgeInsets.only(right: 10.0.w),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: _selectedGift['index'] == index && _giftTabIndex == 3 ? ColorsConfig().subBackgroundBlack() : null,
                                                                              borderRadius: BorderRadius.circular(14.0),
                                                                            ),
                                                                            child: _neckTrophy[index]['item_type'] == 2
                                                                                ? Column(
                                                                                    children: [
                                                                                      Image(
                                                                                        image: NetworkImage(
                                                                                          _neckTrophy[index]['url'],
                                                                                        ),
                                                                                        filterQuality: FilterQuality.high,
                                                                                        width: 65.0.w,
                                                                                        height: 65.0.h,
                                                                                      ),
                                                                                      Container(
                                                                                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '${_neckTrophy[index]['price']}',
                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                          fontSize: 12.0.sp,
                                                                                          fontWeight: FontWeight.w400,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : null,
                                                                          ),
                                                                        );
                                                                      }),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        _hasClick == true
                                                            ? Container(
                                                                height: 157.0,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .fromLTRB(
                                                                        20.0,
                                                                        10.0,
                                                                        20.0,
                                                                        30.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: ColorsConfig()
                                                                      .subBackground1(),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: ColorsConfig().textWhite1(
                                                                          opacity:
                                                                              0.16),
                                                                      blurRadius:
                                                                          10.0,
                                                                      offset: const Offset(
                                                                          0.0,
                                                                          -2.0),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Column(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Image(
                                                                          image:
                                                                              NetworkImage(
                                                                            '${_selectedGift['url']}',
                                                                          ),
                                                                          filterQuality:
                                                                              FilterQuality.high,
                                                                          width:
                                                                              65.0.w,
                                                                          height:
                                                                              65.0.h,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                32.0),
                                                                        Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '${_selectedGift['description']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: numberFormat.format(_selectedGift['price']),
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 12.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            10.0),
                                                                    InkWell(
                                                                      onTap:
                                                                          () {
                                                                        if (_selectedGift['price'] ==
                                                                            0) {
                                                                          SendGiftDataAPI()
                                                                              .gift(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], postIndex: searchResultData['data'][index]['post_index'])
                                                                              .then((value) {
                                                                            int?
                                                                                _existIndex;

                                                                            switch (value.result['status']) {
                                                                              case 10200:
                                                                                setState(() {
                                                                                  if (searchResultData['data'][index]['gift'].length == 0) {
                                                                                    searchResultData['data'][index]['gift'].add({
                                                                                      "image": _selectedGift['url'],
                                                                                      "gift_count": 1,
                                                                                    });
                                                                                  } else {
                                                                                    for (int i = 0; i < searchResultData['data'][index]['gift'].length; i++) {
                                                                                      if (searchResultData['data'][index]['gift'][i]['image'].contains(_selectedGift['url'])) {
                                                                                        _existIndex = i;
                                                                                        break;
                                                                                      }
                                                                                    }

                                                                                    if (_existIndex != null) {
                                                                                      searchResultData['data'][index]['gift'][_existIndex]['gift_count'] = searchResultData['data'][index]['gift'][_existIndex]['gift_count'] + 1;
                                                                                    } else {
                                                                                      searchResultData['data'][index]['gift'].insert(0, {
                                                                                        "image": _selectedGift['url'],
                                                                                        "gift_count": 1,
                                                                                      });
                                                                                    }
                                                                                  }
                                                                                });
                                                                                Navigator.pop(context);
                                                                                break;
                                                                              case 10201:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '자신에게는 선물할 수 없습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10202:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '해당 글이 존재하지 않습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10203:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '해당 아이템이 존재하지 않습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10204:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '유료 아이템을 선물할 수 없습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                            }
                                                                          });
                                                                        } else {
                                                                          SendPricedGiftDataAPI()
                                                                              .pricedGift(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], postIndex: searchResultData['data'][index]['post_index'])
                                                                              .then((value) {
                                                                            int?
                                                                                _existIndex;

                                                                            switch (value.result['status']) {
                                                                              case 10201:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '자신에게는 선물할 수 없습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10202:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '해당 글이 존재하지 않습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10203:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '해당 아이템이 존재하지 않습니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10210:
                                                                                setState(() {
                                                                                  if (searchResultData['data'][index]['gift'].length == 0) {
                                                                                    searchResultData['data'][index]['gift'].add({
                                                                                      "image": _selectedGift['url'],
                                                                                      "gift_count": 1,
                                                                                    });
                                                                                  } else {
                                                                                    for (int i = 0; i < searchResultData['data'][index]['gift'].length; i++) {
                                                                                      if (searchResultData['data'][index]['gift'][i]['image'].contains(_selectedGift['url'])) {
                                                                                        _existIndex = i;
                                                                                        break;
                                                                                      }
                                                                                    }

                                                                                    if (_existIndex != null) {
                                                                                      searchResultData['data'][index]['gift'][_existIndex]['gift_count'] = searchResultData['data'][index]['gift'][_existIndex]['gift_count'] + 1;
                                                                                    } else {
                                                                                      searchResultData['data'][index]['gift'].insert(0, {
                                                                                        "image": _selectedGift['url'],
                                                                                        "gift_count": 1,
                                                                                      });
                                                                                    }
                                                                                  }
                                                                                });
                                                                                Navigator.pop(context);
                                                                                break;
                                                                              case 10211:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '유료 아이템이 아닙니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                              case 10212:
                                                                                ToastBuilder().toast(
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.all(14.0),
                                                                                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig.defaultToast.withOpacity(0.9),
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '보유하신 포인트가 부족합니다',
                                                                                      fontColor: ColorsConfig.defaultWhite,
                                                                                      fontSize: 14.0.sp,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                break;
                                                                            }
                                                                          });
                                                                        }
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        height:
                                                                            42.0,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          // color: ColorsConfig().primary(),
                                                                          borderRadius:
                                                                              BorderRadius.circular(100.0),
                                                                          gradient:
                                                                              LinearGradient(
                                                                            colors: [
                                                                              ColorsConfig().avatarButtonBackground1(),
                                                                              ColorsConfig().avatarButtonBackground2(),
                                                                            ],
                                                                            begin:
                                                                                Alignment.centerLeft,
                                                                            end:
                                                                                Alignment.centerRight,
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '보내기',
                                                                            fontColor:
                                                                                ColorsConfig().background(),
                                                                            fontSize:
                                                                                16.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            : Container(),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            });
                                      });
                                    }
                                  },
                                  child: SvgAssets(
                                    image: 'assets/icon/gift.svg',
                                    color: ColorsConfig().textBlack1(),
                                    width: 18.0,
                                    height: 18.0,
                                  ),
                                ),
                                // 공유
                                MaterialButton(
                                  onPressed: () async {
                                    var shortLink = await DeepLinkBuilder()
                                        .getShortLink(
                                            'share',
                                            '${searchResultData['data'][index]['post_index']}',
                                            searchResultData['data'][index]
                                                ['type']);

                                    Share.share(
                                      '${searchResultData['data'][index]['title']}\n$shortLink',
                                      sharePositionOrigin: Rect.fromLTWH(
                                          0,
                                          0,
                                          MediaQuery.of(context).size.width,
                                          MediaQuery.of(context).size.height /
                                              2),
                                    );
                                  },
                                  child: SvgAssets(
                                    image: 'assets/icon/share.svg',
                                    color: ColorsConfig().textBlack1(),
                                    width: 18.0,
                                    height: 18.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      SharedPreferences.getInstance().then((_prefs) {
                        GetPostListAPI()
                            .list(
                                accesToken: _prefs.getString('AccessToken')!,
                                q: _controller.text,
                                cursor: searchResultData['data'][index - 1]
                                    ['post_index'])
                            .then((value) {
                          for (int i = 0;
                              i < value.result['data'].length;
                              i++) {
                            setState(() {
                              searchResultData['data']
                                  .add(value.result['data'][i]);
                              getSearchDataMoreBtnState.add(false);
                            });
                          }
                        });
                      });
                      return Container();
                    }
                  },
                ),
              )
            : Container(
                color: ColorsConfig().background(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130.0,
                        height: 130.0,
                        child: themeImage(),
                      ),
                      CustomTextBuilder(
                        text: '검색 결과가 없습니다.',
                        fontColor: ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      const SizedBox(height: 65.0),
                    ],
                  ),
                ),
              )
        : Container();
  }
}
