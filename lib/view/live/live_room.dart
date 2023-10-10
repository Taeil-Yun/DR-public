import 'dart:convert';
import 'dart:developer';

import 'package:DRPublic/api/live/add_image.dart';
import 'package:DRPublic/component/image_picker/image_picker.dart';
import 'package:DRPublic/widget/deep_link.dart';
import 'package:DRPublic/widget/image_viewer.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wakelock/wakelock.dart';

import 'package:DRPublic/main.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/api/baes_url.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/chatting/chatting_create.dart';
import 'package:DRPublic/api/live/add_notice.dart';
import 'package:DRPublic/api/live/like_add.dart';
import 'package:DRPublic/api/live/like_cancel.dart';
import 'package:DRPublic/api/live/live_item_list.dart';
import 'package:DRPublic/api/live/live_item_send.dart';
import 'package:DRPublic/api/live/live_rank.dart';
import 'package:DRPublic/api/live/live_room_detail.dart';
import 'package:DRPublic/api/live/live_room_participant_list.dart';
import 'package:DRPublic/api/live/live_symbol_search.dart';
import 'package:DRPublic/api/subscribe/add_subscribe.dart';
import 'package:DRPublic/api/subscribe/cancle_subscribe.dart';
import 'package:DRPublic/api/subscribe/my_subscribe.dart';
import 'package:DRPublic/api/subscribe/your_subscribe.dart';
import 'package:DRPublic/api/user/other_user_profile.dart';
import 'package:DRPublic/util/keyboard_focus_view_scroll.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/widget/holding_balance.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class LiveChartWithChattingScreen extends StatefulWidget {
  const LiveChartWithChattingScreen({Key? key}) : super(key: key);

  @override
  State<LiveChartWithChattingScreen> createState() =>
      _LiveChartWithChattingScreenState();
}

