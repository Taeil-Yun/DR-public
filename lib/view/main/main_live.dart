import 'dart:async';

import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/widget/loading.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/api/live/hot_room_list.dart';
import 'package:DRPublic/api/live/live_join_check.dart';
import 'package:DRPublic/api/live/live_room_list.dart';
import 'package:DRPublic/api/notification/notification_list.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/widget/drawer_widget.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class LiveListScreenBuilder extends StatefulWidget {
  const LiveListScreenBuilder({Key? key}) : super(key: key);

  @override
  State<LiveListScreenBuilder> createState() => _LiveListScreenBuilderState();
}

class _LiveListScreenBuilderState extends State<LiveListScreenBuilder> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final Timer _timer;

  var numberFormat = NumberFormat('###,###,###,###');

  bool isLoading = false;

  int lastNotificationCount = 0;
  int recentNotificationCount = 0;

  List<dynamic> liveListData = [];
  List<dynamic> hotLiveList = [];
  List<bool> allLiveCategoryState = [true, false, false, false];

  Map<String, dynamic> getProfileData = {};

  @override
  void initState() {
    apiInitialize();
    notificationLength();

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();

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
      GetLiveRoomListAPI()
          .list(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          liveListData = value.result;
        });
      }),
      GetHotLiveRoomListAPI()
          .hotList(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          hotLiveList = value.result;
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
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final _prefs = await SharedPreferences.getInstance();

      GetNotificationListDataAPIResponseModel _data =
          await GetNotificationListDataAPI()
              .notifications(accesToken: _prefs.getString('AccessToken')!);

      setState(() {
        if (_data.result.isEmpty) {
          recentNotificationCount = 0;
        } else {
          recentNotificationCount = _data.result.length;
        }
      });

      return _data.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        // toolbarHeight: 70.0,
        leadingWidth: 85.0,
        backgroundColor: ColorsConfig().subBackground1(),
        leading: DRAppBarLeading(
          press: () {
            // _scaffoldKey.currentState?.openDrawer();
          },
          icon: CustomTextBuilder(
            text: '라이브',
            fontColor: ColorsConfig().textWhite1(),
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
          ),
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

                  GetLiveRoomListAPI()
                      .list(accesToken: _prefs.getString('AccessToken')!)
                      .then((value) {
                    setState(() {
                      liveListData = value.result;
                    });
                  });

                  GetHotLiveRoomListAPI()
                      .hotList(accesToken: _prefs.getString('AccessToken')!)
                      .then((value) {
                    setState(() {
                      hotLiveList = value.result;
                    });
                  });
                },
                color: ColorsConfig().textWhite1(),
                backgroundColor: ColorsConfig().subBackgroundBlack(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hotLiveList.isNotEmpty
                          ? Container(
                              color: ColorsConfig().subBackground1(),
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // HOT 라이브 텍스트
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        15.0, 20.0, 15.0, 15.0),
                                    child: CustomTextBuilder(
                                      text: 'HOT 라이브',
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
                                      itemCount: hotLiveList.length,
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
                                                        hotLiveList[index]
                                                            ['idx'])
                                                .then((joined) {
                                              if (joined.result['status'] ==
                                                  14007) {
                                                Navigator.pushNamed(
                                                    context, 'live_room',
                                                    arguments: {
                                                      "room_index":
                                                          hotLiveList[index]
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
                                                    hotLiveList.length - 1
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
                                                          hotLiveList[index]
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
                                                        '${hotLiveList[index]['title']}',
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
                                                            hotLiveList[index]
                                                                ['avatar'],
                                                            scale: 12.5,
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
                                                            '${hotLiveList[index]['nick']}',
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
                                                      text: numberFormat.format(
                                                          hotLiveList[index]
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
                      Container(
                        color: ColorsConfig().subBackground1(),
                        margin: const EdgeInsets.only(top: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 전체 라이브 텍스트
                            Container(
                              margin: const EdgeInsets.fromLTRB(
                                  15.0, 20.0, 15.0, 10.0),
                              child: CustomTextBuilder(
                                text: '전체 라이브',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 22.0.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // 전체 라이브 리스트
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: liveListData.length,
                              itemBuilder: (context, index) {
                                String _tags = '';

                                for (int i = 0;
                                    i <
                                        liveListData[index]['tag']
                                            .toString()
                                            .split(',')
                                            .length;
                                    i++) {
                                  _tags +=
                                      '${liveListData[index]['tag'].toString().split(',')[i].trim().replaceFirst('', '#')} ';
                                }

                                return InkWell(
                                  onTap: () async {
                                    final _prefs =
                                        await SharedPreferences.getInstance();

                                    LiveJoinCheckAPI()
                                        .join(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            roomIndex: liveListData[index]
                                                ['idx'])
                                        .then((joined) {
                                      if (joined.result['status'] == 14007) {
                                        Navigator.pushNamed(
                                            context, 'live_room',
                                            arguments: {
                                              "room_index": liveListData[index]
                                                  ['idx'],
                                              "user_index":
                                                  getProfileData['id'],
                                              "nickname":
                                                  getProfileData['nick'],
                                              "avatar":
                                                  getProfileData['avatar'],
                                              "is_header": false,
                                            });
                                      } else if (joined.result['status'] ==
                                          14008) {
                                        PopUpModal(
                                          title: '',
                                          titlePadding: EdgeInsets.zero,
                                          onTitleWidget: Container(),
                                          content: '',
                                          contentPadding: EdgeInsets.zero,
                                          backgroundColor:
                                              ColorsConfig.transparent,
                                          onContentWidget: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 136.0,
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .subBackground1(),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(8.0),
                                                    topRight:
                                                        Radius.circular(8.0),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text:
                                                        '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
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
                                                      color: ColorsConfig()
                                                          .border1(),
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
                                                            fontSize: 16.0.sp,
                                                            fontWeight:
                                                                FontWeight.w400,
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
                                    padding: const EdgeInsets.all(15.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 이미지
                                        Container(
                                          width: 120.0,
                                          height: 79.0,
                                          margin: const EdgeInsets.only(
                                              right: 10.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig().textBlack2(),
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  liveListData[index]
                                                      ['thumbnail']),
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                        ),
                                        // 제목, 태그, 아바타 이미지, 닉네임, 시청자
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              160.0,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 제목
                                              SizedBox(
                                                height: 40.0,
                                                child: CustomTextBuilder(
                                                  text:
                                                      '${liveListData[index]['title']}',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 18.0.sp,
                                                  fontWeight: FontWeight.w600,
                                                  maxLines: 2,
                                                  textOverflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // 태그
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    160.0,
                                                margin: const EdgeInsets.only(
                                                    top: 2.0, bottom: 5.0),
                                                child: CustomTextBuilder(
                                                  text: _tags,
                                                  fontColor:
                                                      ColorsConfig().hashTag(),
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w400,
                                                  maxLines: 1,
                                                  textOverflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // 아바타 이미지, 닉네임, 시청자 수
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
                                                          BorderRadius.circular(
                                                              10.0),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                          liveListData[index]
                                                              ['avatar'],
                                                          scale: 12.5,
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
                                                          '${liveListData[index]['nick']}',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 12.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  // 시청자 아이콘
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 5.0),
                                                    child: const Icon(
                                                      Icons.group_outlined,
                                                      color: ColorsConfig
                                                          .defaultGray,
                                                      size: 18.0,
                                                    ),
                                                  ),
                                                  // 시청자 수
                                                  CustomTextBuilder(
                                                    text: numberFormat.format(
                                                        liveListData[index]
                                                            ['total']),
                                                    fontColor: ColorsConfig
                                                        .defaultGray,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
