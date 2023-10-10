import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/subscribe/add_subscribe.dart';
import 'package:DRPublic/api/subscribe/cancle_subscribe.dart';
import 'package:DRPublic/api/subscribe/my_subscribe.dart';
import 'package:DRPublic/api/subscribe/your_subscribe.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/widget/text_widget.dart';

class SubScribeListScreen extends StatefulWidget {
  const SubScribeListScreen({Key? key}) : super(key: key);

  @override
  State<SubScribeListScreen> createState() => _SubScribeListScreenState();
}

class _SubScribeListScreenState extends State<SubScribeListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  int _currentIndex = 0;
  List<dynamic> yourSubscribeList = [];
  List<dynamic> mySubscribeList = [];

  @override
  void initState() {
    _tabController = TabController(
      length: 2,
      vsync: this, //vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

    // get args
    Future.delayed(Duration.zero, () {
      setState(() {
        // _tabController.index = getInitialTabIndex();
        // _currentIndex = getInitialTabIndex();

        // argument가 존재할 경우 initialIndex 설정
        _tabController = TabController(
          initialIndex: getInitialTabIndex(),
          length: 2,
          vsync: this, //vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
        );
      });
    });

    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    Future.delayed(Duration.zero, () {
      GetMySubScribeListAPI()
          .subscribe(
              accesToken: _prefs.getString('AccessToken')!,
              nickname: RouteGetArguments().getArgs(context)['user_nickname'])
          .then((value) {
        setState(() {
          mySubscribeList = value.result;
        });
      });

      GetYourSubScribeListAPI()
          .subscribe(
              accesToken: _prefs.getString('AccessToken')!,
              nickname: RouteGetArguments().getArgs(context)['user_nickname'])
          .then((value) {
        setState(() {
          yourSubscribeList = value.result;
        });
      });
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

  int getInitialTabIndex() {
    int _tabIndex = RouteGetArguments().getArgs(context)['tabIndex'];
    return _tabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '구독',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46.0),
          child: Container(
            height: 46.0,
            decoration: BoxDecoration(
              color: ColorsConfig().subBackground1(),
              border: Border(
                top: BorderSide(
                  width: 0.5,
                  color: ColorsConfig().border1(),
                ),
                bottom: BorderSide(
                  width: 0.5,
                  color: ColorsConfig().border1(),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: ColorsConfig().primary(),
              unselectedLabelColor: ColorsConfig().textWhite1(),
              unselectedLabelStyle: TextStyle(
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w400,
              ),
              labelColor: ColorsConfig().textWhite1(),
              labelStyle: TextStyle(
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(
                  child: CustomTextBuilder(
                    text: '구독자',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '구독중',
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
          // 구독자 리스트
          yourSubscribeList.isNotEmpty
              ? Container(
                  color: ColorsConfig().background(),
                  child: ListView.builder(
                    itemCount: yourSubscribeList.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/your_profile',
                              arguments: {
                                'user_index': yourSubscribeList[index]
                                    ['user_index'],
                                'user_nickname': yourSubscribeList[index]
                                    ['user_nick'],
                              });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: ColorsConfig().subBackground1(),
                            border: Border(
                              bottom: BorderSide(
                                width: 0.5,
                                color: ColorsConfig().userIconBackground(),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 프로필 이미지, 닉네임
                              Row(
                                children: [
                                  // 프로필 이미지
                                  Container(
                                    width: 45.0,
                                    height: 45.0,
                                    margin: const EdgeInsets.only(right: 11.0),
                                    decoration: BoxDecoration(
                                      color:
                                          ColorsConfig().userIconBackground(),
                                      borderRadius: BorderRadius.circular(26.0),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          yourSubscribeList[index]
                                              ['avatar_url'],
                                          scale: 5.0,
                                        ),
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.none,
                                        alignment: const Alignment(0.0, -0.3),
                                      ),
                                    ),
                                  ),
                                  CustomTextBuilder(
                                    text:
                                        '${yourSubscribeList[index]['user_nick']}',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () async {
                                  final _prefs =
                                      await SharedPreferences.getInstance();

                                  if (!yourSubscribeList[index]['isFollow']) {
                                    AddSubScribeDataAPI()
                                        .addSubscribe(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            targetIndex:
                                                yourSubscribeList[index]
                                                    ['user_index'])
                                        .then((value) {
                                      if (value.result['status'] == 10400) {
                                        setState(() {
                                          yourSubscribeList[index]['isFollow'] =
                                              true;
                                          mySubscribeList
                                              .add(yourSubscribeList[index]);
                                        });
                                      }
                                    });
                                  } else {
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
                                              color: ColorsConfig()
                                                  .subBackground1(),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(8.0),
                                                topRight: Radius.circular(8.0),
                                              ),
                                            ),
                                            child: Center(
                                              child: CustomTextBuilder(
                                                text: '구독을 취소하시겠습니까?',
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
                                                  color:
                                                      ColorsConfig().border1(),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                  child: Container(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                80.5) /
                                                            2,
                                                    height: 43.0,
                                                    decoration: BoxDecoration(
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
                                                      child: CustomTextBuilder(
                                                        text: '취소',
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
                                                Container(
                                                  width: 0.5,
                                                  height: 43.0,
                                                  color:
                                                      ColorsConfig().border1(),
                                                ),
                                                InkWell(
                                                  onTap: () async {
                                                    final _prefs =
                                                        await SharedPreferences
                                                            .getInstance();

                                                    CancleSubScribeDataAPI()
                                                        .cancleSubscribe(
                                                            accesToken: _prefs
                                                                .getString(
                                                                    'AccessToken')!,
                                                            targetIndex:
                                                                yourSubscribeList[
                                                                        index][
                                                                    'user_index'])
                                                        .then((value) {
                                                      if (value.result[
                                                              'status'] ==
                                                          10405) {
                                                        setState(() {
                                                          yourSubscribeList[
                                                                      index]
                                                                  ['isFollow'] =
                                                              false;
                                                          for (int i = 0;
                                                              i <
                                                                  mySubscribeList
                                                                      .length;
                                                              i++) {
                                                            if (mySubscribeList[
                                                                        i][
                                                                    'user_index'] ==
                                                                yourSubscribeList[
                                                                        index][
                                                                    'user_index']) {
                                                              mySubscribeList
                                                                  .removeAt(i);
                                                            }
                                                          }
                                                        });
                                                      }
                                                    });

                                                    Navigator.pop(context);
                                                  },
                                                  child: Container(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                80.5) /
                                                            2,
                                                    height: 43.0,
                                                    decoration: BoxDecoration(
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
                                                      child: CustomTextBuilder(
                                                        text: '확인',
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textRed1(),
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
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 5.0),
                                  decoration: BoxDecoration(
                                    color: yourSubscribeList[index]['isFollow']
                                        ? ColorsConfig().subBackground1()
                                        : ColorsConfig().primary(),
                                    border: yourSubscribeList[index]['isFollow']
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                  child: CustomTextBuilder(
                                    text: yourSubscribeList[index]['isFollow']
                                        ? '구독취소'
                                        : '구독하기',
                                    fontColor: yourSubscribeList[index]
                                            ['isFollow']
                                        ? ColorsConfig().textWhite1()
                                        : ColorsConfig().subBackground1(),
                                    fontSize: 14.0.sp,
                                    fontWeight: FontWeight.w400,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  color: ColorsConfig().background(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 82.0,
                          height: 82.0,
                          child: Image(
                            image: AssetImage('assets/img/none_subscribe.png'),
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        CustomTextBuilder(
                          text: '구독중인 유저가 없습니다.',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        )
                      ],
                    ),
                  ),
                ),
          // 구독중인 리스트
          mySubscribeList.isNotEmpty
              ? Container(
                  color: ColorsConfig().background(),
                  child: ListView.builder(
                    itemCount: mySubscribeList.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/your_profile',
                              arguments: {
                                'user_index': mySubscribeList[index]
                                    ['user_index'],
                                'user_nickname': mySubscribeList[index]
                                    ['user_nick'],
                              });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: ColorsConfig().subBackground1(),
                            border: Border(
                              bottom: BorderSide(
                                width: 0.5,
                                color: ColorsConfig().userIconBackground(),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 프로필 이미지, 닉네임
                              Row(
                                children: [
                                  // 프로필 이미지
                                  Container(
                                    width: 45.0,
                                    height: 45.0,
                                    margin: const EdgeInsets.only(right: 11.0),
                                    decoration: BoxDecoration(
                                      color:
                                          ColorsConfig().userIconBackground(),
                                      borderRadius: BorderRadius.circular(26.0),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          mySubscribeList[index]['avatar_url'],
                                          scale: 5.0,
                                        ),
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.none,
                                        alignment: const Alignment(0.0, -0.3),
                                      ),
                                    ),
                                  ),
                                  CustomTextBuilder(
                                    text:
                                        '${mySubscribeList[index]['user_nick']}',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
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
                                            color:
                                                ColorsConfig().subBackground1(),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(8.0),
                                              topRight: Radius.circular(8.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: CustomTextBuilder(
                                              text: '구독을 취소하시겠습니까?',
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
                                                onTap: () =>
                                                    Navigator.pop(context),
                                                child: Container(
                                                  width: (MediaQuery.of(context)
                                                              .size
                                                              .width -
                                                          80.5) /
                                                      2,
                                                  height: 43.0,
                                                  decoration: BoxDecoration(
                                                    color: ColorsConfig()
                                                        .subBackground1(),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: CustomTextBuilder(
                                                      text: '취소',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 16.0.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 0.5,
                                                height: 43.0,
                                                color: ColorsConfig().border1(),
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  final _prefs =
                                                      await SharedPreferences
                                                          .getInstance();

                                                  CancleSubScribeDataAPI()
                                                      .cancleSubscribe(
                                                          accesToken:
                                                              _prefs.getString(
                                                                  'AccessToken')!,
                                                          targetIndex:
                                                              mySubscribeList[
                                                                      index][
                                                                  'user_index'])
                                                      .then((value) {
                                                    if (value
                                                            .result['status'] ==
                                                        10405) {
                                                      setState(() {
                                                        for (int i = 0;
                                                            i <
                                                                yourSubscribeList
                                                                    .length;
                                                            i++) {
                                                          if (yourSubscribeList[
                                                                      i][
                                                                  'user_index'] ==
                                                              mySubscribeList[
                                                                      index][
                                                                  'user_index']) {
                                                            yourSubscribeList[i]
                                                                    [
                                                                    'isFollow'] =
                                                                false;
                                                          }
                                                        }
                                                        mySubscribeList[index]
                                                                ['isFollow'] =
                                                            false;
                                                        mySubscribeList.remove(
                                                            mySubscribeList[
                                                                index]);
                                                      });
                                                    }
                                                  });

                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  width: (MediaQuery.of(context)
                                                              .size
                                                              .width -
                                                          80.5) /
                                                      2,
                                                  height: 43.0,
                                                  decoration: BoxDecoration(
                                                    color: ColorsConfig()
                                                        .subBackground1(),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      bottomRight:
                                                          Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: CustomTextBuilder(
                                                      text: '확인',
                                                      fontColor: ColorsConfig()
                                                          .textRed1(),
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
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 5.0),
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().subBackground1(),
                                    border: Border.all(
                                      width: 0.5,
                                      color: ColorsConfig().primary(),
                                    ),
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                  child: CustomTextBuilder(
                                    text: '구독취소',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 14.0.sp,
                                    fontWeight: FontWeight.w400,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  color: ColorsConfig().background(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 82.0,
                          height: 82.0,
                          child: Image(
                            image: AssetImage('assets/img/none_subscribe.png'),
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        CustomTextBuilder(
                          text: '구독중인 유저가 없습니다.',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        )
                      ],
                    ),
                  ),
                ),
        ], //[_currentIndex],
      ),
    );
  }
}
