import 'dart:async';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/tenor/tenor.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/like/add.dart';
import 'package:DRPublic/api/like/cancel.dart';
import 'package:DRPublic/api/post/main_post_detail.dart';
import 'package:DRPublic/api/reply/reply_add.dart';
import 'package:DRPublic/api/reply/reply_change.dart';
import 'package:DRPublic/api/reply/reply_delete.dart';
import 'package:DRPublic/api/reply/reply_like_add.dart';
import 'package:DRPublic/api/reply/reply_like_delete.dart';
import 'package:DRPublic/api/reply/reply_recently.dart';
import 'package:DRPublic/api/reply/reply_time.dart';
import 'package:DRPublic/api/block/add_user_block.dart';
import 'package:DRPublic/api/gift/gift_history.dart';
import 'package:DRPublic/api/gift/gift_list.dart';
import 'package:DRPublic/api/gift/gift_send.dart';
import 'package:DRPublic/api/gift/gift_send_priced.dart';
import 'package:DRPublic/api/post/main_post_list.dart';
import 'package:DRPublic/api/vote/vote_add.dart';
import 'package:DRPublic/api/vote/vote_cancle.dart';
import 'package:DRPublic/api/write/delete_post.dart';
import 'package:DRPublic/widget/deep_link.dart';
import 'package:DRPublic/widget/holding_balance.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class VoteDetailScreen extends StatefulWidget {
  VoteDetailScreen({
    Key? key,
    required this.postIndex,
    this.postType,
  }) : super(key: key);

  int postIndex;
  int? postType;

  @override
  State<VoteDetailScreen> createState() => _VoteDetailScreenState();
}

