import 'dart:async';
import 'dart:io';

import 'package:DRPublic/widget/loading.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/image_cropper/image_cropper.dart';
import 'package:DRPublic/component/image_picker/image_picker.dart';
import 'package:DRPublic/api/gift/gift_history.dart';
import 'package:DRPublic/api/like/add.dart';
import 'package:DRPublic/api/like/cancel.dart';
import 'package:DRPublic/api/notification/notification_list.dart';
import 'package:DRPublic/api/profile/badge_list.dart';
import 'package:DRPublic/api/profile/my_post_list.dart';
import 'package:DRPublic/api/subscribe/my_subscribe.dart';
import 'package:DRPublic/api/subscribe/your_subscribe.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/widget/drawer_widget.dart';
import 'package:DRPublic/widget/get_youtube_thumbnail.dart';
import 'package:DRPublic/widget/sliver_tabbar_widget.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:DRPublic/widget/url_launcher.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  late TabController _trophyTabController;
  late ScrollController _scrollController;

  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  final PageController _pageController = PageController();

  var numberFormat = NumberFormat('###,###,###,###');

  double kExpandedHeight = 332.0;

  Timer? _debounce;

  int _currentIndex = 0;
  int _trophyCurrentIndex = 0;
  int voteTotalCount = 0;
  int addLikeCount = 0;
  int commentsAddLikeCount = 0;
  int getThophysAddLikeCount = 0;
  int sendThophysAddLikeCount = 0;
  int currentPage = 0;
  int lastNotificationCount = 0;
  int recentNotificationCount = 0;

  bool hasExpandedAppBar = false;
  bool changeDescription = false;
  bool onNavigatorState = false;
  bool isLoading = false;

  Map<String, dynamic> getProfileData = {};

  List<dynamic> getBadgeList = [];
  List<dynamic> getMyPostList = [];
  List<dynamic> getCommentsData = [];
  List<dynamic> getTrophyData = [];
  List<dynamic> sendTrophyData = [];
  List<dynamic> getUserToMeSubscribeList = [];
  List<dynamic> getMyToUserSubscribeList = [];
  List<bool> getPostListMoreBtnState = [];
  List<bool> getCommentsMoreBtnState = [];
  List<bool> getTrophyMoreBtnState = [];
  List<bool> sendTrophyMoreBtnState = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setState(() {
        if (RouteGetArguments().getArgs(context)['onNavigator'] != null) {
          onNavigatorState =
              RouteGetArguments().getArgs(context)['onNavigator'];
        }
      });
    });

    _scrollController = ScrollController()
      ..addListener(() {
        scrollListener();
        setState(() {
          hasExpandedAppBar = isSliverAppBarExpanded;
        });
      });

    // 뱃지, 공유글, 댓글, 트로피의 탭바
    _tabController = TabController(
      length: 7,
      vsync: this, // vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

    // 트로피 준 글, 트로피 받은 글의 탭바
    _trophyTabController = TabController(
      length: 2,
      vsync: this,
    );
    _trophyTabController.addListener(trophyHandleTabSelection);

    apiInitialize();

    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
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
      Future.wait([
        // 나를 구독한 사람들
        GetMySubScribeListAPI()
            .subscribe(
                accesToken: _prefs.getString('AccessToken')!,
                nickname: value?.result['nick'])
            .then((value) {
          setState(() {
            getUserToMeSubscribeList = value.result;
          });
        }),
        // 내가 구독한 사람들
        GetYourSubScribeListAPI()
            .subscribe(
                accesToken: _prefs.getString('AccessToken')!,
                nickname: value?.result['nick'])
            .then((value) {
          setState(() {
            getMyToUserSubscribeList = value.result;
          });
        }),
        // 뱃지
        GetBadgeListAPI()
            .badge(
                accesToken: _prefs.getString('AccessToken')!,
                nickname: value?.result['nick'])
            .then((badges) {
          setState(() {
            getBadgeList = badges.result;
          });
        }),
        // 공유글
        GetMyPostListAPI()
            .post(accesToken: _prefs.getString('AccessToken')!, type: 0)
            .then((posts) {
          setState(() {
            getMyPostList = posts.result['data'];

            for (int i = 0; i < posts.result['data'].length; i++) {
              getPostListMoreBtnState.add(false);
            }
          });
        }),
        // 코멘트
        GetMyPostListAPI()
            .post(accesToken: _prefs.getString('AccessToken')!, type: 1)
            .then((comments) {
          setState(() {
            getCommentsData = comments.result['data'];

            for (int i = 0; i < comments.result['data'].length; i++) {
              getCommentsMoreBtnState.add(false);
            }
          });
        }),
        // 내가 선물(트로피) 준 글
        GetMyPostListAPI()
            .post(accesToken: _prefs.getString('AccessToken')!, type: 2)
            .then((thophys) {
          setState(() {
            getTrophyData = thophys.result['data'];

            for (int i = 0; i < thophys.result['data'].length; i++) {
              getTrophyMoreBtnState.add(false);
            }
          });
        }),
        // 내가 선물(트로피) 받은 글
        GetMyPostListAPI()
            .post(accesToken: _prefs.getString('AccessToken')!, type: 3)
            .then((thophys) {
          setState(() {
            sendTrophyData = thophys.result['data'];

            for (int i = 0; i < thophys.result['data'].length; i++) {
              sendTrophyMoreBtnState.add(false);
            }
          });
        }),
      ]);
      //.then((_) {
      //   setState(() {
      //     isLoading = true;
      //   });
      // });
    });
  }

  scrollListener() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (_scrollController.hasClients) {
        if (_scrollController.offset >
            _scrollController.position.maxScrollExtent - 200.0) {
          if (_currentIndex == 3) {
            SharedPreferences.getInstance().then((_prefs) {
              GetMyPostListAPI()
                  .post(
                      accesToken: _prefs.getString('AccessToken')!,
                      type: 0,
                      cursor: getMyPostList.last['post_index'])
                  .then((posts) {
                for (int i = 0; i < posts.result['data'].length; i++) {
                  setState(() {
                    getMyPostList.add(posts.result['data'][i]);
                    getPostListMoreBtnState.add(false);
                  });
                }
              });
            });
          } else if (_currentIndex == 4) {
            SharedPreferences.getInstance().then((_prefs) {
              GetMyPostListAPI()
                  .post(
                      accesToken: _prefs.getString('AccessToken')!,
                      type: 1,
                      cursor: getCommentsData.last['post_index'])
                  .then((comments) {
                for (int i = 0; i < comments.result['data'].length; i++) {
                  setState(() {
                    getCommentsData.add(comments.result['data'][i]);
                    getCommentsMoreBtnState.add(false);
                  });
                }
              });
            });
          } else if (_currentIndex == 5) {
            SharedPreferences.getInstance().then((_prefs) {
              GetMyPostListAPI()
                  .post(
                      accesToken: _prefs.getString('AccessToken')!,
                      type: 2,
                      cursor: getTrophyData.last['post_index'])
                  .then((thophys) {
                for (int i = 0; i < thophys.result['data'].length; i++) {
                  setState(() {
                    getTrophyData.add(thophys.result['data'][i]);
                    getTrophyMoreBtnState.add(false);
                  });
                }
              });
            });
          } else if (_currentIndex == 6) {
            SharedPreferences.getInstance().then((_prefs) {
              GetMyPostListAPI()
                  .post(
                      accesToken: _prefs.getString('AccessToken')!,
                      type: 3,
                      cursor: sendTrophyData.last['post_index'])
                  .then((thophys) {
                for (int i = 0; i < thophys.result['data'].length; i++) {
                  setState(() {
                    sendTrophyData.add(thophys.result['data'][i]);
                    sendTrophyMoreBtnState.add(false);
                  });
                }
              });
            });
          }
        }
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _currentIndex) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  void trophyHandleTabSelection() {
    if (_trophyTabController.indexIsChanging ||
        _trophyTabController.index != _trophyCurrentIndex) {
      setState(() {
        _trophyCurrentIndex = _trophyTabController.index;
      });
    }
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

  // sliver appbar 축소 or 확대 체크 함수
  bool get isSliverAppBarExpanded {
    return _scrollController.hasClients &&
        _scrollController.offset > kExpandedHeight - kToolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _descriptionFocusNode.unfocus();
      },
      child: Scaffold(
        key: !onNavigatorState ? _scaffoldKey : null,
        backgroundColor: ColorsConfig().background(),
        endDrawer: !onNavigatorState ? const DrawerBuilderWidget() : null,
        onEndDrawerChanged: !onNavigatorState
            ? (isDrawerOpen) async {
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
              }
            : null,
        body: getProfileData.isNotEmpty
            ? CustomScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // sliver appbar
                  SliverAppBar(
                    expandedHeight: changeDescription
                        ? kExpandedHeight + 24.0
                        : kExpandedHeight,
                    pinned: true,
                    elevation: 0.0,
                    leadingWidth: !onNavigatorState ? 110.0 : null,
                    backgroundColor: ColorsConfig().profileBackground(),
                    systemOverlayStyle:
                        Theme.of(context).appBarTheme.systemOverlayStyle,
                    leading: !onNavigatorState
                        ? null
                        : DRAppBarLeading(
                            press: () => Navigator.pop(context),
                          ),
                    title: DRAppBarTitle(
                      title: '${getProfileData['nick']}의 채널',
                    ),
                    actions: !onNavigatorState
                        ? [
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
                              padding:
                                  const EdgeInsets.only(left: 5.0, right: 10.0),
                              child: InkWell(
                                onTap: () {
                                  SharedPreferences.getInstance()
                                      .then((_prefs) {
                                    _prefs.setInt('NotificationCount',
                                        recentNotificationCount);
                                  });

                                  setState(() {
                                    lastNotificationCount =
                                        recentNotificationCount;
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
                                    recentNotificationCount !=
                                            lastNotificationCount
                                        ? Positioned(
                                            top: 22.0,
                                            right: 1.0,
                                            child: Container(
                                              width: 6.0,
                                              height: 6.0,
                                              decoration: BoxDecoration(
                                                color: ColorsConfig
                                                    .notificationDots,
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
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
                                      color:
                                          ColorsConfig().userIconBackground(),
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                      image: getProfileData.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                getProfileData['avatar'],
                                                scale: 7.0,
                                              ),
                                              filterQuality: FilterQuality.high,
                                              fit: BoxFit.none,
                                              alignment:
                                                  const Alignment(0.0, -0.3),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        : null,
                    flexibleSpace: FlexibleSpaceBar(
                      background: SafeArea(
                        left: false,
                        right: false,
                        bottom: false,
                        child: Column(
                          children: [
                            // 커버 이미지
                            changeDescription
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 91.0,
                                    margin: const EdgeInsets.only(
                                        top: kToolbarHeight),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: getProfileData[
                                                      'app_background'] !=
                                                  false
                                              ? getProfileData[
                                                          'local_upload'] ==
                                                      true
                                                  ? Image(
                                                      image: FileImage(File(
                                                          getProfileData[
                                                              'app_background'])),
                                                      filterQuality:
                                                          FilterQuality.high,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image(
                                                      image: NetworkImage(
                                                          getProfileData[
                                                              'app_background']),
                                                      filterQuality:
                                                          FilterQuality.high,
                                                      fit: BoxFit.cover,
                                                    )
                                              : Container(),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            ImagePickerSelector()
                                                .imagePicker()
                                                .then((selectImage) {
                                              ImageCropperLauncher()
                                                  .imageCropper(selectImage)
                                                  .then((value) {
                                                setState(() {
                                                  getProfileData[
                                                          'app_background'] =
                                                      value.path;
                                                  getProfileData[
                                                      'local_upload'] = true;
                                                  getProfileData[
                                                          'local_upload_file'] =
                                                      value;
                                                });
                                              });
                                            });
                                          },
                                          child: Container(
                                            color: ColorsConfig().colorPicker(
                                                color:
                                                    ColorsConfig.defaultBlack,
                                                opacity: 0.75),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SvgAssets(
                                                    image:
                                                        'assets/icon/gallery.svg',
                                                    color: ColorsConfig
                                                        .defaultWhite,
                                                  ),
                                                  const SizedBox(width: 10.0),
                                                  CustomTextBuilder(
                                                    text: '이미지 변경',
                                                    fontColor: ColorsConfig
                                                        .defaultWhite,
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 91.0,
                                    margin: const EdgeInsets.only(
                                        top: kToolbarHeight),
                                    child: getProfileData['app_background'] ==
                                            false
                                        ? const Image(
                                            image: AssetImage(
                                                'assets/img/cover_background.png'),
                                            filterQuality: FilterQuality.high,
                                            fit: BoxFit.cover,
                                          )
                                        : getProfileData['local_upload'] == true
                                            ? Image(
                                                image: FileImage(File(
                                                    getProfileData[
                                                        'app_background'])),
                                                filterQuality:
                                                    FilterQuality.high,
                                                fit: BoxFit.cover,
                                              )
                                            : Image(
                                                image: NetworkImage(
                                                    getProfileData[
                                                        'app_background']),
                                                filterQuality:
                                                    FilterQuality.high,
                                                fit: BoxFit.cover,
                                              )),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: changeDescription ? 215.0 : 185.0,
                              padding: const EdgeInsets.fromLTRB(
                                  20.0, 14.0, 20.0, 16.0),
                              child: Row(
                                children: [
                                  // 아바타
                                  Container(
                                    height: 150.0,
                                    margin: const EdgeInsets.only(right: 7.0),
                                    child: getProfileData['avatar'] != null
                                        ? Image(
                                            image: NetworkImage(
                                              getProfileData['avatar'],
                                            ),
                                          )
                                        : Container(),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin:
                                            const EdgeInsets.only(top: 14.0),
                                        child: Row(
                                          children: [
                                            // 닉네임
                                            CustomTextBuilder(
                                              text: '${getProfileData['nick']}',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            const SizedBox(width: 6.0),
                                            // 가입일자
                                            CustomTextBuilder(
                                              text:
                                                  '${DateFormat('yyyy.MM.dd').format(DateTime.parse(getProfileData['reg_date']))} 가입',
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/subscribe',
                                              arguments: {
                                                'tabIndex': 1,
                                                'user_nickname':
                                                    getProfileData['nick'],
                                              });
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(top: 5.0),
                                          child: Row(
                                            children: [
                                              // 구독자
                                              Row(
                                                children: [
                                                  CustomTextBuilder(
                                                    text: '구독자',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  const SizedBox(width: 6.0),
                                                  CustomTextBuilder(
                                                    text: numberFormat.format(
                                                        getUserToMeSubscribeList
                                                            .length),
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 15.5),
                                              // 구독중
                                              Row(
                                                children: [
                                                  CustomTextBuilder(
                                                    text: '구독중',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  const SizedBox(width: 6.0),
                                                  CustomTextBuilder(
                                                    text: numberFormat.format(
                                                        getMyToUserSubscribeList
                                                            .length),
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // 자기소개 텍스트
                                      changeDescription
                                          ? Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  149.0,
                                              height: 76.0,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10.0),
                                              child: TextFormField(
                                                  controller:
                                                      _descriptionController,
                                                  focusNode:
                                                      _descriptionFocusNode,
                                                  autofocus: true,
                                                  cursorColor:
                                                      ColorsConfig().primary(),
                                                  maxLines: null,
                                                  expands: true,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  maxLength: 60,
                                                  decoration: InputDecoration(
                                                    isCollapsed: true,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 5.0,
                                                            vertical: 4.0),
                                                    border: OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                        width: 0.5,
                                                        color: ColorsConfig
                                                            .subscribeBtnPrimary,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.0),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                        width: 0.5,
                                                        color: ColorsConfig
                                                            .subscribeBtnPrimary,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.0),
                                                    ),
                                                    counterText: '',
                                                    hintText: '자기소개가 없습니다.',
                                                    hintStyle: TextStyle(
                                                      color: ColorsConfig()
                                                          .textBlack2(),
                                                      fontSize: 14.0.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                        width: 0.5,
                                                        color: ColorsConfig
                                                            .subscribeBtnPrimary,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.0),
                                                    ),
                                                  ),
                                                  style: TextStyle(
                                                    color: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 14.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  )),
                                            )
                                          : Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  162.0,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10.0),
                                              child: CustomTextBuilder(
                                                text: getProfileData[
                                                            'description'] !=
                                                        null
                                                    ? '${getProfileData['description']}'
                                                    : '',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w400,
                                                maxLines: 3,
                                                textOverflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                      changeDescription
                                          ? InkWell(
                                              onTap: () async {
                                                if (changeDescription) {
                                                  final _prefs =
                                                      await SharedPreferences
                                                          .getInstance();

                                                  UserProfileInfoAPI()
                                                      .setProfile(
                                                          accesToken:
                                                              _prefs.getString(
                                                                  'AccessToken')!,
                                                          description:
                                                              _descriptionController
                                                                  .text,
                                                          image: getProfileData[
                                                                          'local_upload'] !=
                                                                      null &&
                                                                  getProfileData[
                                                                      'local_upload']
                                                              ? getProfileData[
                                                                  'local_upload_file']
                                                              : null)
                                                      .then((value) {
                                                    if (value
                                                            .result['status'] ==
                                                        10005) {
                                                      setState(() {
                                                        getProfileData[
                                                                'description'] =
                                                            _descriptionController
                                                                .text;
                                                        changeDescription =
                                                            false;
                                                        kExpandedHeight = 332.0;
                                                        _descriptionController
                                                            .clear();
                                                      });
                                                    }
                                                  });
                                                }
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    149.0,
                                                height: 33.0,
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig
                                                      .subscribeBtnPrimary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text: '완료',
                                                    fontColor: ColorsConfig
                                                        .defaultWhite,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                // 아바타 변경 버튼
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.pushNamed(context,
                                                        '/avatar_change',
                                                        arguments: {
                                                          'tabIndex': 0
                                                        }).then((_) async {
                                                      final _prefs =
                                                          await SharedPreferences
                                                              .getInstance();

                                                      UserProfileInfoAPI()
                                                          .getProfile(
                                                              accesToken: _prefs
                                                                  .getString(
                                                                      'AccessToken')!)
                                                          .then((value) {
                                                        setState(() {
                                                          getProfileData =
                                                              value?.result;
                                                        });
                                                      });
                                                    });
                                                  },
                                                  child: Container(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width /
                                                                2) -
                                                            77.0,
                                                    height: 33.0,
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig
                                                          .subscribeBtnPrimary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.0),
                                                    ),
                                                    child: Center(
                                                      child: CustomTextBuilder(
                                                        text: '아바타 변경',
                                                        fontColor: ColorsConfig
                                                            .defaultWhite,
                                                        fontSize: 13.0,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5.0),
                                                // 프로필 수정 버튼
                                                InkWell(
                                                  onTap: () async {
                                                    if (changeDescription) {
                                                      final _prefs =
                                                          await SharedPreferences
                                                              .getInstance();

                                                      UserProfileInfoAPI()
                                                          .setProfile(
                                                              accesToken: _prefs
                                                                  .getString(
                                                                      'AccessToken')!,
                                                              description:
                                                                  _descriptionController
                                                                          .text
                                                                          .isNotEmpty
                                                                      ? _descriptionController
                                                                          .text
                                                                      : '')
                                                          .then((value) {
                                                        if (value.result[
                                                                'status'] ==
                                                            10005) {
                                                          setState(() {
                                                            getProfileData[
                                                                    'description'] =
                                                                _descriptionController
                                                                    .text;
                                                            changeDescription =
                                                                false;
                                                            _descriptionController
                                                                .clear();
                                                          });
                                                        }
                                                      });
                                                    } else {
                                                      setState(() {
                                                        changeDescription =
                                                            true;
                                                        _descriptionController
                                                            .text = getProfileData[
                                                                'description'] ??
                                                            '';
                                                        kExpandedHeight = 340.0;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width /
                                                                2) -
                                                            77.0,
                                                    height: 33.0,
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig
                                                          .defaultWhite,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.0),
                                                    ),
                                                    child: Center(
                                                      child: CustomTextBuilder(
                                                        text: '프로필 수정',
                                                        fontColor: ColorsConfig
                                                            .messageBtnBackground,
                                                        fontSize: 13.0,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    shape: !hasExpandedAppBar
                        ? const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16.0),
                              bottomRight: Radius.circular(16.0),
                            ),
                          )
                        : null,
                  ),
                  // tabbar sliver header
                  SliverPersistentHeader(
                    delegate: SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: ColorsConfig().primary(),
                        unselectedLabelColor: ColorsConfig().textWhite1(),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        padding: EdgeInsets.zero,
                        labelPadding: EdgeInsets.zero,
                        labelColor: ColorsConfig().textWhite1(),
                        labelStyle: TextStyle(
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        onTap: (_) {
                          // tabbar 클릭시 탭바의 콘텐츠가 스크롤 값이 sliver appbar 보다 작은경우
                          Future.delayed(const Duration(milliseconds: 6))
                              .then((valu) {
                            if (_scrollController.offset <
                                kExpandedHeight - kToolbarHeight) {
                              setState(() {
                                hasExpandedAppBar = false;
                              });
                            }
                          });
                        },
                        tabs: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '뱃지',
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '프리미엄 콘텐츠',
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '투자내역',
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '공유글',
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '댓글',
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '트로피 준 글',
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            color: ColorsConfig().subBackground1(),
                            child: Tab(
                              child: CustomTextBuilder(
                                text: '트로피 받은 글',
                              ),
                            ),
                          ),
                        ],
                      ),
                      isSliverAppBarExpanded,
                    ),
                    pinned: true,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          constraints: BoxConstraints(
                            minHeight:
                                (MediaQuery.of(context).size.height - 46.0) / 2,
                            maxHeight: double.infinity,
                          ),
                          child: [
                            // 뱃지 리스트
                            SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.all(20.0),
                                    color: ColorsConfig().background(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CustomTextBuilder(
                                              text: '보유뱃지 ',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            CustomTextBuilder(text: ' '),
                                            CustomTextBuilder(
                                              text: '${getBadgeList.length}',
                                              fontColor:
                                                  ColorsConfig().primary(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ],
                                        ),
                                        CustomTextBuilder(
                                          text: '언제 어디서 받을 지 모르는 뱃지의 기회?!',
                                          fontColor:
                                              ColorsConfig().textBlack2(),
                                          fontSize: 14.0.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4.0, bottom: 20.0),
                                    child: getBadgeList.isNotEmpty
                                        ? Column(
                                            children: List.generate(
                                                getBadgeList.length, (index) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 12.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .subBackground1(),
                                                  border: index == 0
                                                      ? Border(
                                                          top: BorderSide(
                                                            width: 0.5,
                                                            color:
                                                                ColorsConfig()
                                                                    .border1(),
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 48.0,
                                                      height: 48.0,
                                                      decoration: BoxDecoration(
                                                        color: ColorsConfig()
                                                            .textBlack2(),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                            getBadgeList[index]
                                                                ['image'],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              104.0,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 16.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          CustomTextBuilder(
                                                            text:
                                                                '${getBadgeList[index]['title']}',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 16.0.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          const SizedBox(
                                                              height: 4.0),
                                                          CustomTextBuilder(
                                                            text:
                                                                '${getBadgeList[index]['description']}',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 14.0.sp,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          )
                                        : Container(
                                            height: 250.0.h,
                                            color: ColorsConfig().background(),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(
                                                    width: 114.0,
                                                    height: 114.0,
                                                    child: Image(
                                                      image: AssetImage(
                                                          'assets/img/none_data.png'),
                                                      filterQuality:
                                                          FilterQuality.high,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  CustomTextBuilder(
                                                    text: '콘텐츠가 없습니다.',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 16.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            // 프리미엄 콘텐츠 리스트
                            // SafeArea(
                            //   top: false,
                            //   left: false,
                            //   right: false,
                            //   child: Container(
                            //     width: MediaQuery.of(context).size.width,
                            //     padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 15.0),
                            //     color: ColorsConfig().background(),
                            //     child: Column(
                            //       children: List.generate(10, (index) {
                            //         return Container(
                            //           width: MediaQuery.of(context).size.width,
                            //           height: 332.0,
                            //           margin: const EdgeInsets.only(top: 15.0),
                            //           decoration: BoxDecoration(
                            //             color: ColorsConfig().subBackground1(),
                            //             borderRadius: BorderRadius.circular(6.0),
                            //           ),
                            //           child: Column(
                            //             crossAxisAlignment: CrossAxisAlignment.start,
                            //             children: [
                            //               // 이미지 영역
                            //               Container(
                            //                 height: 150.0,
                            //                 decoration: const BoxDecoration(
                            //                   color: Color(0xFF666666),
                            //                 ),
                            //                 child: Row(
                            //                   mainAxisAlignment: MainAxisAlignment.end,
                            //                   crossAxisAlignment: CrossAxisAlignment.start,
                            //                   children: [
                            //                     Container(
                            //                       margin: const EdgeInsets.only(top: 10.0, right: 10.0),
                            //                       padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.0),
                            //                       decoration: BoxDecoration(
                            //                         color: ColorsConfig().avatarIconColor(opacity: 0.8),
                            //                         borderRadius: BorderRadius.circular(17.0),
                            //                       ),
                            //                       child: Row(
                            //                         children: [
                            //                           // 이미지 영역
                            //                           Container(
                            //                             width: 22.0,
                            //                             height: 22.0,
                            //                             color: Colors.red,
                            //                             margin: const EdgeInsets.only(right: 7.0),
                            //                           ),
                            //                           // 가격
                            //                           CustomTextBuilder(
                            //                             text: '150',
                            //                             fontColor: ColorsConfig.defaultWhite,
                            //                             fontSize: 17.0,
                            //                             fontWeight: FontWeight.w400,
                            //                           ),
                            //                         ],
                            //                       ),
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //               // 제목, 내용등
                            //               Container(
                            //                 padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                            //                 decoration: BoxDecoration(
                            //                   border: Border(
                            //                     bottom: BorderSide(
                            //                       width: 1.0,
                            //                       color: ColorsConfig().border1(),
                            //                     ),
                            //                   ),
                            //                 ),
                            //                 child: Column(
                            //                   crossAxisAlignment: CrossAxisAlignment.start,
                            //                   children: [
                            //                     // 날짜
                            //                     CustomTextBuilder(
                            //                       text: '2022.09.18 18:20',
                            //                       fontColor: ColorsConfig().textBlack2(),
                            //                       fontSize: 12.0,
                            //                       fontWeight: FontWeight.w400,
                            //                     ),
                            //                     // 제목
                            //                     Container(
                            //                       margin: const EdgeInsets.only(top: 3.0, bottom: 5.0),
                            //                       child: CustomTextBuilder(
                            //                         text: '헛! 허슬플레이어 입니다.',
                            //                         fontColor: ColorsConfig().textWhite1(),
                            //                         fontSize: 18.0,
                            //                         fontWeight: FontWeight.w700,
                            //                       ),
                            //                     ),
                            //                     // 내용
                            //                     CustomTextBuilder(
                            //                       text: '안녕하세요? DR-Public 여러분, 반갑습니다. "팔로우"를 해두시면, 언제나 빠르게 새로운 정보를 얻으실 수 있으십니다.',
                            //                       fontColor: ColorsConfig().textWhite1(),
                            //                       fontSize: 16.0,
                            //                       fontWeight: FontWeight.w400,
                            //                       maxLines: 2,
                            //                       textOverflow: TextOverflow.ellipsis,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //               // 확인하기 버튼
                            //               InkWell(
                            //                 onTap: () {
                            //                   print('saf');
                            //                 },
                            //                 child: SizedBox(
                            //                   width: MediaQuery.of(context).size.width,
                            //                   height: 55.0,
                            //                   child: Center(
                            //                     child: CustomTextBuilder(
                            //                       text: '확인하기',
                            //                       fontColor: ColorsConfig().textWhite1(),
                            //                       fontSize: 16.0,
                            //                       fontWeight: FontWeight.w700,
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         );
                            //       }),
                            //     ),
                            //   ),
                            // ),
                            Container(
                              color: ColorsConfig().background(),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 114.0,
                                      height: 114.0,
                                      child: Image(
                                        image: AssetImage(
                                            'assets/img/none_data.png'),
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                    const SizedBox(height: 20.0),
                                    CustomTextBuilder(
                                      text: '콘텐츠가 없습니다.',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            // 투자내역 리스트
                            Container(
                              color: ColorsConfig().background(),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 114.0,
                                      height: 114.0,
                                      child: Image(
                                        image: AssetImage(
                                            'assets/img/none_data.png'),
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                    const SizedBox(height: 20.0),
                                    CustomTextBuilder(
                                      text: '콘텐츠가 없습니다.',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            // 공유글 리스트
                            SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              child: getMyPostList.isNotEmpty
                                  ? Column(
                                      children: List.generate(
                                          getMyPostList.length, (index) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color:
                                                ColorsConfig().subBackground1(),
                                            border:
                                                index != getMyPostList.length
                                                    ? Border(
                                                        top: BorderSide(
                                                          width: 0.5,
                                                          color: ColorsConfig()
                                                              .border1(),
                                                        ),
                                                      )
                                                    : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 유저 이미지, 닉네임, 날짜, 더보기 버튼
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20.0, 13.0, 20.0, 0.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        // 이미지
                                                        Container(
                                                          width: 42.0,
                                                          height: 42.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ColorsConfig()
                                                                .userIconBackground(),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        21.0),
                                                            image:
                                                                DecorationImage(
                                                              image:
                                                                  NetworkImage(
                                                                getMyPostList[
                                                                        index][
                                                                    'avatar_url'],
                                                                scale: 5.5,
                                                              ),
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                              fit: BoxFit.none,
                                                              alignment:
                                                                  const Alignment(
                                                                      0.0,
                                                                      -0.3),
                                                            ),
                                                          ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
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
                                                                      // 닉네임
                                                                      Container(
                                                                        margin: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                8.0),
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text:
                                                                              '${getMyPostList[index]['nick']}',
                                                                          fontColor:
                                                                              ColorsConfig().textWhite1(),
                                                                          fontSize:
                                                                              16.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                      CustomTextBuilder(
                                                                        text: DateCalculatorWrapper().daysCalculator(getMyPostList[index]
                                                                            [
                                                                            'date']),
                                                                        fontColor:
                                                                            ColorsConfig().textBlack2(),
                                                                        fontSize:
                                                                            12.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            13.0),
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            8.0,
                                                                        vertical:
                                                                            3.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: getMyPostList[index]['type'] ==
                                                                              1
                                                                          ? ColorsConfig()
                                                                              .postLabel()
                                                                          : getMyPostList[index]['type'] == 2
                                                                              ? ColorsConfig().analyticsLabel()
                                                                              : getMyPostList[index]['type'] == 3
                                                                                  ? ColorsConfig().debateLabel()
                                                                                  : getMyPostList[index]['type'] == 4
                                                                                      ? ColorsConfig().newsLabel()
                                                                                      : getMyPostList[index]['type'] == 5
                                                                                          ? ColorsConfig().voteLabel()
                                                                                          : ColorsConfig.defaultWhite,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              4.0),
                                                                    ),
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text: getMyPostList[index]['type'] ==
                                                                              1
                                                                          ? '포스트'
                                                                          : getMyPostList[index]['type'] == 2
                                                                              ? '분 석'
                                                                              : getMyPostList[index]['type'] == 3
                                                                                  ? '토 론'
                                                                                  : getMyPostList[index]['type'] == 4
                                                                                      ? '뉴 스'
                                                                                      : getMyPostList[index]['type'] == 5
                                                                                          ? '투 표'
                                                                                          : '',
                                                                      fontColor:
                                                                          ColorsConfig
                                                                              .defaultWhite,
                                                                      fontSize:
                                                                          11.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap: () async {
                                                                final _prefs =
                                                                    await SharedPreferences
                                                                        .getInstance();

                                                                GetGiftHistoryListDataAPI()
                                                                    .giftHistory(
                                                                        accesToken:
                                                                            _prefs.getString(
                                                                                'AccessToken')!,
                                                                        postIndex:
                                                                            getMyPostList[index][
                                                                                'post_index'])
                                                                    .then(
                                                                        (history) {
                                                                  showModalBottomSheet(
                                                                      context:
                                                                          context,
                                                                      backgroundColor:
                                                                          ColorsConfig()
                                                                              .subBackground1(),
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
                                                                          (BuildContext
                                                                              context) {
                                                                        return SafeArea(
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                const BoxDecoration(
                                                                              borderRadius: BorderRadius.only(
                                                                                topLeft: Radius.circular(12.0),
                                                                                topRight: Radius.circular(12.0),
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                Container(
                                                                                  width: 50.0,
                                                                                  height: 4.0,
                                                                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                  decoration: BoxDecoration(
                                                                                    color: ColorsConfig().textBlack2(),
                                                                                    borderRadius: BorderRadius.circular(100.0),
                                                                                  ),
                                                                                ),
                                                                                Center(
                                                                                  child: Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0, bottom: 15.0),
                                                                                    decoration: BoxDecoration(
                                                                                      border: Border(
                                                                                        bottom: BorderSide(
                                                                                          width: 0.5,
                                                                                          color: ColorsConfig().border1(),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    child: CustomTextBuilder(
                                                                                      text: '선물내역',
                                                                                      fontColor: ColorsConfig().textWhite1(),
                                                                                      fontSize: 18.0.sp,
                                                                                      fontWeight: FontWeight.w600,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Expanded(
                                                                                  child: ListView.builder(
                                                                                      itemCount: history.result['users'].length,
                                                                                      itemBuilder: (context, historyIndex) {
                                                                                        return Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          height: 65.0,
                                                                                          padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                                                                                          decoration: BoxDecoration(
                                                                                            border: Border(
                                                                                              bottom: BorderSide(
                                                                                                width: 0.5,
                                                                                                color: ColorsConfig().border1(),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: Row(
                                                                                                  children: [
                                                                                                    // 아바타 이미지
                                                                                                    Container(
                                                                                                      width: 35.0,
                                                                                                      height: 35.0,
                                                                                                      decoration: BoxDecoration(
                                                                                                        color: ColorsConfig().userIconBackground(),
                                                                                                        borderRadius: BorderRadius.circular(17.5),
                                                                                                        image: history.result['users'][historyIndex]['avatar'].toString().startsWith('https://image.DRPublic.co.kr/undefined') == false
                                                                                                            ? DecorationImage(
                                                                                                                image: NetworkImage(
                                                                                                                  history.result['users'][historyIndex]['avatar'],
                                                                                                                  scale: 7.0,
                                                                                                                ),
                                                                                                                filterQuality: FilterQuality.high,
                                                                                                                fit: BoxFit.none,
                                                                                                                alignment: const Alignment(0.0, -0.3),
                                                                                                              )
                                                                                                            : null,
                                                                                                      ),
                                                                                                    ),
                                                                                                    const SizedBox(width: 15.0),
                                                                                                    CustomTextBuilder(
                                                                                                      text: '${history.result['users'][historyIndex]['nick']}',
                                                                                                      fontColor: ColorsConfig().textWhite1(),
                                                                                                      fontSize: 16.0.sp,
                                                                                                      fontWeight: FontWeight.w400,
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Expanded(
                                                                                                child: ListView.builder(
                                                                                                  scrollDirection: Axis.horizontal,
                                                                                                  itemCount: history.result['gifts'].length,
                                                                                                  itemBuilder: (context, giftHistory) {
                                                                                                    if (history.result['gifts'][giftHistory]['user_index'] != history.result['users'][historyIndex]['user_index']) {
                                                                                                      return Container();
                                                                                                    }
                                                                                                    return Row(
                                                                                                      children: [
                                                                                                        Image(
                                                                                                          image: NetworkImage(
                                                                                                            history.result['gifts'][giftHistory]['image'],
                                                                                                          ),
                                                                                                        ),
                                                                                                        const SizedBox(width: 4.0),
                                                                                                        CustomTextBuilder(
                                                                                                          text: '${history.result['gifts'][giftHistory]['count']}',
                                                                                                          fontColor: ColorsConfig().textBlack2(),
                                                                                                          fontSize: 12.0.sp,
                                                                                                          fontWeight: FontWeight.w700,
                                                                                                        ),
                                                                                                        const SizedBox(width: 4.0),
                                                                                                      ],
                                                                                                    );
                                                                                                  },
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        );
                                                                                      }),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        );
                                                                      });
                                                                });
                                                              },
                                                              child: !getPostListMoreBtnState[
                                                                      index]
                                                                  ? Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              4.0,
                                                                          top:
                                                                              5.0),
                                                                      child:
                                                                          SingleChildScrollView(
                                                                        physics:
                                                                            const NeverScrollableScrollPhysics(),
                                                                        scrollDirection:
                                                                            Axis.horizontal,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: List.generate(getMyPostList[index]['gift'].length > 4 ? 4 : getMyPostList[index]['gift'].length, (giftIndex) {
                                                                                return Container(
                                                                                  margin: const EdgeInsets.only(right: 8.0),
                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    children: [
                                                                                      Container(
                                                                                        width: 24.0,
                                                                                        height: 24.0,
                                                                                        decoration: BoxDecoration(
                                                                                          borderRadius: BorderRadius.circular(9.0),
                                                                                        ),
                                                                                        child: Image(
                                                                                          image: NetworkImage(
                                                                                            getMyPostList[index]['gift'][giftIndex]['image'],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      CustomTextBuilder(
                                                                                        text: '${getMyPostList[index]['gift'][giftIndex]['gift_count']}',
                                                                                        fontColor: ColorsConfig().textBlack2(),
                                                                                        fontSize: 12.0.sp,
                                                                                        fontWeight: FontWeight.w700,
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                );
                                                                              }),
                                                                            ),
                                                                            !getPostListMoreBtnState[index] && getMyPostList[index]['gift'].length > 4
                                                                                ? InkWell(
                                                                                    onTap: () {
                                                                                      setState(() {
                                                                                        getPostListMoreBtnState[index] = true;
                                                                                      });
                                                                                    },
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                                                      child: CustomTextBuilder(
                                                                                        text: '...더보기',
                                                                                        fontColor: ColorsConfig().textBlack2(),
                                                                                        fontSize: 14.0.sp,
                                                                                        fontWeight: FontWeight.w400,
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                : Container(),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              4.0,
                                                                          top:
                                                                              5.0),
                                                                      child:
                                                                          Wrap(
                                                                        children: List.generate(
                                                                            getMyPostList[index]['gift'].length,
                                                                            (giftIndex) {
                                                                          return Container(
                                                                            margin:
                                                                                const EdgeInsets.only(right: 8.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                Container(
                                                                                  width: 24.0,
                                                                                  height: 24.0,
                                                                                  decoration: BoxDecoration(
                                                                                    borderRadius: BorderRadius.circular(9.0),
                                                                                  ),
                                                                                  child: Image(
                                                                                    image: NetworkImage(
                                                                                      getMyPostList[index]['gift'][giftIndex]['image'],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                CustomTextBuilder(
                                                                                  text: '${getMyPostList[index]['gift'][giftIndex]['gift_count']}',
                                                                                  fontColor: ColorsConfig().textBlack2(),
                                                                                  fontSize: 12.0.sp,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }),
                                                                      ),
                                                                    ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // 내용 부분
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                child: InkWell(
                                                  onTap: () {
                                                    if (getMyPostList[index]
                                                            ['type'] ==
                                                        4) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              NewsDetailScreen(
                                                            postIndex:
                                                                getMyPostList[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                getMyPostList[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    } else if (getMyPostList[
                                                            index]['type'] ==
                                                        5) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              VoteDetailScreen(
                                                            postIndex:
                                                                getMyPostList[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                getMyPostList[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PostingDetailScreen(
                                                            postIndex:
                                                                getMyPostList[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                getMyPostList[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: getMyPostList[index]
                                                              ['type'] ==
                                                          4
                                                      ? Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
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
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          60.0,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '${getMyPostList[index]['title']}',
                                                                        fontColor:
                                                                            ColorsConfig().textWhite1(),
                                                                        fontSize:
                                                                            19.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        maxLines:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          60.0,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '${getMyPostList[index]['description']}',
                                                                        fontColor:
                                                                            ColorsConfig().textBlack3(),
                                                                        fontSize:
                                                                            17.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap: () {
                                                                  UrlLauncherBuilder()
                                                                      .launchURL(
                                                                          getMyPostList[index]
                                                                              [
                                                                              'link']);
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: (MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.3) -
                                                                      23.0,
                                                                  height: 75.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: ColorsConfig()
                                                                        .textBlack2(),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      width:
                                                                          0.5,
                                                                      color: ColorsConfig()
                                                                          .primary(),
                                                                    ),
                                                                    image:
                                                                        DecorationImage(
                                                                      image:
                                                                          NetworkImage(
                                                                        getMyPostList[index]
                                                                            [
                                                                            'news_image'],
                                                                      ),
                                                                      filterQuality:
                                                                          FilterQuality
                                                                              .high,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                  child: Stack(
                                                                    children: [
                                                                      Positioned(
                                                                        right:
                                                                            3.0,
                                                                        bottom:
                                                                            3.0,
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                ColorsConfig().linkIconBackground(),
                                                                            borderRadius:
                                                                                BorderRadius.circular(9.0),
                                                                          ),
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                SvgAssets(
                                                                              image: 'assets/icon/link.svg',
                                                                              color: ColorsConfig().primary(),
                                                                              width: 12.0,
                                                                              height: 12.0,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : getMyPostList[index][
                                                                      'type'] ==
                                                                  1 ||
                                                              getMyPostList[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  2 ||
                                                              getMyPostList[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  3
                                                          ? Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
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
                                                                    height:
                                                                        75.0,
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          width: getMyPostList[index]['category'] != null
                                                                              ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                              : MediaQuery.of(context).size.width - 40.0,
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${getMyPostList[index]['title']}',
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                19.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            maxLines:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: getMyPostList[index]['category'] != null
                                                                              ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                              : MediaQuery.of(context).size.width - 40.0,
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${getMyPostList[index]['description']}',
                                                                            fontColor:
                                                                                ColorsConfig().textBlack3(),
                                                                            fontSize:
                                                                                17.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      getMyPostList[index]['category'] != null &&
                                                                              getMyPostList[index]['category'] == 'i'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: getMyPostList[index]['image'].length > 1
                                                                                  ? PageView.builder(
                                                                                      controller: _pageController,
                                                                                      itemCount: getMyPostList[index]['image'].length,
                                                                                      onPageChanged: (int page) {
                                                                                        setState(() {
                                                                                          currentPage = page;
                                                                                        });
                                                                                      },
                                                                                      itemBuilder: (context, imageIndex) {
                                                                                        return Image(
                                                                                            image: NetworkImage(
                                                                                              getMyPostList[index]['image'][imageIndex],
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
                                                                                            getMyPostList[index]['image'][0],
                                                                                          ),
                                                                                          fit: BoxFit.cover,
                                                                                          filterQuality: FilterQuality.high,
                                                                                          alignment: Alignment.center),
                                                                                    ),
                                                                            )
                                                                          : Container(),
                                                                      getMyPostList[index]['category'] != null &&
                                                                              getMyPostList[index]['category'] == 'g'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                image: NetworkImage(
                                                                                  getMyPostList[index]['sub_link'],
                                                                                ),
                                                                                fit: BoxFit.cover,
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                      getMyPostList[index]['category'] != null &&
                                                                              getMyPostList[index]['category'] == 'y'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                image: NetworkImage(getYoutubeThumbnail(getMyPostList[index]['sub_link'])),
                                                                                fit: BoxFit.cover,
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : getMyPostList[index]
                                                                      [
                                                                      'type'] ==
                                                                  5
                                                              ? Container(
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  margin: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12.0),
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text: getMyPostList[
                                                                            index]
                                                                        [
                                                                        'title'],
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textWhite1(),
                                                                    fontSize:
                                                                        19.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                )
                                                              : Container(),
                                                ),
                                              ),
                                              // 좋아요, 댓글, 더보기 버튼
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // 좋아요
                                                  MaterialButton(
                                                    onPressed: () async {
                                                      final _prefs =
                                                          await SharedPreferences
                                                              .getInstance();

                                                      if (!getMyPostList[index]
                                                          ['isLike']) {
                                                        AddLikeSenderAPI()
                                                            .add(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                postIndex:
                                                                    getMyPostList[
                                                                            index]
                                                                        [
                                                                        'post_index'])
                                                            .then((res) {
                                                          if (res.result[
                                                                  'status'] ==
                                                              10800) {
                                                            setState(() {
                                                              getMyPostList[
                                                                      index]
                                                                  ['like']++;
                                                              getMyPostList[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  true;
                                                            });
                                                          }
                                                        });
                                                      } else {
                                                        CancelLikeSenderAPI()
                                                            .cancel(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                postIndex:
                                                                    getMyPostList[
                                                                            index]
                                                                        [
                                                                        'post_index'])
                                                            .then((res) {
                                                          if (res.result[
                                                                  'status'] ==
                                                              10805) {
                                                            setState(() {
                                                              getMyPostList[
                                                                      index]
                                                                  ['like']--;
                                                              getMyPostList[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  false;
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/like.svg',
                                                          color: getMyPostList[
                                                                      index]
                                                                  ['isLike']
                                                              ? ColorsConfig()
                                                                  .primary()
                                                              : ColorsConfig()
                                                                  .textBlack1(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat.format(
                                                              getMyPostList[
                                                                          index]
                                                                      ['like'] +
                                                                  addLikeCount),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack1(),
                                                          fontSize: 13.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // 댓글
                                                  MaterialButton(
                                                    onPressed: () {
                                                      if (getMyPostList[index]
                                                              ['type'] ==
                                                          4) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                NewsDetailScreen(
                                                              postIndex:
                                                                  getMyPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getMyPostList[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              getMyPostList.remove(
                                                                  getMyPostList[
                                                                      index]);
                                                            });
                                                          }
                                                        });
                                                      } else if (getMyPostList[
                                                              index]['type'] ==
                                                          5) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VoteDetailScreen(
                                                              postIndex:
                                                                  getMyPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getMyPostList[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              getMyPostList.remove(
                                                                  getMyPostList[
                                                                      index]);
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
                                                                  getMyPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getMyPostList[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              getMyPostList.remove(
                                                                  getMyPostList[
                                                                      index]);
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/reply.svg',
                                                          color: ColorsConfig()
                                                              .textBlack1(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat
                                                              .format(
                                                                  getMyPostList[
                                                                          index]
                                                                      [
                                                                      'reply']),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack1(),
                                                          fontSize: 13.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Container(),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Container(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    )
                                  : Container(
                                      color: ColorsConfig().background(),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 114.0,
                                              height: 114.0,
                                              child: Image(
                                                image: AssetImage(
                                                    'assets/img/none_data.png'),
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                            const SizedBox(height: 20.0),
                                            CustomTextBuilder(
                                              text: '콘텐츠가 없습니다.',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w400,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            // 댓글 리스트
                            SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              child: getCommentsData.isNotEmpty
                                  ? Column(
                                      children: List.generate(
                                          getCommentsData.length, (index) {
                                        setState(() {
                                          voteTotalCount = 0;
                                        });

                                        return Container(
                                          decoration: BoxDecoration(
                                            color:
                                                ColorsConfig().subBackground1(),
                                            border: Border(
                                              top: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 유저 이미지, 닉네임, 날짜, 더보기 버튼
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20.0, 13.0, 20.0, 0.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (!getCommentsData[
                                                            index]['isMe']) {
                                                          Navigator.pushNamed(
                                                              context,
                                                              '/your_profile',
                                                              arguments: {
                                                                'user_index':
                                                                    getCommentsData[
                                                                            index]
                                                                        [
                                                                        'user_index'],
                                                                'user_nickname':
                                                                    getCommentsData[
                                                                            index]
                                                                        [
                                                                        'nick'],
                                                              });
                                                        }
                                                      },
                                                      child: Row(
                                                        children: [
                                                          // 이미지
                                                          Container(
                                                            width: 42.0,
                                                            height: 42.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .userIconBackground(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          21.0),
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  getCommentsData[
                                                                          index]
                                                                      [
                                                                      'avatar_url'],
                                                                  scale: 5.5,
                                                                ),
                                                                filterQuality:
                                                                    FilterQuality
                                                                        .high,
                                                                fit:
                                                                    BoxFit.none,
                                                                alignment:
                                                                    const Alignment(
                                                                        0.0,
                                                                        -0.3),
                                                              ),
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
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
                                                                        // 닉네임
                                                                        Container(
                                                                          margin: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 8.0),
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${getCommentsData[index]['nick']}',
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                16.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                        CustomTextBuilder(
                                                                          text: DateCalculatorWrapper().daysCalculator(getCommentsData[index]
                                                                              [
                                                                              'date']),
                                                                          fontColor:
                                                                              ColorsConfig().textBlack2(),
                                                                          fontSize:
                                                                              12.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              13.0),
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              8.0,
                                                                          vertical:
                                                                              3.0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: getCommentsData[index]['type'] ==
                                                                                1
                                                                            ? ColorsConfig().postLabel()
                                                                            : getCommentsData[index]['type'] == 2
                                                                                ? ColorsConfig().analyticsLabel()
                                                                                : getCommentsData[index]['type'] == 3
                                                                                    ? ColorsConfig().debateLabel()
                                                                                    : getCommentsData[index]['type'] == 4
                                                                                        ? ColorsConfig().newsLabel()
                                                                                        : getCommentsData[index]['type'] == 5
                                                                                            ? ColorsConfig().voteLabel()
                                                                                            : ColorsConfig.defaultWhite,
                                                                        borderRadius:
                                                                            BorderRadius.circular(4.0),
                                                                      ),
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text: getCommentsData[index]['type'] ==
                                                                                1
                                                                            ? '포스트'
                                                                            : getCommentsData[index]['type'] == 2
                                                                                ? '분 석'
                                                                                : getCommentsData[index]['type'] == 3
                                                                                    ? '토 론'
                                                                                    : getCommentsData[index]['type'] == 4
                                                                                        ? '뉴 스'
                                                                                        : getCommentsData[index]['type'] == 5
                                                                                            ? '투 표'
                                                                                            : '',
                                                                        fontColor:
                                                                            ColorsConfig.defaultWhite,
                                                                        fontSize:
                                                                            11.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap:
                                                                    () async {
                                                                  final _prefs =
                                                                      await SharedPreferences
                                                                          .getInstance();

                                                                  GetGiftHistoryListDataAPI()
                                                                      .giftHistory(
                                                                          accesToken: _prefs.getString(
                                                                              'AccessToken')!,
                                                                          postIndex: getCommentsData[index]
                                                                              [
                                                                              'post_index'])
                                                                      .then(
                                                                          (history) {
                                                                    showModalBottomSheet(
                                                                        context:
                                                                            context,
                                                                        backgroundColor:
                                                                            ColorsConfig()
                                                                                .subBackground1(),
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
                                                                            (BuildContext
                                                                                context) {
                                                                          return SafeArea(
                                                                            child:
                                                                                Container(
                                                                              decoration: const BoxDecoration(
                                                                                borderRadius: BorderRadius.only(
                                                                                  topLeft: Radius.circular(12.0),
                                                                                  topRight: Radius.circular(12.0),
                                                                                ),
                                                                              ),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 50.0,
                                                                                    height: 4.0,
                                                                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig().textBlack2(),
                                                                                      borderRadius: BorderRadius.circular(100.0),
                                                                                    ),
                                                                                  ),
                                                                                  Center(
                                                                                    child: Container(
                                                                                      width: MediaQuery.of(context).size.width,
                                                                                      padding: const EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0, bottom: 15.0),
                                                                                      decoration: BoxDecoration(
                                                                                        border: Border(
                                                                                          bottom: BorderSide(
                                                                                            width: 0.5,
                                                                                            color: ColorsConfig().border1(),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      child: CustomTextBuilder(
                                                                                        text: '선물내역',
                                                                                        fontColor: ColorsConfig().textWhite1(),
                                                                                        fontSize: 18.0.sp,
                                                                                        fontWeight: FontWeight.w600,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: ListView.builder(
                                                                                        itemCount: history.result['users'].length,
                                                                                        itemBuilder: (context, historyIndex) {
                                                                                          return Container(
                                                                                            width: MediaQuery.of(context).size.width,
                                                                                            height: 65.0,
                                                                                            padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                                                                                            decoration: BoxDecoration(
                                                                                              border: Border(
                                                                                                bottom: BorderSide(
                                                                                                  width: 0.5,
                                                                                                  color: ColorsConfig().border1(),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                Expanded(
                                                                                                  child: Row(
                                                                                                    children: [
                                                                                                      // 아바타 이미지
                                                                                                      Container(
                                                                                                        width: 35.0,
                                                                                                        height: 35.0,
                                                                                                        decoration: BoxDecoration(
                                                                                                          color: ColorsConfig().userIconBackground(),
                                                                                                          borderRadius: BorderRadius.circular(17.5),
                                                                                                          image: history.result['users'][historyIndex]['avatar'].toString().startsWith('https://image.DRPublic.co.kr/undefined') == false
                                                                                                              ? DecorationImage(
                                                                                                                  image: NetworkImage(
                                                                                                                    history.result['users'][historyIndex]['avatar'],
                                                                                                                    scale: 7.0,
                                                                                                                  ),
                                                                                                                  filterQuality: FilterQuality.high,
                                                                                                                  fit: BoxFit.none,
                                                                                                                  alignment: const Alignment(0.0, -0.3),
                                                                                                                )
                                                                                                              : null,
                                                                                                        ),
                                                                                                      ),
                                                                                                      const SizedBox(width: 15.0),
                                                                                                      CustomTextBuilder(
                                                                                                        text: '${history.result['users'][historyIndex]['nick']}',
                                                                                                        fontColor: ColorsConfig().textWhite1(),
                                                                                                        fontSize: 16.0.sp,
                                                                                                        fontWeight: FontWeight.w400,
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                                Expanded(
                                                                                                  child: ListView.builder(
                                                                                                    scrollDirection: Axis.horizontal,
                                                                                                    itemCount: history.result['gifts'].length,
                                                                                                    itemBuilder: (context, giftHistory) {
                                                                                                      if (history.result['gifts'][giftHistory]['user_index'] != history.result['users'][historyIndex]['user_index']) {
                                                                                                        return Container();
                                                                                                      }
                                                                                                      return Row(
                                                                                                        children: [
                                                                                                          Image(
                                                                                                            image: NetworkImage(
                                                                                                              history.result['gifts'][giftHistory]['image'],
                                                                                                            ),
                                                                                                          ),
                                                                                                          const SizedBox(width: 4.0),
                                                                                                          CustomTextBuilder(
                                                                                                            text: '${history.result['gifts'][giftHistory]['count']}',
                                                                                                            fontColor: ColorsConfig().textBlack2(),
                                                                                                            fontSize: 12.0.sp,
                                                                                                            fontWeight: FontWeight.w700,
                                                                                                          ),
                                                                                                          const SizedBox(width: 4.0),
                                                                                                        ],
                                                                                                      );
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          );
                                                                                        }),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        });
                                                                  });
                                                                },
                                                                child: !getCommentsMoreBtnState[
                                                                        index]
                                                                    ? Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                4.0,
                                                                            top:
                                                                                5.0),
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          physics:
                                                                              const NeverScrollableScrollPhysics(),
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: List.generate(getCommentsData[index]['gift'].length > 4 ? 4 : getCommentsData[index]['gift'].length, (giftIndex) {
                                                                                  return Container(
                                                                                    margin: const EdgeInsets.only(right: 8.0),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        Container(
                                                                                          width: 24.0,
                                                                                          height: 24.0,
                                                                                          decoration: BoxDecoration(
                                                                                            borderRadius: BorderRadius.circular(9.0),
                                                                                          ),
                                                                                          child: Image(
                                                                                            image: NetworkImage(
                                                                                              getCommentsData[index]['gift'][giftIndex]['image'],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        CustomTextBuilder(
                                                                                          text: '${getCommentsData[index]['gift'][giftIndex]['gift_count']}',
                                                                                          fontColor: ColorsConfig().textBlack2(),
                                                                                          fontSize: 12.0.sp,
                                                                                          fontWeight: FontWeight.w700,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  );
                                                                                }),
                                                                              ),
                                                                              !getCommentsMoreBtnState[index] && getCommentsData[index]['gift'].length > 4
                                                                                  ? InkWell(
                                                                                      onTap: () {
                                                                                        setState(() {
                                                                                          getCommentsMoreBtnState[index] = true;
                                                                                        });
                                                                                      },
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '...더보기',
                                                                                          fontColor: ColorsConfig().textBlack2(),
                                                                                          fontSize: 14.0.sp,
                                                                                          fontWeight: FontWeight.w400,
                                                                                        ),
                                                                                      ),
                                                                                    )
                                                                                  : Container(),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                4.0,
                                                                            top:
                                                                                5.0),
                                                                        child:
                                                                            Wrap(
                                                                          children: List.generate(
                                                                              getCommentsData[index]['gift'].length,
                                                                              (giftIndex) {
                                                                            return Container(
                                                                              margin: const EdgeInsets.only(right: 8.0),
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 24.0,
                                                                                    height: 24.0,
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: BorderRadius.circular(9.0),
                                                                                    ),
                                                                                    child: Image(
                                                                                      image: NetworkImage(
                                                                                        getCommentsData[index]['gift'][giftIndex]['image'],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  CustomTextBuilder(
                                                                                    text: '${getCommentsData[index]['gift'][giftIndex]['gift_count']}',
                                                                                    fontColor: ColorsConfig().textBlack2(),
                                                                                    fontSize: 12.0.sp,
                                                                                    fontWeight: FontWeight.w700,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          }),
                                                                        ),
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
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                child: InkWell(
                                                  onTap: () {
                                                    if (getCommentsData[index]
                                                            ['type'] ==
                                                        4) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              NewsDetailScreen(
                                                            postIndex:
                                                                getCommentsData[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                getCommentsData[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    } else if (getCommentsData[
                                                            index]['type'] ==
                                                        5) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              VoteDetailScreen(
                                                            postIndex:
                                                                getCommentsData[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                getCommentsData[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PostingDetailScreen(
                                                            postIndex:
                                                                getCommentsData[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                getCommentsData[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: getCommentsData[index]
                                                              ['type'] ==
                                                          4
                                                      ? Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
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
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          60.0,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '${getCommentsData[index]['title']}',
                                                                        fontColor:
                                                                            ColorsConfig().textWhite1(),
                                                                        fontSize:
                                                                            19.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        maxLines:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          60.0,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '${getCommentsData[index]['description']}',
                                                                        fontColor:
                                                                            ColorsConfig().textBlack3(),
                                                                        fontSize:
                                                                            17.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap: () {
                                                                  UrlLauncherBuilder()
                                                                      .launchURL(
                                                                          getCommentsData[index]
                                                                              [
                                                                              'link']);
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: (MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.3) -
                                                                      23.0,
                                                                  height: 75.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: ColorsConfig()
                                                                        .textBlack2(),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      width:
                                                                          0.5,
                                                                      color: ColorsConfig()
                                                                          .primary(),
                                                                    ),
                                                                    image:
                                                                        DecorationImage(
                                                                      image:
                                                                          NetworkImage(
                                                                        getCommentsData[index]
                                                                            [
                                                                            'news_image'],
                                                                      ),
                                                                      filterQuality:
                                                                          FilterQuality
                                                                              .high,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                  child: Stack(
                                                                    children: [
                                                                      Positioned(
                                                                        right:
                                                                            3.0,
                                                                        bottom:
                                                                            3.0,
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                ColorsConfig().linkIconBackground(),
                                                                            borderRadius:
                                                                                BorderRadius.circular(9.0),
                                                                          ),
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                SvgAssets(
                                                                              image: 'assets/icon/link.svg',
                                                                              color: ColorsConfig().primary(),
                                                                              width: 12.0,
                                                                              height: 12.0,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : getCommentsData[index][
                                                                      'type'] ==
                                                                  1 ||
                                                              getCommentsData[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  2 ||
                                                              getCommentsData[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  3
                                                          ? Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
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
                                                                    height:
                                                                        75.0,
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          width: getCommentsData[index]['category'] != null
                                                                              ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                              : MediaQuery.of(context).size.width - 40.0,
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${getCommentsData[index]['title']}',
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                19.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            maxLines:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: getCommentsData[index]['category'] != null
                                                                              ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                              : MediaQuery.of(context).size.width - 40.0,
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${getCommentsData[index]['description']}',
                                                                            fontColor:
                                                                                ColorsConfig().textBlack3(),
                                                                            fontSize:
                                                                                17.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      getCommentsData[index]['category'] != null &&
                                                                              getCommentsData[index]['category'] == 'i'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: getCommentsData[index]['image'].length > 1
                                                                                  ? PageView.builder(
                                                                                      controller: _pageController,
                                                                                      itemCount: getCommentsData[index]['image'].length,
                                                                                      onPageChanged: (int page) {
                                                                                        setState(() {
                                                                                          currentPage = page;
                                                                                        });
                                                                                      },
                                                                                      itemBuilder: (context, imageIndex) {
                                                                                        return Image(
                                                                                            image: NetworkImage(
                                                                                              getCommentsData[index]['image'][imageIndex],
                                                                                            ),
                                                                                            fit: BoxFit.cover,
                                                                                            filterQuality: FilterQuality.high,
                                                                                            alignment: Alignment.center);
                                                                                      },
                                                                                    )
                                                                                  : Image(
                                                                                      image: NetworkImage(
                                                                                        getCommentsData[index]['image'][0],
                                                                                      ),
                                                                                      fit: BoxFit.cover,
                                                                                      filterQuality: FilterQuality.high,
                                                                                      alignment: Alignment.center),
                                                                            )
                                                                          : Container(),
                                                                      getCommentsData[index]['category'] != null &&
                                                                              getCommentsData[index]['category'] == 'g'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                image: NetworkImage(
                                                                                  getCommentsData[index]['sub_link'],
                                                                                ),
                                                                                fit: BoxFit.cover,
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                      getCommentsData[index]['category'] != null &&
                                                                              getCommentsData[index]['category'] == 'y'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                image: NetworkImage(getYoutubeThumbnail(getCommentsData[index]['sub_link'])),
                                                                                fit: BoxFit.cover,
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : getCommentsData[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  5
                                                              ? Container(
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  margin: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12.0),
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text: getCommentsData[
                                                                            index]
                                                                        [
                                                                        'title'],
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textWhite1(),
                                                                    fontSize:
                                                                        19.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                )
                                                              : Container(),
                                                ),
                                              ),
                                              // 좋아요, 댓글, 더보기 버튼
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // 좋아요
                                                  MaterialButton(
                                                    onPressed: () async {
                                                      final _prefs =
                                                          await SharedPreferences
                                                              .getInstance();

                                                      if (!getCommentsData[
                                                          index]['isLike']) {
                                                        AddLikeSenderAPI()
                                                            .add(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                postIndex:
                                                                    getCommentsData[
                                                                            index]
                                                                        [
                                                                        'post_index'])
                                                            .then((res) {
                                                          if (res.result[
                                                                  'status'] ==
                                                              10800) {
                                                            setState(() {
                                                              getCommentsData[
                                                                      index]
                                                                  ['like']++;
                                                              getCommentsData[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  true;
                                                            });
                                                          }
                                                        });
                                                      } else {
                                                        CancelLikeSenderAPI()
                                                            .cancel(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                postIndex:
                                                                    getCommentsData[
                                                                            index]
                                                                        [
                                                                        'post_index'])
                                                            .then((res) {
                                                          if (res.result[
                                                                  'status'] ==
                                                              10805) {
                                                            setState(() {
                                                              getCommentsData[
                                                                      index]
                                                                  ['like']--;
                                                              getCommentsData[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  false;
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/like.svg',
                                                          color: getCommentsData[
                                                                      index]
                                                                  ['isLike']
                                                              ? ColorsConfig()
                                                                  .primary()
                                                              : ColorsConfig()
                                                                  .textBlack1(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat.format(
                                                              getCommentsData[
                                                                          index]
                                                                      ['like'] +
                                                                  commentsAddLikeCount),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack1(),
                                                          fontSize: 13.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // 댓글
                                                  MaterialButton(
                                                    onPressed: () {
                                                      if (getCommentsData[index]
                                                              ['type'] ==
                                                          4) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                NewsDetailScreen(
                                                              postIndex:
                                                                  getCommentsData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getCommentsData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              getCommentsData.remove(
                                                                  getCommentsData[
                                                                      index]);
                                                            });
                                                          }
                                                        });
                                                      } else if (getCommentsData[
                                                              index]['type'] ==
                                                          5) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VoteDetailScreen(
                                                              postIndex:
                                                                  getCommentsData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getCommentsData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              getCommentsData.remove(
                                                                  getCommentsData[
                                                                      index]);
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
                                                                  getCommentsData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getCommentsData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              getCommentsData.remove(
                                                                  getCommentsData[
                                                                      index]);
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/reply.svg',
                                                          color: ColorsConfig()
                                                              .textBlack1(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat
                                                              .format(
                                                                  getCommentsData[
                                                                          index]
                                                                      [
                                                                      'reply']),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack1(),
                                                          fontSize: 13.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // 빈 공간
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Container(),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Container(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    )
                                  : Container(
                                      color: ColorsConfig().background(),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 114.0,
                                              height: 114.0,
                                              child: Image(
                                                image: AssetImage(
                                                    'assets/img/none_data.png'),
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                            const SizedBox(height: 20.0),
                                            CustomTextBuilder(
                                              text: '콘텐츠가 없습니다.',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w400,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            // 트로피 준 글 리스트
                            SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              child: Container(
                                child: getTrophyData.isNotEmpty
                                    ? Column(
                                        children: List.generate(
                                            getTrophyData.length, (index) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: ColorsConfig()
                                                  .subBackground1(),
                                              border: Border(
                                                top: BorderSide(
                                                  width: 0.5,
                                                  color:
                                                      ColorsConfig().border1(),
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 유저 이미지, 닉네임, 날짜, 더보기 버튼
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          20.0,
                                                          13.0,
                                                          20.0,
                                                          0.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          if (!getTrophyData[
                                                              index]['isMe']) {
                                                            Navigator.pushNamed(
                                                                context,
                                                                '/your_profile',
                                                                arguments: {
                                                                  'user_index':
                                                                      getTrophyData[
                                                                              index]
                                                                          [
                                                                          'user_index'],
                                                                  'user_nickname':
                                                                      getTrophyData[
                                                                              index]
                                                                          [
                                                                          'nick'],
                                                                });
                                                          }
                                                        },
                                                        child: Row(
                                                          children: [
                                                            // 이미지
                                                            Container(
                                                              width: 42.0,
                                                              height: 42.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: ColorsConfig()
                                                                    .userIconBackground(),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            21.0),
                                                                image:
                                                                    DecorationImage(
                                                                  image:
                                                                      NetworkImage(
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'avatar_url'],
                                                                    scale: 5.5,
                                                                  ),
                                                                  filterQuality:
                                                                      FilterQuality
                                                                          .high,
                                                                  fit: BoxFit
                                                                      .none,
                                                                  alignment:
                                                                      const Alignment(
                                                                          0.0,
                                                                          -0.3),
                                                                ),
                                                              ),
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
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
                                                                          // 닉네임
                                                                          Container(
                                                                            margin:
                                                                                const EdgeInsets.symmetric(horizontal: 8.0),
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getTrophyData[index]['nick']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                          ),
                                                                          CustomTextBuilder(
                                                                            text:
                                                                                DateCalculatorWrapper().daysCalculator(getTrophyData[index]['date']),
                                                                            fontColor:
                                                                                ColorsConfig().textBlack2(),
                                                                            fontSize:
                                                                                12.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                13.0),
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                8.0,
                                                                            vertical:
                                                                                3.0),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: getTrophyData[index]['type'] == 1
                                                                              ? ColorsConfig().postLabel()
                                                                              : getTrophyData[index]['type'] == 2
                                                                                  ? ColorsConfig().analyticsLabel()
                                                                                  : getTrophyData[index]['type'] == 3
                                                                                      ? ColorsConfig().debateLabel()
                                                                                      : getTrophyData[index]['type'] == 4
                                                                                          ? ColorsConfig().newsLabel()
                                                                                          : getTrophyData[index]['type'] == 5
                                                                                              ? ColorsConfig().voteLabel()
                                                                                              : ColorsConfig.defaultWhite,
                                                                          borderRadius:
                                                                              BorderRadius.circular(4.0),
                                                                        ),
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text: getTrophyData[index]['type'] == 1
                                                                              ? '포스트'
                                                                              : getTrophyData[index]['type'] == 2
                                                                                  ? '분 석'
                                                                                  : getTrophyData[index]['type'] == 3
                                                                                      ? '토 론'
                                                                                      : getTrophyData[index]['type'] == 4
                                                                                          ? '뉴 스'
                                                                                          : getTrophyData[index]['type'] == 5
                                                                                              ? '투 표'
                                                                                              : '',
                                                                          fontColor:
                                                                              ColorsConfig.defaultWhite,
                                                                          fontSize:
                                                                              11.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  onTap:
                                                                      () async {
                                                                    final _prefs =
                                                                        await SharedPreferences
                                                                            .getInstance();

                                                                    GetGiftHistoryListDataAPI()
                                                                        .giftHistory(
                                                                            accesToken: _prefs.getString(
                                                                                'AccessToken')!,
                                                                            postIndex: getTrophyData[index][
                                                                                'post_index'])
                                                                        .then(
                                                                            (history) {
                                                                      showModalBottomSheet(
                                                                          context:
                                                                              context,
                                                                          backgroundColor: ColorsConfig()
                                                                              .subBackground1(),
                                                                          shape:
                                                                              const RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.only(
                                                                              topLeft: Radius.circular(12.0),
                                                                              topRight: Radius.circular(12.0),
                                                                            ),
                                                                          ),
                                                                          builder:
                                                                              (BuildContext context) {
                                                                            return SafeArea(
                                                                              child: Container(
                                                                                decoration: const BoxDecoration(
                                                                                  borderRadius: BorderRadius.only(
                                                                                    topLeft: Radius.circular(12.0),
                                                                                    topRight: Radius.circular(12.0),
                                                                                  ),
                                                                                ),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Container(
                                                                                      width: 50.0,
                                                                                      height: 4.0,
                                                                                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                      decoration: BoxDecoration(
                                                                                        color: ColorsConfig().textBlack2(),
                                                                                        borderRadius: BorderRadius.circular(100.0),
                                                                                      ),
                                                                                    ),
                                                                                    Center(
                                                                                      child: Container(
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        padding: const EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0, bottom: 15.0),
                                                                                        decoration: BoxDecoration(
                                                                                          border: Border(
                                                                                            bottom: BorderSide(
                                                                                              width: 0.5,
                                                                                              color: ColorsConfig().border1(),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '선물내역',
                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                          fontSize: 18.0.sp,
                                                                                          fontWeight: FontWeight.w600,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    Expanded(
                                                                                      child: ListView.builder(
                                                                                          itemCount: history.result['users'].length,
                                                                                          itemBuilder: (context, historyIndex) {
                                                                                            return Container(
                                                                                              width: MediaQuery.of(context).size.width,
                                                                                              height: 65.0,
                                                                                              padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                                                                                              decoration: BoxDecoration(
                                                                                                border: Border(
                                                                                                  bottom: BorderSide(
                                                                                                    width: 0.5,
                                                                                                    color: ColorsConfig().border1(),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              child: Row(
                                                                                                children: [
                                                                                                  Expanded(
                                                                                                    child: Row(
                                                                                                      children: [
                                                                                                        // 아바타 이미지
                                                                                                        Container(
                                                                                                          width: 35.0,
                                                                                                          height: 35.0,
                                                                                                          decoration: BoxDecoration(
                                                                                                            color: ColorsConfig().userIconBackground(),
                                                                                                            borderRadius: BorderRadius.circular(17.5),
                                                                                                            image: history.result['users'][historyIndex]['avatar'].toString().startsWith('https://image.DRPublic.co.kr/undefined') == false
                                                                                                                ? DecorationImage(
                                                                                                                    image: NetworkImage(
                                                                                                                      history.result['users'][historyIndex]['avatar'],
                                                                                                                      scale: 7.0,
                                                                                                                    ),
                                                                                                                    filterQuality: FilterQuality.high,
                                                                                                                    fit: BoxFit.none,
                                                                                                                    alignment: const Alignment(0.0, -0.3),
                                                                                                                  )
                                                                                                                : null,
                                                                                                          ),
                                                                                                        ),
                                                                                                        const SizedBox(width: 15.0),
                                                                                                        CustomTextBuilder(
                                                                                                          text: '${history.result['users'][historyIndex]['nick']}',
                                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                                          fontSize: 16.0.sp,
                                                                                                          fontWeight: FontWeight.w400,
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  ),
                                                                                                  Expanded(
                                                                                                    child: ListView.builder(
                                                                                                      scrollDirection: Axis.horizontal,
                                                                                                      itemCount: history.result['gifts'].length,
                                                                                                      itemBuilder: (context, giftHistory) {
                                                                                                        if (history.result['gifts'][giftHistory]['user_index'] != history.result['users'][historyIndex]['user_index']) {
                                                                                                          return Container();
                                                                                                        }
                                                                                                        return Row(
                                                                                                          children: [
                                                                                                            Image(
                                                                                                              image: NetworkImage(
                                                                                                                history.result['gifts'][giftHistory]['image'],
                                                                                                              ),
                                                                                                            ),
                                                                                                            const SizedBox(width: 4.0),
                                                                                                            CustomTextBuilder(
                                                                                                              text: '${history.result['gifts'][giftHistory]['count']}',
                                                                                                              fontColor: ColorsConfig().textBlack2(),
                                                                                                              fontSize: 12.0.sp,
                                                                                                              fontWeight: FontWeight.w700,
                                                                                                            ),
                                                                                                            const SizedBox(width: 4.0),
                                                                                                          ],
                                                                                                        );
                                                                                                      },
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            );
                                                                                          }),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          });
                                                                    });
                                                                  },
                                                                  child: !getTrophyMoreBtnState[
                                                                          index]
                                                                      ? Container(
                                                                          margin: const EdgeInsets
                                                                              .only(
                                                                              left: 4.0,
                                                                              top: 5.0),
                                                                          child:
                                                                              SingleChildScrollView(
                                                                            physics:
                                                                                const NeverScrollableScrollPhysics(),
                                                                            scrollDirection:
                                                                                Axis.horizontal,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Row(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: List.generate(getTrophyData[index]['gift'].length > 4 ? 4 : getTrophyData[index]['gift'].length, (giftIndex) {
                                                                                    return Container(
                                                                                      margin: EdgeInsets.only(right: 8.0.r),
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                          Container(
                                                                                            width: 24.0,
                                                                                            height: 24.0,
                                                                                            decoration: BoxDecoration(
                                                                                              borderRadius: BorderRadius.circular(9.0),
                                                                                            ),
                                                                                            child: Image(
                                                                                              image: NetworkImage(
                                                                                                getTrophyData[index]['gift'][giftIndex]['image'],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          CustomTextBuilder(
                                                                                            text: '${getTrophyData[index]['gift'][giftIndex]['gift_count']}',
                                                                                            fontColor: ColorsConfig().textBlack2(),
                                                                                            fontSize: 12.0.sp,
                                                                                            fontWeight: FontWeight.w700,
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    );
                                                                                  }),
                                                                                ),
                                                                                !getTrophyMoreBtnState[index] && getTrophyData[index]['gift'].length > 4
                                                                                    ? InkWell(
                                                                                        onTap: () {
                                                                                          setState(() {
                                                                                            getTrophyMoreBtnState[index] = true;
                                                                                          });
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '...더보기',
                                                                                            fontColor: ColorsConfig().textBlack2(),
                                                                                            fontSize: 14.0.sp,
                                                                                            fontWeight: FontWeight.w400,
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                    : Container(),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          margin: const EdgeInsets
                                                                              .only(
                                                                              left: 4.0,
                                                                              top: 5.0),
                                                                          child:
                                                                              Wrap(
                                                                            children:
                                                                                List.generate(getTrophyData[index]['gift'].length, (giftIndex) {
                                                                              return Container(
                                                                                margin: EdgeInsets.only(right: 8.0.r),
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Container(
                                                                                      width: 24.0,
                                                                                      height: 24.0,
                                                                                      decoration: BoxDecoration(
                                                                                        borderRadius: BorderRadius.circular(9.0),
                                                                                      ),
                                                                                      child: Image(
                                                                                        image: NetworkImage(
                                                                                          getTrophyData[index]['gift'][giftIndex]['image'],
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    CustomTextBuilder(
                                                                                      text: '${getTrophyData[index]['gift'][giftIndex]['gift_count']}',
                                                                                      fontColor: ColorsConfig().textBlack2(),
                                                                                      fontSize: 12.0.sp,
                                                                                      fontWeight: FontWeight.w700,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            }),
                                                                          ),
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20.0),
                                                  child: InkWell(
                                                    onTap: () {
                                                      if (getTrophyData[index]
                                                              ['type'] ==
                                                          4) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                NewsDetailScreen(
                                                              postIndex:
                                                                  getTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getTrophyData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        );
                                                      } else if (getTrophyData[
                                                              index]['type'] ==
                                                          5) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VoteDetailScreen(
                                                              postIndex:
                                                                  getTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getTrophyData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                PostingDetailScreen(
                                                              postIndex:
                                                                  getTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getTrophyData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: getTrophyData[index]
                                                                ['type'] ==
                                                            4
                                                        ? Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
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
                                                                        width: (MediaQuery.of(context).size.width *
                                                                                0.75) -
                                                                            60.0,
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text:
                                                                              '${getTrophyData[index]['title']}',
                                                                          fontColor:
                                                                              ColorsConfig().textWhite1(),
                                                                          fontSize:
                                                                              19.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          maxLines:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: (MediaQuery.of(context).size.width *
                                                                                0.75) -
                                                                            60.0,
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text:
                                                                              '${getTrophyData[index]['description']}',
                                                                          fontColor:
                                                                              ColorsConfig().textBlack3(),
                                                                          fontSize:
                                                                              17.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                          maxLines:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  onTap: () {
                                                                    UrlLauncherBuilder().launchURL(
                                                                        getTrophyData[index]
                                                                            [
                                                                            'link']);
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    width: (MediaQuery.of(context).size.width *
                                                                            0.3) -
                                                                        23.0,
                                                                    height:
                                                                        75.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: ColorsConfig()
                                                                          .textBlack2(),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        width:
                                                                            0.5,
                                                                        color: ColorsConfig()
                                                                            .primary(),
                                                                      ),
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            NetworkImage(
                                                                          getTrophyData[index]
                                                                              [
                                                                              'news_image'],
                                                                        ),
                                                                        filterQuality:
                                                                            FilterQuality.high,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        Stack(
                                                                      children: [
                                                                        Positioned(
                                                                          right:
                                                                              3.0,
                                                                          bottom:
                                                                              3.0,
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                18.0,
                                                                            height:
                                                                                18.0,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: ColorsConfig().linkIconBackground(),
                                                                              borderRadius: BorderRadius.circular(9.0),
                                                                            ),
                                                                            child:
                                                                                Center(
                                                                              child: SvgAssets(
                                                                                image: 'assets/icon/link.svg',
                                                                                color: ColorsConfig().primary(),
                                                                                width: 12.0,
                                                                                height: 12.0,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : getTrophyData[index][
                                                                        'type'] ==
                                                                    1 ||
                                                                getTrophyData[
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    2 ||
                                                                getTrophyData[
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    3
                                                            ? Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            6.0),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    SizedBox(
                                                                      height:
                                                                          75.0,
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          SizedBox(
                                                                            width: getTrophyData[index]['category'] != null
                                                                                ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                                : MediaQuery.of(context).size.width - 40.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getTrophyData[index]['title']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 19.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                              maxLines: 2,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width: getTrophyData[index]['category'] != null
                                                                                ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                                : MediaQuery.of(context).size.width - 40.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getTrophyData[index]['description']}',
                                                                              fontColor: ColorsConfig().textBlack3(),
                                                                              fontSize: 17.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                              maxLines: 1,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        getTrophyData[index]['category'] != null &&
                                                                                getTrophyData[index]['category'] == 'i'
                                                                            ? SizedBox(
                                                                                width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                height: 75.0,
                                                                                child: getTrophyData[index]['image'].length > 1
                                                                                    ? PageView.builder(
                                                                                        controller: _pageController,
                                                                                        itemCount: getTrophyData[index]['image'].length,
                                                                                        onPageChanged: (int page) {
                                                                                          setState(() {
                                                                                            currentPage = page;
                                                                                          });
                                                                                        },
                                                                                        itemBuilder: (context, imageIndex) {
                                                                                          return Image(
                                                                                              image: NetworkImage(
                                                                                                getTrophyData[index]['image'][imageIndex],
                                                                                              ),
                                                                                              fit: BoxFit.cover,
                                                                                              filterQuality: FilterQuality.high,
                                                                                              alignment: Alignment.center);
                                                                                        },
                                                                                      )
                                                                                    : Image(
                                                                                        image: NetworkImage(
                                                                                          getTrophyData[index]['image'][0],
                                                                                        ),
                                                                                        fit: BoxFit.cover,
                                                                                        filterQuality: FilterQuality.high,
                                                                                        alignment: Alignment.center),
                                                                              )
                                                                            : Container(),
                                                                        getTrophyData[index]['category'] != null &&
                                                                                getTrophyData[index]['category'] == 'g'
                                                                            ? SizedBox(
                                                                                width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                height: 75.0,
                                                                                child: Image(
                                                                                  image: NetworkImage(
                                                                                    getTrophyData[index]['sub_link'],
                                                                                  ),
                                                                                  fit: BoxFit.cover,
                                                                                  filterQuality: FilterQuality.high,
                                                                                ),
                                                                              )
                                                                            : Container(),
                                                                        getTrophyData[index]['category'] != null &&
                                                                                getTrophyData[index]['category'] == 'y'
                                                                            ? SizedBox(
                                                                                width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                height: 75.0,
                                                                                child: Image(
                                                                                  image: NetworkImage(getYoutubeThumbnail(getTrophyData[index]['sub_link'])),
                                                                                  fit: BoxFit.cover,
                                                                                  filterQuality: FilterQuality.high,
                                                                                ),
                                                                              )
                                                                            : Container(),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            : getTrophyData[index]
                                                                        [
                                                                        'type'] ==
                                                                    5
                                                                ? Container(
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    margin: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            12.0),
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text: getTrophyData[
                                                                              index]
                                                                          [
                                                                          'title'],
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textWhite1(),
                                                                      fontSize:
                                                                          19.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                  ),
                                                ),
                                                // 좋아요, 댓글, 더보기 버튼
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // 좋아요
                                                    MaterialButton(
                                                      onPressed: () async {
                                                        final _prefs =
                                                            await SharedPreferences
                                                                .getInstance();

                                                        if (!getTrophyData[
                                                            index]['isLike']) {
                                                          AddLikeSenderAPI()
                                                              .add(
                                                                  accesToken: _prefs
                                                                      .getString(
                                                                          'AccessToken')!,
                                                                  postIndex: getTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'])
                                                              .then((res) {
                                                            if (res.result[
                                                                    'status'] ==
                                                                10800) {
                                                              setState(() {
                                                                getTrophyData[
                                                                        index]
                                                                    ['like']++;
                                                                getTrophyData[
                                                                        index][
                                                                    'isLike'] = true;
                                                              });
                                                            }
                                                          });
                                                        } else {
                                                          CancelLikeSenderAPI()
                                                              .cancel(
                                                                  accesToken: _prefs
                                                                      .getString(
                                                                          'AccessToken')!,
                                                                  postIndex: getTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'])
                                                              .then((res) {
                                                            if (res.result[
                                                                    'status'] ==
                                                                10805) {
                                                              setState(() {
                                                                getTrophyData[
                                                                        index]
                                                                    ['like']--;
                                                                getTrophyData[
                                                                            index]
                                                                        [
                                                                        'isLike'] =
                                                                    false;
                                                              });
                                                            }
                                                          });
                                                        }
                                                      },
                                                      child: Row(
                                                        children: [
                                                          SvgAssets(
                                                            image:
                                                                'assets/icon/like.svg',
                                                            color: getTrophyData[
                                                                        index]
                                                                    ['isLike']
                                                                ? ColorsConfig()
                                                                    .primary()
                                                                : ColorsConfig()
                                                                    .textBlack1(),
                                                            width: 18.0,
                                                            height: 18.0,
                                                          ),
                                                          const SizedBox(
                                                              width: 10.0),
                                                          CustomTextBuilder(
                                                            text: numberFormat.format(
                                                                getTrophyData[
                                                                            index]
                                                                        [
                                                                        'like'] +
                                                                    getThophysAddLikeCount),
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textBlack1(),
                                                            fontSize: 13.0.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // 댓글
                                                    MaterialButton(
                                                      onPressed: () {
                                                        if (getTrophyData[index]
                                                                ['type'] ==
                                                            4) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  NewsDetailScreen(
                                                                postIndex:
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'post_index'],
                                                                postType:
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getTrophyData.remove(
                                                                    getTrophyData[
                                                                        index]);
                                                              });
                                                            }
                                                          });
                                                        } else if (getTrophyData[
                                                                    index]
                                                                ['type'] ==
                                                            5) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  VoteDetailScreen(
                                                                postIndex:
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'post_index'],
                                                                postType:
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getTrophyData.remove(
                                                                    getTrophyData[
                                                                        index]);
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
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'post_index'],
                                                                postType:
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getTrophyData.remove(
                                                                    getTrophyData[
                                                                        index]);
                                                              });
                                                            }
                                                          });
                                                        }
                                                      },
                                                      child: Row(
                                                        children: [
                                                          SvgAssets(
                                                            image:
                                                                'assets/icon/reply.svg',
                                                            color: ColorsConfig()
                                                                .textBlack1(),
                                                            width: 18.0,
                                                            height: 18.0,
                                                          ),
                                                          const SizedBox(
                                                              width: 10.0),
                                                          CustomTextBuilder(
                                                            text: numberFormat.format(
                                                                getTrophyData[
                                                                        index]
                                                                    ['reply']),
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textBlack1(),
                                                            fontSize: 13.0.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    MaterialButton(
                                                      onPressed: () {},
                                                      child: Container(),
                                                    ),
                                                    MaterialButton(
                                                      onPressed: () {},
                                                      child: Container(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      )
                                    : Container(
                                        height: 250.0.h,
                                        color: ColorsConfig().background(),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 114.0,
                                                height: 114.0,
                                                child: Image(
                                                  image: AssetImage(
                                                      'assets/img/none_data.png'),
                                                  filterQuality:
                                                      FilterQuality.high,
                                                ),
                                              ),
                                              const SizedBox(height: 20.0),
                                              CustomTextBuilder(
                                                text: '콘텐츠가 없습니다.',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w400,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            // 트로피 받은 글 리스트
                            SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              child: sendTrophyData.isNotEmpty
                                  ? Column(
                                      children: List.generate(
                                          sendTrophyData.length, (index) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color:
                                                ColorsConfig().subBackground1(),
                                            border: Border(
                                              top: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 유저 이미지, 닉네임, 날짜, 더보기 버튼
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20.0, 13.0, 20.0, 0.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (!sendTrophyData[
                                                            index]['isMe']) {
                                                          Navigator.pushNamed(
                                                              context,
                                                              '/your_profile',
                                                              arguments: {
                                                                'user_index':
                                                                    sendTrophyData[
                                                                            index]
                                                                        [
                                                                        'user_index'],
                                                                'user_nickname':
                                                                    getTrophyData[
                                                                            index]
                                                                        [
                                                                        'nick'],
                                                              });
                                                        }
                                                      },
                                                      child: Row(
                                                        children: [
                                                          // 이미지
                                                          Container(
                                                            width: 42.0,
                                                            height: 42.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .userIconBackground(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          21.0),
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'avatar_url'],
                                                                  scale: 5.5,
                                                                ),
                                                                filterQuality:
                                                                    FilterQuality
                                                                        .high,
                                                                fit:
                                                                    BoxFit.none,
                                                                alignment:
                                                                    const Alignment(
                                                                        0.0,
                                                                        -0.3),
                                                              ),
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
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
                                                                        // 닉네임
                                                                        Container(
                                                                          margin: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 8.0),
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${sendTrophyData[index]['nick']}',
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                16.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                        CustomTextBuilder(
                                                                          text: DateCalculatorWrapper().daysCalculator(sendTrophyData[index]
                                                                              [
                                                                              'date']),
                                                                          fontColor:
                                                                              ColorsConfig().textBlack2(),
                                                                          fontSize:
                                                                              12.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              13.0),
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              8.0,
                                                                          vertical:
                                                                              3.0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: sendTrophyData[index]['type'] ==
                                                                                1
                                                                            ? ColorsConfig().postLabel()
                                                                            : sendTrophyData[index]['type'] == 2
                                                                                ? ColorsConfig().analyticsLabel()
                                                                                : sendTrophyData[index]['type'] == 3
                                                                                    ? ColorsConfig().debateLabel()
                                                                                    : sendTrophyData[index]['type'] == 4
                                                                                        ? ColorsConfig().newsLabel()
                                                                                        : sendTrophyData[index]['type'] == 5
                                                                                            ? ColorsConfig().voteLabel()
                                                                                            : ColorsConfig.defaultWhite,
                                                                        borderRadius:
                                                                            BorderRadius.circular(4.0),
                                                                      ),
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text: sendTrophyData[index]['type'] ==
                                                                                1
                                                                            ? '포스트'
                                                                            : sendTrophyData[index]['type'] == 2
                                                                                ? '분 석'
                                                                                : sendTrophyData[index]['type'] == 3
                                                                                    ? '토 론'
                                                                                    : sendTrophyData[index]['type'] == 4
                                                                                        ? '뉴 스'
                                                                                        : sendTrophyData[index]['type'] == 5
                                                                                            ? '투 표'
                                                                                            : '',
                                                                        fontColor:
                                                                            ColorsConfig.defaultWhite,
                                                                        fontSize:
                                                                            11.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap:
                                                                    () async {
                                                                  final _prefs =
                                                                      await SharedPreferences
                                                                          .getInstance();

                                                                  GetGiftHistoryListDataAPI()
                                                                      .giftHistory(
                                                                          accesToken: _prefs.getString(
                                                                              'AccessToken')!,
                                                                          postIndex: sendTrophyData[index]
                                                                              [
                                                                              'post_index'])
                                                                      .then(
                                                                          (history) {
                                                                    showModalBottomSheet(
                                                                        context:
                                                                            context,
                                                                        backgroundColor:
                                                                            ColorsConfig()
                                                                                .subBackground1(),
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
                                                                            (BuildContext
                                                                                context) {
                                                                          return SafeArea(
                                                                            child:
                                                                                Container(
                                                                              decoration: const BoxDecoration(
                                                                                borderRadius: BorderRadius.only(
                                                                                  topLeft: Radius.circular(12.0),
                                                                                  topRight: Radius.circular(12.0),
                                                                                ),
                                                                              ),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 50.0,
                                                                                    height: 4.0,
                                                                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig().textBlack2(),
                                                                                      borderRadius: BorderRadius.circular(100.0),
                                                                                    ),
                                                                                  ),
                                                                                  Center(
                                                                                    child: Container(
                                                                                      width: MediaQuery.of(context).size.width,
                                                                                      padding: const EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0, bottom: 15.0),
                                                                                      decoration: BoxDecoration(
                                                                                        border: Border(
                                                                                          bottom: BorderSide(
                                                                                            width: 0.5,
                                                                                            color: ColorsConfig().border1(),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      child: CustomTextBuilder(
                                                                                        text: '선물내역',
                                                                                        fontColor: ColorsConfig().textWhite1(),
                                                                                        fontSize: 18.0.sp,
                                                                                        fontWeight: FontWeight.w600,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: ListView.builder(
                                                                                        itemCount: history.result['users'].length,
                                                                                        itemBuilder: (context, historyIndex) {
                                                                                          return Container(
                                                                                            width: MediaQuery.of(context).size.width,
                                                                                            height: 65.0,
                                                                                            padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                                                                                            decoration: BoxDecoration(
                                                                                              border: Border(
                                                                                                bottom: BorderSide(
                                                                                                  width: 0.5,
                                                                                                  color: ColorsConfig().border1(),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                Expanded(
                                                                                                  child: Row(
                                                                                                    children: [
                                                                                                      // 아바타 이미지
                                                                                                      Container(
                                                                                                        width: 35.0,
                                                                                                        height: 35.0,
                                                                                                        decoration: BoxDecoration(
                                                                                                          color: ColorsConfig().userIconBackground(),
                                                                                                          borderRadius: BorderRadius.circular(17.5),
                                                                                                          image: history.result['users'][historyIndex]['avatar'].toString().startsWith('https://image.DRPublic.co.kr/undefined') == false
                                                                                                              ? DecorationImage(
                                                                                                                  image: NetworkImage(
                                                                                                                    history.result['users'][historyIndex]['avatar'],
                                                                                                                    scale: 7.0,
                                                                                                                  ),
                                                                                                                  filterQuality: FilterQuality.high,
                                                                                                                  fit: BoxFit.none,
                                                                                                                  alignment: const Alignment(0.0, -0.3),
                                                                                                                )
                                                                                                              : null,
                                                                                                        ),
                                                                                                      ),
                                                                                                      const SizedBox(width: 15.0),
                                                                                                      CustomTextBuilder(
                                                                                                        text: '${history.result['users'][historyIndex]['nick']}',
                                                                                                        fontColor: ColorsConfig().textWhite1(),
                                                                                                        fontSize: 16.0.sp,
                                                                                                        fontWeight: FontWeight.w400,
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                                Expanded(
                                                                                                  child: ListView.builder(
                                                                                                    scrollDirection: Axis.horizontal,
                                                                                                    itemCount: history.result['gifts'].length,
                                                                                                    itemBuilder: (context, giftHistory) {
                                                                                                      if (history.result['gifts'][giftHistory]['user_index'] != history.result['users'][historyIndex]['user_index']) {
                                                                                                        return Container();
                                                                                                      }
                                                                                                      return Row(
                                                                                                        children: [
                                                                                                          Image(
                                                                                                            image: NetworkImage(
                                                                                                              history.result['gifts'][giftHistory]['image'],
                                                                                                            ),
                                                                                                          ),
                                                                                                          const SizedBox(width: 4.0),
                                                                                                          CustomTextBuilder(
                                                                                                            text: '${history.result['gifts'][giftHistory]['count']}',
                                                                                                            fontColor: ColorsConfig().textBlack2(),
                                                                                                            fontSize: 12.0.sp,
                                                                                                            fontWeight: FontWeight.w700,
                                                                                                          ),
                                                                                                          const SizedBox(width: 4.0),
                                                                                                        ],
                                                                                                      );
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          );
                                                                                        }),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        });
                                                                  });
                                                                },
                                                                child: !sendTrophyMoreBtnState[
                                                                        index]
                                                                    ? Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                4.0,
                                                                            top:
                                                                                5.0),
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          physics:
                                                                              const NeverScrollableScrollPhysics(),
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: List.generate(sendTrophyData[index]['gift'].length > 4 ? 4 : sendTrophyData[index]['gift'].length, (giftIndex) {
                                                                                  return Container(
                                                                                    margin: EdgeInsets.only(right: 8.0.r),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        Container(
                                                                                          width: 24.0,
                                                                                          height: 24.0,
                                                                                          decoration: BoxDecoration(
                                                                                            borderRadius: BorderRadius.circular(9.0),
                                                                                          ),
                                                                                          child: Image(
                                                                                            image: NetworkImage(
                                                                                              sendTrophyData[index]['gift'][giftIndex]['image'],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        CustomTextBuilder(
                                                                                          text: '${sendTrophyData[index]['gift'][giftIndex]['gift_count']}',
                                                                                          fontColor: ColorsConfig().textBlack2(),
                                                                                          fontSize: 12.0.sp,
                                                                                          fontWeight: FontWeight.w700,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  );
                                                                                }),
                                                                              ),
                                                                              !sendTrophyMoreBtnState[index] && sendTrophyData[index]['gift'].length > 4
                                                                                  ? InkWell(
                                                                                      onTap: () {
                                                                                        setState(() {
                                                                                          sendTrophyMoreBtnState[index] = true;
                                                                                        });
                                                                                      },
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                                                        child: CustomTextBuilder(
                                                                                          text: '...더보기',
                                                                                          fontColor: ColorsConfig().textBlack2(),
                                                                                          fontSize: 14.0.sp,
                                                                                          fontWeight: FontWeight.w400,
                                                                                        ),
                                                                                      ),
                                                                                    )
                                                                                  : Container(),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                4.0,
                                                                            top:
                                                                                5.0),
                                                                        child:
                                                                            Wrap(
                                                                          children: List.generate(
                                                                              sendTrophyData[index]['gift'].length,
                                                                              (giftIndex) {
                                                                            return Container(
                                                                              margin: EdgeInsets.only(right: 8.0.r),
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 24.0,
                                                                                    height: 24.0,
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: BorderRadius.circular(9.0),
                                                                                    ),
                                                                                    child: Image(
                                                                                      image: NetworkImage(
                                                                                        sendTrophyData[index]['gift'][giftIndex]['image'],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  CustomTextBuilder(
                                                                                    text: '${sendTrophyData[index]['gift'][giftIndex]['gift_count']}',
                                                                                    fontColor: ColorsConfig().textBlack2(),
                                                                                    fontSize: 12.0.sp,
                                                                                    fontWeight: FontWeight.w700,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          }),
                                                                        ),
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
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                child: InkWell(
                                                  onTap: () {
                                                    if (sendTrophyData[index]
                                                            ['type'] ==
                                                        4) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              NewsDetailScreen(
                                                            postIndex:
                                                                sendTrophyData[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                sendTrophyData[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    } else if (sendTrophyData[
                                                            index]['type'] ==
                                                        5) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              VoteDetailScreen(
                                                            postIndex:
                                                                sendTrophyData[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                sendTrophyData[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PostingDetailScreen(
                                                            postIndex:
                                                                sendTrophyData[
                                                                        index][
                                                                    'post_index'],
                                                            postType:
                                                                sendTrophyData[
                                                                        index]
                                                                    ['type'],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: sendTrophyData[index]
                                                              ['type'] ==
                                                          4
                                                      ? Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
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
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          56.0,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '${sendTrophyData[index]['title']}',
                                                                        fontColor:
                                                                            ColorsConfig().textWhite1(),
                                                                        fontSize:
                                                                            19.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        maxLines:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: (MediaQuery.of(context).size.width *
                                                                              0.75) -
                                                                          56.0,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '${sendTrophyData[index]['description']}',
                                                                        fontColor:
                                                                            ColorsConfig().textBlack3(),
                                                                        fontSize:
                                                                            17.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap: () {
                                                                  UrlLauncherBuilder()
                                                                      .launchURL(
                                                                          sendTrophyData[index]
                                                                              [
                                                                              'link']);
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: (MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.3) -
                                                                      23.0,
                                                                  height: 75.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: ColorsConfig()
                                                                        .textBlack2(),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      width:
                                                                          0.5,
                                                                      color: ColorsConfig()
                                                                          .primary(),
                                                                    ),
                                                                    image:
                                                                        DecorationImage(
                                                                      image:
                                                                          NetworkImage(
                                                                        sendTrophyData[index]
                                                                            [
                                                                            'news_image'],
                                                                      ),
                                                                      filterQuality:
                                                                          FilterQuality
                                                                              .high,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                  child: Stack(
                                                                    children: [
                                                                      Positioned(
                                                                        right:
                                                                            3.0,
                                                                        bottom:
                                                                            3.0,
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                ColorsConfig().linkIconBackground(),
                                                                            borderRadius:
                                                                                BorderRadius.circular(9.0),
                                                                          ),
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                SvgAssets(
                                                                              image: 'assets/icon/link.svg',
                                                                              color: ColorsConfig().primary(),
                                                                              width: 12.0,
                                                                              height: 12.0,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : sendTrophyData[index][
                                                                      'type'] ==
                                                                  1 ||
                                                              sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  2 ||
                                                              sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  3
                                                          ? Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
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
                                                                    height:
                                                                        75.0,
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          width: sendTrophyData[index]['category'] != null
                                                                              ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                              : MediaQuery.of(context).size.width - 40.0,
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${sendTrophyData[index]['title']}',
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                19.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            maxLines:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: sendTrophyData[index]['category'] != null
                                                                              ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                              : MediaQuery.of(context).size.width - 40.0,
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                '${sendTrophyData[index]['description']}',
                                                                            fontColor:
                                                                                ColorsConfig().textBlack3(),
                                                                            fontSize:
                                                                                17.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      sendTrophyData[index]['category'] != null &&
                                                                              sendTrophyData[index]['category'] == 'i'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: sendTrophyData[index]['image'].length > 1
                                                                                  ? PageView.builder(
                                                                                      controller: _pageController,
                                                                                      itemCount: sendTrophyData[index]['image'].length,
                                                                                      onPageChanged: (int page) {
                                                                                        setState(() {
                                                                                          currentPage = page;
                                                                                        });
                                                                                      },
                                                                                      itemBuilder: (context, imageIndex) {
                                                                                        return Image(
                                                                                            image: NetworkImage(
                                                                                              sendTrophyData[index]['image'][imageIndex],
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
                                                                                            sendTrophyData[index]['image'][0],
                                                                                          ),
                                                                                          fit: BoxFit.cover,
                                                                                          filterQuality: FilterQuality.high,
                                                                                          alignment: Alignment.center),
                                                                                    ),
                                                                            )
                                                                          : Container(),
                                                                      sendTrophyData[index]['category'] != null &&
                                                                              sendTrophyData[index]['category'] == 'g'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                image: NetworkImage(
                                                                                  sendTrophyData[index]['sub_link'],
                                                                                ),
                                                                                fit: BoxFit.cover,
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                      sendTrophyData[index]['category'] != null &&
                                                                              sendTrophyData[index]['category'] == 'y'
                                                                          ? SizedBox(
                                                                              width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                              height: 75.0,
                                                                              child: Image(
                                                                                image: NetworkImage(getYoutubeThumbnail(sendTrophyData[index]['sub_link'])),
                                                                                fit: BoxFit.cover,
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'type'] ==
                                                                  5
                                                              ? Container(
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  margin: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12.0),
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text: sendTrophyData[
                                                                            index]
                                                                        [
                                                                        'title'],
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textWhite1(),
                                                                    fontSize:
                                                                        19.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                )
                                                              : Container(),
                                                ),
                                              ),
                                              // 좋아요, 댓글, 더보기 버튼
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // 좋아요
                                                  MaterialButton(
                                                    onPressed: () async {
                                                      final _prefs =
                                                          await SharedPreferences
                                                              .getInstance();

                                                      if (!sendTrophyData[index]
                                                          ['isLike']) {
                                                        AddLikeSenderAPI()
                                                            .add(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                postIndex:
                                                                    sendTrophyData[
                                                                            index]
                                                                        [
                                                                        'post_index'])
                                                            .then((res) {
                                                          if (res.result[
                                                                  'status'] ==
                                                              10800) {
                                                            setState(() {
                                                              sendTrophyData[
                                                                      index]
                                                                  ['like']++;
                                                              sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  true;
                                                            });
                                                          }
                                                        });
                                                      } else {
                                                        CancelLikeSenderAPI()
                                                            .cancel(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                postIndex:
                                                                    sendTrophyData[
                                                                            index]
                                                                        [
                                                                        'post_index'])
                                                            .then((res) {
                                                          if (res.result[
                                                                  'status'] ==
                                                              10805) {
                                                            setState(() {
                                                              sendTrophyData[
                                                                      index]
                                                                  ['like']--;
                                                              sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  false;
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/like.svg',
                                                          color: sendTrophyData[
                                                                      index]
                                                                  ['isLike']
                                                              ? ColorsConfig()
                                                                  .primary()
                                                              : ColorsConfig()
                                                                  .textBlack1(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat.format(
                                                              sendTrophyData[
                                                                          index]
                                                                      ['like'] +
                                                                  sendThophysAddLikeCount),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack1(),
                                                          fontSize: 13.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // 댓글
                                                  MaterialButton(
                                                    onPressed: () {
                                                      if (sendTrophyData[index]
                                                              ['type'] ==
                                                          4) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                NewsDetailScreen(
                                                              postIndex:
                                                                  sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  sendTrophyData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              sendTrophyData.remove(
                                                                  sendTrophyData[
                                                                      index]);
                                                            });
                                                          }
                                                        });
                                                      } else if (sendTrophyData[
                                                              index]['type'] ==
                                                          5) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VoteDetailScreen(
                                                              postIndex:
                                                                  sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  sendTrophyData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              sendTrophyData.remove(
                                                                  sendTrophyData[
                                                                      index]);
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
                                                                  sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  sendTrophyData[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        ).then((returns) {
                                                          if (returns['ret']) {
                                                            setState(() {
                                                              sendTrophyData.remove(
                                                                  sendTrophyData[
                                                                      index]);
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/reply.svg',
                                                          color: ColorsConfig()
                                                              .textBlack1(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat
                                                              .format(
                                                                  sendTrophyData[
                                                                          index]
                                                                      [
                                                                      'reply']),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack1(),
                                                          fontSize: 13.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Container(),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Container(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    )
                                  : Container(
                                      height: 250.0.h,
                                      color: ColorsConfig().background(),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 114.0,
                                              height: 114.0,
                                              child: Image(
                                                image: AssetImage(
                                                    'assets/img/none_data.png'),
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                            const SizedBox(height: 20.0),
                                            CustomTextBuilder(
                                              text: '콘텐츠가 없습니다.',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w400,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ][_currentIndex],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Container(),
      ),
    );
  }
}