class _LiveChartWithChattingScreenState
    extends State<LiveChartWithChattingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late WebViewController _chartWebViewController;
  late WebViewController _infoWebViewController;
  late TabController _tabController;
  late TabController _contentTabController;
  late TextEditingController _chattingEditingController;
  late TextEditingController _noticeEditingController;
  late TextEditingController liveSymbolSearchController;
  late FocusNode _chattingFocusNode;
  late FocusNode _noticeFocusNode;
  late FocusNode liveSymbolSearchFocusNode;
  late ScrollController _chattingScrollController;
  late ScrollController liveSymbolScrollController;

  late dynamic channel;

  var numberFormat = NumberFormat('###,###,###,###');

  bool showAppBarState = false;
  bool inputHasFocus = false;
  bool isNoticeModifyState = false;
  bool userIsHeader = false;
  bool socketPingState = false;

  int roomIndex = 0;
  int userIndex = 0;
  int _currentTabIndex = 0;
  int _currentContentTabIndex = 0;

  String userNickname = '';
  String userAvatar = '';
  String chatId = '';

  Color chattingSendButtonColor = ColorsConfig().textWhite1();
  Color noticeRegistButtonColor = ColorsConfig().textBlack2();

  List<dynamic> participantsList = [];
  List<dynamic> rankList = [];

  Map<String, dynamic> liveRoomDetailData = {};
  Map<String, dynamic> liveWebSocketData = {
    'message': [],
    'stock': {},
    'join': {},
    'left': {},
    'emit': {},
    'notice': {},
  };

  @override
  void initState() {
    Wakelock.enable();

    _chattingEditingController = TextEditingController()
      ..addListener(() {
        if (_chattingEditingController.text.isNotEmpty) {
          setState(
              () => chattingSendButtonColor = ColorsConfig.subscribeBtnPrimary);
        } else {
          setState(() => chattingSendButtonColor = ColorsConfig().textWhite1());
        }
      });
    _chattingFocusNode = FocusNode();

    _noticeEditingController = TextEditingController()
      ..addListener(() {
        if (_noticeEditingController.text.isNotEmpty) {
          setState(
              () => noticeRegistButtonColor = ColorsConfig.subscribeBtnPrimary);
        } else {
          setState(() => noticeRegistButtonColor = ColorsConfig().textBlack2());
        }
      });
    _noticeFocusNode = FocusNode();

    liveSymbolSearchController = TextEditingController();
    liveSymbolSearchFocusNode = FocusNode();

    _tabController = TabController(
      length: 2,
      vsync: this, // vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

    _contentTabController = TabController(
      length: 4,
      vsync: this,
    );
    _contentTabController.addListener(_handleContentTabSelection);

    _chattingScrollController = ScrollController();
    liveSymbolScrollController = ScrollController();

    Future.delayed(Duration.zero, () {
      setState(() {
        channel = IOWebSocketChannel.connect(Uri.parse(
            '${ApiBaseUrlConfig().chatUri}ws/live?room=${RouteGetArguments().getArgs(context)['room_index']}&id=${RouteGetArguments().getArgs(context)['user_index']}&nick=${RouteGetArguments().getArgs(context)['nickname']}&avatar=${RouteGetArguments().getArgs(context)['avatar']}&is_header=${RouteGetArguments().getArgs(context)['is_header']}'));
        roomIndex = RouteGetArguments().getArgs(context)['room_index'];
        userIndex = RouteGetArguments().getArgs(context)['user_index'];
        userNickname = RouteGetArguments().getArgs(context)['nickname'];
        userAvatar = RouteGetArguments().getArgs(context)['avatar'];
        userIsHeader = RouteGetArguments().getArgs(context)['is_header'];
      });
    }).then((_) {
      apiInitialize();
      initializeSocket();
    });

    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    Wakelock.disable();

    _chattingEditingController.dispose();
    _chattingFocusNode.dispose();
    _chattingScrollController.dispose();
    _tabController.dispose();
    _contentTabController.dispose();
    liveSymbolScrollController.dispose();

    WidgetsBinding.instance.removeObserver(this);

    channel.sink.close();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        Wakelock.enable();

        if (channel.closeCode != null) {
          Future.delayed(Duration.zero, () {
            setState(() {
              socketPingState = true;
              channel = IOWebSocketChannel.connect(Uri.parse(
                  '${ApiBaseUrlConfig().chatUri}ws/live?room=${RouteGetArguments().getArgs(context)['room_index']}&id=${RouteGetArguments().getArgs(context)['user_index']}&nick=${RouteGetArguments().getArgs(context)['nickname']}&avatar=${RouteGetArguments().getArgs(context)['avatar']}&is_header=${RouteGetArguments().getArgs(context)['is_header']}'));
            });
          }).then((_) {
            apiInitialize();
            initializeSocket();
          });
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        Wakelock.disable();
        break;
      case AppLifecycleState.detached:
        Wakelock.disable();
        channel.sink.close();
        break;
    }
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetLiveRoomDetailAPI()
        .liveDetail(
            accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex)
        .then((value) {
      setState(() {
        liveRoomDetailData = value.result;

        if (!socketPingState && userIndex != value.result['user_index']) {
          liveWebSocketData['message'].add({
            "type": "first_join",
            "message": {
              "message": true,
            },
          });
        }

        if (socketPingState) {
          liveWebSocketData['message'].add({
            "type": "re_join",
            "message": {
              "message": true,
            },
          });
        }
      });
    });

    GetLiveParticipantListAPI()
        .participants(
            accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex)
        .then((value) {
      setState(() {
        participantsList = value.result;
      });
    });

    GetLiveRankListAPI()
        .rank(
            accesToken: _prefs.getString('AccessToken')!, roomIndex: roomIndex)
        .then((value) {
      setState(() {
        rankList = value.result;
      });
    });
  }

  Future liveGetSymbols({required String search, String? type}) async {
    final _prefs = await SharedPreferences.getInstance();

    return type != null
        ? await GetLiveSymbolSearchListAPI().search(
            accesToken: _prefs.getString('AccessToken')!, q: search, type: type)
        : await GetLiveSymbolSearchListAPI()
            .search(accesToken: _prefs.getString('AccessToken')!, q: search);
  }

  Future<void> initializeSocket() async {
    final _prefs = await SharedPreferences.getInstance();
    channel.stream.listen((event) {
      log(event);
      if (event != 'ping') {
        setState(() {
          if (json.decode(event)['type'] == 'message' ||
              json.decode(event)['type'] == 'gift' ||
              json.decode(event)['type'] == 'image') {
            liveWebSocketData['message'].add(json.decode(event));

            Future.delayed(const Duration(milliseconds: 200), () {
              _chattingScrollController.animateTo(
                  _chattingScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn);
            });

            if (json.decode(event)['type'] == 'gift') {
              GetLiveRankListAPI()
                  .rank(
                      accesToken: _prefs.getString('AccessToken')!,
                      roomIndex: roomIndex)
                  .then((value) {
                setState(() {
                  rankList = value.result;
                });
              });
            }
          } else if (json.decode(event)['type'] == 'join') {
            Future.delayed(const Duration(milliseconds: 100), () {
              setState(() {
                liveRoomDetailData['total'] = json.decode(event)['message']
                        ['user_count'] +
                    json.decode(event)['message']['guest_count'];
              });

              GetLiveParticipantListAPI()
                  .participants(
                      accesToken: _prefs.getString('AccessToken')!,
                      roomIndex: roomIndex)
                  .then((value) {
                setState(() {
                  participantsList = value.result;
                });

                if (json.decode(event)['message']['nickname'] != null &&
                    json.decode(event)['message']['nickname'] != '') {
                  if (userIsHeader) {
                    liveWebSocketData['message'].add({
                      "type": "user_join",
                      "message": {
                        "nickname": json.decode(event)['message']['nickname'],
                      },
                    });
                  }
                } else {
                  setState(() {
                    participantsList.add({
                      'idx': '0',
                      'room_index': roomIndex,
                      'chat_index': json.decode(event)['message']['chat_id'],
                      'nick':
                          '비회원 ${json.decode(event)['message']['guest_count']}명',
                      'avatar':
                          '${ApiBaseUrlConfig().defaultImageUri}avatars/basic_dero.png'
                    });
                  });
                }
              });

              if (userNickname == json.decode(event)['message']['nickname'] &&
                  userIndex.toString() == json.decode(event)['message']['id']) {
                setState(() {
                  chatId = json.decode(event)['message']['chat_id'];
                });
              }
            });
          } else if (json.decode(event)['type'] == 'left') {
            Future.delayed(const Duration(milliseconds: 100), () {
              setState(() {
                liveRoomDetailData['total'] = json.decode(event)['message']
                        ['user_count'] +
                    json.decode(event)['message']['guest_count'];
              });
            });

            GetLiveParticipantListAPI()
                .participants(
                    accesToken: _prefs.getString('AccessToken')!,
                    roomIndex: roomIndex)
                .then((value) {
              setState(() {
                participantsList = value.result;

                if (json.decode(event)['message']['guest_count'] > 0) {
                  participantsList.add({
                    'idx': '0',
                    'room_index': roomIndex,
                    'chat_index': json.decode(event)['message']['chat_id'],
                    'nick':
                        '비회원 ${json.decode(event)['message']['guest_count']}명',
                    'avatar':
                        '${ApiBaseUrlConfig().defaultImageUri}avatars/basic_dero.png'
                  });
                }
              });
            });

            if (json.decode(event)['message']['is_head']) {
              PopUpModal(
                title: '',
                titlePadding: EdgeInsets.zero,
                onTitleWidget: Container(),
                content: '',
                contentPadding: EdgeInsets.zero,
                backgroundColor: ColorsConfig.transparent,
                barrierDismissible: false,
                onContentWidget: WillPopScope(
                  onWillPop: () => Future.value(false),
                  child: Column(
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
                            text: '라이브 톡이 종료되었습니다.',
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
                                channel.sink.close();

                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width - 80.0,
                                height: 43.0,
                                decoration: BoxDecoration(
                                  color: ColorsConfig().subBackground1(),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8.0),
                                    bottomRight: Radius.circular(8.0),
                                  ),
                                ),
                                child: Center(
                                  child: CustomTextBuilder(
                                    text: '확인',
                                    fontColor: ColorsConfig().textWhite1(),
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
                ),
              ).dialog(context);
            }
          } else if (json.decode(event)['type'] == 'stock') {
            liveWebSocketData['stock'] = json.decode(event);

            _chartWebViewController.loadUrl(liveWebSocketData['stock']
                    .isNotEmpty
                ? DRPublicApp.themeNotifier.value == ThemeMode.light
                    ? '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=light'
                    : '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=dark'
                : DRPublicApp.themeNotifier.value == ThemeMode.light
                    ? '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=light'
                    : '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=dark');

            _infoWebViewController.loadUrl(liveWebSocketData['stock'].isNotEmpty
                ? DRPublicApp.themeNotifier.value == ThemeMode.light
                    ? '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=light'
                    : '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=dark'
                : DRPublicApp.themeNotifier.value == ThemeMode.light
                    ? '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=light'
                    : '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=dark');
          } else if (json.decode(event)['type'] == 'emit') {
            for (int i = 0; i < participantsList.length; i++) {
              if (json.decode(event)['message'] ==
                      participantsList[i]['chat_index'] &&
                  userIndex == participantsList[i]['user_index']) {
                PopUpModal(
                  title: '',
                  titlePadding: EdgeInsets.zero,
                  onTitleWidget: Container(),
                  content: '',
                  contentPadding: EdgeInsets.zero,
                  backgroundColor: ColorsConfig.transparent,
                  barrierDismissible: false,
                  onContentWidget: WillPopScope(
                    onWillPop: () => Future.value(false),
                    child: Column(
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
                                  channel.sink.close();

                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width - 80.0,
                                  height: 43.0,
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().subBackground1(),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8.0),
                                      bottomRight: Radius.circular(8.0),
                                    ),
                                  ),
                                  child: Center(
                                    child: CustomTextBuilder(
                                      text: '확인',
                                      fontColor: ColorsConfig().textWhite1(),
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
                  ),
                ).dialog(context);
              } else {}
            }
          } else if (json.decode(event)['type'] == 'notice') {
            liveRoomDetailData['notice'] = json.decode(event)['message'];
            liveWebSocketData['notice'] = json.decode(event);

            liveWebSocketData['message'].add({
              "type": "notice",
              "message": {
                "message": _chattingEditingController.text.trim(),
              },
            });

            if (_currentContentTabIndex == 0) {
              Future.delayed(const Duration(milliseconds: 200), () {
                _chattingScrollController.animateTo(
                    _chattingScrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeIn);
              });
            }
          } else if (json.decode(event)['type'] == 'like') {
            liveRoomDetailData['likecount'] = json.decode(event)['message'];
          }
        });
      }
    });
  }

  Future<void> _handleTabSelection() async {
    if (_tabController.indexIsChanging ||
        _tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  Future<void> _handleContentTabSelection() async {
    if (_contentTabController.indexIsChanging ||
        _contentTabController.index != _currentContentTabIndex) {
      setState(() {
        _currentContentTabIndex = _contentTabController.index;

        if (_currentContentTabIndex == 0) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _chattingScrollController.animateTo(
                _chattingScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _chattingFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: ColorsConfig().background(),
        appBar: !_chattingFocusNode.hasFocus && !isNoticeModifyState
            ? DRAppBar(
                systemUiOverlayStyle:
                    Theme.of(context).appBarTheme.systemOverlayStyle,
                leading: !userIsHeader
                    ? DRAppBarLeading(
                        press: () => Navigator.pop(context),
                      )
                    : null,
                title: const DRAppBarTitle(
                  title: '라이브',
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          backgroundColor: ColorsConfig().subBackground1(),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                            ),
                          ),
                          builder: (BuildContext _context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 50.0,
                                    height: 4.0,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: ColorsConfig().border1(),
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                    ),
                                  ),
                                  // 방장 닉네임
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.fromLTRB(
                                        30.0, 21.0, 30.0, 15.0),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 0.5,
                                          color: ColorsConfig().border1(),
                                        ),
                                      ),
                                    ),
                                    child: CustomTextBuilder(
                                      text: userIsHeader
                                          ? '더보기'
                                          : '${liveRoomDetailData['nick']}',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  // 공유하기 버튼
                                  InkWell(
                                    onTap: () async {
                                      Navigator.pop(_context);

                                      var shortLink = await DeepLinkBuilder()
                                          .getShortLinkForLiveRoom(
                                              roomId:
                                                  liveRoomDetailData['idx']);

                                      Share.share(
                                        '${liveRoomDetailData['title']}\n$shortLink',
                                        sharePositionOrigin: Rect.fromLTWH(
                                            0,
                                            0,
                                            MediaQuery.of(context).size.width,
                                            MediaQuery.of(context).size.height /
                                                2),
                                      );
                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0, vertical: 15.0),
                                      child: CustomTextBuilder(
                                        text: '공유하기',
                                        fontSize: 16.0.sp,
                                        fontColor: ColorsConfig().textWhite1(),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  // 신고하기 버튼
                                  !userIsHeader
                                      ? InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(
                                                context, '/report',
                                                arguments: {
                                                  'type': 4,
                                                  'targetIndex': roomIndex,
                                                });
                                          },
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30.0,
                                                vertical: 15.0),
                                            child: CustomTextBuilder(
                                              text: '신고하기',
                                              fontSize: 16.0,
                                              fontColor:
                                                  ColorsConfig().textRed2(),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        )
                                      : Container(),
                                  // 방 나가기
                                  userIsHeader
                                      ? InkWell(
                                          onTap: () {
                                            channel.sink.close();

                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MainScreenBuilder()),
                                                (route) => false);
                                          },
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30.0,
                                                vertical: 15.0),
                                            child: CustomTextBuilder(
                                              text: '라이브종료',
                                              fontSize: 16.0,
                                              fontColor:
                                                  ColorsConfig().textRed2(),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            );
                          });
                    },
                    icon: SvgAssets(
                      image: 'assets/icon/more_horizontal.svg',
                      color: ColorsConfig().textWhite1(),
                      width: 18.0,
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(37.0),
                  child: Container(
                    height: 37.0,
                    padding: const EdgeInsets.only(left: 20.0, right: 10.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1.0,
                          color: ColorsConfig().border1(),
                        ),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.45,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            padding: EdgeInsets.zero,
                            indicatorColor: ColorsConfig().primary(),
                            unselectedLabelColor: ColorsConfig().textWhite1(),
                            unselectedLabelStyle: TextStyle(
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            labelColor: ColorsConfig().primary(),
                            labelStyle: TextStyle(
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: [
                              Tab(
                                child: CustomTextBuilder(
                                  text: '차트',
                                ),
                              ),
                              Tab(
                                child: CustomTextBuilder(
                                  text: '정보',
                                ),
                              ),
                            ],
                          ),
                        ),
                        userIsHeader
                            ? SizedBox(
                                width: (MediaQuery.of(context).size.width -
                                        (MediaQuery.of(context).size.width /
                                            1.45)) -
                                    30.0,
                                child: TextButton(
                                  onPressed: () {
                                    List<dynamic> _datas = [];

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
                                          return StatefulBuilder(
                                            builder: (context, state) {
                                              return Container(
                                                height: (MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    1.2),
                                                decoration: const BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(12.0),
                                                    topRight:
                                                        Radius.circular(12.0),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 50.0,
                                                      height: 4.0,
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8.0),
                                                      decoration: BoxDecoration(
                                                        color: ColorsConfig()
                                                            .textBlack2(),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    100.0),
                                                      ),
                                                    ),
                                                    // search
                                                    Container(
                                                      height: 36.0,
                                                      margin: const EdgeInsets
                                                          .fromLTRB(15.0, 15.0,
                                                          15.0, 20.0),
                                                      child: TextFormField(
                                                        controller:
                                                            liveSymbolSearchController,
                                                        focusNode:
                                                            liveSymbolSearchFocusNode,
                                                        keyboardType:
                                                            TextInputType.text,
                                                        onFieldSubmitted:
                                                            (_str) {
                                                          liveGetSymbols(
                                                                  search: _str)
                                                              .then((value) {
                                                            // 검색시 스크롤 최상단으로 돌려줌
                                                            liveSymbolScrollController
                                                                .jumpTo(0.0);
                                                            // 검색어 초기화
                                                            state(() {
                                                              // 검색 데이터 초기화
                                                              _datas.clear();
                                                              // 검색 리스트를 담아줌
                                                              _datas =
                                                                  value.result;
                                                            });
                                                          });
                                                          liveSymbolSearchController
                                                              .clear();
                                                        },
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      9.0),
                                                          filled: true,
                                                          fillColor: ColorsConfig()
                                                              .avatarPartsBackground(),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide.none,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                          ),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide.none,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide.none,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                          ),
                                                          hintText: '종목검색',
                                                          hintStyle: TextStyle(
                                                            color: ColorsConfig()
                                                                .textBlack2(),
                                                            fontSize: 16.0.sp,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                          prefixIcon: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            15.0),
                                                                child:
                                                                    SvgAssets(
                                                                  image:
                                                                      'assets/icon/search.svg',
                                                                  color: ColorsConfig()
                                                                      .textBlack2(),
                                                                  width: 17.0,
                                                                  height: 17.0,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        style: TextStyle(
                                                          color: ColorsConfig()
                                                              .textWhite1(),
                                                          fontSize: 16.0.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                    // search list
                                                    Expanded(
                                                      child: ListView.builder(
                                                        controller:
                                                            liveSymbolScrollController,
                                                        itemCount:
                                                            _datas.length,
                                                        itemBuilder: (context,
                                                            searchIndex) {
                                                          return InkWell(
                                                            onTap: () {
                                                              channel.sink.add(
                                                                  json.encode({
                                                                "type": "stock",
                                                                "message": {
                                                                  "room":
                                                                      roomIndex,
                                                                  "message":
                                                                      "${_datas[searchIndex]['exchange']}:${_datas[searchIndex]['symbol']}/${_datas[searchIndex]['title']}",
                                                                },
                                                              }));
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          25.0,
                                                                      vertical:
                                                                          10.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                    width: 0.25,
                                                                    color: ColorsConfig()
                                                                        .border1(),
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      CustomTextBuilder(
                                                                        text:
                                                                            '${_datas[searchIndex]['title']}',
                                                                        fontColor:
                                                                            ColorsConfig().textWhite1(),
                                                                        fontSize:
                                                                            16.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                      CustomTextBuilder(
                                                                        text:
                                                                            '${_datas[searchIndex]['exchange']}:${_datas[searchIndex]['symbol']}',
                                                                        fontColor:
                                                                            ColorsConfig().textBlack2(),
                                                                        fontSize:
                                                                            14.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  CustomTextBuilder(
                                                                    text: _datas[searchIndex]['exchange'] ==
                                                                            'KRX'
                                                                        ? '국내주식'
                                                                        : '암호화폐',
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textBlack2(),
                                                                    fontSize:
                                                                        14.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
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
                                              );
                                            },
                                          );
                                        });
                                  },
                                  child: Row(
                                    children: [
                                      SvgAssets(
                                        image: 'assets/icon/search.svg',
                                        color: ColorsConfig().textWhite1(),
                                        width: 16.0,
                                        height: 16.0,
                                      ),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(left: 5.0),
                                        child: CustomTextBuilder(
                                          text: '종목변경',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w400,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          bottom: _chattingFocusNode.hasFocus ? true : false,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: ColorsConfig().subBackground1(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chattingFocusNode.hasFocus
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          padding: EdgeInsets.zero,
                          indicatorColor: ColorsConfig().primary(),
                          unselectedLabelColor: ColorsConfig().textWhite1(),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 16.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          labelColor: ColorsConfig().primary(),
                          labelStyle: TextStyle(
                            fontSize: 16.0.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          tabs: [
                            Tab(
                              child: CustomTextBuilder(
                                text: '차트',
                              ),
                            ),
                            Tab(
                              child: CustomTextBuilder(
                                text: '정보',
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(),
                // 차트 및 정보
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 214.0,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 차트
                      WebView(
                        initialUrl: liveWebSocketData['stock'].isNotEmpty
                            ? DRPublicApp.themeNotifier.value == ThemeMode.light
                                ? '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=light'
                                : '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=dark'
                            : DRPublicApp.themeNotifier.value == ThemeMode.light
                                ? '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=light'
                                : '${ApiBaseUrlConfig().webViewUri}webview/advanced?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=dark',
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated: (_controller) {
                          setState(() {
                            _chartWebViewController = _controller;
                          });
                        },
                      ),
                      // 정보
                      WebView(
                        initialUrl: liveWebSocketData['stock'].isNotEmpty
                            ? DRPublicApp.themeNotifier.value == ThemeMode.light
                                ? '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=light'
                                : '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=${liveWebSocketData['stock']['message']['message'].toString().split(':')[0]}&symbol=${liveWebSocketData['stock']['message']['message'].toString().split(':')[1].split('/')[0]}&name=${Uri.encodeComponent(liveWebSocketData['stock']['message']['message'].toString().split('/')[1])}&theme=dark'
                            : DRPublicApp.themeNotifier.value == ThemeMode.light
                                ? '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=light'
                                : '${ApiBaseUrlConfig().webViewUri}webview/info?exchange=KRX&symbol=005930&name=${Uri.encodeComponent('삼성전자')}&theme=dark',
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated: (_controller) {
                          setState(() {
                            _infoWebViewController = _controller;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // 간략한 방 정보
                !_chattingFocusNode.hasFocus && !isNoticeModifyState
                    ? Container(
                        width: MediaQuery.of(context).size.width,
                        height: 75.0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 10.0),
                        color: ColorsConfig().subBackground1(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 방 제목
                            InkWell(
                              onTap: () {
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
                                      return StatefulBuilder(
                                        builder: (context, state) {
                                          return Container(
                                            height: (MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2) +
                                                65.0,
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(12.0),
                                                topRight: Radius.circular(12.0),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 50.0,
                                                  height: 4.0,
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  decoration: BoxDecoration(
                                                    color: ColorsConfig()
                                                        .textBlack2(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100.0),
                                                  ),
                                                ),
                                                // 정보 타이틀
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        width: 0.25,
                                                        color: ColorsConfig()
                                                            .border1(),
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    15.0,
                                                                vertical: 10.0),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child:
                                                            CustomTextBuilder(
                                                          text: '정보',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textWhite1(),
                                                          fontSize: 20.0.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        icon: SvgAssets(
                                                          image:
                                                              'assets/icon/close_btn.svg',
                                                          color: ColorsConfig()
                                                              .textWhite1(),
                                                          width: 14.0,
                                                          height: 14.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // 라이브 방 타이틀, 방장 아바타, 닉네임, 구독자 수, {구독 버튼: only user}
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  15.0,
                                                                  15.0,
                                                                  0.0,
                                                                  10.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border(
                                                              bottom:
                                                                  BorderSide(
                                                                width: 0.25,
                                                                color: ColorsConfig()
                                                                    .border1(),
                                                              ),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              // 라이브 방 타이틀
                                                              Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            5.0),
                                                                child:
                                                                    CustomTextBuilder(
                                                                  text:
                                                                      '${liveRoomDetailData['title']}',
                                                                  fontColor:
                                                                      ColorsConfig()
                                                                          .textWhite1(),
                                                                  fontSize:
                                                                      18.0.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                              // 방장 아바타, 닉네임, 구독자 수 {구독 버튼: only user}
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  // 방장 아바타, 닉네임, 구독자 수
                                                                  Row(
                                                                    children: [
                                                                      // 방장 아바타
                                                                      Container(
                                                                        width:
                                                                            18.0,
                                                                        height:
                                                                            18.0,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              ColorsConfig().userIconBackground(),
                                                                          borderRadius:
                                                                              BorderRadius.circular(9.0),
                                                                          image:
                                                                              DecorationImage(
                                                                            image:
                                                                                NetworkImage(
                                                                              liveRoomDetailData['avatar'],
                                                                              scale: 12.5,
                                                                            ),
                                                                            fit:
                                                                                BoxFit.none,
                                                                            alignment:
                                                                                const Alignment(0.0, -0.3),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      // 닉네임
                                                                      Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                5.0),
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text:
                                                                              '${liveRoomDetailData['nick']}ㆍ',
                                                                          fontColor:
                                                                              ColorsConfig().textWhite1(),
                                                                          fontSize:
                                                                              14.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                        ),
                                                                      ),
                                                                      // 구독자 수
                                                                      CustomTextBuilder(
                                                                        text:
                                                                            '구독자 ${NumberFormat().format(liveRoomDetailData['subscribe_count'])}명',
                                                                        fontColor:
                                                                            ColorsConfig().textBlack2(),
                                                                        fontSize:
                                                                            14.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  // {구독 버튼: only user}
                                                                  !userIsHeader
                                                                      ? TextButton(
                                                                          onPressed:
                                                                              () async {
                                                                            final _prefs =
                                                                                await SharedPreferences.getInstance();

                                                                            if (liveRoomDetailData['isFollow']) {
                                                                              CancleSubScribeDataAPI().cancleSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: liveRoomDetailData['user_index']).then((value) {
                                                                                if (value.result['status'] == 10405) {
                                                                                  state(() {
                                                                                    liveRoomDetailData['isFollow'] = false;
                                                                                  });
                                                                                }
                                                                              });
                                                                            } else {
                                                                              AddSubScribeDataAPI().addSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: liveRoomDetailData['user_index']).then((value) {
                                                                                if (value.result['status'] == 10400) {
                                                                                  state(() {
                                                                                    liveRoomDetailData['isFollow'] = true;
                                                                                  });
                                                                                }
                                                                              });
                                                                            }
                                                                          },
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text: !liveRoomDetailData['isFollow']
                                                                                ? '구독'
                                                                                : '구독중',
                                                                            fontColor: !liveRoomDetailData['isFollow']
                                                                                ? ColorsConfig.subscribeBtnPrimary
                                                                                : ColorsConfig().textBlack2(),
                                                                            fontSize:
                                                                                14.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                          ),
                                                                          style:
                                                                              TextButton.styleFrom(
                                                                            tapTargetSize:
                                                                                MaterialTapTargetSize.shrinkWrap,
                                                                          ),
                                                                        )
                                                                      : Container(),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        // 방 설명
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(15.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text:
                                                                '${liveRoomDetailData['description']}',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 14.0.sp,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        50.0,
                                    child: CustomTextBuilder(
                                      text: liveRoomDetailData.isNotEmpty
                                          ? '${liveRoomDetailData['title']}'
                                          : '',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w400,
                                      maxLines: 1,
                                      textOverflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 8.0),
                                      alignment: Alignment.centerRight,
                                      child: SvgAssets(
                                        image: 'assets/icon/arrow_down.svg',
                                        color: ColorsConfig().textWhite1(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 방장 아바타, 닉네임, 시청자 수
                                Row(
                                  children: [
                                    // 방장 아바타
                                    Container(
                                      width: 18.0,
                                      height: 18.0,
                                      decoration: BoxDecoration(
                                        color:
                                            ColorsConfig().userIconBackground(),
                                        borderRadius:
                                            BorderRadius.circular(9.0),
                                        image: liveRoomDetailData.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  liveRoomDetailData['avatar'],
                                                  scale: 11.5,
                                                ),
                                                fit: BoxFit.none,
                                                alignment:
                                                    const Alignment(0.0, -0.3),
                                              )
                                            : null,
                                      ),
                                    ),
                                    // 방장 닉네임
                                    liveRoomDetailData.isNotEmpty
                                        ? Container(
                                            margin: const EdgeInsets.only(
                                                left: 4.0),
                                            child: CustomTextBuilder(
                                              text:
                                                  '${liveRoomDetailData['nick']}ㆍ',
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          )
                                        : Container(),
                                    // 시청자 수
                                    liveRoomDetailData.isNotEmpty
                                        ? CustomTextBuilder(
                                            text: NumberFormat().format(
                                                    liveRoomDetailData[
                                                        'total']) +
                                                '명 참여중',
                                            fontColor: ColorsConfig.defaultGray,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                          )
                                        : Container(),
                                  ],
                                ),
                                // 좋아요 버튼
                                InkWell(
                                  onTap: !userIsHeader &&
                                          liveRoomDetailData.isNotEmpty
                                      ? () async {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          if (!liveRoomDetailData['isLike']) {
                                            AddLiveLikeSendAPI()
                                                .addLiveLike(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    roomIndex:
                                                        liveRoomDetailData[
                                                            'idx'])
                                                .then((value) {
                                              if (value.result['status'] ==
                                                  10800) {
                                                setState(() {
                                                  liveRoomDetailData['isLike'] =
                                                      true;
                                                  channel.sink.add(json.encode({
                                                    "type": "like",
                                                    "message":
                                                        liveRoomDetailData[
                                                                'likecount'] +
                                                            1,
                                                  }));
                                                });
                                              }
                                            });
                                          } else {
                                            CancelLiveLikeSendAPI()
                                                .cancelLiveLike(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    roomIndex:
                                                        liveRoomDetailData[
                                                            'idx'])
                                                .then((value) {
                                              if (value.result['status'] ==
                                                  10805) {
                                                setState(() {
                                                  liveRoomDetailData['isLike'] =
                                                      false;
                                                  channel.sink.add(json.encode({
                                                    "type": "like",
                                                    "message":
                                                        liveRoomDetailData[
                                                                'likecount'] -
                                                            1,
                                                  }));
                                                });
                                              }
                                            });
                                          }
                                        }
                                      : null,
                                  child: Row(
                                    children: [
                                      SvgAssets(
                                        image: !userIsHeader &&
                                                liveRoomDetailData.isNotEmpty &&
                                                !liveRoomDetailData['isLike']
                                            ? 'assets/icon/live_like.svg'
                                            : 'assets/icon/live_like_click.svg',
                                        color: !userIsHeader &&
                                                liveRoomDetailData.isNotEmpty &&
                                                !liveRoomDetailData['isLike']
                                            ? ColorsConfig.defaultGray
                                            : ColorsConfig.subscribeBtnPrimary,
                                        width: 15.0,
                                        height: 15.0,
                                      ),
                                      const SizedBox(width: 5.0),
                                      CustomTextBuilder(
                                        text: !userIsHeader &&
                                                liveRoomDetailData.isNotEmpty &&
                                                !liveRoomDetailData['isLike']
                                            ? '추천'
                                            : '${liveRoomDetailData['likecount']}',
                                        fontColor: ColorsConfig().textWhite1(),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Container(),
                // 채팅, 공지, 라이브 참여자, 랭킹등
                Expanded(
                  child: Row(
                    children: [
                      // 사이드 탭바
                      !_chattingFocusNode.hasFocus && !isNoticeModifyState
                          ? Container(
                              width: 52.0,
                              height: MediaQuery.of(context).size.height,
                              color: ColorsConfig().subBackground1(),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: TabBar(
                                  controller: _contentTabController,
                                  isScrollable: true,
                                  padding: EdgeInsets.zero,
                                  labelPadding: EdgeInsets.zero,
                                  indicator: BoxDecoration(
                                    color: ColorsConfig().background(),
                                    border: const Border(
                                      bottom: BorderSide(
                                        width: 3.0,
                                        color: ColorsConfig.subscribeBtnPrimary,
                                      ),
                                    ),
                                  ),
                                  tabs: [
                                    RotatedBox(
                                      quarterTurns: -1,
                                      child: Tab(
                                        height: 52.0,
                                        child: SvgAssets(
                                          image: 'assets/icon/chat.svg',
                                          color: _currentContentTabIndex == 0
                                              ? ColorsConfig().textWhite1()
                                              : ColorsConfig.defaultGray,
                                        ),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: -1,
                                      child: Tab(
                                        height: 52.0,
                                        child: SvgAssets(
                                          image: 'assets/icon/notice.svg',
                                          color: _currentContentTabIndex == 1
                                              ? ColorsConfig().textWhite1()
                                              : ColorsConfig.defaultGray,
                                        ),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: -1,
                                      child: Tab(
                                        height: 52.0,
                                        child: SvgAssets(
                                          image: 'assets/icon/group.svg',
                                          color: _currentContentTabIndex == 2
                                              ? ColorsConfig().textWhite1()
                                              : ColorsConfig.defaultGray,
                                        ),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: -1,
                                      child: Tab(
                                        height: 52.0,
                                        child: SvgAssets(
                                          image: 'assets/icon/rank.svg',
                                          color: _currentContentTabIndex == 3
                                              ? ColorsConfig().textWhite1()
                                              : ColorsConfig.defaultGray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                      // 탭바별 콘텐츠영역
                      Expanded(
                        child: Container(
                          color: ColorsConfig().background(),
                          child: TabBarView(
                            controller: _contentTabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // 채팅
                              SafeArea(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            10.0, 10.0, 10.0, 0.0),
                                        child: ListView.builder(
                                          controller: _chattingScrollController,
                                          itemCount:
                                              liveWebSocketData['message']
                                                  .length,
                                          itemBuilder: (context, index) {
                                            HasKeyboardFocusViewScrolling()
                                                .jumpToScroll(
                                                    focus: inputHasFocus,
                                                    controller:
                                                        _chattingScrollController);

                                            if (liveWebSocketData['message']
                                                    [index]['type'] ==
                                                'user_join') {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 42.0,
                                                        vertical: 10.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .defaultWhiteBlackColors(
                                                          opacity: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          13.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text:
                                                        '${liveWebSocketData['message'][index]['message']['nickname']} 님이 입장하셨습니다.',
                                                    fontColor: ColorsConfig()
                                                        .defaultWhiteBlackColors(),
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }

                                            if (liveWebSocketData['message']
                                                    [index]['type'] ==
                                                'first_join') {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 42.0,
                                                        vertical: 10.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .defaultWhiteBlackColors(
                                                          opacity: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          13.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text:
                                                        'DR-Public 라이브에 입장하였습니다.',
                                                    fontColor: ColorsConfig
                                                        .subscribeBtnPrimary,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }

                                            if (liveWebSocketData['message']
                                                    [index]['type'] ==
                                                're_join') {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 42.0,
                                                        vertical: 10.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .defaultWhiteBlackColors(
                                                          opacity: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          13.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text:
                                                        'DR-Public 라이브에 재입장하였습니다.',
                                                    fontColor: ColorsConfig
                                                        .subscribeBtnPrimary,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }

                                            if (liveWebSocketData['message']
                                                    [index]['type'] ==
                                                'gift') {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 88.0,
                                                margin: const EdgeInsets.only(
                                                    bottom: 10.0),
                                                padding: const EdgeInsets.only(
                                                    right: 10.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig
                                                      .liveItemSendBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          3.0),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // 아바타, 닉네임, D코인
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // 아바타
                                                          Container(
                                                            width: 30.0,
                                                            height: 30.0,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 3.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .userIconBackground(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15.0),
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  liveWebSocketData['message']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'message']
                                                                      [
                                                                      'avatar_url'],
                                                                  scale: 8.0,
                                                                ),
                                                                fit:
                                                                    BoxFit.none,
                                                                alignment:
                                                                    const Alignment(
                                                                        0.0,
                                                                        -0.3),
                                                              ),
                                                            ),
                                                          ),
                                                          // 닉네임, D코인
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              CustomTextBuilder(
                                                                text:
                                                                    '${liveWebSocketData['message'][index]['message']['nickname']}',
                                                                fontColor:
                                                                    ColorsConfig
                                                                        .defaultWhite,
                                                                fontSize: 14.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  SvgAssets(
                                                                    image:
                                                                        'assets/icon/dcoin.svg',
                                                                    width: 14.0,
                                                                    height:
                                                                        14.0,
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          2.0),
                                                                  CustomTextBuilder(
                                                                    text:
                                                                        '${liveWebSocketData['message'][index]['message']['price']}',
                                                                    fontColor:
                                                                        ColorsConfig
                                                                            .defaultWhite,
                                                                    fontSize:
                                                                        10.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // 아이템 이미지
                                                    Image(
                                                      image: NetworkImage(
                                                          liveWebSocketData[
                                                                      'message']
                                                                  [index][
                                                              'message']['url']),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            if (liveWebSocketData['message']
                                                    [index]['type'] ==
                                                'notice') {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 42.0,
                                                        vertical: 10.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .defaultWhiteBlackColors(
                                                          opacity: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          13.0),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text: '새로운 공지사항이 등록되었습니다.',
                                                    fontColor: ColorsConfig
                                                        .subscribeBtnPrimary,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }

                                            if (liveWebSocketData['message']
                                                    [index]['type'] ==
                                                'image') {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                      onTap: userNickname !=
                                                              liveWebSocketData[
                                                                              'message']
                                                                          [
                                                                          index]
                                                                      [
                                                                      'message']
                                                                  ['nickname']
                                                          ? () async {
                                                              final _prefs =
                                                                  await SharedPreferences
                                                                      .getInstance();

                                                              OtherUserProfileInfoAPI()
                                                                  .userProfile(
                                                                      accesToken:
                                                                          _prefs.getString(
                                                                              'AccessToken')!,
                                                                      userNickname:
                                                                          liveWebSocketData['message'][index]['message']
                                                                              [
                                                                              'nickname'])
                                                                  .then(
                                                                      (value) async {
                                                                var userToMeFollow = await GetMySubScribeListAPI().subscribe(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    nickname: liveWebSocketData['message']
                                                                            [
                                                                            index]['message']
                                                                        [
                                                                        'nickname']);
                                                                var meToUserFollow = await GetYourSubScribeListAPI().subscribe(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    nickname: liveWebSocketData['message']
                                                                            [
                                                                            index]['message']
                                                                        [
                                                                        'nickname']);

                                                                showModalBottomSheet(
                                                                    context:
                                                                        context,
                                                                    backgroundColor:
                                                                        ColorsConfig()
                                                                            .subBackground1(),
                                                                    shape:
                                                                        const RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .only(
                                                                        topLeft:
                                                                            Radius.circular(12.0),
                                                                        topRight:
                                                                            Radius.circular(12.0),
                                                                      ),
                                                                    ),
                                                                    builder:
                                                                        (BuildContext
                                                                            builderContext) {
                                                                      return StatefulBuilder(
                                                                        builder:
                                                                            (stateContext,
                                                                                state) {
                                                                          return Stack(
                                                                            children: [
                                                                              Column(
                                                                                children: [
                                                                                  // 커버이미지
                                                                                  Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    height: 115.0,
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: const BorderRadius.only(
                                                                                        topLeft: Radius.circular(12.0),
                                                                                        topRight: Radius.circular(12.0),
                                                                                      ),
                                                                                      image: value.result['app_background'] != false
                                                                                          ? DecorationImage(
                                                                                              image: NetworkImage(value.result['app_background']),
                                                                                              fit: BoxFit.cover,
                                                                                              filterQuality: FilterQuality.high,
                                                                                            )
                                                                                          : const DecorationImage(
                                                                                              image: AssetImage('assets/img/cover_background.png'),
                                                                                              fit: BoxFit.cover,
                                                                                              filterQuality: FilterQuality.high,
                                                                                            ),
                                                                                    ),
                                                                                  ),
                                                                                  // 정보
                                                                                  Expanded(
                                                                                    child: Container(
                                                                                      width: MediaQuery.of(context).size.width,
                                                                                      padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 30.0),
                                                                                      child: Column(
                                                                                        children: [
                                                                                          // 상대 프로필 페이지 이동 버튼
                                                                                          InkWell(
                                                                                            onTap: () {
                                                                                              Navigator.pushNamed(context, '/your_profile', arguments: {
                                                                                                'user_index': value.result['idx'],
                                                                                                'user_nickname': value.result['nick'],
                                                                                              });
                                                                                            },
                                                                                            child: Container(
                                                                                              alignment: Alignment.centerRight,
                                                                                              child: SvgAssets(
                                                                                                image: 'assets/icon/home.svg',
                                                                                                color: ColorsConfig().textWhite1(),
                                                                                                width: 22.0,
                                                                                                height: 22.0,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          // 닉네임
                                                                                          Container(
                                                                                            margin: const EdgeInsets.only(top: 38.0),
                                                                                            child: CustomTextBuilder(
                                                                                              text: '${value.result['nick']}',
                                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                                              fontSize: 20.0,
                                                                                              fontWeight: FontWeight.w700,
                                                                                            ),
                                                                                          ),
                                                                                          // 구독자 수, 구독중 수
                                                                                          Container(
                                                                                            margin: const EdgeInsets.only(top: 5.0),
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                              children: [
                                                                                                // 구독자 수
                                                                                                Row(
                                                                                                  children: [
                                                                                                    CustomTextBuilder(
                                                                                                      text: '구독자',
                                                                                                      fontColor: ColorsConfig().textWhite1(),
                                                                                                      fontSize: 14.0,
                                                                                                      fontWeight: FontWeight.w400,
                                                                                                    ),
                                                                                                    const SizedBox(width: 10.0),
                                                                                                    CustomTextBuilder(
                                                                                                      text: numberFormat.format(userToMeFollow.result.length),
                                                                                                      fontColor: ColorsConfig().textWhite1(),
                                                                                                      fontSize: 14.0,
                                                                                                      fontWeight: FontWeight.w400,
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                                const SizedBox(width: 20.0),
                                                                                                // 구독중 수
                                                                                                Row(
                                                                                                  children: [
                                                                                                    CustomTextBuilder(
                                                                                                      text: '구독중',
                                                                                                      fontColor: ColorsConfig().textWhite1(),
                                                                                                      fontSize: 14.0,
                                                                                                      fontWeight: FontWeight.w400,
                                                                                                    ),
                                                                                                    const SizedBox(width: 10.0),
                                                                                                    CustomTextBuilder(
                                                                                                      text: numberFormat.format(meToUserFollow.result.length),
                                                                                                      fontColor: ColorsConfig().textWhite1(),
                                                                                                      fontSize: 14.0,
                                                                                                      fontWeight: FontWeight.w400,
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                          // 상대 자기소개
                                                                                          value.result['description'] != null && value.result['description'].isNotEmpty
                                                                                              ? Container(
                                                                                                  margin: const EdgeInsets.only(top: 10.0),
                                                                                                  child: CustomTextBuilder(
                                                                                                    text: '${value.result['description']}',
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 12.0,
                                                                                                    fontWeight: FontWeight.w400,
                                                                                                  ),
                                                                                                )
                                                                                              : Container(),
                                                                                          // 구독하기 버튼, {메시지 보내기 버튼, 내보내기 버튼}
                                                                                          Container(
                                                                                            margin: const EdgeInsets.only(top: 15.0),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                // 구독하기 버튼
                                                                                                InkWell(
                                                                                                  onTap: () async {
                                                                                                    final _prefs = await SharedPreferences.getInstance();

                                                                                                    if (value.result['isFollow']) {
                                                                                                      CancleSubScribeDataAPI().cancleSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: value.result['idx']).then((res) {
                                                                                                        if (res.result['status'] == 10405) {
                                                                                                          state(() {
                                                                                                            value.result['isFollow'] = false;
                                                                                                            userToMeFollow.result.length--;
                                                                                                          });
                                                                                                        }
                                                                                                      });
                                                                                                    } else {
                                                                                                      AddSubScribeDataAPI().addSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: value.result['idx']).then((res) {
                                                                                                        if (res.result['status'] == 10400) {
                                                                                                          state(() {
                                                                                                            value.result['isFollow'] = true;
                                                                                                            userToMeFollow.result.length++;
                                                                                                          });
                                                                                                        }
                                                                                                      });
                                                                                                    }
                                                                                                  },
                                                                                                  child: Container(
                                                                                                    width: (MediaQuery.of(context).size.width - 45.0) / 2,
                                                                                                    height: 37.0,
                                                                                                    decoration: BoxDecoration(
                                                                                                      color: !value.result['isFollow'] ? ColorsConfig.subscribeBtnPrimary : ColorsConfig().avatarPartsBackground(),
                                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                                    ),
                                                                                                    child: Center(
                                                                                                      child: CustomTextBuilder(
                                                                                                        text: !value.result['isFollow'] ? '구독하기' : '구독취소',
                                                                                                        fontColor: !value.result['isFollow'] ? ColorsConfig.defaultWhite : ColorsConfig().textWhite1(),
                                                                                                        fontSize: 14.0,
                                                                                                        fontWeight: FontWeight.w400,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                const SizedBox(width: 15.0),
                                                                                                // {메시지 보내기 버튼, 내보내기 버튼}
                                                                                                InkWell(
                                                                                                  onTap: () async {
                                                                                                    final _prefs = await SharedPreferences.getInstance();

                                                                                                    if (!userIsHeader) {
                                                                                                      ChattingCreateAPI().create(accesToken: _prefs.getString('AccessToken')!, userIndex: value.result['idx']).then((_) {
                                                                                                        Navigator.pushNamed(context, '/note_detail', arguments: {
                                                                                                          'userIndex': value.result['idx'],
                                                                                                          'nickname': value.result['nick'],
                                                                                                          'avatar': value.result['avatar'],
                                                                                                        });
                                                                                                      });
                                                                                                    } else {
                                                                                                      Navigator.pop(builderContext);

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
                                                                                                                  text: '참여자를 내보내고\n더 이상 참여하지 못하게 합니다.',
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
                                                                                                                    onTap: () => Navigator.pop(context),
                                                                                                                    child: Container(
                                                                                                                      width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                                                                                      height: 43.0,
                                                                                                                      decoration: BoxDecoration(
                                                                                                                        color: ColorsConfig().subBackground1(),
                                                                                                                        borderRadius: const BorderRadius.only(
                                                                                                                          bottomLeft: Radius.circular(8.0),
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      child: Center(
                                                                                                                        child: CustomTextBuilder(
                                                                                                                          text: '취소',
                                                                                                                          fontColor: ColorsConfig().textWhite1(),
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
                                                                                                                    onTap: () {
                                                                                                                      Navigator.pop(context);

                                                                                                                      channel.sink.add(json.encode({
                                                                                                                        "type": "emit",
                                                                                                                        "message": liveWebSocketData['message'][index]['message']['chat_id'],
                                                                                                                      }));
                                                                                                                    },
                                                                                                                    child: Container(
                                                                                                                      width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                                                                                      height: 43.0,
                                                                                                                      decoration: BoxDecoration(
                                                                                                                        color: ColorsConfig().subBackground1(),
                                                                                                                        borderRadius: const BorderRadius.only(
                                                                                                                          bottomRight: Radius.circular(8.0),
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      child: Center(
                                                                                                                        child: CustomTextBuilder(
                                                                                                                          text: '확인',
                                                                                                                          fontColor: ColorsConfig().textWhite1(),
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
                                                                                                  },
                                                                                                  child: Container(
                                                                                                    width: (MediaQuery.of(context).size.width - 45.0) / 2,
                                                                                                    height: 37.0,
                                                                                                    decoration: BoxDecoration(
                                                                                                      color: ColorsConfig().profileSendMessageBackground(),
                                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                                    ),
                                                                                                    child: Center(
                                                                                                      child: CustomTextBuilder(
                                                                                                        text: userIsHeader ? '내보내기' : '메시지 보내기',
                                                                                                        fontColor: userIsHeader ? ColorsConfig().background() : ColorsConfig().avatarPartsWrapBackground(),
                                                                                                        fontSize: 14.0,
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
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 50.0,
                                                                                    height: 4.0,
                                                                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                    decoration: BoxDecoration(
                                                                                      color: ColorsConfig().border1(),
                                                                                      borderRadius: BorderRadius.circular(100.0),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              // 유저 아바타
                                                                              Positioned(
                                                                                left: (MediaQuery.of(context).size.width / 2) - 52.5,
                                                                                top: 70.0,
                                                                                child: Container(
                                                                                  width: 105.0,
                                                                                  height: 105.0,
                                                                                  decoration: BoxDecoration(
                                                                                    color: ColorsConfig().userIconBackground(),
                                                                                    borderRadius: BorderRadius.circular(52.5),
                                                                                    image: DecorationImage(
                                                                                      image: NetworkImage(
                                                                                        value.result['avatar'],
                                                                                        scale: 2.7,
                                                                                      ),
                                                                                      fit: BoxFit.none,
                                                                                      alignment: const Alignment(0.0, -0.7),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        },
                                                                      );
                                                                    });
                                                              });
                                                            }
                                                          : null,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 25.0,
                                                            height: 25.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .userIconBackground(),
                                                              border: liveWebSocketData['message'][index]['message']
                                                                              [
                                                                              'is_head'] !=
                                                                          null &&
                                                                      liveWebSocketData['message']
                                                                              [
                                                                              index]['message']
                                                                          [
                                                                          'is_head']
                                                                  ? Border.all(
                                                                      width:
                                                                          1.0,
                                                                      color: ColorsConfig
                                                                          .subscribeBtnPrimary,
                                                                    )
                                                                  : null,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.5),
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  liveWebSocketData['message']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'message']
                                                                      [
                                                                      'avatar_url'],
                                                                  scale: 10.0,
                                                                ),
                                                                fit:
                                                                    BoxFit.none,
                                                                alignment:
                                                                    const Alignment(
                                                                        0.0,
                                                                        -0.3),
                                                              ),
                                                            ),
                                                          ),
                                                          liveWebSocketData['message'][index]
                                                                              [
                                                                              'message']
                                                                          [
                                                                          'is_head'] !=
                                                                      null &&
                                                                  liveWebSocketData['message']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'message']
                                                                      [
                                                                      'is_head']
                                                              ? Container(
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              3.0),
                                                                  child:
                                                                      SvgAssets(
                                                                    image:
                                                                        'assets/icon/crown.svg',
                                                                    width: 15.0,
                                                                    height:
                                                                        11.0,
                                                                  ),
                                                                )
                                                              : Container(),
                                                          Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 5.0,
                                                                    right:
                                                                        10.0),
                                                            child:
                                                                CustomTextBuilder(
                                                              text:
                                                                  '${liveWebSocketData['message'][index]['message']['nickname']}',
                                                              fontColor:
                                                                  ColorsConfig
                                                                      .defaultGray,
                                                              fontSize: 16.0.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            routeMoveVertical(
                                                                page: ImageViewerSingleBuilder(
                                                                    image: liveWebSocketData['message'][index]
                                                                            [
                                                                            'message']
                                                                        [
                                                                        'message'])));
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 5.0),
                                                        constraints:
                                                            const BoxConstraints(
                                                          maxWidth: 230.0,
                                                          maxHeight: 150.0,
                                                        ),
                                                        child: Image(
                                                          image: NetworkImage(
                                                              liveWebSocketData[
                                                                              'message']
                                                                          [
                                                                          index]
                                                                      [
                                                                      'message']
                                                                  ['message']),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 10.0),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  InkWell(
                                                    onTap: userNickname !=
                                                            liveWebSocketData[
                                                                            'message']
                                                                        [index]
                                                                    ['message']
                                                                ['nickname']
                                                        ? () async {
                                                            final _prefs =
                                                                await SharedPreferences
                                                                    .getInstance();

                                                            OtherUserProfileInfoAPI()
                                                                .userProfile(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    userNickname:
                                                                        liveWebSocketData['message'][index]['message']
                                                                            [
                                                                            'nickname'])
                                                                .then(
                                                                    (value) async {
                                                              var userToMeFollow = await GetMySubScribeListAPI().subscribe(
                                                                  accesToken: _prefs
                                                                      .getString(
                                                                          'AccessToken')!,
                                                                  nickname: liveWebSocketData['message']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'message']
                                                                      [
                                                                      'nickname']);
                                                              var meToUserFollow = await GetYourSubScribeListAPI().subscribe(
                                                                  accesToken: _prefs
                                                                      .getString(
                                                                          'AccessToken')!,
                                                                  nickname: liveWebSocketData['message']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'message']
                                                                      [
                                                                      'nickname']);

                                                              showModalBottomSheet(
                                                                  context:
                                                                      context,
                                                                  backgroundColor:
                                                                      ColorsConfig()
                                                                          .subBackground1(),
                                                                  shape:
                                                                      const RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .only(
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              12.0),
                                                                      topRight:
                                                                          Radius.circular(
                                                                              12.0),
                                                                    ),
                                                                  ),
                                                                  builder:
                                                                      (BuildContext
                                                                          builderContext) {
                                                                    return StatefulBuilder(
                                                                      builder:
                                                                          (stateContext,
                                                                              state) {
                                                                        return Stack(
                                                                          children: [
                                                                            Column(
                                                                              children: [
                                                                                // 커버이미지
                                                                                Container(
                                                                                  width: MediaQuery.of(context).size.width,
                                                                                  height: 115.0,
                                                                                  decoration: BoxDecoration(
                                                                                    borderRadius: const BorderRadius.only(
                                                                                      topLeft: Radius.circular(12.0),
                                                                                      topRight: Radius.circular(12.0),
                                                                                    ),
                                                                                    image: value.result['app_background'] != false
                                                                                        ? DecorationImage(
                                                                                            image: NetworkImage(value.result['app_background']),
                                                                                            fit: BoxFit.cover,
                                                                                            filterQuality: FilterQuality.high,
                                                                                          )
                                                                                        : const DecorationImage(
                                                                                            image: AssetImage('assets/img/cover_background.png'),
                                                                                            fit: BoxFit.cover,
                                                                                            filterQuality: FilterQuality.high,
                                                                                          ),
                                                                                  ),
                                                                                ),
                                                                                // 정보
                                                                                Expanded(
                                                                                  child: Container(
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 30.0),
                                                                                    child: Column(
                                                                                      children: [
                                                                                        // 상대 프로필 페이지 이동 버튼
                                                                                        InkWell(
                                                                                          onTap: () {
                                                                                            Navigator.pushNamed(context, '/your_profile', arguments: {
                                                                                              'user_index': value.result['idx'],
                                                                                              'user_nickname': value.result['nick'],
                                                                                            });
                                                                                          },
                                                                                          child: Container(
                                                                                            alignment: Alignment.centerRight,
                                                                                            child: SvgAssets(
                                                                                              image: 'assets/icon/home.svg',
                                                                                              color: ColorsConfig().textWhite1(),
                                                                                              width: 22.0,
                                                                                              height: 22.0,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        // 닉네임
                                                                                        Container(
                                                                                          margin: const EdgeInsets.only(top: 38.0),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '${value.result['nick']}',
                                                                                            fontColor: ColorsConfig().textWhite1(),
                                                                                            fontSize: 20.0,
                                                                                            fontWeight: FontWeight.w700,
                                                                                          ),
                                                                                        ),
                                                                                        // 구독자 수, 구독중 수
                                                                                        Container(
                                                                                          margin: const EdgeInsets.only(top: 5.0),
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              // 구독자 수
                                                                                              Row(
                                                                                                children: [
                                                                                                  CustomTextBuilder(
                                                                                                    text: '구독자',
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 14.0,
                                                                                                    fontWeight: FontWeight.w400,
                                                                                                  ),
                                                                                                  const SizedBox(width: 10.0),
                                                                                                  CustomTextBuilder(
                                                                                                    text: numberFormat.format(userToMeFollow.result.length),
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 14.0,
                                                                                                    fontWeight: FontWeight.w400,
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                              const SizedBox(width: 20.0),
                                                                                              // 구독중 수
                                                                                              Row(
                                                                                                children: [
                                                                                                  CustomTextBuilder(
                                                                                                    text: '구독중',
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 14.0,
                                                                                                    fontWeight: FontWeight.w400,
                                                                                                  ),
                                                                                                  const SizedBox(width: 10.0),
                                                                                                  CustomTextBuilder(
                                                                                                    text: numberFormat.format(meToUserFollow.result.length),
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 14.0,
                                                                                                    fontWeight: FontWeight.w400,
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                        // 상대 자기소개
                                                                                        value.result['description'] != null && value.result['description'].isNotEmpty
                                                                                            ? Container(
                                                                                                margin: const EdgeInsets.only(top: 10.0),
                                                                                                child: CustomTextBuilder(
                                                                                                  text: '${value.result['description']}',
                                                                                                  fontColor: ColorsConfig().textWhite1(),
                                                                                                  fontSize: 12.0,
                                                                                                  fontWeight: FontWeight.w400,
                                                                                                ),
                                                                                              )
                                                                                            : Container(),
                                                                                        // 구독하기 버튼, {메시지 보내기 버튼, 내보내기 버튼}
                                                                                        Container(
                                                                                          margin: const EdgeInsets.only(top: 15.0),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              // 구독하기 버튼
                                                                                              InkWell(
                                                                                                onTap: () async {
                                                                                                  final _prefs = await SharedPreferences.getInstance();

                                                                                                  if (value.result['isFollow']) {
                                                                                                    CancleSubScribeDataAPI().cancleSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: value.result['idx']).then((res) {
                                                                                                      if (res.result['status'] == 10405) {
                                                                                                        state(() {
                                                                                                          value.result['isFollow'] = false;
                                                                                                          userToMeFollow.result.length--;
                                                                                                        });
                                                                                                      }
                                                                                                    });
                                                                                                  } else {
                                                                                                    AddSubScribeDataAPI().addSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: value.result['idx']).then((res) {
                                                                                                      if (res.result['status'] == 10400) {
                                                                                                        state(() {
                                                                                                          value.result['isFollow'] = true;
                                                                                                          userToMeFollow.result.length++;
                                                                                                        });
                                                                                                      }
                                                                                                    });
                                                                                                  }
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: (MediaQuery.of(context).size.width - 45.0) / 2,
                                                                                                  height: 37.0,
                                                                                                  decoration: BoxDecoration(
                                                                                                    color: !value.result['isFollow'] ? ColorsConfig.subscribeBtnPrimary : ColorsConfig().avatarPartsBackground(),
                                                                                                    borderRadius: BorderRadius.circular(6.0),
                                                                                                  ),
                                                                                                  child: Center(
                                                                                                    child: CustomTextBuilder(
                                                                                                      text: !value.result['isFollow'] ? '구독하기' : '구독취소',
                                                                                                      fontColor: !value.result['isFollow'] ? ColorsConfig.defaultWhite : ColorsConfig().textWhite1(),
                                                                                                      fontSize: 14.0,
                                                                                                      fontWeight: FontWeight.w400,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              const SizedBox(width: 15.0),
                                                                                              // {메시지 보내기 버튼, 내보내기 버튼}
                                                                                              InkWell(
                                                                                                onTap: () async {
                                                                                                  final _prefs = await SharedPreferences.getInstance();

                                                                                                  if (!userIsHeader) {
                                                                                                    ChattingCreateAPI().create(accesToken: _prefs.getString('AccessToken')!, userIndex: value.result['idx']).then((_) {
                                                                                                      Navigator.pushNamed(context, '/note_detail', arguments: {
                                                                                                        'userIndex': value.result['idx'],
                                                                                                        'nickname': value.result['nick'],
                                                                                                        'avatar': value.result['avatar'],
                                                                                                      });
                                                                                                    });
                                                                                                  } else {
                                                                                                    Navigator.pop(builderContext);

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
                                                                                                                text: '참여자를 내보내고\n더 이상 참여하지 못하게 합니다.',
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
                                                                                                                  onTap: () => Navigator.pop(context),
                                                                                                                  child: Container(
                                                                                                                    width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                                                                                    height: 43.0,
                                                                                                                    decoration: BoxDecoration(
                                                                                                                      color: ColorsConfig().subBackground1(),
                                                                                                                      borderRadius: const BorderRadius.only(
                                                                                                                        bottomLeft: Radius.circular(8.0),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                    child: Center(
                                                                                                                      child: CustomTextBuilder(
                                                                                                                        text: '취소',
                                                                                                                        fontColor: ColorsConfig().textWhite1(),
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
                                                                                                                  onTap: () {
                                                                                                                    Navigator.pop(context);

                                                                                                                    channel.sink.add(json.encode({
                                                                                                                      "type": "emit",
                                                                                                                      "message": liveWebSocketData['message'][index]['message']['chat_id'],
                                                                                                                    }));
                                                                                                                  },
                                                                                                                  child: Container(
                                                                                                                    width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                                                                                    height: 43.0,
                                                                                                                    decoration: BoxDecoration(
                                                                                                                      color: ColorsConfig().subBackground1(),
                                                                                                                      borderRadius: const BorderRadius.only(
                                                                                                                        bottomRight: Radius.circular(8.0),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                    child: Center(
                                                                                                                      child: CustomTextBuilder(
                                                                                                                        text: '확인',
                                                                                                                        fontColor: ColorsConfig().textWhite1(),
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
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: (MediaQuery.of(context).size.width - 45.0) / 2,
                                                                                                  height: 37.0,
                                                                                                  decoration: BoxDecoration(
                                                                                                    color: ColorsConfig().profileSendMessageBackground(),
                                                                                                    borderRadius: BorderRadius.circular(6.0),
                                                                                                  ),
                                                                                                  child: Center(
                                                                                                    child: CustomTextBuilder(
                                                                                                      text: userIsHeader ? '내보내기' : '메시지 보내기',
                                                                                                      fontColor: userIsHeader ? ColorsConfig().background() : ColorsConfig().avatarPartsWrapBackground(),
                                                                                                      fontSize: 14.0,
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
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Container(
                                                                                  width: 50.0,
                                                                                  height: 4.0,
                                                                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                  decoration: BoxDecoration(
                                                                                    color: ColorsConfig().border1(),
                                                                                    borderRadius: BorderRadius.circular(100.0),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            // 유저 아바타
                                                                            Positioned(
                                                                              left: (MediaQuery.of(context).size.width / 2) - 52.5,
                                                                              top: 70.0,
                                                                              child: Container(
                                                                                width: 105.0,
                                                                                height: 105.0,
                                                                                decoration: BoxDecoration(
                                                                                  color: ColorsConfig().userIconBackground(),
                                                                                  borderRadius: BorderRadius.circular(52.5),
                                                                                  image: DecorationImage(
                                                                                    image: NetworkImage(
                                                                                      value.result['avatar'],
                                                                                      scale: 2.7,
                                                                                    ),
                                                                                    fit: BoxFit.none,
                                                                                    alignment: const Alignment(0.0, -0.7),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                  });
                                                            });
                                                          }
                                                        : null,
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 25.0,
                                                          height: 25.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ColorsConfig()
                                                                .userIconBackground(),
                                                            border: liveWebSocketData['message']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'message']
                                                                    ['is_head']
                                                                ? Border.all(
                                                                    width: 1.0,
                                                                    color: ColorsConfig
                                                                        .subscribeBtnPrimary,
                                                                  )
                                                                : null,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.5),
                                                            image:
                                                                DecorationImage(
                                                              image:
                                                                  NetworkImage(
                                                                liveWebSocketData['message']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'message']
                                                                    [
                                                                    'avatar_url'],
                                                                scale: 10.0,
                                                              ),
                                                              fit: BoxFit.none,
                                                              alignment:
                                                                  const Alignment(
                                                                      0.0,
                                                                      -0.3),
                                                            ),
                                                          ),
                                                        ),
                                                        liveWebSocketData['message']
                                                                        [index]
                                                                    ['message']
                                                                ['is_head']
                                                            ? Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            3.0),
                                                                child:
                                                                    SvgAssets(
                                                                  image:
                                                                      'assets/icon/crown.svg',
                                                                  width: 15.0,
                                                                  height: 11.0,
                                                                ),
                                                              )
                                                            : Container(),
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 5.0,
                                                                  right: 10.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text:
                                                                '${liveWebSocketData['message'][index]['message']['nickname']}',
                                                            fontColor:
                                                                ColorsConfig
                                                                    .defaultGray,
                                                            fontSize: 16.0.sp,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              top: 5.0),
                                                      child: CustomTextBuilder(
                                                        text:
                                                            '${liveWebSocketData['message'][index]['message']['message']}',
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textWhite1(),
                                                        fontSize: 14.0.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // 입력폼
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            if (!userIsHeader) {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              GetLiveGiftListAPI()
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
                                                            Radius.circular(
                                                                12.0),
                                                        topRight:
                                                            Radius.circular(
                                                                12.0),
                                                      ),
                                                    ),
                                                    builder:
                                                        (BuildContext context) {
                                                      int _giftTabIndex = 0;

                                                      List<dynamic> _diiiiiro =
                                                          [];
                                                      List<dynamic> _rooooomi =
                                                          [];

                                                      Map<String, dynamic>
                                                          _selectedGift = {};

                                                      var _giftTabController =
                                                          TabController(
                                                        length: 2,
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
                                                          i <
                                                              gifts.result
                                                                  .length;
                                                          i++) {
                                                        if (gifts.result[i]
                                                                ['item_type'] ==
                                                            3) {
                                                          _diiiiiro.add(
                                                              gifts.result[i]);
                                                        } else if (gifts
                                                                    .result[i]
                                                                ['item_type'] ==
                                                            4) {
                                                          _rooooomi.add(
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
                                                                    1.5
                                                                : MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height /
                                                                    1.65,
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
                                                                        BorderRadius.circular(
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
                                                                          15.0),
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '선물하기',
                                                                        fontColor:
                                                                            ColorsConfig().textWhite1(),
                                                                        fontSize:
                                                                            22.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
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
                                                                        ColorsConfig
                                                                            .subscribeBtnPrimary,
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
                                                                        ColorsConfig
                                                                            .subscribeBtnPrimary,
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
                                                                              '디로',
                                                                        ),
                                                                      ),
                                                                      Tab(
                                                                        child:
                                                                            CustomTextBuilder(
                                                                          text:
                                                                              '루미',
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      Padding(
                                                                    padding: !_hasClick
                                                                        ? const EdgeInsets
                                                                            .all(
                                                                            15.0)
                                                                        : const EdgeInsets
                                                                            .fromLTRB(
                                                                            15.0,
                                                                            15.0,
                                                                            15.0,
                                                                            0.0),
                                                                    child:
                                                                        TabBarView(
                                                                      controller:
                                                                          _giftTabController,
                                                                      physics:
                                                                          const NeverScrollableScrollPhysics(),
                                                                      children: [
                                                                        GridView
                                                                            .builder(
                                                                          gridDelegate:
                                                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                                            crossAxisCount:
                                                                                3, // 한개의 행에 보여줄 item 개수
                                                                            crossAxisSpacing:
                                                                                15.0,
                                                                            mainAxisSpacing:
                                                                                15.0,
                                                                            childAspectRatio:
                                                                                1 / 1.247,
                                                                          ),
                                                                          itemCount:
                                                                              _diiiiiro.length,
                                                                          itemBuilder:
                                                                              (context, grids) {
                                                                            return InkWell(
                                                                              splashColor: ColorsConfig.transparent,
                                                                              highlightColor: ColorsConfig.transparent,
                                                                              onTap: () {
                                                                                state(() {
                                                                                  if (_hasClick && _selectedGift['index'] == grids) {
                                                                                    _hasClick = false;
                                                                                    _selectedGift = {};
                                                                                  } else {
                                                                                    _hasClick = true;
                                                                                    _selectedGift = {
                                                                                      "index": grids,
                                                                                      "item_index": _diiiiiro[grids]['item_index'],
                                                                                      "item_type": _diiiiiro[grids]['item_type'],
                                                                                      "item_type_name": _diiiiiro[grids]['item_type_name'],
                                                                                      "url": _diiiiiro[grids]['url'],
                                                                                      "description": _diiiiiro[grids]['description'],
                                                                                      "price": _diiiiiro[grids]['price'],
                                                                                    };
                                                                                  }
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: _selectedGift['index'] == grids && _giftTabIndex == 0 ? ColorsConfig().subBackgroundBlack() : null,
                                                                                  borderRadius: BorderRadius.circular(5.0),
                                                                                ),
                                                                                child: Column(
                                                                                  children: [
                                                                                    Image(
                                                                                      image: NetworkImage(
                                                                                        _diiiiiro[grids]['url'],
                                                                                      ),
                                                                                      filterQuality: FilterQuality.high,
                                                                                    ),
                                                                                    Container(
                                                                                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                      child: CustomTextBuilder(
                                                                                        text: '${_diiiiiro[grids]['price']}',
                                                                                        fontColor: ColorsConfig().textWhite1(),
                                                                                        fontSize: 14.0.sp,
                                                                                        fontWeight: FontWeight.w400,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                        GridView
                                                                            .builder(
                                                                          gridDelegate:
                                                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                                            crossAxisCount:
                                                                                3, // 한개의 행에 보여줄 item 개수
                                                                            crossAxisSpacing:
                                                                                15.0,
                                                                            mainAxisSpacing:
                                                                                15.0,
                                                                            childAspectRatio:
                                                                                1 / 1.247,
                                                                          ),
                                                                          itemCount:
                                                                              _rooooomi.length,
                                                                          itemBuilder:
                                                                              (context, grids) {
                                                                            return InkWell(
                                                                              splashColor: ColorsConfig.transparent,
                                                                              highlightColor: ColorsConfig.transparent,
                                                                              onTap: () {
                                                                                state(() {
                                                                                  if (_hasClick && _selectedGift['index'] == grids) {
                                                                                    _hasClick = false;
                                                                                    _selectedGift = {};
                                                                                  } else {
                                                                                    _hasClick = true;
                                                                                    _selectedGift = {
                                                                                      "index": grids,
                                                                                      "item_index": _rooooomi[grids]['item_index'],
                                                                                      "item_type": _rooooomi[grids]['item_type'],
                                                                                      "item_type_name": _rooooomi[grids]['item_type_name'],
                                                                                      "url": _rooooomi[grids]['url'],
                                                                                      "description": _rooooomi[grids]['description'],
                                                                                      "price": _rooooomi[grids]['price'],
                                                                                    };
                                                                                  }
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: _selectedGift['index'] == grids && _giftTabIndex == 1 ? ColorsConfig().subBackgroundBlack() : null,
                                                                                  borderRadius: BorderRadius.circular(5.0),
                                                                                ),
                                                                                child: _rooooomi[grids]['item_type'] == 4
                                                                                    ? Column(
                                                                                        children: [
                                                                                          Image(
                                                                                            image: NetworkImage(
                                                                                              _rooooomi[grids]['url'],
                                                                                            ),
                                                                                            filterQuality: FilterQuality.high,
                                                                                          ),
                                                                                          Container(
                                                                                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                                            child: CustomTextBuilder(
                                                                                              text: '${_rooooomi[grids]['price']}',
                                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                                              fontSize: 14.0.sp,
                                                                                              fontWeight: FontWeight.w400,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      )
                                                                                    : null,
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                _hasClick ==
                                                                        true
                                                                    ? Container(
                                                                        padding: const EdgeInsets
                                                                            .fromLTRB(
                                                                            20.0,
                                                                            10.0,
                                                                            20.0,
                                                                            30.0),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              ColorsConfig().subBackground1(),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: ColorsConfig().textWhite1(opacity: 0.16),
                                                                              blurRadius: 10.0,
                                                                              offset: const Offset(0.0, -2.0),
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
                                                                                  width: 100.0,
                                                                                  height: 100.0,
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
                                                                            const SizedBox(height: 10.0),
                                                                            InkWell(
                                                                              onTap: () {
                                                                                LiveGiftDataSendAPI().giftSend(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], roomIndex: liveRoomDetailData['idx']).then((value) {
                                                                                  switch (value.result['status']) {
                                                                                    case 10200:
                                                                                      channel.sink.add(json.encode({
                                                                                        "type": "gift",
                                                                                        "message": {
                                                                                          "chat_id": chatId,
                                                                                          "nickname": userNickname,
                                                                                          "avatar_url": userAvatar,
                                                                                          "url": _selectedGift['url'],
                                                                                          "price": _selectedGift['price'],
                                                                                        },
                                                                                      }));
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
                                                                                            text: '보유하신 포인트가 부족합니다',
                                                                                            fontColor: ColorsConfig.defaultWhite,
                                                                                            fontSize: 14.0.sp,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      break;
                                                                                  }
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                width: MediaQuery.of(context).size.width,
                                                                                height: 42.0,
                                                                                decoration: BoxDecoration(
                                                                                  color: ColorsConfig.subscribeBtnPrimary,
                                                                                  borderRadius: BorderRadius.circular(100.0),
                                                                                ),
                                                                                child: Center(
                                                                                  child: CustomTextBuilder(
                                                                                    text: '보내기',
                                                                                    fontColor: ColorsConfig.defaultWhite,
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
                                            } else {
                                              ImagePickerSelector()
                                                  .imagePicker()
                                                  .then((pickImage) async {
                                                final SharedPreferences _prefs =
                                                    await SharedPreferences
                                                        .getInstance();

                                                AddImageLiveRoomAPI()
                                                    .addImage(
                                                        accessToken:
                                                            _prefs.getString(
                                                                'AccessToken')!,
                                                        roomIndex: roomIndex,
                                                        image: pickImage)
                                                    .then((getImage) {
                                                  if (getImage
                                                          .result['status'] ==
                                                      14009) {
                                                    channel.sink
                                                        .add(json.encode({
                                                      "type": "image",
                                                      "message": {
                                                        "chat_id": chatId,
                                                        "is_head": userIsHeader,
                                                        "nickname":
                                                            userNickname,
                                                        "avatar_url":
                                                            userAvatar,
                                                        "message": getImage
                                                                .result['data']
                                                            ['image'],
                                                      },
                                                    }));
                                                  } else if (getImage
                                                          .result['status'] ==
                                                      14010) {}
                                                });
                                              });
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 10.0),
                                            child: !userIsHeader
                                                ? const Image(
                                                    image: AssetImage(
                                                        'assets/img/live_gift.png'),
                                                    width: 32.0,
                                                    height: 32.0,
                                                  )
                                                : SvgAssets(
                                                    image:
                                                        'assets/icon/picture.svg',
                                                    color: ColorsConfig()
                                                        .textWhite1(),
                                                  ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              minHeight: 40.0,
                                              maxHeight: 60.0,
                                            ),
                                            child: Focus(
                                              onFocusChange: (value) {
                                                setState(() {
                                                  inputHasFocus = value;
                                                });
                                              },
                                              child: TextFormField(
                                                controller:
                                                    _chattingEditingController,
                                                focusNode: _chattingFocusNode,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.all(
                                                          10.0),
                                                  isCollapsed: true,
                                                  filled: true,
                                                  fillColor: ColorsConfig()
                                                      .subBackground1(),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide.none,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide.none,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide.none,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                  ),
                                                ),
                                                onEditingComplete: () {
                                                  channel.sink.add(json.encode({
                                                    "type": "message",
                                                    "message": {
                                                      "chat_id": chatId,
                                                      "is_head": userIsHeader,
                                                      "nickname": userNickname,
                                                      "avatar_url": userAvatar,
                                                      "message":
                                                          _chattingEditingController
                                                              .text
                                                              .trim(),
                                                    },
                                                  }));

                                                  _chattingEditingController
                                                      .clear();

                                                  _chattingFocusNode
                                                      .requestFocus();
                                                },
                                                style: TextStyle(
                                                  color: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                keyboardType:
                                                    TextInputType.text,
                                              ),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (_chattingEditingController.text
                                                .trim()
                                                .isNotEmpty) {
                                              channel.sink.add(json.encode({
                                                "type": "message",
                                                "message": {
                                                  "chat_id": chatId,
                                                  "is_head": userIsHeader,
                                                  "nickname": userNickname,
                                                  "avatar_url": userAvatar,
                                                  "message":
                                                      _chattingEditingController
                                                          .text
                                                          .trim(),
                                                },
                                              }));

                                              _chattingEditingController
                                                  .clear();
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 10.0),
                                            child: SvgAssets(
                                              image: 'assets/icon/send.svg',
                                              color: chattingSendButtonColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 공지
                              SafeArea(
                                left: false,
                                right: false,
                                top: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15.0),
                                        child: userIsHeader
                                            ? !isNoticeModifyState
                                                ? SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // 공지 텍스트
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 13.0,
                                                                  bottom: 5.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: '[공지]',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textBlack2(),
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                        // 공지내용
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 13.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: liveRoomDetailData[
                                                                            'notice'] !=
                                                                        null &&
                                                                    liveRoomDetailData[
                                                                            'notice']
                                                                        .isNotEmpty
                                                                ? '${liveRoomDetailData['notice']}'
                                                                : '공지사항을 입력하세요.',
                                                            fontColor: liveRoomDetailData[
                                                                            'notice'] !=
                                                                        null &&
                                                                    liveRoomDetailData[
                                                                            'notice']
                                                                        .isNotEmpty
                                                                ? ColorsConfig()
                                                                    .textWhite1()
                                                                : ColorsConfig()
                                                                    .textBlack2(),
                                                            fontSize: 14.0,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // 공지 텍스트
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(
                                                            top: 13.0,
                                                            bottom: 5.0),
                                                        child:
                                                            CustomTextBuilder(
                                                          text: '[공지]',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack2(),
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                      // 공지내용
                                                      Expanded(
                                                        child: TextFormField(
                                                          controller:
                                                              _noticeEditingController,
                                                          focusNode:
                                                              _noticeFocusNode,
                                                          expands: true,
                                                          maxLines: null,
                                                          cursorColor: ColorsConfig
                                                              .subscribeBtnPrimary,
                                                          autofocus: true,
                                                          decoration:
                                                              InputDecoration(
                                                            isCollapsed: true,
                                                            border:
                                                                const OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide
                                                                      .none,
                                                            ),
                                                            enabledBorder:
                                                                const OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide
                                                                      .none,
                                                            ),
                                                            focusedBorder:
                                                                const OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide
                                                                      .none,
                                                            ),
                                                            hintText:
                                                                '공지사항을 입력하세요.',
                                                            hintStyle:
                                                                TextStyle(
                                                              color: ColorsConfig()
                                                                  .textBlack2(),
                                                              fontSize: 14.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                          style: TextStyle(
                                                            color: ColorsConfig()
                                                                .textWhite1(),
                                                            fontSize: 14.0,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                            : liveRoomDetailData['notice'] !=
                                                        null &&
                                                    liveRoomDetailData['notice']
                                                        .isNotEmpty
                                                ? SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // 공지 텍스트
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 13.0,
                                                                  bottom: 5.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: '[공지]',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textBlack2(),
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                        // 공지내용
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 13.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: liveRoomDetailData[
                                                                            'notice'] !=
                                                                        null &&
                                                                    liveRoomDetailData[
                                                                            'notice']
                                                                        .isNotEmpty
                                                                ? '${liveRoomDetailData['notice']}'
                                                                : '공자사항을 입력하세요.',
                                                            fontColor: liveRoomDetailData[
                                                                            'notice'] !=
                                                                        null &&
                                                                    liveRoomDetailData[
                                                                            'notice']
                                                                        .isNotEmpty
                                                                ? ColorsConfig()
                                                                    .textWhite1()
                                                                : ColorsConfig()
                                                                    .textBlack2(),
                                                            fontSize: 14.0,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Center(
                                                    child: CustomTextBuilder(
                                                      text: '등록된 공지사항이 없습니다.',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    userIsHeader
                                        ? !isNoticeModifyState
                                            ? Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      if (!isNoticeModifyState) {
                                                        isNoticeModifyState =
                                                            true;
                                                      } else {
                                                        isNoticeModifyState =
                                                            false;
                                                      }
                                                    });
                                                  },
                                                  style: TextButton.styleFrom(
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: CustomTextBuilder(
                                                    text: '수정',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        isNoticeModifyState =
                                                            false;
                                                      });
                                                    },
                                                    style: TextButton.styleFrom(
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: CustomTextBuilder(
                                                      text: '취소',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        _noticeEditingController
                                                                .text
                                                                .trim()
                                                                .isNotEmpty
                                                            ? () async {
                                                                final _prefs =
                                                                    await SharedPreferences
                                                                        .getInstance();

                                                                AddLiveNoticeAPI()
                                                                    .notice(
                                                                        accesToken:
                                                                            _prefs.getString(
                                                                                'AccessToken')!,
                                                                        notice: _noticeEditingController
                                                                            .text
                                                                            .trim())
                                                                    .then(
                                                                        (value) {
                                                                  if (value.result[
                                                                          'status'] ==
                                                                      14003) {
                                                                    setState(
                                                                        () {
                                                                      liveRoomDetailData[
                                                                              'notice'] =
                                                                          _noticeEditingController
                                                                              .text
                                                                              .trim();
                                                                      isNoticeModifyState =
                                                                          false;
                                                                    });

                                                                    channel.sink
                                                                        .add(json
                                                                            .encode({
                                                                      "type":
                                                                          "notice",
                                                                      "message": _noticeEditingController
                                                                          .text
                                                                          .trim(),
                                                                    }));
                                                                  }
                                                                });
                                                              }
                                                            : null,
                                                    style: TextButton.styleFrom(
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: CustomTextBuilder(
                                                      text: '등록',
                                                      fontColor:
                                                          noticeRegistButtonColor,
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              )
                                        : Container(),
                                  ],
                                ),
                              ),
                              // 참여자
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: participantsList.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: participantsList.length,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap:
                                                participantsList[index]
                                                                ['idx'] !=
                                                            0 &&
                                                        userNickname !=
                                                            participantsList[
                                                                index]['nick']
                                                    ? () async {
                                                        final _prefs =
                                                            await SharedPreferences
                                                                .getInstance();

                                                        OtherUserProfileInfoAPI()
                                                            .userProfile(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                userNickname:
                                                                    participantsList[
                                                                            index]
                                                                        [
                                                                        'nick'])
                                                            .then(
                                                                (value) async {
                                                          var userToMeFollow = await GetMySubScribeListAPI().subscribe(
                                                              accesToken: _prefs
                                                                  .getString(
                                                                      'AccessToken')!,
                                                              nickname:
                                                                  participantsList[
                                                                          index]
                                                                      ['nick']);
                                                          var meToUserFollow = await GetYourSubScribeListAPI().subscribe(
                                                              accesToken: _prefs
                                                                  .getString(
                                                                      'AccessToken')!,
                                                              nickname:
                                                                  participantsList[
                                                                          index]
                                                                      ['nick']);

                                                          showModalBottomSheet(
                                                              context: context,
                                                              backgroundColor:
                                                                  ColorsConfig()
                                                                      .subBackground1(),
                                                              shape:
                                                                  const RoundedRectangleBorder(
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
                                                              builder: (BuildContext
                                                                  builderContext) {
                                                                return StatefulBuilder(
                                                                  builder:
                                                                      (stateContext,
                                                                          state) {
                                                                    return Stack(
                                                                      children: [
                                                                        Column(
                                                                          children: [
                                                                            // 커버이미지
                                                                            Container(
                                                                              width: MediaQuery.of(context).size.width,
                                                                              height: 115.0,
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: const BorderRadius.only(
                                                                                  topLeft: Radius.circular(12.0),
                                                                                  topRight: Radius.circular(12.0),
                                                                                ),
                                                                                image: value.result['app_background'] != false
                                                                                    ? DecorationImage(
                                                                                        image: NetworkImage(value.result['app_background']),
                                                                                        fit: BoxFit.cover,
                                                                                        filterQuality: FilterQuality.high,
                                                                                      )
                                                                                    : const DecorationImage(
                                                                                        image: AssetImage('assets/img/cover_background.png'),
                                                                                        fit: BoxFit.cover,
                                                                                        filterQuality: FilterQuality.high,
                                                                                      ),
                                                                              ),
                                                                            ),
                                                                            // 정보
                                                                            Expanded(
                                                                              child: Container(
                                                                                width: MediaQuery.of(context).size.width,
                                                                                padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 30.0),
                                                                                child: Column(
                                                                                  children: [
                                                                                    // 상대 프로필 페이지 이동 버튼
                                                                                    InkWell(
                                                                                      onTap: () {
                                                                                        Navigator.pushNamed(context, '/your_profile', arguments: {
                                                                                          'user_index': value.result['idx'],
                                                                                          'user_nickname': value.result['nick'],
                                                                                        });
                                                                                      },
                                                                                      child: Container(
                                                                                        alignment: Alignment.centerRight,
                                                                                        child: SvgAssets(
                                                                                          image: 'assets/icon/home.svg',
                                                                                          color: ColorsConfig().textWhite1(),
                                                                                          width: 22.0,
                                                                                          height: 22.0,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    // 닉네임
                                                                                    Container(
                                                                                      margin: const EdgeInsets.only(top: 38.0),
                                                                                      child: CustomTextBuilder(
                                                                                        text: '${value.result['nick']}',
                                                                                        fontColor: ColorsConfig().textWhite1(),
                                                                                        fontSize: 20.0,
                                                                                        fontWeight: FontWeight.w700,
                                                                                      ),
                                                                                    ),
                                                                                    // 구독자 수, 구독중 수
                                                                                    Container(
                                                                                      margin: const EdgeInsets.only(top: 5.0),
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                        children: [
                                                                                          // 구독자 수
                                                                                          Row(
                                                                                            children: [
                                                                                              CustomTextBuilder(
                                                                                                text: '구독자',
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 14.0,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                              const SizedBox(width: 10.0),
                                                                                              CustomTextBuilder(
                                                                                                text: numberFormat.format(userToMeFollow.result.length),
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 14.0,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          const SizedBox(width: 20.0),
                                                                                          // 구독중 수
                                                                                          Row(
                                                                                            children: [
                                                                                              CustomTextBuilder(
                                                                                                text: '구독중',
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 14.0,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                              const SizedBox(width: 10.0),
                                                                                              CustomTextBuilder(
                                                                                                text: numberFormat.format(meToUserFollow.result.length),
                                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                                fontSize: 14.0,
                                                                                                fontWeight: FontWeight.w400,
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                    // 상대 자기소개
                                                                                    value.result['description'] != null && value.result['description'].isNotEmpty
                                                                                        ? Container(
                                                                                            margin: const EdgeInsets.only(top: 10.0),
                                                                                            child: CustomTextBuilder(
                                                                                              text: '${value.result['description']}',
                                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                                              fontSize: 12.0,
                                                                                              fontWeight: FontWeight.w400,
                                                                                            ),
                                                                                          )
                                                                                        : Container(),
                                                                                    // 구독하기 버튼, {메시지 보내기 버튼, 내보내기 버튼}
                                                                                    Container(
                                                                                      margin: const EdgeInsets.only(top: 15.0),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          // 구독하기 버튼
                                                                                          InkWell(
                                                                                            onTap: () async {
                                                                                              final _prefs = await SharedPreferences.getInstance();

                                                                                              if (value.result['isFollow']) {
                                                                                                CancleSubScribeDataAPI().cancleSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: value.result['idx']).then((res) {
                                                                                                  if (res.result['status'] == 10405) {
                                                                                                    state(() {
                                                                                                      value.result['isFollow'] = false;
                                                                                                      userToMeFollow.result.length--;
                                                                                                    });
                                                                                                  }
                                                                                                });
                                                                                              } else {
                                                                                                AddSubScribeDataAPI().addSubscribe(accesToken: _prefs.getString('AccessToken')!, targetIndex: value.result['idx']).then((res) {
                                                                                                  if (res.result['status'] == 10400) {
                                                                                                    state(() {
                                                                                                      value.result['isFollow'] = true;
                                                                                                      userToMeFollow.result.length++;
                                                                                                    });
                                                                                                  }
                                                                                                });
                                                                                              }
                                                                                            },
                                                                                            child: Container(
                                                                                              width: (MediaQuery.of(context).size.width - 45.0) / 2,
                                                                                              height: 37.0,
                                                                                              decoration: BoxDecoration(
                                                                                                color: !value.result['isFollow'] ? ColorsConfig.subscribeBtnPrimary : ColorsConfig().avatarPartsBackground(),
                                                                                                borderRadius: BorderRadius.circular(6.0),
                                                                                              ),
                                                                                              child: Center(
                                                                                                child: CustomTextBuilder(
                                                                                                  text: !value.result['isFollow'] ? '구독하기' : '구독취소',
                                                                                                  fontColor: !value.result['isFollow'] ? ColorsConfig.defaultWhite : ColorsConfig().textWhite1(),
                                                                                                  fontSize: 14.0,
                                                                                                  fontWeight: FontWeight.w400,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(width: 15.0),
                                                                                          // {메시지 보내기 버튼, 내보내기 버튼}
                                                                                          InkWell(
                                                                                            onTap: () async {
                                                                                              final _prefs = await SharedPreferences.getInstance();

                                                                                              if (!userIsHeader) {
                                                                                                ChattingCreateAPI().create(accesToken: _prefs.getString('AccessToken')!, userIndex: value.result['idx']).then((_) {
                                                                                                  Navigator.pushNamed(context, '/note_detail', arguments: {
                                                                                                    'userIndex': value.result['idx'],
                                                                                                    'nickname': value.result['nick'],
                                                                                                    'avatar': value.result['avatar'],
                                                                                                  });
                                                                                                });
                                                                                              } else {
                                                                                                Navigator.pop(builderContext);

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
                                                                                                            text: '참여자를 내보내고\n더 이상 참여하지 못하게 합니다.',
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
                                                                                                              onTap: () => Navigator.pop(context),
                                                                                                              child: Container(
                                                                                                                width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                                                                                height: 43.0,
                                                                                                                decoration: BoxDecoration(
                                                                                                                  color: ColorsConfig().subBackground1(),
                                                                                                                  borderRadius: const BorderRadius.only(
                                                                                                                    bottomLeft: Radius.circular(8.0),
                                                                                                                  ),
                                                                                                                ),
                                                                                                                child: Center(
                                                                                                                  child: CustomTextBuilder(
                                                                                                                    text: '취소',
                                                                                                                    fontColor: ColorsConfig().textWhite1(),
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
                                                                                                              onTap: () {
                                                                                                                Navigator.pop(context);

                                                                                                                channel.sink.add(json.encode({
                                                                                                                  "type": "emit",
                                                                                                                  "message": participantsList[index]['chat_index'],
                                                                                                                }));
                                                                                                              },
                                                                                                              child: Container(
                                                                                                                width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                                                                                height: 43.0,
                                                                                                                decoration: BoxDecoration(
                                                                                                                  color: ColorsConfig().subBackground1(),
                                                                                                                  borderRadius: const BorderRadius.only(
                                                                                                                    bottomRight: Radius.circular(8.0),
                                                                                                                  ),
                                                                                                                ),
                                                                                                                child: Center(
                                                                                                                  child: CustomTextBuilder(
                                                                                                                    text: '확인',
                                                                                                                    fontColor: ColorsConfig().textWhite1(),
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
                                                                                            },
                                                                                            child: Container(
                                                                                              width: (MediaQuery.of(context).size.width - 45.0) / 2,
                                                                                              height: 37.0,
                                                                                              decoration: BoxDecoration(
                                                                                                color: ColorsConfig().profileSendMessageBackground(),
                                                                                                borderRadius: BorderRadius.circular(6.0),
                                                                                              ),
                                                                                              child: Center(
                                                                                                child: CustomTextBuilder(
                                                                                                  text: userIsHeader ? '내보내기' : '메시지 보내기',
                                                                                                  fontColor: userIsHeader ? ColorsConfig().background() : ColorsConfig().avatarPartsWrapBackground(),
                                                                                                  fontSize: 14.0,
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
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Container(
                                                                              width: 50.0,
                                                                              height: 4.0,
                                                                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                              decoration: BoxDecoration(
                                                                                color: ColorsConfig().border1(),
                                                                                borderRadius: BorderRadius.circular(100.0),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        // 유저 아바타
                                                                        Positioned(
                                                                          left: (MediaQuery.of(context).size.width / 2) -
                                                                              52.5,
                                                                          top:
                                                                              70.0,
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                105.0,
                                                                            height:
                                                                                105.0,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: ColorsConfig().userIconBackground(),
                                                                              borderRadius: BorderRadius.circular(52.5),
                                                                              image: DecorationImage(
                                                                                image: NetworkImage(
                                                                                  value.result['avatar'],
                                                                                  scale: 2.7,
                                                                                ),
                                                                                fit: BoxFit.none,
                                                                                alignment: const Alignment(0.0, -0.7),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                        });
                                                      }
                                                    : null,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10.0),
                                              child: Row(
                                                children: [
                                                  // 아바타
                                                  Container(
                                                    width: 25.0,
                                                    height: 25.0,
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig()
                                                          .userIconBackground(),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.5),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                          participantsList[
                                                              index]['avatar'],
                                                          scale: 8.5,
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
                                                    margin:
                                                        const EdgeInsets.only(
                                                            left: 6.0),
                                                    child: CustomTextBuilder(
                                                      text:
                                                          '${participantsList[index]['nick']}',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(),
                              ),
                              // 랭킹
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: rankList.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: rankList.length,
                                        // itemCount: userIsHeader
                                        //   ? rankList.length
                                        //   : rankList.length > 5
                                        //     ? 5
                                        //     : rankList.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 17.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // 아바타, {1등/2등/3등 트로피},닉네임
                                                Row(
                                                  children: [
                                                    // 아바타
                                                    Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: BoxDecoration(
                                                        color: ColorsConfig()
                                                            .userIconBackground(),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(21.0),
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                            rankList[index]
                                                                ['avatar'],
                                                            scale: 5.5,
                                                          ),
                                                          fit: BoxFit.none,
                                                          alignment:
                                                              const Alignment(
                                                                  0.0, -0.3),
                                                        ),
                                                      ),
                                                    ),
                                                    index == 0
                                                        ? Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 5.0),
                                                            child: SvgAssets(
                                                              image:
                                                                  'assets/icon/trophy1.svg',
                                                              width: 18.0,
                                                              height: 18.0,
                                                            ),
                                                          )
                                                        : index == 1
                                                            ? Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            5.0),
                                                                child:
                                                                    SvgAssets(
                                                                  image:
                                                                      'assets/icon/trophy2.svg',
                                                                  width: 18.0,
                                                                  height: 18.0,
                                                                ),
                                                              )
                                                            : index == 2
                                                                ? Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            5.0),
                                                                    child:
                                                                        SvgAssets(
                                                                      image:
                                                                          'assets/icon/trophy3.svg',
                                                                      width:
                                                                          18.0,
                                                                      height:
                                                                          18.0,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                    // 닉네임
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 5.0),
                                                      child: CustomTextBuilder(
                                                        text:
                                                            '${rankList[index]['nick']}',
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textWhite1(),
                                                        fontSize: 18.0,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // 사용 디코인 수량
                                                Row(
                                                  children: [
                                                    // 코인 사용량
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 5.0),
                                                      child: CustomTextBuilder(
                                                        text: NumberFormat()
                                                            .format(
                                                                rankList[index]
                                                                    ['total']),
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textWhite1(),
                                                        fontSize: 16.0,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                    // 코인 이미지
                                                    SvgAssets(
                                                      image:
                                                          'assets/icon/dcoin.svg',
                                                      width: 30.0,
                                                      height: 30.0,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: CustomTextBuilder(
                                          text: '방장에게 아이템을 선물해보세요.',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w400,
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
            ),
          ),
        ),
      ),
    );
  }
}
