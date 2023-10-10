import 'package:DRPublic/widget/loading.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/notification/notification_delete_all.dart';
import 'package:DRPublic/api/notification/notification_list.dart';
import 'package:DRPublic/api/notification/notification_read.dart';
import 'package:DRPublic/api/post/get_post_return_data.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/widget/text_widget.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ScrollController scrollController = ScrollController();

  List<dynamic> notificationDatas = [];

  bool isLoading = false;

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    Future.wait([
      GetNotificationListDataAPI()
          .notifications(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          notificationDatas = value.result;
        });
      }),
    ]).then((_) {
      setState(() {
        isLoading = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        leading: DRAppBarLeading(
          press: () {
            Navigator.pop(context);
          },
        ),
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        backgroundColor: ColorsConfig().subBackground1(),
        title: const DRAppBarTitle(
          title: '알림',
        ),
      ),
      body: isLoading
          ? Container(
              color: ColorsConfig().background(),
              child: Column(
                children: [
                  notificationDatas.isNotEmpty
                      ? Container(
                          height: 40.0,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: ColorsConfig().background(),
                            border: Border(
                              top: BorderSide(
                                width: 0.5,
                                color: ColorsConfig().border1(),
                              ),
                            ),
                          ),
                          child: InkWell(
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
                                        color: ColorsConfig().subBackground1(),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8.0),
                                          topRight: Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Center(
                                        child: CustomTextBuilder(
                                          text: '알림내역을 전부 삭제하시겠습니까?',
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
                                            onTap: () => Navigator.pop(context),
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
                                                  fontWeight: FontWeight.w400,
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

                                              NotificationDeleteAllAPI()
                                                  .notificationDeleteAll(
                                                      accesToken:
                                                          _prefs.getString(
                                                              'AccessToken')!)
                                                  .then((value) {
                                                if (value.result['status'] ==
                                                    10605) {
                                                  setState(() {
                                                    notificationDatas = [];
                                                    Navigator.pop(context);
                                                  });
                                                }
                                              });
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
                                                  text: '삭제',
                                                  fontColor:
                                                      ColorsConfig().textRed1(),
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
                            },
                            child: CustomTextBuilder(
                              text: '전체삭제',
                              fontColor: ColorsConfig().textWhite1(),
                              fontSize: 12.0.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      : Container(),
                  Expanded(
                    child: notificationDatas.isNotEmpty
                        ? RefreshIndicator(
                            onRefresh: () async {
                              final _prefs =
                                  await SharedPreferences.getInstance();

                              GetNotificationListDataAPI()
                                  .notifications(
                                      accesToken:
                                          _prefs.getString('AccessToken')!)
                                  .then((value) {
                                setState(() {
                                  notificationDatas = value.result;
                                });
                              });
                            },
                            color: ColorsConfig().textWhite1(),
                            backgroundColor:
                                ColorsConfig().subBackgroundBlack(),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              controller: scrollController,
                              itemCount: notificationDatas.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () async {
                                    final _prefs =
                                        await SharedPreferences.getInstance();

                                    NotificationReadDataPatchAPI()
                                        .readNotification(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            index: notificationDatas[index]
                                                ['alarm_index'])
                                        .then((value) {
                                      if (value.result['status'] == 10600) {
                                        setState(() {
                                          notificationDatas[index]['isread'] =
                                              true;
                                        });

                                        switch (notificationDatas[index]
                                            ['alarm_type']) {
                                          case 0:
                                            Navigator.pushNamed(
                                                context, '/subscribe',
                                                arguments: {
                                                  'tabIndex': 0,
                                                  'user_nickname':
                                                      notificationDatas[index]
                                                          ['nick'],
                                                });
                                            break;
                                          case 1:
                                            break;
                                          case 2:
                                            Navigator.pushNamed(
                                                context, '/note_detail',
                                                arguments: {
                                                  'userIndex':
                                                      notificationDatas[index]
                                                          ['target_index'],
                                                  'nickname':
                                                      notificationDatas[index]
                                                          ['nick'],
                                                  'avatar':
                                                      notificationDatas[index]
                                                          ['target_avatar'],
                                                });
                                            break;
                                          case 3:
                                            GetPostTypeAPI()
                                                .postType(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    postIndex:
                                                        notificationDatas[index]
                                                            ['post_index'])
                                                .then((val) {
                                              if (val.result['type'] == 4) {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            NewsDetailScreen(
                                                                postIndex:
                                                                    notificationDatas[
                                                                            index]
                                                                        [
                                                                        'post_index'])));
                                              } else if (val.result['type'] ==
                                                  5) {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            VoteDetailScreen(
                                                                postIndex:
                                                                    notificationDatas[
                                                                            index]
                                                                        [
                                                                        'post_index'])));
                                              } else {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            PostingDetailScreen(
                                                                postIndex:
                                                                    notificationDatas[
                                                                            index]
                                                                        [
                                                                        'post_index'])));
                                              }
                                            });
                                            break;
                                          case 4:
                                            Navigator.pushNamed(
                                                context, '/my_profile',
                                                arguments: {
                                                  'onNavigator': true,
                                                });
                                            break;
                                          case 5:
                                            Navigator.pushNamed(
                                                context, '/service_center',
                                                arguments: {"tabIndex": 1});
                                            break;
                                          default:
                                        }
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    decoration: BoxDecoration(
                                      color: ColorsConfig().subBackground1(),
                                      border: Border(
                                        top: BorderSide(
                                          width: 0.5,
                                          color: ColorsConfig()
                                              .userIconBackground(),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 45.0,
                                          height: 45.0,
                                          margin: const EdgeInsets.only(
                                              right: 10.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig()
                                                .userIconBackground(),
                                            borderRadius:
                                                BorderRadius.circular(22.5),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                notificationDatas[index]
                                                    ['target_avatar'],
                                                scale: notificationDatas[index][
                                                                'alarm_type'] !=
                                                            4 &&
                                                        notificationDatas[index]
                                                                [
                                                                'alarm_type'] !=
                                                            5
                                                    ? 5.0
                                                    : 1.0,
                                              ),
                                              filterQuality: FilterQuality.high,
                                              fit: notificationDatas[index]
                                                              ['alarm_type'] !=
                                                          4 &&
                                                      notificationDatas[index]
                                                              ['alarm_type'] !=
                                                          5
                                                  ? BoxFit.none
                                                  : BoxFit.contain,
                                              alignment: notificationDatas[
                                                                  index]
                                                              ['alarm_type'] !=
                                                          4 &&
                                                      notificationDatas[index]
                                                              ['alarm_type'] !=
                                                          5
                                                  ? const Alignment(0.0, -0.3)
                                                  : Alignment.center,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              94.0,
                                          height: 52.0,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomTextBuilder(
                                                      text: notificationDatas[
                                                                      index][
                                                                  'alarm_type'] ==
                                                              0
                                                          ? '${notificationDatas[index]['nick']}님이 나를 구독하기 시작했습니다.'
                                                          : notificationDatas[
                                                                          index]
                                                                      [
                                                                      'alarm_type'] ==
                                                                  1
                                                              ? '${notificationDatas[index]['nick']}님이 새 글을 공유했습니다.'
                                                              : notificationDatas[
                                                                              index]
                                                                          [
                                                                          'alarm_type'] ==
                                                                      2
                                                                  ? '${notificationDatas[index]['nick']}님이 보낸 새 메시지가 도착했습니다.'
                                                                  : notificationDatas[index]
                                                                              [
                                                                              'alarm_type'] ==
                                                                          3
                                                                      ? '${notificationDatas[index]['nick']}님이 나에게 댓글을 남겼습니다.'
                                                                      : notificationDatas[index]['alarm_type'] ==
                                                                              4
                                                                          ? '새 뱃지가 도착했습니다'
                                                                          : '문의하신 내용에 대한 답변이 완료되었습니다',
                                                      fontColor:
                                                          !notificationDatas[
                                                                      index]
                                                                  ['isread']
                                                              ? ColorsConfig()
                                                                  .textWhite1()
                                                              : ColorsConfig()
                                                                  .textBlack2(),
                                                      fontSize: 15.0.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      maxLines: 1,
                                                      textOverflow:
                                                          TextOverflow.ellipsis,
                                                      textScaleFactor: 1.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  CustomTextBuilder(
                                                    text: DateCalculatorWrapper()
                                                        .daysCalculator(
                                                            notificationDatas[
                                                                    index]
                                                                ['reg_date']),
                                                    fontColor: ColorsConfig()
                                                        .textBlack2(),
                                                    fontSize: 13.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  )
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
                          )
                        : Container(
                            color: ColorsConfig().background(),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 80.0,
                                    height: 80.0,
                                    child: Image(
                                      image: AssetImage(
                                          'assets/img/none_notification.png'),
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                  const SizedBox(height: 20.0),
                                  CustomTextBuilder(
                                    text: '새로운 알림이 없습니다.',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w400,
                                  )
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 25.0),
                ],
              ),
            )
          : const LoadingProgressScreen(),
    );
  }
}
