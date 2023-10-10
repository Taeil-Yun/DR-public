import 'dart:async';

import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/widget/loading.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/api/live/hot_room_list.dart';
import 'package:DRPublic/api/live/live_join_check.dart';
import 'package:DRPublic/api/notification/notification_list.dart';
import 'package:DRPublic/api/post/hot_post_list.dart';
import 'package:DRPublic/api/post/main_post_detail.dart';
import 'package:DRPublic/api/user/get_recommend.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/widget/drawer_widget.dart';
import 'package:DRPublic/widget/label_category_widget.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class MainHomeScreenBuilder extends StatefulWidget {
  const MainHomeScreenBuilder({Key? key}) : super(key: key);

  @override
  State<MainHomeScreenBuilder> createState() => _MainHomeScreenBuilderState();
}

class _MainHomeScreenBuilderState extends State<MainHomeScreenBuilder> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  int lastNotificationCount = 0;
  int recentNotificationCount = 0;

  String dropdownCategoryValue = '국내증시';

  bool isLoading = false;

  List<dynamic> getHotLiveList = [];
  List<dynamic> getRecommendList = [];

  Map<String, dynamic> getProfileData = {};
  Map<String, dynamic> getHotPostData = {};

  @override
  void initState() {
    apiInitialize();
    notificationLength();

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    if (_prefs.getInt('NotificationCount') != null) {
      setState(
          () => lastNotificationCount = _prefs.getInt('NotificationCount')!);
    }

    Future.wait([
      UserProfileInfoAPI()
          .getProfile(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          getProfileData = value?.result;
        });
      }),
      GetHotLiveRoomListAPI()
          .hotList(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          getHotLiveList = value.result;
        });
      }),
      GetRecommendDataAPI()
          .recommend(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          getRecommendList = value.result;
        });
      }),
      GetHotPostListAPI()
          .hotPost(
              accesToken: _prefs.getString('AccessToken')!, postCategory: 1)
          .then((value) {
        setState(() {
          getHotPostData = value.result;
        });
      }),
      GetNotificationListDataAPI()
          .notifications(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          if (value.result.isEmpty) {
            recentNotificationCount = 0;
          } else {
            recentNotificationCount = value.result.length;
          }
        });
      }),
    ]).then((_) {
      setState(() {
        isLoading = true;
      });
    });
  }

  Future notificationLength() async {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final _prefs = await SharedPreferences.getInstance();

      GetNotificationListDataAPIResponseModel _data =
          await GetNotificationListDataAPI()
              .notifications(accesToken: _prefs.getString('AccessToken')!);

      // setState(() {
      if (_data.result.isEmpty) {
        recentNotificationCount = 0;
      } else {
        recentNotificationCount = _data.result.length;
      }
      // });

      return _data.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        backgroundColor: ColorsConfig().subBackground1(),
        // leadingWidth: 130.0,
        // leading: DRAppBarLeading(
        //   press: () {
        //     // _scaffoldKey.currentState?.openDrawer();
        //   },
        //   icon: const Image(
        //     image: AssetImage('assets/splash/splash2x.png'),
        //     filterQuality: FilterQuality.high,
        //   ),
        // ),
        center: false,
        title: const Image(
          image: AssetImage('assets/splash/splash_m.png'),
          width: 140.0,
          filterQuality: FilterQuality.high,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: SvgAssets(
              image: 'assets/icon/search.svg',
              color: ColorsConfig().textBlack2(),
              width: 20.0,
              height: 20.0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 10.0),
            child: InkWell(
              onTap: () {
                SharedPreferences.getInstance().then((_prefs) {
                  _prefs.setInt('NotificationCount', recentNotificationCount);
                });

                setState(() {
                  lastNotificationCount = recentNotificationCount;
                });

                Navigator.pushNamed(context, '/notification');
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgAssets(
                    image: 'assets/icon/notification.svg',
                    color: ColorsConfig().textBlack2(),
                    width: 22.0,
                    height: 22.0,
                  ),
                  recentNotificationCount != lastNotificationCount
                      ? Positioned(
                          top: 22.0,
                          right: 1.0,
                          child: Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              color: ColorsConfig.notificationDots,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                icon: Container(
                  width: 39.0,
                  height: 39.0,
                  decoration: BoxDecoration(
                    color: ColorsConfig().userIconBackground(),
                    borderRadius: BorderRadius.circular(100.0),
                    image: getProfileData.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              getProfileData['avatar'],
                              scale: 7.0,
                            ),
                            filterQuality: FilterQuality.high,
                            fit: BoxFit.none,
                            alignment: const Alignment(0.0, -0.3),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: ColorsConfig().background(),
              child: RefreshIndicator(
                onRefresh: () async {
                  final SharedPreferences _prefs =
                      await SharedPreferences.getInstance();

                  GetHotLiveRoomListAPI()
                      .hotList(accesToken: _prefs.getString('AccessToken')!)
                      .then((value) {
                    setState(() {
                      getHotLiveList = value.result;
                    });
                  });

                  GetRecommendDataAPI()
                      .recommend(accesToken: _prefs.getString('AccessToken')!)
                      .then((value) {
                    setState(() {
                      getRecommendList = value.result;
                    });
                  });

                  GetHotPostListAPI()
                      .hotPost(
                    accesToken: _prefs.getString('AccessToken')!,
                    postCategory: dropdownCategoryValue == '국내증시'
                        ? 1
                        : dropdownCategoryValue == '해외증시'
                            ? 2
                            : dropdownCategoryValue == '파생상품'
                                ? 3
                                : dropdownCategoryValue == '암호화폐'
                                    ? 4
                                    : dropdownCategoryValue == '커뮤니티'
                                        ? 5
                                        : 0,
                  )
                      .then((value) {
                    setState(() {
                      getHotPostData = value.result;
                    });
                  });
                },
                color: ColorsConfig().textWhite1(),
                backgroundColor: ColorsConfig().subBackgroundBlack(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getHotLiveList.isNotEmpty
                          ? Container(
                              color: ColorsConfig().subBackground1(),
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 라이브 텍스트
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        15.0, 20.0, 15.0, 15.0),
                                    child: CustomTextBuilder(
                                      text: 'DR-Public 라이브',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 22.0.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  // 라이브 가로 스크롤 영역
                                  SizedBox(
                                    height: 197.0,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: getHotLiveList.length,
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () async {
                                            final _prefs =
                                                await SharedPreferences
                                                    .getInstance();

                                            LiveJoinCheckAPI()
                                                .join(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    roomIndex:
                                                        getHotLiveList[index]
                                                            ['idx'])
                                                .then((joined) {
                                              if (joined.result['status'] ==
                                                  14007) {
                                                Navigator.pushNamed(
                                                    context, 'live_room',
                                                    arguments: {
                                                      "room_index":
                                                          getHotLiveList[index]
                                                              ['idx'],
                                                      "user_index":
                                                          getProfileData['id'],
                                                      "nickname":
                                                          getProfileData[
                                                              'nick'],
                                                      "avatar": getProfileData[
                                                          'avatar'],
                                                      "is_header": false,
                                                    });
                                              } else if (joined
                                                      .result['status'] ==
                                                  14008) {
                                                PopUpModal(
                                                  title: '',
                                                  titlePadding: EdgeInsets.zero,
                                                  onTitleWidget: Container(),
                                                  content: '',
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  backgroundColor:
                                                      ColorsConfig.transparent,
                                                  onContentWidget: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        height: 136.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: ColorsConfig()
                                                              .subBackground1(),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    8.0),
                                                            topRight:
                                                                Radius.circular(
                                                                    8.0),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child:
                                                              CustomTextBuilder(
                                                            text:
                                                                '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 16.0.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(
                                                              width: 0.5,
                                                              color:
                                                                  ColorsConfig()
                                                                      .border1(),
                                                            ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    80.0,
                                                                height: 43.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: ColorsConfig()
                                                                      .subBackground1(),
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .only(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            8.0),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text: '확인',
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textWhite1(),
                                                                    fontSize:
                                                                        16.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
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
                                            width: 200.0,
                                            height: 197.0,
                                            margin: index !=
                                                    getHotLiveList.length - 1
                                                ? const EdgeInsets.only(
                                                    left: 15.0)
                                                : const EdgeInsets.symmetric(
                                                    horizontal: 15.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 이미지
                                                Container(
                                                  width: 200.0,
                                                  height: 130.0,
                                                  decoration: BoxDecoration(
                                                    color: ColorsConfig()
                                                        .textBlack2(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                          getHotLiveList[index]
                                                              ['thumbnail']),
                                                      fit: BoxFit.cover,
                                                      filterQuality:
                                                          FilterQuality.high,
                                                    ),
                                                  ),
                                                ),
                                                // 제목
                                                Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 5.0),
                                                  child: CustomTextBuilder(
                                                    text:
                                                        '${getHotLiveList[index]['title']}',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 18.0.sp,
                                                    fontWeight: FontWeight.w700,
                                                    maxLines: 1,
                                                    textOverflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                // 아바타 이미지, 닉네임, 시청자
                                                Row(
                                                  children: [
                                                    // 아바타 이미지
                                                    Container(
                                                      width: 20.0,
                                                      height: 20.0,
                                                      decoration: BoxDecoration(
                                                        color: ColorsConfig()
                                                            .userIconBackground(),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                            getHotLiveList[
                                                                    index]
                                                                ['avatar'],
                                                            scale: 9.0,
                                                          ),
                                                          fit: BoxFit.none,
                                                          alignment:
                                                              const Alignment(
                                                                  0.0, -0.3),
                                                        ),
                                                      ),
                                                    ),
                                                    // 닉네임
                                                    Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5.0),
                                                      child: CustomTextBuilder(
                                                        text:
                                                            '${getHotLiveList[index]['nick']}',
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textWhite1(),
                                                        fontSize: 13.0.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    // 시청자 아이콘
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 5.0),
                                                      child: Icon(
                                                        Icons.group_outlined,
                                                        color: ColorsConfig
                                                            .defaultGray,
                                                        size: 22.0.sp,
                                                      ),
                                                    ),
                                                    // 시청자 수
                                                    CustomTextBuilder(
                                                      text: NumberFormat()
                                                          .format(
                                                              getHotLiveList[
                                                                      index]
                                                                  ['total']),
                                                      fontColor: ColorsConfig
                                                          .defaultGray,
                                                      fontSize: 14.0.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      getRecommendList.isNotEmpty
                          ? Container(
                              color: ColorsConfig().subBackground1(),
                              margin: const EdgeInsets.only(top: 10.0),
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // DR-Public 추천 채널 텍스트
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        15.0, 20.0, 15.0, 15.0),
                                    child: CustomTextBuilder(
                                      text: 'DR-Public 추천 채널',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 22.0.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  // DR-Public 추천 채널 가로 스크롤 영역
                                  SizedBox(
                                    height: 195.0,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: getRecommendList.length,
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () {
                                            if (getRecommendList[index]
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
                                                        getRecommendList[index]
                                                            ['user_index'],
                                                    'user_nickname':
                                                        getRecommendList[index]
                                                            ['nick'],
                                                  });
                                            }
                                          },
                                          child: Container(
                                            width: 200.0,
                                            height: 195.0,
                                            margin: index !=
                                                    getRecommendList.length - 1
                                                ? const EdgeInsets.only(
                                                    left: 15.0)
                                                : const EdgeInsets.symmetric(
                                                    horizontal: 15.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1.0,
                                                color: ColorsConfig().border1(),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: Stack(
                                              children: [
                                                // 이미지
                                                Container(
                                                  width: 200.0,
                                                  height: 85.0,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(6.0),
                                                      topRight:
                                                          Radius.circular(6.0),
                                                    ),
                                                    image: getRecommendList[
                                                                    index][
                                                                'app_background'] !=
                                                            false
                                                        ? DecorationImage(
                                                            image: NetworkImage(
                                                                getRecommendList[
                                                                        index][
                                                                    'app_background']),
                                                            fit: BoxFit.cover,
                                                            filterQuality:
                                                                FilterQuality
                                                                    .high,
                                                          )
                                                        : const DecorationImage(
                                                            image: AssetImage(
                                                                'assets/img/cover_background.png'),
                                                            fit: BoxFit.cover,
                                                            filterQuality:
                                                                FilterQuality
                                                                    .high,
                                                          ),
                                                  ),
                                                ),
                                                // 이름, 설명
                                                Positioned(
                                                  bottom: 0.0,
                                                  child: Container(
                                                    width: 200.0,
                                                    height: 112.5,
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        10.0, 30.0, 10.0, 5.0),
                                                    child: Column(
                                                      children: [
                                                        // 이름
                                                        CustomTextBuilder(
                                                          text:
                                                              '${getRecommendList[index]['nick']}',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textWhite1(),
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                        const SizedBox(
                                                            height: 5.0),
                                                        // 설명
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 5.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text:
                                                                '${getRecommendList[index]['description'] ?? ''}',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textBlack2(),
                                                            fontSize: 14.0,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            maxLines: 2,
                                                            textOverflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                // 아바타 이미지
                                                Positioned(
                                                  left: 72.5,
                                                  top: 45.0,
                                                  child: Container(
                                                    width: 55.0,
                                                    height: 55.0,
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig()
                                                          .userIconBackground(),
                                                      border: Border.all(
                                                        width: 2.0,
                                                        color: ColorsConfig()
                                                            .background(),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              40.0),
                                                      image: getRecommendList[
                                                                      index]
                                                                  ['avatar'] !=
                                                              false
                                                          ? DecorationImage(
                                                              image:
                                                                  NetworkImage(
                                                                getRecommendList[
                                                                        index]
                                                                    ['avatar'],
                                                                scale: 5.0,
                                                              ),
                                                              fit: BoxFit.none,
                                                              alignment:
                                                                  const Alignment(
                                                                      0.0,
                                                                      -0.3),
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      // DR-Public HOT 텍스트, 드롭다운 박스
                      Container(
                        color: ColorsConfig().subBackground1(),
                        margin: const EdgeInsets.only(top: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // DR-Public HOT 텍스트
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  15.0, 20.0, 15.0, 15.0),
                              child: CustomTextBuilder(
                                text: 'DR-Public HOT',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 22.0.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // 드롭다운 박스
                            Container(
                              width: 86.0,
                              height: 35.0,
                              margin: const EdgeInsets.only(right: 15.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              child: ButtonTheme(
                                alignedDropdown: true,
                                child: DropdownButton(
                                  value: dropdownCategoryValue,
                                  icon: Container(
                                    margin: const EdgeInsets.only(left: 4.0),
                                    child: SvgAssets(
                                      image: 'assets/icon/arrow_down.svg',
                                      color: ColorsConfig().textBlack2(),
                                      width: 12.0,
                                    ),
                                  ),
                                  dropdownColor:
                                      ColorsConfig().subBackground3(),
                                  underline: DropdownButtonHideUnderline(
                                    child: Container(),
                                  ),
                                  style: TextStyle(
                                      color: ColorsConfig().textWhite1(),
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w400),
                                  items: List.generate(5, (item) {
                                    return DropdownMenuItem(
                                      value: item == 0
                                          ? '국내증시'
                                          : item == 1
                                              ? '해외증시'
                                              : item == 2
                                                  ? '파생상품'
                                                  : item == 3
                                                      ? '암호화폐'
                                                      : '커뮤니티',
                                      alignment: Alignment.center,
                                      child: CustomTextBuilder(
                                        text: item == 0
                                            ? '국내증시'
                                            : item == 1
                                                ? '해외증시'
                                                : item == 2
                                                    ? '파생상품'
                                                    : item == 3
                                                        ? '암호화폐'
                                                        : '커뮤니티',
                                        height: 1.0,
                                      ),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setState(() async {
                                      final _prefs =
                                          await SharedPreferences.getInstance();
                                      int _categoryTypes = 0;

                                      dropdownCategoryValue = value.toString();

                                      switch (value) {
                                        case '전체':
                                          _categoryTypes = 0;
                                          break;
                                        case '국내증시':
                                          _categoryTypes = 1;
                                          break;
                                        case '해외증시':
                                          _categoryTypes = 2;
                                          break;
                                        case '파생상품':
                                          _categoryTypes = 3;
                                          break;
                                        case '암호화폐':
                                          _categoryTypes = 4;
                                          break;
                                        case '커뮤니티':
                                          _categoryTypes = 5;
                                          break;
                                      }

                                      GetHotPostListAPI()
                                          .hotPost(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              postCategory: _categoryTypes)
                                          .then((value) {
                                        setState(() {
                                          getHotPostData = value.result;
                                        });
                                      });
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // DR-Public HOT 데이터 영역
                      getHotPostData.isNotEmpty
                          ? ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: getHotPostData['data'].length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    if (getHotPostData['data'][index]['type'] ==
                                        4) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NewsDetailScreen(
                                            postIndex: getHotPostData['data']
                                                [index]['post_index'],
                                            postType: getHotPostData['data']
                                                [index]['type'],
                                          ),
                                        ),
                                      ).then((returns) async {
                                        if (returns != null) {
                                          if (returns['ret']) {
                                            setState(() {
                                              getHotPostData['data'].remove(
                                                  getHotPostData['data']
                                                      [index]);
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
                                                      getHotPostData['data']
                                                          [index]['post_index'])
                                              .then((value) {
                                            setState(() {
                                              getHotPostData['data'][index] =
                                                  value.result;
                                            });
                                          });
                                        }
                                      });
                                    } else if (getHotPostData['data'][index]
                                            ['type'] ==
                                        5) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              VoteDetailScreen(
                                            postIndex: getHotPostData['data']
                                                [index]['post_index'],
                                            postType: getHotPostData['data']
                                                [index]['type'],
                                          ),
                                        ),
                                      ).then((returns) async {
                                        if (returns != null) {
                                          if (returns['ret']) {
                                            setState(() {
                                              getHotPostData['data'].remove(
                                                  getHotPostData['data']
                                                      [index]);
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
                                                      getHotPostData['data']
                                                          [index]['post_index'])
                                              .then((value) {
                                            setState(() {
                                              getHotPostData['data'][index] =
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
                                            postIndex: getHotPostData['data']
                                                [index]['post_index'],
                                            postType: getHotPostData['data']
                                                [index]['type'],
                                          ),
                                        ),
                                      ).then((returns) async {
                                        if (returns != null) {
                                          if (returns['ret']) {
                                            setState(() {
                                              getHotPostData['data'].remove(
                                                  getHotPostData['data']
                                                      [index]);
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
                                                      getHotPostData['data']
                                                          [index]['post_index'])
                                              .then((value) {
                                            setState(() {
                                              getHotPostData['data'][index] =
                                                  value.result;
                                            });
                                          });
                                        }
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 15.0),
                                    decoration: BoxDecoration(
                                      color: ColorsConfig().subBackground1(),
                                      border: index !=
                                              getHotPostData['data'].length - 1
                                          ? Border(
                                              bottom: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        // 아바타 이미지, 닉네임, 업로드 날짜, 트로피, 글 타입
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // 아바타 이미지, 닉네임, 업로드 날짜, 트로피
                                            Row(
                                              children: [
                                                // 아바타 이미지
                                                Container(
                                                  width: 35.0,
                                                  height: 35.0,
                                                  margin: const EdgeInsets.only(
                                                      right: 8.0),
                                                  decoration: BoxDecoration(
                                                    color: ColorsConfig()
                                                        .userIconBackground(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            17.5),
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        getHotPostData['data']
                                                                [index]
                                                            ['avatar_url'],
                                                        scale: 7.0,
                                                      ),
                                                      fit: BoxFit.none,
                                                      alignment:
                                                          const Alignment(
                                                              0.0, -0.3),
                                                    ),
                                                  ),
                                                ),
                                                // 닉네임, 업로드 날짜, 트로피
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        // 닉네임
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 5.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text:
                                                                '${getHotPostData['data'][index]['nick']}',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 14.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        // 업로드 날짜
                                                        CustomTextBuilder(
                                                          text: DateCalculatorWrapper()
                                                              .daysCalculator(
                                                                  getHotPostData[
                                                                              'data']
                                                                          [
                                                                          index]
                                                                      ['date']),
                                                          fontColor:
                                                              ColorsConfig
                                                                  .defaultGray,
                                                          fontSize: 12.0,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ],
                                                    ),
                                                    // 트로피
                                                    Row(
                                                      children: List.generate(
                                                          getHotPostData['data']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'gift']
                                                                      .length >
                                                                  4
                                                              ? 4
                                                              : getHotPostData[
                                                                              'data']
                                                                          [
                                                                          index]
                                                                      ['gift']
                                                                  .length,
                                                          (trophys) {
                                                        return Row(
                                                          children: [
                                                            Container(
                                                              width: 18.0,
                                                              height: 18.0,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          4.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            9.0),
                                                                image:
                                                                    DecorationImage(
                                                                  image: NetworkImage(getHotPostData['data'][index]
                                                                              [
                                                                              'gift']
                                                                          [
                                                                          trophys]
                                                                      [
                                                                      'image']),
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          9.0),
                                                              child:
                                                                  CustomTextBuilder(
                                                                text:
                                                                    '${getHotPostData['data'][index]['gift'][trophys]['gift_count']}',
                                                                fontColor:
                                                                    ColorsConfig
                                                                        .defaultGray,
                                                                fontSize: 12.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            // 글 타입
                                            LabelCategoryWidgetBuilder(
                                                data: getHotPostData['data']
                                                    [index]['type']),
                                          ],
                                        ),
                                        const SizedBox(height: 15.0),
                                        // 제목, 내용, 이미지
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // 제목, 내용
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  170.0,
                                              height: 75.0,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 제목
                                                  CustomTextBuilder(
                                                    text:
                                                        '${getHotPostData['data'][index]['title']}',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 19.0.sp,
                                                    fontWeight: FontWeight.w600,
                                                    maxLines: 1,
                                                    textOverflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  // 내용
                                                  CustomTextBuilder(
                                                    text:
                                                        '${getHotPostData['data'][index]['description']}',
                                                    fontColor: ColorsConfig()
                                                        .textBlack2(),
                                                    fontSize: 17.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                    maxLines: 2,
                                                    textOverflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 이미지
                                            Container(
                                              width: 95.0,
                                              height: 73.0,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF666666),
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                image: getHotPostData['data']
                                                                [index]
                                                            ['category'] ==
                                                        'i'
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                            getHotPostData[
                                                                        'data']
                                                                    [index]
                                                                ['image'][0]),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
            )
          : const LoadingProgressScreen(),
      endDrawer: const DrawerBuilderWidget(),
      onEndDrawerChanged: (isDrawerOpen) async {
        if (!isDrawerOpen) {
          final _prefs = await SharedPreferences.getInstance();

          UserProfileInfoAPI()
              .getProfile(accesToken: _prefs.getString('AccessToken')!)
              .then((value) {
            setState(() {
              getProfileData = value?.result;
            });
          });
        }
      },
      backgroundColor: ColorsConfig().background(),
    );
  }
}