class _VoteDetailScreenState extends State<VoteDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController gifSearchController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final FocusNode gifSearchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController gifScrollController = ScrollController();

  var numberFormat = NumberFormat('###,###,###,###');

  Timer? _debounce;

  Map<String, dynamic> postDetailData = {};

  List<dynamic> timeLineReplyData = [];
  List<dynamic> recentlyReplyData = [];
  List<bool> useReplyChange = [];
  List<Map<String, dynamic>> replyChangeControllers = [];

  int addLikeCount = 0;
  int voteTotalCount = 0;

  bool likeState = false;
  bool useSort = false;

  Color replySendButtonColor = ColorsConfig.transparent;

  @override
  void initState() {
    apiInitialize();

    _textController.addListener(() {
      setState(() {
        replySendButtonColor = _textController.text.isNotEmpty
            ? ColorsConfig().primary()
            : ColorsConfig().textBlack2();
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _scrollController.dispose();
    gifScrollController.dispose();
    gifSearchFocusNode.dispose();
    gifSearchController.dispose();

    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    PostDetailDataAPI()
        .detail(
            accesToken: _prefs.getString('AccessToken')!,
            postIndex: widget.postIndex)
        .then((value) {
      setState(() {
        postDetailData = value.result;
        likeState = value.result['isLike'];
      });
    });

    Future.wait([
      GetTimeLineReplyAPI()
          .timeLineReply(
              accesToken: _prefs.getString('AccessToken')!,
              postIndex: widget.postIndex)
          .then((value) {
        setState(() {
          timeLineReplyData = value.result;

          for (int i = 0; i < value.result.length; i++) {
            Map<String, dynamic> _ctlToMap = {
              "controller": TextEditingController(),
              "focus_node": FocusNode(),
              "hasText": true,
            };
            replyChangeControllers.add(_ctlToMap);
            useReplyChange.add(false);
          }
        });
      }),
      GetRecentlyReplyAPI()
          .recentlyReply(
              accesToken: _prefs.getString('AccessToken')!,
              postIndex: widget.postIndex)
          .then((value) {
        setState(() {
          recentlyReplyData = value.result;
        });
      }),
    ]);

    _scrollController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 200), () async {
        if (useSort &&
            _scrollController.position.maxScrollExtent - 200 <=
                _scrollController.position.pixels) {
          GetRecentlyReplyAPI()
              .recentlyReply(
                  accesToken: _prefs.getString('AccessToken')!,
                  postIndex: widget.postIndex,
                  cursor: recentlyReplyData.last['reply_index'])
              .then((value) {
            setState(() {
              for (int i = 0; i < value.result.length; i++) {
                recentlyReplyData.add(value.result[i]);
              }
            });
          });
        }
      });
    });
  }

  Future getTenorGif({String search = '', dynamic useNext}) async {
    return useNext != null
        ? await TenorCustomBuilder().getTenorDatas(search, pos: useNext)
        : await TenorCustomBuilder().getTenorDatas(search);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _textFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: DRAppBar(
          leading: DRAppBarLeading(
            press: () => Navigator.pop(context),
          ),
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          backgroundColor: ColorsConfig().subBackground1(),
          title: const DRAppBarTitle(
            title: '공유글',
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (postDetailData['isMe']) {
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().textBlack2(),
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.only(
                                      top: 10.0,
                                      bottom: 15.0,
                                      left: 30.0,
                                      right: 30.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        width: 0.5,
                                        color: ColorsConfig().border1(),
                                      ),
                                    ),
                                  ),
                                  child: CustomTextBuilder(
                                    text: '공유글',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 18.0.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                                text: '삭제하시겠습니까?',
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
                                                  onTap: () {
                                                    Navigator.pop(context);
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

                                                    DeletePostDataAPI()
                                                        .deletePost(
                                                            accesToken: _prefs
                                                                .getString(
                                                                    'AccessToken')!,
                                                            postIndex:
                                                                postDetailData[
                                                                    'post_index'])
                                                        .then((_d) {
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context, {
                                                        'ret': true,
                                                      });
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
                                                        text: '삭제',
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
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '삭제하기',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                } else {
                  BuildContext dialogContext = context;
                  BuildContext dataContext = context;
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().textBlack2(),
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.fromLTRB(
                                      30.0, 10.5, 30.0, 14.5),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        width: 0.5,
                                        color: ColorsConfig().border1(),
                                      ),
                                    ),
                                  ),
                                  child: CustomTextBuilder(
                                    text: '${postDetailData['nick']}',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 18.0.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/report',
                                        arguments: {
                                          'type': 1,
                                          'targetIndex':
                                              postDetailData['post_index'],
                                        });
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '신고하기',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
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
                                            padding: const EdgeInsets.all(25.0),
                                            decoration: BoxDecoration(
                                              color: ColorsConfig()
                                                  .subBackground1(),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(8.0),
                                                topRight: Radius.circular(8.0),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CustomTextBuilder(
                                                  text:
                                                      '${postDetailData['nick']}님을 차단하시겠습니까?',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                const SizedBox(height: 10.0),
                                                CustomTextBuilder(
                                                  text:
                                                      '차단 시 ${postDetailData['nick']}님과 관련된 메시지, 모든 게시글이 차단되며, 구독중인 경우 구독이 해제됩니다.',
                                                  fontColor: ColorsConfig()
                                                      .textBlack2(),
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ],
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
                                                  onTap: () => Navigator.pop(
                                                      dialogContext),
                                                  child: Container(
                                                    width: (MediaQuery.of(
                                                                    dataContext)
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
                                                        fontSize: 16.0,
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

                                                    AddUserBlockAPI()
                                                        .addBlock(
                                                            accesToken: _prefs
                                                                .getString(
                                                                    'AccessToken')!,
                                                            targetIndex:
                                                                postDetailData[
                                                                    'user_index'])
                                                        .then((res) {
                                                      if (res.result[
                                                              'status'] ==
                                                          11100) {
                                                        Navigator.pop(
                                                            dialogContext);
                                                        ToastBuilder().toast(
                                                          Container(
                                                            width: MediaQuery.of(
                                                                    dataContext)
                                                                .size
                                                                .width,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(14.0),
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        30.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig
                                                                  .defaultToast
                                                                  .withOpacity(
                                                                      0.9),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6.0),
                                                            ),
                                                            child:
                                                                CustomTextBuilder(
                                                              text:
                                                                  '${postDetailData['nick']}님이 차단되었습니다',
                                                              fontColor:
                                                                  ColorsConfig
                                                                      .defaultWhite,
                                                              fontSize: 14.0.sp,
                                                            ),
                                                          ),
                                                        );
                                                      } else if (res.result[
                                                              'status'] ==
                                                          11101) {
                                                        Navigator.pop(
                                                            dialogContext);
                                                        ToastBuilder().toast(
                                                          Container(
                                                            width: MediaQuery.of(
                                                                    dataContext)
                                                                .size
                                                                .width,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(14.0),
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        30.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig
                                                                  .defaultToast
                                                                  .withOpacity(
                                                                      0.9),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6.0),
                                                            ),
                                                            child:
                                                                CustomTextBuilder(
                                                              text:
                                                                  '이미 차단된 유저입니다.',
                                                              fontColor:
                                                                  ColorsConfig
                                                                      .defaultWhite,
                                                              fontSize: 14.0.sp,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    width: (MediaQuery.of(
                                                                    dataContext)
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
                                                        text: '차단',
                                                        fontColor:
                                                            ColorsConfig()
                                                                .textRed1(),
                                                        fontSize: 16.0,
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
                                    ).dialog(dialogContext);
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '차단하기',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                }
              },
              icon: SvgAssets(
                image: 'assets/icon/more_vertical.svg',
                color: ColorsConfig().textBlack2(),
                width: 18.0,
                height: 18.0,
              ),
            ),
          ],
        ),
        body: postDetailData.isNotEmpty
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: ColorsConfig().background(),
                  border: Border(
                    top: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: ColorsConfig().subBackground1(),
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(
                              children: [
                                // 업로드 사용자 프로필 이미지, 닉네임, 업로드 시간, Label등
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (postDetailData['isMe']) {
                                            Navigator.pushNamed(
                                                context, '/my_profile',
                                                arguments: {
                                                  'onNavigator': true,
                                                });
                                          } else {
                                            Navigator.pushNamed(
                                                context, '/your_profile',
                                                arguments: {
                                                  'user_index': postDetailData[
                                                      'user_index'],
                                                  'user_nickname':
                                                      postDetailData['nick'],
                                                });
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            // 프로필 이미지
                                            Container(
                                              width: 40.0,
                                              height: 40.0,
                                              margin: const EdgeInsets.only(
                                                  right: 8.0),
                                              decoration: BoxDecoration(
                                                color: ColorsConfig()
                                                    .userIconBackground(),
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    postDetailData[
                                                        'avatar_url'],
                                                    scale: 6.0,
                                                  ),
                                                  filterQuality:
                                                      FilterQuality.high,
                                                  fit: BoxFit.none,
                                                  alignment: const Alignment(
                                                      0.0, -0.3),
                                                ),
                                              ),
                                            ),
                                            // 닉네임, 업로드 시간
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 닉네임
                                                CustomTextBuilder(
                                                  text:
                                                      '${postDetailData['nick']}',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 16.0.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                // 날짜
                                                CustomTextBuilder(
                                                  text: DateFormat(
                                                          'yyyy.MM.dd ${DateCalculatorWrapper().calculatorAMPM(postDetailData['date'])}')
                                                      .format(DateTime.parse(
                                                              postDetailData[
                                                                  'date'])
                                                          .toLocal()),
                                                  fontColor:
                                                      ColorsConfig.defaultGray,
                                                  fontSize: 12.0.sp,
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.8,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // label
                                      Container(
                                        margin:
                                            const EdgeInsets.only(left: 13.0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 3.0),
                                        decoration: BoxDecoration(
                                          color: postDetailData['type'] == 1
                                              ? ColorsConfig().postLabel()
                                              : postDetailData['type'] == 2
                                                  ? ColorsConfig()
                                                      .analyticsLabel()
                                                  : postDetailData['type'] == 3
                                                      ? ColorsConfig()
                                                          .debateLabel()
                                                      : postDetailData[
                                                                  'type'] ==
                                                              4
                                                          ? ColorsConfig()
                                                              .newsLabel()
                                                          : postDetailData[
                                                                      'type'] ==
                                                                  5
                                                              ? ColorsConfig()
                                                                  .voteLabel()
                                                              : ColorsConfig
                                                                  .defaultWhite,
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: CustomTextBuilder(
                                          text: postDetailData['type'] == 1
                                              ? '포스트'
                                              : postDetailData['type'] == 2
                                                  ? '분 석'
                                                  : postDetailData['type'] == 3
                                                      ? '토 론'
                                                      : postDetailData[
                                                                  'type'] ==
                                                              4
                                                          ? '뉴 스'
                                                          : postDetailData[
                                                                      'type'] ==
                                                                  5
                                                              ? '투 표'
                                                              : '',
                                          fontColor: ColorsConfig.defaultWhite,
                                          fontSize: 11.0.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 선물받은 뱃지영역
                                postDetailData['gift'].isNotEmpty
                                    ? InkWell(
                                        onTap: () async {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          GetGiftHistoryListDataAPI()
                                              .giftHistory(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  postIndex: postDetailData[
                                                      'post_index'])
                                              .then((history) {
                                            showModalBottomSheet(
                                                context: context,
                                                backgroundColor: ColorsConfig()
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
                                                    (BuildContext context) {
                                                  return SafeArea(
                                                    child: Container(
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
                                                        mainAxisSize:
                                                            MainAxisSize.min,
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
                                                          Center(
                                                            child: Container(
                                                              width:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          20.0,
                                                                      top: 10.0,
                                                                      right:
                                                                          20.0,
                                                                      bottom:
                                                                          15.0),
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
                                                              child:
                                                                  CustomTextBuilder(
                                                                text: '선물내역',
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textWhite1(),
                                                                fontSize:
                                                                    18.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: ListView
                                                                .builder(
                                                                    itemCount: history
                                                                        .result[
                                                                            'users']
                                                                        .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            historyIndex) {
                                                                      return Container(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        height:
                                                                            65.0,
                                                                        padding: const EdgeInsets
                                                                            .fromLTRB(
                                                                            20.0,
                                                                            15.0,
                                                                            20.0,
                                                                            15.0),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border(
                                                                            bottom:
                                                                                BorderSide(
                                                                              width: 0.5,
                                                                              color: ColorsConfig().border1(),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Row(
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
                                        child: Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          margin:
                                              const EdgeInsets.only(top: 5.0),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Wrap(
                                            children: List.generate(
                                                postDetailData['gift'].length,
                                                (giftIndex) {
                                              return Container(
                                                margin: EdgeInsets.only(
                                                    right: 8.0.r),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 24.0,
                                                      height: 24.0,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(9.0),
                                                      ),
                                                      child: Image(
                                                        image: NetworkImage(
                                                          postDetailData['gift']
                                                                  [giftIndex]
                                                              ['image'],
                                                        ),
                                                      ),
                                                    ),
                                                    CustomTextBuilder(
                                                      text:
                                                          '${postDetailData['gift'][giftIndex]['gift_count']}',
                                                      fontColor: ColorsConfig
                                                          .defaultGray,
                                                      fontSize: 12.0.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      )
                                    : Container(),
                                // 제목
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.only(
                                      top: 12.0, bottom: 8.0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: CustomTextBuilder(
                                    text: '${postDetailData['title']}',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // 투표항목
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: List.generate(
                                            postDetailData['vote'].length,
                                            (votes) {
                                          return InkWell(
                                            onTap: () async {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              if (DateTime.parse(postDetailData[
                                                          'vote_end_date'])
                                                      .millisecondsSinceEpoch >
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch) {
                                                if (postDetailData[
                                                        'selected_vote_index'] ==
                                                    null) {
                                                  SelectVoteAPI()
                                                      .addVote(
                                                          accesToken: _prefs
                                                              .getString(
                                                                  'AccessToken')!,
                                                          postIndex:
                                                              postDetailData[
                                                                  'post_index'],
                                                          voteIndex:
                                                              postDetailData[
                                                                          'vote']
                                                                      [votes][
                                                                  'vote_index'])
                                                      .then((_v) {
                                                    setState(() {
                                                      postDetailData[
                                                              'selected_vote_index'] =
                                                          postDetailData['vote']
                                                                  [votes]
                                                              ['vote_index'];
                                                      postDetailData['vote']
                                                              [votes]['cnt'] =
                                                          postDetailData['vote']
                                                                      [votes]
                                                                  ['cnt'] +
                                                              1;
                                                      postDetailData[
                                                              'vote_count'] =
                                                          postDetailData[
                                                                  'vote_count'] +
                                                              1;
                                                    });
                                                  });
                                                } else if (postDetailData[
                                                            'selected_vote_index'] !=
                                                        null &&
                                                    postDetailData[
                                                            'selected_vote_index'] ==
                                                        postDetailData['vote']
                                                                [votes]
                                                            ['vote_index']) {
                                                  SelectedVoteCancleAPI()
                                                      .cancel(
                                                          accesToken: _prefs
                                                              .getString(
                                                                  'AccessToken')!,
                                                          postIndex:
                                                              postDetailData[
                                                                  'post_index'],
                                                          voteIndex:
                                                              postDetailData[
                                                                          'vote']
                                                                      [votes][
                                                                  'vote_index'])
                                                      .then((_v) {
                                                    setState(() {
                                                      postDetailData[
                                                              'selected_vote_index'] =
                                                          null;
                                                      postDetailData['vote']
                                                              [votes]['cnt'] =
                                                          postDetailData['vote']
                                                                      [votes]
                                                                  ['cnt'] -
                                                              1;
                                                      postDetailData[
                                                              'vote_count'] =
                                                          postDetailData[
                                                                  'vote_count'] -
                                                              1;
                                                    });
                                                  });
                                                }
                                              }
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 36.0,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              decoration: BoxDecoration(
                                                color: ColorsConfig.transparent,
                                                border: Border.all(
                                                  width: 0.5,
                                                  color: postDetailData[
                                                                  'selected_vote_index'] ==
                                                              null ||
                                                          postDetailData[
                                                                  'selected_vote_index'] !=
                                                              postDetailData[
                                                                          'vote']
                                                                      [votes]
                                                                  ['vote_index']
                                                      ? ColorsConfig().border1()
                                                      : ColorsConfig()
                                                          .voteBorder(),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Stack(
                                                children: [
                                                  postDetailData['vote_count'] >
                                                          0
                                                      ? LinearPercentIndicator(
                                                          percent: postDetailData[
                                                                          'vote']
                                                                      [votes]
                                                                  ['cnt'] /
                                                              postDetailData[
                                                                  'vote_count'],
                                                          lineHeight: 100,
                                                          padding:
                                                              EdgeInsets.zero,
                                                          barRadius:
                                                              const Radius
                                                                  .circular(
                                                                  4.0),
                                                          animation: true,
                                                          backgroundColor:
                                                              ColorsConfig
                                                                  .transparent,
                                                          progressColor: postDetailData[
                                                                          'selected_vote_index'] ==
                                                                      null ||
                                                                  postDetailData[
                                                                          'selected_vote_index'] !=
                                                                      postDetailData['vote']
                                                                              [
                                                                              votes]
                                                                          [
                                                                          'vote_index']
                                                              ? ColorsConfig()
                                                                  .graphColor2()
                                                              : ColorsConfig()
                                                                  .graphColor1(),
                                                        )
                                                      : Container(),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CustomTextBuilder(
                                                          text: postDetailData[
                                                                  'vote'][votes]
                                                              ['vote_title'],
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textWhite1(),
                                                          fontSize: 16.0.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                        CustomTextBuilder(
                                                          text: postDetailData[
                                                                          'selected_vote_index'] !=
                                                                      null ||
                                                                  DateTime.parse(postDetailData[
                                                                              'date'])
                                                                          .millisecondsSinceEpoch <
                                                                      DateTime.now()
                                                                          .millisecondsSinceEpoch
                                                              ? postDetailData[
                                                                          'vote_count'] >
                                                                      0
                                                                  ? '${(postDetailData['vote'][votes]['cnt'] / postDetailData['vote_count'] * 100).toStringAsFixed(0)}%'
                                                                  : '0%'
                                                              : '',
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack2(),
                                                          fontSize: 16.0.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.only(
                                            top: 5.0, bottom: 11.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            CustomTextBuilder(
                                              text:
                                                  '총 ${postDetailData['vote_count']}명 투표',
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 12.0.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            CustomTextBuilder(
                                              text: DateCalculatorWrapper()
                                                              .expiredDate(
                                                                  postDetailData[
                                                                      'vote_end_date']) >=
                                                          0 &&
                                                      DateCalculatorWrapper()
                                                              .expiredHoursForDate(
                                                                  postDetailData[
                                                                      'vote_end_date']) >
                                                          0
                                                  ? '${DateCalculatorWrapper().expiredDate(postDetailData['vote_end_date'])}일 ${DateCalculatorWrapper().expiredHoursForDate(postDetailData['vote_end_date'])}시간 남음'
                                                  : DateCalculatorWrapper()
                                                                  .expiredDate(
                                                                      postDetailData[
                                                                          'vote_end_date']) >=
                                                              0 &&
                                                          DateCalculatorWrapper()
                                                                  .expiredHoursForDate(
                                                                      postDetailData[
                                                                          'vote_end_date']) <=
                                                              0 &&
                                                          DateCalculatorWrapper()
                                                                  .expiredMinutesForDate(
                                                                      postDetailData[
                                                                          'vote_end_date']) >
                                                              0
                                                      ? '${DateCalculatorWrapper().expiredDate(postDetailData['vote_end_date'])}일 ${DateCalculatorWrapper().expiredHoursForDate(postDetailData['vote_end_date'])}시간 ${DateCalculatorWrapper().expiredMinutesForDate(postDetailData['vote_end_date'])}분 남음'
                                                      : '투표가 마감되었습니다.',
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 12.0.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          // 태그, 좋아요, 댓글, 선물, 공유, 더보기 등
                          Container(
                            color: ColorsConfig().subBackground1(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20.0),
                                  padding: const EdgeInsets.fromLTRB(
                                      20.0, 30.0, 20.0, 0.0),
                                  child: Wrap(
                                    children: List.generate(
                                        postDetailData['tag']
                                            .toString()
                                            .split(',')
                                            .length, (tags) {
                                      return InkWell(
                                        onTap: () async {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          GetPostListAPI()
                                              .list(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  q: postDetailData['tag']
                                                      .toString()
                                                      .split(',')[tags])
                                              .then((value) {
                                            Navigator.pushNamed(
                                                context, '/search_result',
                                                arguments: {
                                                  'search':
                                                      postDetailData['tag']
                                                          .toString()
                                                          .split(',')[tags],
                                                  'result': value.result,
                                                });
                                          });
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 4.0),
                                          child: CustomTextBuilder(
                                            text: postDetailData['tag']
                                                .toString()
                                                .split(',')[tags]
                                                .replaceFirst('', '#'),
                                            fontColor: ColorsConfig().hashTag(),
                                            fontSize: 16.0.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // 좋아요, 댓글, 선물, 공유, 더보기 버튼
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 좋아요
                                    MaterialButton(
                                      onPressed: () async {
                                        final _prefs = await SharedPreferences
                                            .getInstance();

                                        if (!likeState) {
                                          AddLikeSenderAPI()
                                              .add(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  postIndex: postDetailData[
                                                      'post_index'])
                                              .then((res) {
                                            if (res.result['status'] == 10800) {
                                              setState(() {
                                                likeState = true;
                                                postDetailData['like']++;
                                              });
                                            }
                                          });
                                        } else {
                                          CancelLikeSenderAPI()
                                              .cancel(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  postIndex: postDetailData[
                                                      'post_index'])
                                              .then((res) {
                                            if (res.result['status'] == 10805) {
                                              setState(() {
                                                likeState = false;
                                                postDetailData['like']--;
                                              });
                                            }
                                          });
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          SvgAssets(
                                            image: 'assets/icon/like.svg',
                                            color: likeState
                                                ? ColorsConfig().primary()
                                                : ColorsConfig().textBlack1(),
                                            width: 18.0,
                                            height: 18.0,
                                          ),
                                          const SizedBox(width: 10.0),
                                          CustomTextBuilder(
                                            text: numberFormat.format(
                                                postDetailData['like'] +
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
                                        _textFocusNode.requestFocus();
                                      },
                                      child: Row(
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
                                                postDetailData['reply']),
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
                                        if (postDetailData['isMe']) {
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
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          GetGiftListDataAPI()
                                              .gift(
                                                  accesToken: _prefs.getString(
                                                      'AccessToken')!)
                                              .then((gifts) {
                                            bool _hasClick = false;

                                            showModalBottomSheet(
                                                context: context,
                                                backgroundColor: ColorsConfig()
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
                                                  List<dynamic> _reaction = [];
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
                                                      _trophy
                                                          .add(gifts.result[i]);
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
                                                              width:
                                                                  MediaQuery.of(
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
                                                                          children: List.generate(
                                                                              gifts.result.length,
                                                                              (index) {
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
                                                                          children: List.generate(
                                                                              _trophy.length,
                                                                              (index) {
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
                                                                          children: List.generate(
                                                                              _reaction.length,
                                                                              (index) {
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
                                                                          children: List.generate(
                                                                              _neckTrophy.length,
                                                                              (index) {
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
                                                                          offset: const Offset(
                                                                              0.0,
                                                                              -2.0),
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
                                                                            height:
                                                                                10.0),
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            if (_selectedGift['price'] ==
                                                                                0) {
                                                                              SendGiftDataAPI().gift(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], postIndex: postDetailData['post_index']).then((value) {
                                                                                int? _existIndex;

                                                                                switch (value.result['status']) {
                                                                                  case 10200:
                                                                                    setState(() {
                                                                                      if (postDetailData['gift'].length == 0) {
                                                                                        postDetailData['gift'].add({
                                                                                          "image": _selectedGift['url'],
                                                                                          "gift_count": 1,
                                                                                        });
                                                                                      } else {
                                                                                        for (int i = 0; i < postDetailData['gift'].length; i++) {
                                                                                          if (postDetailData['gift'][i]['image'].contains(_selectedGift['url'])) {
                                                                                            _existIndex = i;
                                                                                            break;
                                                                                          }
                                                                                        }

                                                                                        if (_existIndex != null) {
                                                                                          postDetailData['gift'][_existIndex]['gift_count'] = postDetailData['gift'][_existIndex]['gift_count'] + 1;
                                                                                        } else {
                                                                                          postDetailData['gift'].insert(0, {
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
                                                                              SendPricedGiftDataAPI().pricedGift(accesToken: _prefs.getString('AccessToken')!, itemIndex: _selectedGift['item_index'], postIndex: postDetailData['post_index']).then((value) {
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
                                                                                      if (postDetailData['gift'].length == 0) {
                                                                                        postDetailData['gift'].add({
                                                                                          "image": _selectedGift['url'],
                                                                                          "gift_count": 1,
                                                                                        });
                                                                                      } else {
                                                                                        for (int i = 0; i < postDetailData['gift'].length; i++) {
                                                                                          if (postDetailData['gift'][i]['image'].contains(_selectedGift['url'])) {
                                                                                            _existIndex = i;
                                                                                            break;
                                                                                          }
                                                                                        }

                                                                                        if (_existIndex != null) {
                                                                                          postDetailData['gift'][_existIndex]['gift_count'] = postDetailData['gift'][_existIndex]['gift_count'] + 1;
                                                                                        } else {
                                                                                          postDetailData['gift'].insert(0, {
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
                                                                            width:
                                                                                MediaQuery.of(context).size.width,
                                                                            height:
                                                                                42.0,
                                                                            decoration:
                                                                                BoxDecoration(
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
                                                                            child:
                                                                                Center(
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
                                                '${postDetailData['post_index']}',
                                                postDetailData['type']);

                                        Share.share(
                                          '${postDetailData['title']}\n$shortLink',
                                          sharePositionOrigin: Rect.fromLTWH(
                                              0,
                                              0,
                                              MediaQuery.of(context).size.width,
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
                          const SizedBox(height: 8.0),
                          Container(
                            height: 45.0,
                            color: ColorsConfig().subBackground1(),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          useSort = false;
                                        });
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10.0),
                                        child: CustomTextBuilder(
                                          text: '시간순',
                                          fontColor: !useSort
                                              ? ColorsConfig().textWhite1()
                                              : ColorsConfig().textBlack2(),
                                          fontSize: 16.0.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          useSort = true;
                                        });
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10.0),
                                        child: CustomTextBuilder(
                                          text: '최신순',
                                          fontColor: useSort
                                              ? ColorsConfig().textWhite1()
                                              : ColorsConfig().textBlack2(),
                                          fontSize: 16.0.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 0.0),
                          // 댓글 영역
                          !useSort
                              ? Column(
                                  children: List.generate(
                                      timeLineReplyData.length, (index) {
                                    return Column(
                                      children: [
                                        // 댓글 원본 영역
                                        Container(
                                          padding:
                                              const EdgeInsets.only(top: 13.0),
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
                                            children: [
                                              // 프로필 이미지, 닉네임, 시간, 더보기 버튼
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 20.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (timeLineReplyData[
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
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'user_index'],
                                                                'user_nickname':
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'nick'],
                                                              });
                                                        }
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: 35.0,
                                                            height: 35.0,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .userIconBackground(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          17.5),
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  timeLineReplyData[
                                                                          index]
                                                                      [
                                                                      'avatar'],
                                                                  scale: 7.0,
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
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              63.0,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          !useReplyChange[index]
                                                              ? Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Container(
                                                                          margin: const EdgeInsets
                                                                              .only(
                                                                              right: 6.0),
                                                                          child:
                                                                              CustomTextBuilder(
                                                                            text:
                                                                                timeLineReplyData[index]['parent_nick'],
                                                                            fontColor:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                16.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                        CustomTextBuilder(
                                                                          text: DateCalculatorWrapper().daysCalculator(timeLineReplyData[index]
                                                                              [
                                                                              'reg_dt']),
                                                                          fontColor:
                                                                              ColorsConfig.defaultGray,
                                                                          fontSize:
                                                                              14.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                          height:
                                                                              1.5,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    timeLineReplyData[index]['message'] !=
                                                                            '삭제 된 메시지입니다.'
                                                                        ? InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              final _prefs = await SharedPreferences.getInstance();

                                                                              if (timeLineReplyData[index]['isMe']) {
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
                                                                                              Container(
                                                                                                width: MediaQuery.of(context).size.width,
                                                                                                padding: const EdgeInsets.only(top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
                                                                                                decoration: BoxDecoration(
                                                                                                  border: Border(
                                                                                                    bottom: BorderSide(
                                                                                                      width: 0.5,
                                                                                                      color: ColorsConfig().border1(),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                child: CustomTextBuilder(
                                                                                                  text: '댓글',
                                                                                                  fontColor: ColorsConfig().textWhite1(),
                                                                                                  fontSize: 18.0.sp,
                                                                                                  fontWeight: FontWeight.w600,
                                                                                                ),
                                                                                              ),
                                                                                              timeLineReplyData[index]['type'] == 0
                                                                                                  ? InkWell(
                                                                                                      onTap: () {
                                                                                                        Navigator.pop(context, {
                                                                                                          "select": 1,
                                                                                                        });
                                                                                                      },
                                                                                                      child: Container(
                                                                                                        width: MediaQuery.of(context).size.width,
                                                                                                        height: 50.0,
                                                                                                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                                        alignment: Alignment.centerLeft,
                                                                                                        child: CustomTextBuilder(
                                                                                                          text: '수정하기',
                                                                                                          fontColor: ColorsConfig().textWhite1(),
                                                                                                          fontSize: 16.0.sp,
                                                                                                          fontWeight: FontWeight.w700,
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  : Container(),
                                                                                              InkWell(
                                                                                                onTap: () {
                                                                                                  Navigator.pop(context, {
                                                                                                    "select": 2,
                                                                                                  });
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: MediaQuery.of(context).size.width,
                                                                                                  height: 50.0,
                                                                                                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                                  alignment: Alignment.centerLeft,
                                                                                                  child: CustomTextBuilder(
                                                                                                    text: '삭제하기',
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 16.0.sp,
                                                                                                    fontWeight: FontWeight.w700,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }).then((_val) {
                                                                                  if (_val['select'] == 1) {
                                                                                    setState(() {
                                                                                      useReplyChange[index] = true;
                                                                                      replyChangeControllers[index]['controller'].text = timeLineReplyData[index]['message'];
                                                                                    });
                                                                                  } else if (_val['select'] == 2) {
                                                                                    DeleteReplyDataAPI().deleteReply(accesToken: _prefs.getString('AccessToken')!, replyIndex: timeLineReplyData[index]['reply_index'], isParent: 1).then((_v) {
                                                                                      setState(() {
                                                                                        timeLineReplyData[index]['type'] = 0;
                                                                                        timeLineReplyData[index]['message'] = '삭제 된 메시지입니다.';
                                                                                      });
                                                                                    });
                                                                                  }
                                                                                });
                                                                              } else {
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
                                                                                              Container(
                                                                                                width: MediaQuery.of(context).size.width,
                                                                                                padding: const EdgeInsets.only(top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
                                                                                                decoration: BoxDecoration(
                                                                                                  border: Border(
                                                                                                    bottom: BorderSide(
                                                                                                      width: 0.5,
                                                                                                      color: ColorsConfig().border1(),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                child: CustomTextBuilder(
                                                                                                  text: '${timeLineReplyData[index]['parent_nick']}',
                                                                                                  fontColor: ColorsConfig().textWhite1(),
                                                                                                  fontSize: 18.0.sp,
                                                                                                  fontWeight: FontWeight.w600,
                                                                                                ),
                                                                                              ),
                                                                                              InkWell(
                                                                                                onTap: () {
                                                                                                  Navigator.pop(context);
                                                                                                  Navigator.pushNamed(context, '/report', arguments: {
                                                                                                    'type': 2,
                                                                                                    'targetIndex': timeLineReplyData[index]['reply_index'],
                                                                                                  });
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: MediaQuery.of(context).size.width,
                                                                                                  height: 50.0,
                                                                                                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                                  alignment: Alignment.centerLeft,
                                                                                                  child: CustomTextBuilder(
                                                                                                    text: '신고하기',
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 16.0.sp,
                                                                                                    fontWeight: FontWeight.w400,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    });
                                                                              }
                                                                            },
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 13.0),
                                                                              child: SvgAssets(
                                                                                image: 'assets/icon/more_horizontal.svg',
                                                                                color: ColorsConfig().textBlack2(),
                                                                                width: 18.0,
                                                                              ),
                                                                            ),
                                                                          )
                                                                        : Container(),
                                                                  ],
                                                                )
                                                              : Container(),
                                                          !useReplyChange[index]
                                                              ? Container(
                                                                  margin: const EdgeInsets
                                                                      .only(
                                                                      top: 6.0,
                                                                      bottom:
                                                                          10.0,
                                                                      right:
                                                                          20.0),
                                                                  child: timeLineReplyData[index]
                                                                              [
                                                                              'type'] ==
                                                                          0
                                                                      ? CustomTextBuilder(
                                                                          text:
                                                                              '${timeLineReplyData[index]['message']}',
                                                                          fontColor:
                                                                              ColorsConfig().textWhite1(),
                                                                          fontSize:
                                                                              16.0.sp,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                        )
                                                                      : Image(
                                                                          image:
                                                                              NetworkImage(
                                                                            timeLineReplyData[index]['gif'],
                                                                          ),
                                                                          filterQuality:
                                                                              FilterQuality.high,
                                                                        ),
                                                                )
                                                              : Container(
                                                                  margin: const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          10.0),
                                                                  child: Column(
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            110.0,
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            bottom:
                                                                                15.0),
                                                                        child:
                                                                            TextFormField(
                                                                          controller:
                                                                              replyChangeControllers[index]['controller'],
                                                                          focusNode:
                                                                              replyChangeControllers[index]['focus_node'],
                                                                          expands:
                                                                              true,
                                                                          maxLines:
                                                                              null,
                                                                          autofocus:
                                                                              true,
                                                                          decoration:
                                                                              InputDecoration(
                                                                            isCollapsed:
                                                                                true,
                                                                            contentPadding:
                                                                                const EdgeInsets.symmetric(horizontal: 11.0, vertical: 8.0),
                                                                            border:
                                                                                OutlineInputBorder(
                                                                              borderSide: BorderSide(
                                                                                width: 0.5,
                                                                                color: ColorsConfig().primary(),
                                                                              ),
                                                                            ),
                                                                            focusedBorder:
                                                                                OutlineInputBorder(
                                                                              borderSide: BorderSide(
                                                                                width: 0.5,
                                                                                color: ColorsConfig().primary(),
                                                                              ),
                                                                            ),
                                                                            enabledBorder:
                                                                                OutlineInputBorder(
                                                                              borderSide: BorderSide(
                                                                                width: 0.5,
                                                                                color: ColorsConfig().primary(),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                ColorsConfig().textWhite1(),
                                                                            fontSize:
                                                                                14.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                          ),
                                                                          onChanged:
                                                                              (text) {
                                                                            setState(() {
                                                                              if (replyChangeControllers[index]['controller'].text.isEmpty) {
                                                                                replyChangeControllers[index]['hasText'] = false;
                                                                              } else {
                                                                                replyChangeControllers[index]['hasText'] = true;
                                                                              }
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                useReplyChange[index] = false;
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 13.5, vertical: 8.5),
                                                                              decoration: BoxDecoration(
                                                                                color: ColorsConfig().textWhite1(),
                                                                                border: Border.all(
                                                                                  width: 0.5,
                                                                                  color: ColorsConfig().border1(),
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                              child: CustomTextBuilder(text: '취소', fontColor: ColorsConfig().background(), fontSize: 14.0.sp, fontWeight: FontWeight.w700),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 8.0),
                                                                          InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              final _prefs = await SharedPreferences.getInstance();

                                                                              if (replyChangeControllers[index]['hasText']) {
                                                                                if (replyChangeControllers[index]['controller'].toString().trim().isNotEmpty) {
                                                                                  ChangeReplyAPI()
                                                                                      .changeReply(
                                                                                    accesToken: _prefs.getString('AccessToken')!,
                                                                                    isParent: 1,
                                                                                    message: replyChangeControllers[index]['controller'].text,
                                                                                    replyIndex: timeLineReplyData[index]['reply_index'],
                                                                                  )
                                                                                      .then((_v) {
                                                                                    setState(() {
                                                                                      replyChangeControllers[index]['focus_node'].unfocus();
                                                                                      timeLineReplyData[index] = _v.result;
                                                                                      useReplyChange[index] = false;
                                                                                    });
                                                                                  });
                                                                                }
                                                                              }
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 13.5, vertical: 8.5),
                                                                              decoration: BoxDecoration(
                                                                                color: replyChangeControllers[index]['hasText'] ? ColorsConfig().primary() : ColorsConfig().textBlack2(),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                              child: CustomTextBuilder(
                                                                                text: '수정하기',
                                                                                fontColor: ColorsConfig().background(),
                                                                                fontSize: 14.0.sp,
                                                                                fontWeight: FontWeight.w700,
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
                                                  ],
                                                ),
                                              ),
                                              !useReplyChange[index]
                                                  ? Row(
                                                      children: [
                                                        const SizedBox(
                                                            width: 35.0),
                                                        // 좋아요
                                                        MaterialButton(
                                                          onPressed: () async {
                                                            final _prefs =
                                                                await SharedPreferences
                                                                    .getInstance();

                                                            if (timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'isLike'] ==
                                                                    null ||
                                                                timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'isLike'] ==
                                                                    false) {
                                                              AddReplyLikeDataAPI()
                                                                  .addReplyLike(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                replyIndex:
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'reply_index'],
                                                              )
                                                                  .then((_v) {
                                                                if (_v.result[
                                                                        'status'] ==
                                                                    10720) {
                                                                  setState(() {
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'isLike'] = true;
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'like']++;
                                                                  });
                                                                }
                                                              });
                                                            } else {
                                                              DeleteReplyLikeDataAPI()
                                                                  .deleteReplyLike(
                                                                accesToken: _prefs
                                                                    .getString(
                                                                        'AccessToken')!,
                                                                replyIndex:
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'reply_index'],
                                                              )
                                                                  .then((_v) {
                                                                if (_v.result[
                                                                        'status'] ==
                                                                    10725) {
                                                                  setState(() {
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'isLike'] = false;
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'like']--;
                                                                  });
                                                                }
                                                              });
                                                            }
                                                          },
                                                          child: Row(
                                                            children: [
                                                              timeLineReplyData[
                                                                              index]
                                                                          [
                                                                          'isLike'] ==
                                                                      true
                                                                  ? SvgAssets(
                                                                      image:
                                                                          'assets/icon/like.svg',
                                                                      color: ColorsConfig()
                                                                          .primary(),
                                                                      width:
                                                                          18.0,
                                                                      height:
                                                                          18.0,
                                                                    )
                                                                  : SvgAssets(
                                                                      image:
                                                                          'assets/icon/like.svg',
                                                                      color: ColorsConfig()
                                                                          .textBlack2(),
                                                                      width:
                                                                          18.0,
                                                                      height:
                                                                          18.0,
                                                                    ),
                                                              const SizedBox(
                                                                  width: 6.0),
                                                              CustomTextBuilder(
                                                                text: numberFormat.format(
                                                                    timeLineReplyData[
                                                                            index]
                                                                        [
                                                                        'like']),
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textBlack2(),
                                                                fontSize:
                                                                    12.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        // 댓글
                                                        MaterialButton(
                                                          onPressed: () {
                                                            Navigator.pushNamed(
                                                                context,
                                                                '/sub_reply_detail',
                                                                arguments: {
                                                                  'sub_reply':
                                                                      timeLineReplyData[
                                                                          index],
                                                                  'type':
                                                                      'timeLine',
                                                                  'post_index':
                                                                      widget
                                                                          .postIndex,
                                                                });
                                                          },
                                                          child: Row(
                                                            children: [
                                                              SvgAssets(
                                                                image:
                                                                    'assets/icon/reply.svg',
                                                                color: ColorsConfig()
                                                                    .textBlack2(),
                                                                width: 18.0,
                                                                height: 18.0,
                                                              ),
                                                              const SizedBox(
                                                                  width: 6.0),
                                                              CustomTextBuilder(
                                                                text: numberFormat.format(
                                                                    timeLineReplyData[index]
                                                                            [
                                                                            'child']
                                                                        .length),
                                                                fontColor:
                                                                    ColorsConfig()
                                                                        .textBlack2(),
                                                                fontSize:
                                                                    12.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ),
                                        // 대댓글 영역
                                        InkWell(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, '/sub_reply_detail',
                                                arguments: {
                                                  'sub_reply':
                                                      timeLineReplyData[index],
                                                  'type': 'timeLine',
                                                  'post_index':
                                                      widget.postIndex,
                                                });
                                          },
                                          child: Column(
                                            children: List.generate(
                                                !useSort
                                                    ? timeLineReplyData[index]
                                                                    ['child']
                                                                .length <
                                                            3
                                                        ? timeLineReplyData[
                                                                index]['child']
                                                            .length
                                                        : 3
                                                    : 0, (subIndex) {
                                              return Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        33.0, 13.0, 20.0, 0.0),
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig()
                                                          .background(),
                                                      border: Border(
                                                        top: BorderSide(
                                                          width: 0.5,
                                                          color: ColorsConfig()
                                                              .border1(),
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        // 프로필 이미지, 닉네임, 시간, 더보기 버튼
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Container(
                                                                  width: 35.0,
                                                                  height: 35.0,
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: ColorsConfig()
                                                                        .userIconBackground(),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            17.5),
                                                                    image:
                                                                        DecorationImage(
                                                                      image:
                                                                          NetworkImage(
                                                                        timeLineReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'avatar'],
                                                                        scale:
                                                                            7.0,
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
                                                              ],
                                                            ),
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width -
                                                                  96.0,
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          Container(
                                                                            margin:
                                                                                const EdgeInsets.only(right: 6.0),
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: timeLineReplyData[index]['child'][subIndex]['parent_nick'],
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                          ),
                                                                          CustomTextBuilder(
                                                                            text:
                                                                                DateCalculatorWrapper().daysCalculator(timeLineReplyData[index]['child'][subIndex]['reg_dt']),
                                                                            fontColor:
                                                                                ColorsConfig.defaultGray,
                                                                            fontSize:
                                                                                14.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            height:
                                                                                1.5,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      timeLineReplyData[index]['child'][subIndex]['message'] !=
                                                                              '삭제 된 메시지입니다.'
                                                                          ? Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 13.0),
                                                                              child: SvgAssets(
                                                                                image: 'assets/icon/more_horizontal.svg',
                                                                                color: ColorsConfig().textBlack2(),
                                                                                width: 18.0,
                                                                              ),
                                                                            )
                                                                          : Container(
                                                                              padding: const EdgeInsets.symmetric(vertical: 13.0),
                                                                            ),
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            6.0,
                                                                        bottom:
                                                                            10.0),
                                                                    child: timeLineReplyData[index]['child'][subIndex]['type'] ==
                                                                            0
                                                                        ? Text
                                                                            .rich(
                                                                            TextSpan(
                                                                              children: <TextSpan>[
                                                                                TextSpan(
                                                                                  text: '[${timeLineReplyData[index]['child'][subIndex]['parent_nick']} > ${timeLineReplyData[index]['child'][subIndex]['child_nick']}]',
                                                                                  style: TextStyle(
                                                                                    color: ColorsConfig().textBlack2(),
                                                                                    fontSize: 14.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                                const TextSpan(
                                                                                  text: ' ',
                                                                                ),
                                                                                TextSpan(
                                                                                  text: timeLineReplyData[index]['child'][subIndex]['message'],
                                                                                  style: TextStyle(
                                                                                    color: ColorsConfig().textWhite1(),
                                                                                    fontSize: 16.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          )
                                                                        : Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              CustomTextBuilder(
                                                                                text: '[${timeLineReplyData[index]['child'][subIndex]['parent_nick']} > ${timeLineReplyData[index]['child'][subIndex]['child_nick']}]',
                                                                                style: TextStyle(
                                                                                  color: ColorsConfig().textBlack2(),
                                                                                  fontSize: 16.0.sp,
                                                                                  fontWeight: FontWeight.w400,
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Image(
                                                                                image: NetworkImage(
                                                                                  timeLineReplyData[index]['child'][subIndex]['gif'],
                                                                                ),
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const SizedBox(
                                                                width: 15.0),
                                                            // 좋아요
                                                            MaterialButton(
                                                              onPressed:
                                                                  () async {
                                                                final _prefs =
                                                                    await SharedPreferences
                                                                        .getInstance();

                                                                if (timeLineReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'isLike'] ==
                                                                        null ||
                                                                    timeLineReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'isLike'] ==
                                                                        false) {
                                                                  AddReplyLikeDataAPI()
                                                                      .addReplyLike(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    replyIndex: timeLineReplyData[index]['child']
                                                                            [
                                                                            subIndex]
                                                                        [
                                                                        'reply_index'],
                                                                  )
                                                                      .then(
                                                                          (_v) {
                                                                    if (_v.result[
                                                                            'status'] ==
                                                                        10720) {
                                                                      setState(
                                                                          () {
                                                                        timeLineReplyData[index]['child'][subIndex]['isLike'] =
                                                                            true;
                                                                        timeLineReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'like']++;
                                                                      });
                                                                    }
                                                                  });
                                                                } else {
                                                                  DeleteReplyLikeDataAPI()
                                                                      .deleteReplyLike(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    replyIndex: timeLineReplyData[index]['child']
                                                                            [
                                                                            subIndex]
                                                                        [
                                                                        'reply_index'],
                                                                  )
                                                                      .then(
                                                                          (_v) {
                                                                    if (_v.result[
                                                                            'status'] ==
                                                                        10725) {
                                                                      setState(
                                                                          () {
                                                                        timeLineReplyData[index]['child'][subIndex]['isLike'] =
                                                                            false;
                                                                        timeLineReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'like']--;
                                                                      });
                                                                    }
                                                                  });
                                                                }
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  timeLineReplyData[index]['child'][subIndex]
                                                                              [
                                                                              'isLike'] ==
                                                                          true
                                                                      ? SvgAssets(
                                                                          image:
                                                                              'assets/icon/like.svg',
                                                                          color:
                                                                              ColorsConfig().primary(),
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                        )
                                                                      : SvgAssets(
                                                                          image:
                                                                              'assets/icon/like.svg',
                                                                          color:
                                                                              ColorsConfig().textBlack2(),
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                        ),
                                                                  const SizedBox(
                                                                      width:
                                                                          6.0),
                                                                  CustomTextBuilder(
                                                                    text: numberFormat.format(timeLineReplyData[index]['child']
                                                                            [
                                                                            subIndex]
                                                                        [
                                                                        'like']),
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textBlack2(),
                                                                    fontSize:
                                                                        12.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // 댓글
                                                            MaterialButton(
                                                              onPressed: () {
                                                                Navigator.pushNamed(
                                                                    context,
                                                                    '/sub_reply_detail',
                                                                    arguments: {
                                                                      'sub_reply':
                                                                          timeLineReplyData[
                                                                              index],
                                                                      'type':
                                                                          'timeLine',
                                                                      'post_index':
                                                                          widget
                                                                              .postIndex,
                                                                    });
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  SvgAssets(
                                                                    image:
                                                                        'assets/icon/reply.svg',
                                                                    color: ColorsConfig()
                                                                        .textBlack2(),
                                                                    width: 18.0,
                                                                    height:
                                                                        18.0,
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          6.0),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                )
                              : Container(),
                          useSort
                              ? Column(
                                  children: List.generate(
                                      recentlyReplyData.length, (index) {
                                    return Column(
                                      children: [
                                        // 댓글 원본 영역
                                        Container(
                                          padding:
                                              const EdgeInsets.only(top: 13.0),
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
                                            children: [
                                              // 프로필 이미지, 닉네임, 시간, 더보기 버튼
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 20.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (recentlyReplyData[
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
                                                                    recentlyReplyData[
                                                                            index]
                                                                        [
                                                                        'user_index'],
                                                                'user_nickname':
                                                                    recentlyReplyData[
                                                                            index]
                                                                        [
                                                                        'nick'],
                                                              });
                                                        }
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: 35.0,
                                                            height: 35.0,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .userIconBackground(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          17.5),
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  recentlyReplyData[
                                                                          index]
                                                                      [
                                                                      'avatar'],
                                                                  scale: 7.0,
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
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              63.0,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            6.0),
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text: recentlyReplyData[
                                                                              index]
                                                                          [
                                                                          'parent_nick'],
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
                                                                    text: DateCalculatorWrapper().daysCalculator(
                                                                        recentlyReplyData[index]
                                                                            [
                                                                            'reg_dt']),
                                                                    fontColor:
                                                                        ColorsConfig
                                                                            .defaultGray,
                                                                    fontSize:
                                                                        14.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                    height: 1.5,
                                                                  ),
                                                                ],
                                                              ),
                                                              recentlyReplyData[
                                                                              index]
                                                                          [
                                                                          'message'] !=
                                                                      '삭제 된 메시지입니다.'
                                                                  ? InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        final _prefs =
                                                                            await SharedPreferences.getInstance();

                                                                        if (recentlyReplyData[index]
                                                                            [
                                                                            'isMe']) {
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
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.only(top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            border: Border(
                                                                                              bottom: BorderSide(
                                                                                                width: 0.5,
                                                                                                color: ColorsConfig().border1(),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '댓글',
                                                                                            fontColor: ColorsConfig().textWhite1(),
                                                                                            fontSize: 18.0.sp,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                        ),
                                                                                        recentlyReplyData[index]['type'] == 0
                                                                                            ? InkWell(
                                                                                                onTap: () {
                                                                                                  Navigator.pop(context, {
                                                                                                    "select": 1,
                                                                                                  });
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: MediaQuery.of(context).size.width,
                                                                                                  height: 50.0,
                                                                                                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                                  alignment: Alignment.centerLeft,
                                                                                                  child: CustomTextBuilder(
                                                                                                    text: '수정하기',
                                                                                                    fontColor: ColorsConfig().textWhite1(),
                                                                                                    fontSize: 16.0.sp,
                                                                                                    fontWeight: FontWeight.w700,
                                                                                                  ),
                                                                                                ),
                                                                                              )
                                                                                            : Container(),
                                                                                        InkWell(
                                                                                          onTap: () {
                                                                                            Navigator.pop(context, {
                                                                                              "select": 2,
                                                                                            });
                                                                                          },
                                                                                          child: Container(
                                                                                            width: MediaQuery.of(context).size.width,
                                                                                            height: 50.0,
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                            alignment: Alignment.centerLeft,
                                                                                            child: CustomTextBuilder(
                                                                                              text: '삭제하기',
                                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                                              fontSize: 16.0.sp,
                                                                                              fontWeight: FontWeight.w700,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              }).then((_val) {
                                                                            if (_val['select'] ==
                                                                                1) {
                                                                              setState(() {
                                                                                useReplyChange[index] = true;
                                                                                replyChangeControllers[index]['controller'].text = recentlyReplyData[index]['message'];
                                                                              });
                                                                            } else if (_val['select'] ==
                                                                                2) {
                                                                              DeleteReplyDataAPI().deleteReply(accesToken: _prefs.getString('AccessToken')!, replyIndex: recentlyReplyData[index]['reply_index'], isParent: 1).then((_v) {
                                                                                setState(() {
                                                                                  recentlyReplyData[index]['type'] = 0;
                                                                                  recentlyReplyData[index]['message'] = '삭제 된 메시지입니다.';
                                                                                });
                                                                              });
                                                                            }
                                                                          });
                                                                        } else {
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
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width,
                                                                                          padding: const EdgeInsets.only(top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
                                                                                          decoration: BoxDecoration(
                                                                                            border: Border(
                                                                                              bottom: BorderSide(
                                                                                                width: 0.5,
                                                                                                color: ColorsConfig().border1(),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          child: CustomTextBuilder(
                                                                                            text: '${recentlyReplyData[index]['parent_nick']}',
                                                                                            fontColor: ColorsConfig().textWhite1(),
                                                                                            fontSize: 18.0.sp,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                        ),
                                                                                        InkWell(
                                                                                          onTap: () {
                                                                                            Navigator.pop(context);
                                                                                            Navigator.pushNamed(context, '/report', arguments: {
                                                                                              'type': 2,
                                                                                              'targetIndex': recentlyReplyData[index]['reply_index'],
                                                                                            });
                                                                                          },
                                                                                          child: Container(
                                                                                            width: MediaQuery.of(context).size.width,
                                                                                            height: 50.0,
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                                                                            alignment: Alignment.centerLeft,
                                                                                            child: CustomTextBuilder(
                                                                                              text: '신고하기',
                                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                                              fontSize: 16.0.sp,
                                                                                              fontWeight: FontWeight.w400,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              });
                                                                        }
                                                                      },
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                20.0,
                                                                            vertical:
                                                                                13.0),
                                                                        child:
                                                                            SvgAssets(
                                                                          image:
                                                                              'assets/icon/more_horizontal.svg',
                                                                          color:
                                                                              ColorsConfig().textBlack2(),
                                                                          width:
                                                                              18.0,
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              13.0),
                                                                    ),
                                                            ],
                                                          ),
                                                          Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 6.0,
                                                                    bottom:
                                                                        10.0,
                                                                    right:
                                                                        20.0),
                                                            child: recentlyReplyData[
                                                                            index]
                                                                        [
                                                                        'type'] ==
                                                                    0
                                                                ? CustomTextBuilder(
                                                                    text:
                                                                        '${recentlyReplyData[index]['message']}',
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textWhite1(),
                                                                    fontSize:
                                                                        16.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  )
                                                                : Image(
                                                                    image:
                                                                        NetworkImage(
                                                                      recentlyReplyData[
                                                                              index]
                                                                          [
                                                                          'gif'],
                                                                    ),
                                                                    filterQuality:
                                                                        FilterQuality
                                                                            .high,
                                                                  ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const SizedBox(width: 35.0),
                                                  // 좋아요
                                                  MaterialButton(
                                                    onPressed: () async {
                                                      final _prefs =
                                                          await SharedPreferences
                                                              .getInstance();

                                                      if (recentlyReplyData[
                                                                      index]
                                                                  ['isLike'] ==
                                                              null ||
                                                          recentlyReplyData[
                                                                      index]
                                                                  ['isLike'] ==
                                                              false) {
                                                        AddReplyLikeDataAPI()
                                                            .addReplyLike(
                                                          accesToken:
                                                              _prefs.getString(
                                                                  'AccessToken')!,
                                                          replyIndex:
                                                              recentlyReplyData[
                                                                      index][
                                                                  'reply_index'],
                                                        )
                                                            .then((_v) {
                                                          if (_v.result[
                                                                  'status'] ==
                                                              10720) {
                                                            setState(() {
                                                              recentlyReplyData[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  true;
                                                              recentlyReplyData[
                                                                      index]
                                                                  ['like']++;
                                                            });
                                                          }
                                                        });
                                                      } else {
                                                        DeleteReplyLikeDataAPI()
                                                            .deleteReplyLike(
                                                          accesToken:
                                                              _prefs.getString(
                                                                  'AccessToken')!,
                                                          replyIndex:
                                                              recentlyReplyData[
                                                                      index][
                                                                  'reply_index'],
                                                        )
                                                            .then((_v) {
                                                          if (_v.result[
                                                                  'status'] ==
                                                              10725) {
                                                            setState(() {
                                                              timeLineReplyData[
                                                                          index]
                                                                      [
                                                                      'isLike'] =
                                                                  false;
                                                              timeLineReplyData[
                                                                      index]
                                                                  ['like']--;
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        recentlyReplyData[index]
                                                                    [
                                                                    'isLike'] ==
                                                                true
                                                            ? SvgAssets(
                                                                image:
                                                                    'assets/icon/like.svg',
                                                                color: ColorsConfig()
                                                                    .primary(),
                                                                width: 18.0,
                                                                height: 18.0,
                                                              )
                                                            : SvgAssets(
                                                                image:
                                                                    'assets/icon/like.svg',
                                                                color: ColorsConfig()
                                                                    .textBlack2(),
                                                                width: 18.0,
                                                                height: 18.0,
                                                              ),
                                                        const SizedBox(
                                                            width: 6.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat.format(
                                                              recentlyReplyData[
                                                                      index]
                                                                  ['like']),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack2(),
                                                          fontSize: 12.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // 댓글
                                                  MaterialButton(
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                          context,
                                                          '/sub_reply_detail',
                                                          arguments: {
                                                            'sub_reply':
                                                                recentlyReplyData[
                                                                    index],
                                                            'type': 'recently',
                                                            'post_index': widget
                                                                .postIndex,
                                                          });
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SvgAssets(
                                                          image:
                                                              'assets/icon/reply.svg',
                                                          color: ColorsConfig()
                                                              .textBlack2(),
                                                          width: 18.0,
                                                          height: 18.0,
                                                        ),
                                                        const SizedBox(
                                                            width: 6.0),
                                                        CustomTextBuilder(
                                                          text: numberFormat.format(
                                                              recentlyReplyData[
                                                                          index]
                                                                      ['child']
                                                                  .length),
                                                          fontColor:
                                                              ColorsConfig()
                                                                  .textBlack2(),
                                                          fontSize: 12.0.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 대댓글 영역
                                        InkWell(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, '/sub_reply_detail',
                                                arguments: {
                                                  'sub_reply':
                                                      recentlyReplyData[index],
                                                  'type': 'recently',
                                                  'post_index':
                                                      widget.postIndex,
                                                });
                                          },
                                          child: Column(
                                            children: List.generate(
                                                useSort
                                                    ? recentlyReplyData[index]
                                                                    ['child']
                                                                .length <
                                                            3
                                                        ? recentlyReplyData[
                                                                index]['child']
                                                            .length
                                                        : 3
                                                    : 0, (subIndex) {
                                              return Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        33.0, 13.0, 20.0, 0.0),
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig()
                                                          .background(),
                                                      border: Border(
                                                        top: BorderSide(
                                                          width: 0.5,
                                                          color: ColorsConfig()
                                                              .border1(),
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        // 프로필 이미지, 닉네임, 시간, 더보기 버튼
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Container(
                                                                  width: 35.0,
                                                                  height: 35.0,
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              8.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: ColorsConfig()
                                                                        .userIconBackground(),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            17.5),
                                                                    image:
                                                                        DecorationImage(
                                                                      image:
                                                                          NetworkImage(
                                                                        recentlyReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'avatar'],
                                                                        scale:
                                                                            7.0,
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
                                                              ],
                                                            ),
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width -
                                                                  96.0,
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          Container(
                                                                            margin:
                                                                                const EdgeInsets.only(right: 6.0),
                                                                            child:
                                                                                CustomTextBuilder(
                                                                              text: recentlyReplyData[index]['child'][subIndex]['parent_nick'],
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                          ),
                                                                          CustomTextBuilder(
                                                                            text:
                                                                                DateCalculatorWrapper().daysCalculator(recentlyReplyData[index]['child'][subIndex]['reg_dt']),
                                                                            fontColor:
                                                                                ColorsConfig.defaultGray,
                                                                            fontSize:
                                                                                14.0.sp,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            height:
                                                                                1.5,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      recentlyReplyData[index]['child'][subIndex]['message'] !=
                                                                              '삭제 된 메시지입니다.'
                                                                          ? Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 13.0),
                                                                              child: SvgAssets(
                                                                                image: 'assets/icon/more_horizontal.svg',
                                                                                color: ColorsConfig().textBlack2(),
                                                                                width: 18.0,
                                                                              ),
                                                                            )
                                                                          : Container(
                                                                              padding: const EdgeInsets.symmetric(vertical: 13.0),
                                                                            ),
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            6.0,
                                                                        bottom:
                                                                            10.0),
                                                                    child: recentlyReplyData[index]['child'][subIndex]['type'] ==
                                                                            0
                                                                        ? Text
                                                                            .rich(
                                                                            TextSpan(
                                                                              children: <TextSpan>[
                                                                                TextSpan(
                                                                                  text: '[${recentlyReplyData[index]['child'][subIndex]['parent_nick']} > ${recentlyReplyData[index]['child'][subIndex]['child_nick']}]',
                                                                                  style: TextStyle(
                                                                                    color: ColorsConfig().textBlack2(),
                                                                                    fontSize: 16.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                                const TextSpan(
                                                                                  text: ' ',
                                                                                ),
                                                                                TextSpan(
                                                                                  text: recentlyReplyData[index]['child'][subIndex]['message'],
                                                                                  style: TextStyle(
                                                                                    color: ColorsConfig().textWhite1(),
                                                                                    fontSize: 16.0.sp,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          )
                                                                        : Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              CustomTextBuilder(
                                                                                text: '[${recentlyReplyData[index]['child'][subIndex]['parent_nick']} > ${recentlyReplyData[index]['child'][subIndex]['child_nick']}]',
                                                                                style: TextStyle(
                                                                                  color: ColorsConfig().textBlack2(),
                                                                                  fontSize: 16.0.sp,
                                                                                  fontWeight: FontWeight.w400,
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Image(
                                                                                image: NetworkImage(
                                                                                  recentlyReplyData[index]['child'][subIndex]['gif'],
                                                                                ),
                                                                                filterQuality: FilterQuality.high,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const SizedBox(
                                                                width: 15.0),
                                                            // 좋아요
                                                            MaterialButton(
                                                              onPressed:
                                                                  () async {
                                                                final _prefs =
                                                                    await SharedPreferences
                                                                        .getInstance();

                                                                if (recentlyReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'isLike'] ==
                                                                        null ||
                                                                    recentlyReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'isLike'] ==
                                                                        false) {
                                                                  AddReplyLikeDataAPI()
                                                                      .addReplyLike(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    replyIndex: recentlyReplyData[index]['child']
                                                                            [
                                                                            subIndex]
                                                                        [
                                                                        'reply_index'],
                                                                  )
                                                                      .then(
                                                                          (_v) {
                                                                    if (_v.result[
                                                                            'status'] ==
                                                                        10720) {
                                                                      setState(
                                                                          () {
                                                                        recentlyReplyData[index]['child'][subIndex]['isLike'] =
                                                                            true;
                                                                        recentlyReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'like']++;
                                                                      });
                                                                    }
                                                                  });
                                                                } else {
                                                                  DeleteReplyLikeDataAPI()
                                                                      .deleteReplyLike(
                                                                    accesToken:
                                                                        _prefs.getString(
                                                                            'AccessToken')!,
                                                                    replyIndex: recentlyReplyData[index]['child']
                                                                            [
                                                                            subIndex]
                                                                        [
                                                                        'reply_index'],
                                                                  )
                                                                      .then(
                                                                          (_v) {
                                                                    if (_v.result[
                                                                            'status'] ==
                                                                        10725) {
                                                                      setState(
                                                                          () {
                                                                        recentlyReplyData[index]['child'][subIndex]['isLike'] =
                                                                            false;
                                                                        recentlyReplyData[index]['child'][subIndex]
                                                                            [
                                                                            'like']--;
                                                                      });
                                                                    }
                                                                  });
                                                                }
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  recentlyReplyData[index]['child'][subIndex]
                                                                              [
                                                                              'isLike'] ==
                                                                          true
                                                                      ? SvgAssets(
                                                                          image:
                                                                              'assets/icon/like.svg',
                                                                          color:
                                                                              ColorsConfig().primary(),
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                        )
                                                                      : SvgAssets(
                                                                          image:
                                                                              'assets/icon/like.svg',
                                                                          color:
                                                                              ColorsConfig().textBlack2(),
                                                                          width:
                                                                              18.0,
                                                                          height:
                                                                              18.0,
                                                                        ),
                                                                  const SizedBox(
                                                                      width:
                                                                          6.0),
                                                                  CustomTextBuilder(
                                                                    text: numberFormat.format(recentlyReplyData[index]['child']
                                                                            [
                                                                            subIndex]
                                                                        [
                                                                        'like']),
                                                                    fontColor:
                                                                        ColorsConfig()
                                                                            .textBlack2(),
                                                                    fontSize:
                                                                        12.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // 댓글
                                                            MaterialButton(
                                                              onPressed: () {
                                                                Navigator.pushNamed(
                                                                    context,
                                                                    '/sub_reply_detail',
                                                                    arguments: {
                                                                      'sub_reply':
                                                                          recentlyReplyData[
                                                                              index],
                                                                      'type':
                                                                          'recently',
                                                                      'post_index':
                                                                          widget
                                                                              .postIndex,
                                                                    });
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  SvgAssets(
                                                                    image:
                                                                        'assets/icon/reply.svg',
                                                                    color: ColorsConfig()
                                                                        .textBlack2(),
                                                                    width: 18.0,
                                                                    height:
                                                                        18.0,
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          6.0),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                )
                              : Container(),
                          const SizedBox(height: 80.0),
                        ],
                      ),
                    ),
                    // 댓글달기
                    replyInputWidget(),
                  ],
                ),
              )
            : Container(),
      ),
    );
  }

  Widget replyInputWidget() {
    for (int i = 0; i < useReplyChange.length; i++) {
      if (useReplyChange[i] == true) {
        return Container();
      }
    }
    return Positioned(
      bottom: 0.0,
      width: MediaQuery.of(context).size.width,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: _textFocusNode.hasFocus ? 50.0 : 70.0,
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        decoration: BoxDecoration(
          color: ColorsConfig().subBackground1(),
          border: Border(
            top: BorderSide(
              width: 0.5,
              color: ColorsConfig().border1(),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsConfig()
                  .colorPicker(color: ColorsConfig.defaultBlack, opacity: 0.11),
              blurRadius: 16.0,
              offset: const Offset(0.0, -3.0),
            ),
          ],
        ),
        child: TextFormField(
          controller: _textController,
          focusNode: _textFocusNode,
          keyboardType: TextInputType.text,
          maxLines: null,
          cursorColor: ColorsConfig().primary(),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            hintText: '댓글을 입력해주세요.',
            hintStyle: TextStyle(
              color: ColorsConfig().textBlack2(),
              fontSize: 14.0.sp,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: InkWell(
              onTap: () {
                getTenorGif().then((value) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: ColorsConfig().background(),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                    ),
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      var _next = value['next'];
                      var _gifs = value['media'];
                      return StatefulBuilder(
                        builder: (context, state) {
                          gifScrollController.addListener(() {
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();

                            _debounce = Timer(const Duration(milliseconds: 150),
                                () async {
                              if (gifScrollController.position.pixels >=
                                  gifScrollController.position.maxScrollExtent -
                                      900.0) {
                                getTenorGif(
                                        search: gifSearchController.text,
                                        useNext:
                                            gifSearchController.text.isEmpty
                                                ? _next
                                                : 20)
                                    .then((_value) {
                                  state(() {
                                    _next = _value['next'];

                                    for (var tenorResult in _value['media']) {
                                      _gifs.add(tenorResult);
                                    }
                                  });
                                });
                              }
                            });
                          });

                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height / 1.2,
                            child: Column(
                              children: [
                                Container(
                                  height: 127.0.h,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 18.3.r, vertical: 22.8.r),
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().background(),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12.0),
                                      topRight: Radius.circular(12.0),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CustomTextBuilder(
                                                  text: 'GIF 선택',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 16.0.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                SizedBox(width: 20.0.w),
                                                SvgAssets(
                                                  image:
                                                      'assets/icon/arrow_down.svg',
                                                  color: ColorsConfig()
                                                      .textWhite1(),
                                                  width: 16.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: CustomTextBuilder(
                                              text: '완료',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 34.0.h,
                                        child: TextFormField(
                                          controller: gifSearchController,
                                          focusNode: gifSearchFocusNode,
                                          keyboardType: TextInputType.text,
                                          onFieldSubmitted: (_str) {
                                            getTenorGif(search: _str)
                                                .then((_value) {
                                              // 검색시 스크롤 최상단으로 돌려줌
                                              gifScrollController.jumpTo(0.0);
                                              // 검색어 초기화
                                              state(() {
                                                // gif 데이터 초기화
                                                _gifs.clear();
                                                // 다음 스크롤링을 위한 데이터
                                                _next = _value['next'];

                                                // gif 리스트를 담아줌
                                                for (var tenorResult
                                                    in _value['media']) {
                                                  _gifs.add(tenorResult);
                                                }
                                              });
                                            });
                                          },
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 9.0),
                                            filled: true,
                                            fillColor: ColorsConfig()
                                                .subBackgroundBlack(),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig()
                                                    .subBackgroundBlack(),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig()
                                                    .subBackgroundBlack(),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig()
                                                    .subBackgroundBlack(),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                            ),
                                            hintText: 'GIF 검색...',
                                            hintStyle: TextStyle(
                                              color:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 14.0.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            prefixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 9.0),
                                                  child: SvgAssets(
                                                    image:
                                                        'assets/icon/search.svg',
                                                    color: ColorsConfig()
                                                        .textBlack2(),
                                                    width: 16.0,
                                                    height: 16.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: ColorsConfig().textWhite1(),
                                            fontSize: 14.0.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          onChanged: (value) {},
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: GridView.builder(
                                    controller: gifScrollController,
                                    itemCount: _gifs.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, // 한개의 행에 보여줄 item 개수
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                    ),
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () async {
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          setState(() {
                                            AddReplyDataAPI()
                                                .addReply(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              type: 1,
                                              postIndex: widget.postIndex,
                                              gif: _gifs[index],
                                            )
                                                .then((value) {
                                              setState(() {
                                                timeLineReplyData
                                                    .add(value.result);
                                                recentlyReplyData
                                                    .add(value.result);
                                                useReplyChange.add(false);
                                                _textFocusNode.unfocus();
                                                _textController.clear();
                                                _scrollController.jumpTo(
                                                    _scrollController.position
                                                        .maxScrollExtent);
                                                postDetailData['reply']++;
                                                replyChangeControllers.add({
                                                  "controller":
                                                      TextEditingController(),
                                                  "focus_node": FocusNode(),
                                                  "hasText": true,
                                                });
                                              });
                                            });
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: ColorsConfig().textBlack2(),
                                            image: DecorationImage(
                                                image: NetworkImage(
                                                    '${_gifs[index]}'),
                                                fit: BoxFit.cover),
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
                    },
                  );
                }).then((value) {
                  gifSearchFocusNode.unfocus();
                  gifSearchController.clear();
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 15.0),
                    child: SvgAssets(
                      image: 'assets/icon/gif.svg',
                      color: ColorsConfig().textBlack2(),
                      width: 20.0,
                      height: 20.0,
                    ),
                  ),
                ],
              ),
            ),
            suffixIcon: TextButton(
              onPressed: () async {
                final _prefs = await SharedPreferences.getInstance();

                if (_textController.text.trim().isNotEmpty) {
                  AddReplyDataAPI()
                      .addReply(
                    accesToken: _prefs.getString('AccessToken')!,
                    type: 0,
                    postIndex: widget.postIndex,
                    message: _textController.text,
                  )
                      .then((value) {
                    setState(() {
                      timeLineReplyData.add(value.result);
                      recentlyReplyData.add(value.result);
                      useReplyChange.add(false);
                      replyChangeControllers.add({
                        "controller": TextEditingController(),
                        "focus_node": FocusNode(),
                        "hasText": true,
                      });
                      _textFocusNode.unfocus();
                      _textController.clear();
                      _scrollController
                          .jumpTo(_scrollController.position.maxScrollExtent);
                      postDetailData['reply']++;
                    });
                  });
                }
              },
              child: CustomTextBuilder(
                text: '등록',
                fontColor: replySendButtonColor,
                fontSize: 14.0.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          style: TextStyle(
            color: ColorsConfig().textWhite1(),
            fontSize: 14.0.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
