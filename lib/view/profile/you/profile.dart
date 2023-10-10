import 'dart:async';

import 'package:DRPublic/widget/loading.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/enumerated.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/chatting/chatting_create.dart';
import 'package:DRPublic/api/gift/gift_history.dart';
import 'package:DRPublic/api/like/add.dart';
import 'package:DRPublic/api/like/cancel.dart';
import 'package:DRPublic/api/profile/badge_list.dart';
import 'package:DRPublic/api/profile/your_post_list.dart';
import 'package:DRPublic/api/subscribe/add_subscribe.dart';
import 'package:DRPublic/api/subscribe/cancle_subscribe.dart';
import 'package:DRPublic/api/subscribe/your_subscribe.dart';
import 'package:DRPublic/api/user/other_user_profile.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/widget/get_youtube_thumbnail.dart';
import 'package:DRPublic/widget/sliver_tabbar_widget.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:DRPublic/widget/url_launcher.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({Key? key}) : super(key: key);

  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  final PageController _pageController = PageController();

  var numberFormat = NumberFormat('###,###,###,###');

  Timer? _debounce;

  double kExpandedHeight = 332.0;

  int _currentIndex = 0;
  int addLikeCount = 0;
  int commentsAddLikeCount = 0;
  int currentPage = 0;
  int userIndex = 0;

  String userNickname = '';

  bool hasExpandedAppBar = false;
  bool isLoading = false;

  AccountState accountState = AccountState.normal;

  Map<String, dynamic> getUserProfileData = {};

  List<dynamic> getBadgeList = [];
  List<dynamic> getYourPostList = [];
  List<dynamic> getCommentsData = [];
  List<dynamic> getMyToUserSubscribeList = [];
  List<bool> getPostListMoreBtnState = [];
  List<bool> getCommentsMoreBtnState = [];

  @override
  void initState() {
    _scrollController = ScrollController()
      ..addListener(() {
        scrollListener();
        setState(() {
          hasExpandedAppBar = isSliverAppBarExpanded;
        });
      });

    _tabController = TabController(
      length: 5,
      vsync: this, //vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

    Future.delayed(Duration.zero, () {
      setState(() {
        userIndex = RouteGetArguments().getArgs(context)['user_index'];
        userNickname =
            RouteGetArguments().getArgs(context)['user_nickname'] ?? '';
      });
    });

    apiInitialize();

    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    Future.delayed(Duration.zero, () {
      OtherUserProfileInfoAPI()
          .userProfile(
              accesToken: _prefs.getString('AccessToken')!,
              userIndex: RouteGetArguments().getArgs(context)['user_index'])
          .then((value) {
        setState(() {
          getUserProfileData = value.result;

          switch (value.result['status']) {
            case 11200:
              accountState = AccountState.normal;
              break;
            case 11201:
              accountState = AccountState.suspension;
              break;
            case 11202:
              accountState = AccountState.withdrawal;
              break;
          }
        });

        Future.wait([
          // 나를 구독한 사람들
          GetYourSubScribeListAPI()
              .subscribe(
                  accesToken: _prefs.getString('AccessToken')!,
                  nickname: value.result['nick'])
              .then((value) {
            setState(() {
              getMyToUserSubscribeList = value.result;
            });
          }),
          // 뱃지
          GetBadgeListAPI()
              .badge(
                  accesToken: _prefs.getString('AccessToken')!,
                  nickname: value.result['nick'])
              .then((badges) {
            setState(() {
              getBadgeList = badges.result;
            });
          }),
          // 공유글
          GetYourPostListAPI()
              .post(
                  accesToken: _prefs.getString('AccessToken')!,
                  nickname: value.result['nick'],
                  type: 0)
              .then((posts) {
            setState(() {
              getYourPostList = posts.result['data'];

              for (int i = 0; i < posts.result['data'].length; i++) {
                getPostListMoreBtnState.add(false);
              }
            });
          }),
          // 코멘트
          GetYourPostListAPI()
              .post(
                  accesToken: _prefs.getString('AccessToken')!,
                  nickname: value.result['nick'],
                  type: 1)
              .then((comments) {
            setState(() {
              getCommentsData = comments.result['data'];

              for (int i = 0; i < comments.result['data'].length; i++) {
                getCommentsMoreBtnState.add(false);
              }
            });
          }),
        ]).then((_) {
          setState(() {
            isLoading = true;
          });
        });
      });
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
              GetYourPostListAPI()
                  .post(
                      accesToken: _prefs.getString('AccessToken')!,
                      nickname: getYourPostList.first['nick'],
                      type: 0,
                      cursor: getYourPostList.last['post_index'])
                  .then((posts) {
                for (int i = 0; i < posts.result['data'].length; i++) {
                  setState(() {
                    getYourPostList.add(posts.result['data'][i]);
                    getPostListMoreBtnState.add(false);
                  });
                }
              });
            });
          } else if (_currentIndex == 4) {
            SharedPreferences.getInstance().then((_prefs) {
              GetYourPostListAPI()
                  .post(
                      accesToken: _prefs.getString('AccessToken')!,
                      nickname: getCommentsData.first['nick'],
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

  // sliver appbar 축소 or 확대 체크 함수
  bool get isSliverAppBarExpanded {
    return _scrollController.hasClients &&
        _scrollController.offset > kExpandedHeight - kToolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    if (accountState != AccountState.normal) {
      return Scaffold(
        backgroundColor: ColorsConfig().subBackground1(),
        appBar: DRAppBar(
          title: DRAppBarTitle(
            title: userNickname,
          ),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(20.0),
          alignment: const Alignment(0.0, -0.15),
          child: CustomTextBuilder(
            text: '더 이상 이용되지 않는 계정입니다.',
            fontColor: ColorsConfig().textBlack2(),
            fontSize: 20.0.sp,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorsConfig().background(),
      body: isLoading
          ? getUserProfileData.isNotEmpty
              ? CustomScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // sliver appbar
                    SliverAppBar(
                      expandedHeight: kExpandedHeight,
                      pinned: true,
                      elevation: 0.0,
                      backgroundColor: ColorsConfig().background(),
                      systemOverlayStyle:
                          Theme.of(context).appBarTheme.systemOverlayStyle,
                      leading: DRAppBarLeading(
                        press: () {
                          Navigator.pop(context);
                        },
                      ),
                      title: DRAppBarTitle(
                        title: '${getUserProfileData['nick']}의 채널',
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: SafeArea(
                          left: false,
                          right: false,
                          bottom: false,
                          child: Column(
                            children: [
                              // 커버 이미지
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 91.0,
                                margin:
                                    const EdgeInsets.only(top: kToolbarHeight),
                                child: getUserProfileData['app_background'] ==
                                        false
                                    ? const Image(
                                        image: AssetImage(
                                            'assets/img/cover_background.png'),
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.cover,
                                      )
                                    : Image(
                                        image: NetworkImage(getUserProfileData[
                                            'app_background']),
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 185.0,
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 14.0, 20.0, 16.0),
                                child: Row(
                                  children: [
                                    // 아바타
                                    Container(
                                      height: 150.0,
                                      margin: const EdgeInsets.only(right: 7.0),
                                      child: getUserProfileData['avatar'] !=
                                              false
                                          ? Image(
                                              image: NetworkImage(
                                                getUserProfileData['avatar'],
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
                                                text:
                                                    '${getUserProfileData['nick']}',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              const SizedBox(width: 6.0),
                                              // 가입일자
                                              CustomTextBuilder(
                                                text:
                                                    '${DateFormat('yyyy.MM.dd').format(DateTime.parse(getUserProfileData['reg_date']))} 가입',
                                                fontColor:
                                                    ColorsConfig().textBlack2(),
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 5.0),
                                          child: Row(
                                            children: [
                                              CustomTextBuilder(
                                                text: '구독자',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              const SizedBox(width: 6.0),
                                              CustomTextBuilder(
                                                text: numberFormat.format(
                                                    getMyToUserSubscribeList
                                                        .length),
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 자기소개 텍스트
                                        getUserProfileData['description'] !=
                                                null
                                            ? Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    162.0,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10.0),
                                                child: CustomTextBuilder(
                                                  text:
                                                      '${getUserProfileData['description']}',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w400,
                                                  maxLines: 3,
                                                  textOverflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              )
                                            : Container(),
                                        getUserProfileData['description'] ==
                                                null
                                            ? const SizedBox(height: 10.0)
                                            : Container(),
                                        Row(
                                          children: [
                                            // 구독 버튼
                                            InkWell(
                                              onTap: () {
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
                                                            text: getUserProfileData[
                                                                    'isFollow']
                                                                ? '구독을 취소하시겠습니까?'
                                                                : '구독을 하시겠습니까?',
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
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Container(
                                                                width: (MediaQuery.of(context)
                                                                            .size
                                                                            .width -
                                                                        80.5) /
                                                                    2,
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
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text: '취소',
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
                                                            Container(
                                                              width: 0.5,
                                                              height: 43.0,
                                                              color:
                                                                  ColorsConfig()
                                                                      .border1(),
                                                            ),
                                                            InkWell(
                                                              onTap: () async {
                                                                final _prefs =
                                                                    await SharedPreferences
                                                                        .getInstance();

                                                                if (getUserProfileData[
                                                                    'isFollow']) {
                                                                  CancleSubScribeDataAPI()
                                                                      .cancleSubscribe(
                                                                          accesToken: _prefs.getString(
                                                                              'AccessToken')!,
                                                                          targetIndex: RouteGetArguments().getArgs(context)[
                                                                              'user_index'])
                                                                      .then(
                                                                          (value) {
                                                                    if (value.result[
                                                                            'status'] ==
                                                                        10405) {
                                                                      setState(
                                                                          () {
                                                                        getUserProfileData['isFollow'] =
                                                                            false;
                                                                      });

                                                                      GetYourSubScribeListAPI()
                                                                          .subscribe(
                                                                              accesToken: _prefs.getString('AccessToken')!,
                                                                              nickname: userNickname)
                                                                          .then((val) {
                                                                        setState(
                                                                            () {
                                                                          getMyToUserSubscribeList =
                                                                              val.result;
                                                                        });
                                                                      });
                                                                    }
                                                                  });
                                                                } else {
                                                                  AddSubScribeDataAPI()
                                                                      .addSubscribe(
                                                                          accesToken: _prefs.getString(
                                                                              'AccessToken')!,
                                                                          targetIndex: RouteGetArguments().getArgs(context)[
                                                                              'user_index'])
                                                                      .then(
                                                                          (value) {
                                                                    if (value.result[
                                                                            'status'] ==
                                                                        10400) {
                                                                      setState(
                                                                          () {
                                                                        getUserProfileData['isFollow'] =
                                                                            true;
                                                                      });

                                                                      GetYourSubScribeListAPI()
                                                                          .subscribe(
                                                                              accesToken: _prefs.getString('AccessToken')!,
                                                                              nickname: userNickname)
                                                                          .then((val) {
                                                                        setState(
                                                                            () {
                                                                          getMyToUserSubscribeList =
                                                                              val.result;
                                                                        });
                                                                      });
                                                                    }
                                                                  });
                                                                }

                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: Container(
                                                                width: (MediaQuery.of(context)
                                                                            .size
                                                                            .width -
                                                                        80.5) /
                                                                    2,
                                                                height: 43.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: ColorsConfig()
                                                                      .subBackground1(),
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .only(
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                  child:
                                                                      CustomTextBuilder(
                                                                    text: '확인',
                                                                    fontColor: getUserProfileData[
                                                                            'isFollow']
                                                                        ? ColorsConfig()
                                                                            .textRed1()
                                                                        : ColorsConfig
                                                                            .subscribeBtnPrimary,
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
                                              },
                                              child: Container(
                                                width: 96.0,
                                                height: 33.0,
                                                decoration: BoxDecoration(
                                                  color: !getUserProfileData[
                                                          'isFollow']
                                                      ? ColorsConfig
                                                          .subscribeBtnPrimary
                                                      : ColorsConfig()
                                                          .button2(),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text: !getUserProfileData[
                                                            'isFollow']
                                                        ? '구독하기'
                                                        : '구독취소',
                                                    fontColor: ColorsConfig
                                                        .defaultWhite,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            // 메시지 버튼
                                            InkWell(
                                              onTap: () async {
                                                final _prefs =
                                                    await SharedPreferences
                                                        .getInstance();

                                                ChattingCreateAPI()
                                                    .create(
                                                        accesToken:
                                                            _prefs.getString(
                                                                'AccessToken')!,
                                                        userIndex:
                                                            RouteGetArguments()
                                                                    .getArgs(
                                                                        context)[
                                                                'user_index'])
                                                    .then((value) {
                                                  Navigator.pushNamed(
                                                      context, '/note_detail',
                                                      arguments: {
                                                        'userIndex':
                                                            RouteGetArguments()
                                                                    .getArgs(
                                                                        context)[
                                                                'user_index'],
                                                        'nickname':
                                                            getUserProfileData[
                                                                'nick'],
                                                        'avatar':
                                                            getUserProfileData[
                                                                'avatar'],
                                                      });
                                                });
                                              },
                                              child: Container(
                                                width: 96.0,
                                                height: 33.0,
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .avatarIconBackground(),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text: '메시지 보내기',
                                                    fontColor: ColorsConfig()
                                                        .textAllBlack1(),
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // const SizedBox(width: 5.0),
                                            // Container(
                                            //   decoration: BoxDecoration(
                                            //     color: ColorsConfig().profileButton1(),
                                            //     borderRadius: BorderRadius.circular(6.0),
                                            //   ),
                                            //   padding: const EdgeInsets.symmetric(horizontal: 10.5, vertical: 7.8),
                                            //   child: Center(
                                            //     child: SvgAssets(
                                            //       image: 'assets/icon/notification.svg',
                                            //       color: ColorsConfig().textAllBlack1(),
                                            //       width: 20.0,
                                            //       height: 20.0,
                                            //     ),
                                            //   ),
                                            // ),
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
                                  (MediaQuery.of(context).size.height - 46.0) /
                                      2,
                              maxHeight: double.infinity,
                            ),
                            // color: ColorsConfig().defaultWhite,
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
                                      decoration: BoxDecoration(
                                        color: ColorsConfig().background(),
                                        border: Border(
                                          bottom: BorderSide(
                                            width: 0.5,
                                            color: ColorsConfig().border1(),
                                          ),
                                        ),
                                      ),
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
                                    getBadgeList.isNotEmpty
                                        ? Container(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            color:
                                                ColorsConfig().subBackground1(),
                                            child: Column(
                                              children: List.generate(
                                                  getBadgeList.length, (index) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20.0,
                                                      vertical: 12.0),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 48.0,
                                                        height: 48.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: ColorsConfig()
                                                              .textBlack2(),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          image:
                                                              DecorationImage(
                                                            image: NetworkImage(
                                                                '${getBadgeList[index]['image']}'),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            104.0,
                                                        margin: const EdgeInsets
                                                            .only(left: 16.0),
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
                                                                  FontWeight
                                                                      .w600,
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
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
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
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 16.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  )
                                                ],
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
                                child: getYourPostList.isNotEmpty
                                    ? Column(
                                        children: List.generate(
                                            getYourPostList.length, (index) {
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
                                                                  getYourPostList[
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
                                                                                '${getYourPostList[index]['nick']}',
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                16.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                        CustomTextBuilder(
                                                                          text: DateCalculatorWrapper().daysCalculator(getYourPostList[index]
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
                                                                        color: getYourPostList[index]['type'] ==
                                                                                1
                                                                            ? ColorsConfig().postLabel()
                                                                            : getYourPostList[index]['type'] == 2
                                                                                ? ColorsConfig().analyticsLabel()
                                                                                : getYourPostList[index]['type'] == 3
                                                                                    ? ColorsConfig().debateLabel()
                                                                                    : getYourPostList[index]['type'] == 4
                                                                                        ? ColorsConfig().newsLabel()
                                                                                        : getYourPostList[index]['type'] == 5
                                                                                            ? ColorsConfig().voteLabel()
                                                                                            : null,
                                                                        borderRadius:
                                                                            BorderRadius.circular(4.0),
                                                                      ),
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text: getYourPostList[index]['type'] ==
                                                                                1
                                                                            ? '포스트'
                                                                            : getYourPostList[index]['type'] == 2
                                                                                ? '분 석'
                                                                                : getYourPostList[index]['type'] == 3
                                                                                    ? '토 론'
                                                                                    : getYourPostList[index]['type'] == 4
                                                                                        ? '뉴 스'
                                                                                        : getYourPostList[index]['type'] == 5
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
                                                              // 선물받은 뱃지영역
                                                              getYourPostList[index]
                                                                          [
                                                                          'gift']
                                                                      .isNotEmpty
                                                                  ? InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        final _prefs =
                                                                            await SharedPreferences.getInstance();

                                                                        GetGiftHistoryListDataAPI()
                                                                            .giftHistory(
                                                                                accesToken: _prefs.getString('AccessToken')!,
                                                                                postIndex: getYourPostList[index]['post_index'])
                                                                            .then((history) {
                                                                          showModalBottomSheet(
                                                                              context: context,
                                                                              backgroundColor: ColorsConfig().subBackground1(),
                                                                              shape: const RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.only(
                                                                                  topLeft: Radius.circular(12.0),
                                                                                  topRight: Radius.circular(12.0),
                                                                                ),
                                                                              ),
                                                                              builder: (BuildContext context) {
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
                                                                      child: !getPostListMoreBtnState[
                                                                              index]
                                                                          ? Container(
                                                                              margin: const EdgeInsets.only(left: 4.0, top: 5.0),
                                                                              child: SingleChildScrollView(
                                                                                physics: const NeverScrollableScrollPhysics(),
                                                                                scrollDirection: Axis.horizontal,
                                                                                child: Row(
                                                                                  children: [
                                                                                    Row(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: List.generate(getYourPostList[index]['gift'].length > 4 ? 4 : getYourPostList[index]['gift'].length, (giftIndex) {
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
                                                                                                    getYourPostList[index]['gift'][giftIndex]['image'],
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              CustomTextBuilder(
                                                                                                text: '${getYourPostList[index]['gift'][giftIndex]['gift_count']}',
                                                                                                fontColor: ColorsConfig().textBlack2(),
                                                                                                fontSize: 12.0.sp,
                                                                                                fontWeight: FontWeight.w700,
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        );
                                                                                      }),
                                                                                    ),
                                                                                    !getPostListMoreBtnState[index] && getYourPostList[index]['gift'].length > 4
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
                                                                              margin: const EdgeInsets.only(left: 4.0, top: 5.0),
                                                                              child: Wrap(
                                                                                children: List.generate(getYourPostList[index]['gift'].length, (giftIndex) {
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
                                                                                              getYourPostList[index]['gift'][giftIndex]['image'],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        CustomTextBuilder(
                                                                                          text: '${getYourPostList[index]['gift'][giftIndex]['gift_count']}',
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
                                                                    )
                                                                  : Container(),
                                                            ],
                                                          ),
                                                        ],
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
                                                      if (getYourPostList[index]
                                                              ['type'] ==
                                                          4) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                NewsDetailScreen(
                                                              postIndex:
                                                                  getYourPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getYourPostList[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        );
                                                      } else if (getYourPostList[
                                                              index]['type'] ==
                                                          5) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VoteDetailScreen(
                                                              postIndex:
                                                                  getYourPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getYourPostList[
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
                                                                  getYourPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'],
                                                              postType:
                                                                  getYourPostList[
                                                                          index]
                                                                      ['type'],
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: getYourPostList[
                                                                    index][
                                                                'type'] ==
                                                            4
                                                        ? Column(
                                                            children: [
                                                              Container(
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
                                                                            width:
                                                                                (MediaQuery.of(context).size.width * 0.75) - 60.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getYourPostList[index]['title']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 19.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                              maxLines: 2,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                (MediaQuery.of(context).size.width * 0.75) - 60.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getYourPostList[index]['description']}',
                                                                              fontColor: ColorsConfig().textBlack3(),
                                                                              fontSize: 17.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                              maxLines: 1,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    InkWell(
                                                                      onTap:
                                                                          () {
                                                                        UrlLauncherBuilder().launchURL(getYourPostList[index]
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
                                                                          color:
                                                                              ColorsConfig().textBlack2(),
                                                                          border:
                                                                              Border.all(
                                                                            width:
                                                                                0.5,
                                                                            color:
                                                                                ColorsConfig().primary(),
                                                                          ),
                                                                          image:
                                                                              DecorationImage(
                                                                            image:
                                                                                NetworkImage(
                                                                              getYourPostList[index]['news_image'],
                                                                            ),
                                                                            filterQuality:
                                                                                FilterQuality.high,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Stack(
                                                                          children: [
                                                                            Positioned(
                                                                              right: 3.0,
                                                                              bottom: 3.0,
                                                                              child: Container(
                                                                                width: 18.0,
                                                                                height: 18.0,
                                                                                decoration: BoxDecoration(
                                                                                  color: ColorsConfig().linkIconBackground(),
                                                                                  borderRadius: BorderRadius.circular(9.0),
                                                                                ),
                                                                                child: Center(
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
                                                              ),
                                                            ],
                                                          )
                                                        : getYourPostList[
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    1 ||
                                                                getYourPostList[
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    2 ||
                                                                getYourPostList[
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
                                                                            width: getYourPostList[index]['category'] != null
                                                                                ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                                : MediaQuery.of(context).size.width - 40.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getYourPostList[index]['title']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 19.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                              maxLines: 2,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width: getYourPostList[index]['category'] != null
                                                                                ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                                : MediaQuery.of(context).size.width - 40.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getYourPostList[index]['description']}',
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
                                                                        getYourPostList[index]['category'] != null &&
                                                                                getYourPostList[index]['category'] == 'i'
                                                                            ? SizedBox(
                                                                                width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                height: 75.0,
                                                                                child: getYourPostList[index]['image'].length > 1
                                                                                    ? PageView.builder(
                                                                                        controller: _pageController,
                                                                                        itemCount: getYourPostList[index]['image'].length,
                                                                                        onPageChanged: (int page) {
                                                                                          setState(() {
                                                                                            currentPage = page;
                                                                                          });
                                                                                        },
                                                                                        itemBuilder: (context, imageIndex) {
                                                                                          return Image(
                                                                                              image: NetworkImage(
                                                                                                getYourPostList[index]['image'][imageIndex],
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
                                                                                              getYourPostList[index]['image'][0],
                                                                                            ),
                                                                                            fit: BoxFit.cover,
                                                                                            filterQuality: FilterQuality.high,
                                                                                            alignment: Alignment.center),
                                                                                      ),
                                                                              )
                                                                            : Container(),
                                                                        getYourPostList[index]['category'] != null &&
                                                                                getYourPostList[index]['category'] == 'g'
                                                                            ? SizedBox(
                                                                                width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                height: 75.0,
                                                                                child: Image(
                                                                                  image: NetworkImage(
                                                                                    getYourPostList[index]['sub_link'],
                                                                                  ),
                                                                                  fit: BoxFit.cover,
                                                                                  filterQuality: FilterQuality.high,
                                                                                ),
                                                                              )
                                                                            : Container(),
                                                                        getYourPostList[index]['category'] != null &&
                                                                                getYourPostList[index]['category'] == 'y'
                                                                            ? SizedBox(
                                                                                width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                height: 75.0,
                                                                                child: Image(
                                                                                  image: NetworkImage(getYoutubeThumbnail(getYourPostList[index]['sub_link'])),
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
                                                            : getYourPostList[
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    5
                                                                ? Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        margin: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                12.0),
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text: getYourPostList[index]
                                                                              [
                                                                              'title'],
                                                                          fontColor:
                                                                              ColorsConfig().textWhite1(),
                                                                          fontSize:
                                                                              19.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
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

                                                        if (!getYourPostList[
                                                            index]['isLike']) {
                                                          AddLikeSenderAPI()
                                                              .add(
                                                                  accesToken: _prefs
                                                                      .getString(
                                                                          'AccessToken')!,
                                                                  postIndex: getYourPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'])
                                                              .then((res) {
                                                            if (res.result[
                                                                    'status'] ==
                                                                10800) {
                                                              setState(() {
                                                                getYourPostList[
                                                                        index]
                                                                    ['like']++;
                                                                getYourPostList[
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
                                                                  postIndex: getYourPostList[
                                                                          index]
                                                                      [
                                                                      'post_index'])
                                                              .then((res) {
                                                            if (res.result[
                                                                    'status'] ==
                                                                10805) {
                                                              setState(() {
                                                                getYourPostList[
                                                                        index]
                                                                    ['like']--;
                                                                getYourPostList[
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
                                                            color: getYourPostList[
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
                                                                getYourPostList[
                                                                            index]
                                                                        [
                                                                        'like'] +
                                                                    0),
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
                                                        if (getYourPostList[
                                                                    index]
                                                                ['type'] ==
                                                            4) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  NewsDetailScreen(
                                                                postIndex:
                                                                    getYourPostList[
                                                                            index]
                                                                        [
                                                                        'post_index'],
                                                                postType:
                                                                    getYourPostList[
                                                                            index]
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getYourPostList.remove(
                                                                    getYourPostList[
                                                                        index]);
                                                              });
                                                            }
                                                          });
                                                        } else if (getYourPostList[
                                                                    index]
                                                                ['type'] ==
                                                            5) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  VoteDetailScreen(
                                                                postIndex:
                                                                    getYourPostList[
                                                                            index]
                                                                        [
                                                                        'post_index'],
                                                                postType:
                                                                    getYourPostList[
                                                                            index]
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getYourPostList.remove(
                                                                    getYourPostList[
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
                                                                    getYourPostList[
                                                                            index]
                                                                        [
                                                                        'post_index'],
                                                                postType:
                                                                    getYourPostList[
                                                                            index]
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getYourPostList.remove(
                                                                    getYourPostList[
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
                                                                getYourPostList[
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
                                                          if (getCommentsData[
                                                              index]['isMe']) {
                                                            Navigator.pushNamed(
                                                                context,
                                                                '/my_profile',
                                                                arguments: {
                                                                  'onNavigator':
                                                                      true,
                                                                });
                                                          } else {
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
                                                                              text: '${getCommentsData[index]['nick']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                          ),
                                                                          CustomTextBuilder(
                                                                            text:
                                                                                DateCalculatorWrapper().daysCalculator(getCommentsData[index]['date']),
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
                                                                          color: getCommentsData[index]['type'] == 1
                                                                              ? ColorsConfig().postLabel()
                                                                              : getCommentsData[index]['type'] == 2
                                                                                  ? ColorsConfig().analyticsLabel()
                                                                                  : getCommentsData[index]['type'] == 3
                                                                                      ? ColorsConfig().debateLabel()
                                                                                      : getCommentsData[index]['type'] == 4
                                                                                          ? ColorsConfig().newsLabel()
                                                                                          : getCommentsData[index]['type'] == 5
                                                                                              ? ColorsConfig().voteLabel()
                                                                                              : null,
                                                                          borderRadius:
                                                                              BorderRadius.circular(4.0),
                                                                        ),
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text: getCommentsData[index]['type'] == 1
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
                                                                // 선물받은 뱃지영역
                                                                getCommentsData[index]
                                                                            [
                                                                            'gift']
                                                                        .isNotEmpty
                                                                    ? InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          final _prefs =
                                                                              await SharedPreferences.getInstance();

                                                                          GetGiftHistoryListDataAPI()
                                                                              .giftHistory(accesToken: _prefs.getString('AccessToken')!, postIndex: getCommentsData[index]['post_index'])
                                                                              .then((history) {
                                                                            showModalBottomSheet(
                                                                                context: context,
                                                                                backgroundColor: ColorsConfig().subBackground1(),
                                                                                shape: const RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.only(
                                                                                    topLeft: Radius.circular(12.0),
                                                                                    topRight: Radius.circular(12.0),
                                                                                  ),
                                                                                ),
                                                                                builder: (BuildContext context) {
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
                                                                        child: !getCommentsMoreBtnState[index]
                                                                            ? Container(
                                                                                margin: const EdgeInsets.only(left: 4.0, top: 5.0),
                                                                                child: SingleChildScrollView(
                                                                                  physics: const NeverScrollableScrollPhysics(),
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  child: Row(
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
                                                                                margin: const EdgeInsets.only(left: 4.0, top: 5.0),
                                                                                child: Wrap(
                                                                                  children: List.generate(getCommentsData[index]['gift'].length, (giftIndex) {
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
                                                                      )
                                                                    : Container(),
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
                                                                          index]
                                                                      [
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
                                                                          index]
                                                                      [
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
                                                    child: getCommentsData[
                                                                    index][
                                                                'type'] ==
                                                            4
                                                        ? Column(
                                                            children: [
                                                              Container(
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
                                                                            width:
                                                                                (MediaQuery.of(context).size.width * 0.75) - 60.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getCommentsData[index]['title']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 19.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                              maxLines: 2,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                (MediaQuery.of(context).size.width * 0.75) - 60.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getCommentsData[index]['description']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 17.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                              maxLines: 1,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    InkWell(
                                                                      onTap:
                                                                          () {
                                                                        UrlLauncherBuilder().launchURL(getCommentsData[index]
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
                                                                          color:
                                                                              ColorsConfig().textBlack2(),
                                                                          border:
                                                                              Border.all(
                                                                            width:
                                                                                0.5,
                                                                            color:
                                                                                ColorsConfig().primary(),
                                                                          ),
                                                                          image:
                                                                              DecorationImage(
                                                                            image:
                                                                                NetworkImage(
                                                                              getCommentsData[index]['news_image'],
                                                                            ),
                                                                            filterQuality:
                                                                                FilterQuality.high,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Stack(
                                                                          children: [
                                                                            Positioned(
                                                                              right: 3.0,
                                                                              bottom: 3.0,
                                                                              child: Container(
                                                                                width: 18.0,
                                                                                height: 18.0,
                                                                                decoration: BoxDecoration(
                                                                                  color: ColorsConfig().linkIconBackground(),
                                                                                  borderRadius: BorderRadius.circular(9.0),
                                                                                ),
                                                                                child: Center(
                                                                                  child: SvgAssets(
                                                                                    image: 'assets/icon/link.svg',
                                                                                    color: ColorsConfig().primary(),
                                                                                    width: 12.0,
                                                                                    height: 12.0,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : getCommentsData[
                                                                            index]
                                                                        [
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
                                                                            width: getCommentsData[index]['category'] != null
                                                                                ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                                : MediaQuery.of(context).size.width - 40.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getCommentsData[index]['title']}',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 19.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                              maxLines: 2,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width: getCommentsData[index]['category'] != null
                                                                                ? (MediaQuery.of(context).size.width * 0.75) - 56.0
                                                                                : MediaQuery.of(context).size.width - 40.0,
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: '${getCommentsData[index]['description']}',
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
                                                                                    : SizedBox(
                                                                                        width: (MediaQuery.of(context).size.width * 0.3) - 23.0,
                                                                                        height: 75.0,
                                                                                        child: Image(
                                                                                            image: NetworkImage(
                                                                                              getCommentsData[index]['image'][0],
                                                                                            ),
                                                                                            fit: BoxFit.cover,
                                                                                            filterQuality: FilterQuality.high,
                                                                                            alignment: Alignment.center),
                                                                                      ),
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
                                                                                  fit: BoxFit.contain,
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
                                                                ? Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        margin: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                12.0),
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text: getCommentsData[index]
                                                                              [
                                                                              'title'],
                                                                          fontColor:
                                                                              ColorsConfig().textWhite1(),
                                                                          fontSize:
                                                                              19.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
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
                                                                  postIndex: getCommentsData[
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
                                                                  postIndex: getCommentsData[
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
                                                                        [
                                                                        'like'] +
                                                                    0),
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
                                                        if (getCommentsData[
                                                                    index]
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
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
                                                              setState(() {
                                                                getCommentsData.remove(
                                                                    getCommentsData[
                                                                        index]);
                                                              });
                                                            }
                                                          });
                                                        } else if (getCommentsData[
                                                                    index]
                                                                ['type'] ==
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
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
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
                                                                        [
                                                                        'type'],
                                                              ),
                                                            ),
                                                          ).then((returns) {
                                                            if (returns[
                                                                'ret']) {
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
                                                            text: numberFormat.format(
                                                                getCommentsData[
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
                            ][_currentIndex],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Container()
          : const LoadingProgressScreen(),
    );
  }
}
