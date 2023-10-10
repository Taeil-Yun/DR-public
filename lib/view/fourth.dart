import 'dart:async';

import 'package:DRPublic/api/notification/notification_list.dart';
import 'package:DRPublic/widget/loading.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/chatting/chatting_delete.dart';
import 'package:DRPublic/api/chatting/chatting_list.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/widget/drawer_widget.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class FourthScreenBuilder extends StatefulWidget {
  const FourthScreenBuilder({Key? key}) : super(key: key);

  @override
  State<FourthScreenBuilder> createState() => _FourthScreenBuilderState();
}

class _FourthScreenBuilderState extends State<FourthScreenBuilder> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int lastNotificationCount = 0;
  int recentNotificationCount = 0;

  bool isLoading = false;

  List<dynamic> chattingListData = [];

  Map<String, dynamic> getProfileData = {};

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    Future.wait([
      GetChattingListAPI()
          .chattingList(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          chattingListData = value.result;
        });
      }),
      UserProfileInfoAPI()
          .getProfile(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          getProfileData = value?.result;
        });
      }),
    ]).then((_) {
      isLoading = true;
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
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        leadingWidth: 70.0,
        backgroundColor: ColorsConfig().subBackground1(),
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
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
          ? chattingListData.isNotEmpty
              ? Container(
                  color: ColorsConfig().background(),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final _prefs = await SharedPreferences.getInstance();

                      GetChattingListAPI()
                          .chattingList(
                              accesToken: _prefs.getString('AccessToken')!)
                          .then((value) {
                        setState(() {
                          chattingListData = value.result;
                        });
                      });
                    },
                    color: ColorsConfig().textWhite1(),
                    backgroundColor: ColorsConfig().subBackgroundBlack(),
                    child: SlidableAutoCloseBehavior(
                      child: ListView.builder(
                        itemCount: chattingListData.length,
                        itemBuilder: (context, index) {
                          return Slidable(
                            key: UniqueKey(),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              dragDismissible: false,
                              dismissible: DismissiblePane(
                                onDismissed: () {},
                              ),
                              extentRatio: 0.20,
                              children: [
                                SlidableAction(
                                  flex: 1,
                                  onPressed: (_context) {
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
                                                text: TextConstant
                                                    .deleteMessageAlertText,
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
                                                        text: TextConstant
                                                            .cancelText,
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

                                                    ChattingDeleteAPI()
                                                        .delete(
                                                            accesToken: _prefs
                                                                .getString(
                                                                    'AccessToken')!,
                                                            userIndex:
                                                                chattingListData[
                                                                        index][
                                                                    'user_index'])
                                                        .then((value) {
                                                      if (value.result[
                                                              'status'] ==
                                                          10505) {
                                                        setState(() {
                                                          chattingListData
                                                              .removeAt(index);
                                                        });
                                                      }

                                                      Navigator.pop(context);
                                                    });
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
                                                        text: TextConstant
                                                            .removeText,
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
                                  },
                                  backgroundColor: ColorsConfig().textRed1(),
                                  icon: Icons.delete,
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/note_detail',
                                    arguments: {
                                      'userIndex': chattingListData[index]
                                          ['user_index'],
                                      'nickname': chattingListData[index]
                                          ['nick'],
                                      'avatar': chattingListData[index]
                                          ['avatar_url'],
                                    });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: ColorsConfig().subBackground1(),
                                  border: Border(
                                    top: index == 0
                                        ? BorderSide(
                                            width: 0.5,
                                            color: ColorsConfig().border1(),
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 52.0,
                                      height: 52.0,
                                      margin:
                                          const EdgeInsets.only(right: 11.0),
                                      decoration: BoxDecoration(
                                        color:
                                            ColorsConfig().userIconBackground(),
                                        borderRadius:
                                            BorderRadius.circular(26.0),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            chattingListData[index]
                                                ['avatar_url'],
                                            scale: 5.0,
                                          ),
                                          filterQuality: FilterQuality.high,
                                          fit: BoxFit.none,
                                          alignment: const Alignment(0.0, -0.5),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          93.0,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CustomTextBuilder(
                                                text:
                                                    '${chattingListData[index]['nick']}',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              const SizedBox(width: 11.0),
                                              CustomTextBuilder(
                                                text: DateCalculatorWrapper()
                                                    .daysCalculator(
                                                        chattingListData[index]
                                                            ['last_send_date']),
                                                fontColor:
                                                    ColorsConfig().textBlack2(),
                                                fontSize: 12.0.sp,
                                                fontWeight: FontWeight.w400,
                                              )
                                            ],
                                          ),
                                          CustomTextBuilder(
                                            text:
                                                '${chattingListData[index]['message']}',
                                            fontColor:
                                                ColorsConfig().textBlack2(),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                            maxLines: 2,
                                            textOverflow: TextOverflow.ellipsis,
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
                            image: AssetImage('assets/img/none_message.png'),
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        CustomTextBuilder(
                          text: TextConstant.noMessageText,
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        )
                      ],
                    ),
                  ),
                )
          : const LoadingProgressScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chatting_create');
        },
        backgroundColor: ColorsConfig().subBackground1(),
        elevation: 6.0,
        tooltip: TextConstant.writingText,
        child: SvgAssets(
          image: 'assets/icon/write.svg',
          color: ColorsConfig().primary(),
          width: 24.0,
          height: 24.0,
        ),
      ),
    );
  }
}
