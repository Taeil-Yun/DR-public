import 'dart:async';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/tenor/tenor.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/api/reply/reply_add.dart';
import 'package:DRPublic/api/reply/reply_change.dart';
import 'package:DRPublic/api/reply/reply_delete.dart';
import 'package:DRPublic/api/reply/reply_like_add.dart';
import 'package:DRPublic/api/reply/reply_like_delete.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class SubReplyDetailScreen extends StatefulWidget {
  const SubReplyDetailScreen({Key? key}) : super(key: key);

  @override
  State<SubReplyDetailScreen> createState() => _SubReplyDetailScreenState();
}

class _SubReplyDetailScreenState extends State<SubReplyDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController gifSearchController = TextEditingController();
  final FocusNode gifSearchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController gifScrollController = ScrollController();

  var numberFormat = NumberFormat('###,###,###,###');

  Timer? _debounce;

  int postIndex = 0;
  int parentUserIndex = 0;
  int? selectedUserIndex;

  Color replySendButtonColor = ColorsConfig.transparent;

  Map<String, dynamic> getSubReplyList = {};

  List<bool> useReplyChange = [];

  List<Map<String, dynamic>> replyChangeControllers = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setState(() {
        getSubReplyList = RouteGetArguments().getArgs(context)['sub_reply'];
        postIndex = RouteGetArguments().getArgs(context)['post_index'];

        if (RouteGetArguments().getArgs(context)['type'] == 'timeLine') {
          for (int i = 0; i < getSubReplyList['child'].length; i++) {
            Map<String, dynamic> _ctlToMap = {
              "controller": TextEditingController(),
              "focus_node": FocusNode(),
              "hasText": true,
            };
            replyChangeControllers.add(_ctlToMap);
            useReplyChange.add(false);
          }
        } else {}
      });
    });

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
    gifSearchController.dispose();
    gifSearchFocusNode.dispose();
    _scrollController.dispose();
    gifScrollController.dispose();

    super.dispose();
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
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          backgroundColor: ColorsConfig().subBackground1(),
          leading: DRAppBarLeading(
            press: () => Navigator.pop(context),
          ),
          title: const DRAppBarTitle(
            title: '대댓글',
          ),
        ),
        body: getSubReplyList.isNotEmpty
            ? Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 35.0),
                      color: ColorsConfig().background(),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: getSubReplyList['child'].length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              padding: const EdgeInsets.only(top: 13.0),
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
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
                                    padding: const EdgeInsets.only(left: 20.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (getSubReplyList['isMe']) {
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
                                                        getSubReplyList[
                                                            'user_index'],
                                                    'user_nickname':
                                                        getSubReplyList['nick'],
                                                  });
                                            }
                                          },
                                          child: Column(
                                            children: [
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
                                                      getSubReplyList['avatar'],
                                                      scale: 7.0,
                                                    ),
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    fit: BoxFit.none,
                                                    alignment: const Alignment(
                                                        0.0, -0.3),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              63.0,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                            .only(right: 6.0),
                                                        child:
                                                            CustomTextBuilder(
                                                          text: getSubReplyList[
                                                              'parent_nick'],
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
                                                                getSubReplyList[
                                                                    'reg_dt']),
                                                        fontColor: ColorsConfig
                                                            .defaultGray,
                                                        fontSize: 14.0.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.5,
                                                      ),
                                                    ],
                                                  ),
                                                  getSubReplyList['message'] !=
                                                          '삭제 된 메시지입니다.'
                                                      ? InkWell(
                                                          onTap: () async {
                                                            final _prefs =
                                                                await SharedPreferences
                                                                    .getInstance();

                                                            if (getSubReplyList[
                                                                'isMe']) {
                                                              showModalBottomSheet(
                                                                  context:
                                                                      context,
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
                                                                          context) {
                                                                    return SafeArea(
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            const BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(12.0),
                                                                            topRight:
                                                                                Radius.circular(12.0),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
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
                                                                                text: '대댓글',
                                                                                fontColor: ColorsConfig().textWhite1(),
                                                                                fontSize: 18.0.sp,
                                                                                fontWeight: FontWeight.w600,
                                                                              ),
                                                                            ),
                                                                            getSubReplyList['type'] == 0
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
                                                                if (_val[
                                                                        'select'] ==
                                                                    1) {
                                                                  setState(() {
                                                                    useReplyChange[
                                                                            index] =
                                                                        true;
                                                                    getSubReplyList['controller']
                                                                            .text =
                                                                        getSubReplyList[
                                                                            'message'];
                                                                  });
                                                                } else if (_val[
                                                                        'select'] ==
                                                                    2) {
                                                                  DeleteReplyDataAPI()
                                                                      .deleteReply(
                                                                          accesToken: _prefs.getString(
                                                                              'AccessToken')!,
                                                                          replyIndex: getSubReplyList[
                                                                              'reply_index'],
                                                                          isParent:
                                                                              1)
                                                                      .then(
                                                                          (_v) {
                                                                    setState(
                                                                        () {
                                                                      getSubReplyList[
                                                                          'type'] = 0;
                                                                      getSubReplyList[
                                                                              'message'] =
                                                                          '삭제 된 메시지입니다.';
                                                                    });
                                                                  });
                                                                }
                                                              });
                                                            } else {
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
                                                                          context) {
                                                                    return SafeArea(
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            const BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(12.0),
                                                                            topRight:
                                                                                Radius.circular(12.0),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
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
                                                                                text: '${getSubReplyList['parent_nick']}',
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
                                                                                  'targetIndex': getSubReplyList['reply_index'],
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
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        20.0,
                                                                    vertical:
                                                                        13.0),
                                                            child: SvgAssets(
                                                              image:
                                                                  'assets/icon/more_horizontal.svg',
                                                              color: ColorsConfig()
                                                                  .textBlack2(),
                                                              width: 18.0,
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      13.0),
                                                        ),
                                                ],
                                              ),
                                              useReplyChange.isNotEmpty
                                                  ? !useReplyChange[index]
                                                      ? Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 6.0,
                                                                  bottom: 10.0,
                                                                  right: 20.0),
                                                          child: getSubReplyList[
                                                                      'type'] ==
                                                                  0
                                                              ? CustomTextBuilder(
                                                                  text:
                                                                      '${getSubReplyList['message']}',
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
                                                                    getSubReplyList[
                                                                        'gif'],
                                                                  ),
                                                                  filterQuality:
                                                                      FilterQuality
                                                                          .high,
                                                                ),
                                                        )
                                                      : Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 10.0),
                                                          child: Column(
                                                            children: [
                                                              Container(
                                                                height: 110.0,
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            15.0),
                                                                child:
                                                                    TextFormField(
                                                                  controller: replyChangeControllers[
                                                                          index]
                                                                      [
                                                                      'controller'],
                                                                  focusNode: replyChangeControllers[
                                                                          index]
                                                                      [
                                                                      'focus_node'],
                                                                  expands: true,
                                                                  maxLines:
                                                                      null,
                                                                  autofocus:
                                                                      true,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    isCollapsed:
                                                                        true,
                                                                    contentPadding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            11.0,
                                                                        vertical:
                                                                            8.0),
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        width:
                                                                            0.5,
                                                                        color: ColorsConfig()
                                                                            .primary(),
                                                                      ),
                                                                    ),
                                                                    focusedBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        width:
                                                                            0.5,
                                                                        color: ColorsConfig()
                                                                            .primary(),
                                                                      ),
                                                                    ),
                                                                    enabledBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        width:
                                                                            0.5,
                                                                        color: ColorsConfig()
                                                                            .primary(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  style:
                                                                      TextStyle(
                                                                    color: ColorsConfig()
                                                                        .textWhite1(),
                                                                    fontSize:
                                                                        14.0.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                  onChanged:
                                                                      (text) {
                                                                    setState(
                                                                        () {
                                                                      if (replyChangeControllers[index]
                                                                              [
                                                                              'controller']
                                                                          .text
                                                                          .isEmpty) {
                                                                        replyChangeControllers[index]['hasText'] =
                                                                            false;
                                                                      } else {
                                                                        replyChangeControllers[index]['hasText'] =
                                                                            true;
                                                                      }
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(
                                                                          () {
                                                                        useReplyChange[index] =
                                                                            false;
                                                                      });
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              13.5,
                                                                          vertical:
                                                                              8.5),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: ColorsConfig()
                                                                            .textWhite1(),
                                                                        border:
                                                                            Border.all(
                                                                          width:
                                                                              0.5,
                                                                          color:
                                                                              ColorsConfig().border1(),
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      child: CustomTextBuilder(
                                                                          text:
                                                                              '취소',
                                                                          fontColor: ColorsConfig()
                                                                              .background(),
                                                                          fontSize: 12.0
                                                                              .sp,
                                                                          fontWeight:
                                                                              FontWeight.w700),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          8.0),
                                                                  InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      final _prefs =
                                                                          await SharedPreferences
                                                                              .getInstance();

                                                                      if (replyChangeControllers[
                                                                              index]
                                                                          [
                                                                          'hasText']) {
                                                                        if (replyChangeControllers[index]['controller']
                                                                            .toString()
                                                                            .trim()
                                                                            .isNotEmpty) {
                                                                          ChangeReplyAPI()
                                                                              .changeReply(
                                                                            accesToken:
                                                                                _prefs.getString('AccessToken')!,
                                                                            isParent:
                                                                                1,
                                                                            message:
                                                                                replyChangeControllers[index]['controller'].text,
                                                                            replyIndex:
                                                                                getSubReplyList['reply_index'],
                                                                          )
                                                                              .then((_v) {
                                                                            setState(() {
                                                                              replyChangeControllers[index]['focus_node'].unfocus();
                                                                              getSubReplyList = _v.result;
                                                                              useReplyChange[index] = false;
                                                                            });
                                                                          });
                                                                        }
                                                                      }
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              13.5,
                                                                          vertical:
                                                                              8.5),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: replyChangeControllers[index]['hasText']
                                                                            ? ColorsConfig().primary()
                                                                            : ColorsConfig().textBlack2(),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      child:
                                                                          CustomTextBuilder(
                                                                        text:
                                                                            '수정하기',
                                                                        fontColor:
                                                                            ColorsConfig().background(),
                                                                        fontSize:
                                                                            12.0.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                  : Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              top: 6.0,
                                                              bottom: 10.0,
                                                              right: 20.0),
                                                      child: getSubReplyList[
                                                                  'type'] ==
                                                              0
                                                          ? CustomTextBuilder(
                                                              text:
                                                                  '${getSubReplyList['message']}',
                                                              fontColor:
                                                                  ColorsConfig()
                                                                      .textWhite1(),
                                                              fontSize: 16.0.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            )
                                                          : Image(
                                                              image:
                                                                  NetworkImage(
                                                                getSubReplyList[
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
                                          final _prefs = await SharedPreferences
                                              .getInstance();

                                          if (getSubReplyList['isLike'] ==
                                                  null ||
                                              getSubReplyList['isLike'] ==
                                                  false) {
                                            AddReplyLikeDataAPI()
                                                .addReplyLike(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              replyIndex: getSubReplyList[
                                                  'reply_index'],
                                            )
                                                .then((_v) {
                                              if (_v.result['status'] ==
                                                  10720) {
                                                setState(() {
                                                  getSubReplyList['isLike'] =
                                                      true;
                                                  getSubReplyList['like']++;
                                                });
                                              }
                                            });
                                          } else {
                                            DeleteReplyLikeDataAPI()
                                                .deleteReplyLike(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              replyIndex: getSubReplyList[
                                                  'reply_index'],
                                            )
                                                .then((_v) {
                                              if (_v.result['status'] ==
                                                  10725) {
                                                setState(() {
                                                  getSubReplyList['isLike'] =
                                                      false;
                                                  getSubReplyList['like']--;
                                                });
                                              }
                                            });
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            getSubReplyList['isLike'] == true
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
                                            const SizedBox(width: 6.0),
                                            CustomTextBuilder(
                                              text: numberFormat.format(
                                                  getSubReplyList['like']),
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 12.0.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 댓글
                                      MaterialButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedUserIndex = index - 1;
                                            parentUserIndex =
                                                getSubReplyList['user_index'];
                                            _textFocusNode.requestFocus();
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            SvgAssets(
                                              image: 'assets/icon/reply.svg',
                                              color:
                                                  ColorsConfig().textBlack2(),
                                              width: 18.0,
                                              height: 18.0,
                                            ),
                                            const SizedBox(width: 6.0),
                                            CustomTextBuilder(
                                              text: numberFormat.format(
                                                  getSubReplyList['child']
                                                      .length),
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 12.0.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(top: 13.0),
                                decoration: BoxDecoration(
                                  color: ColorsConfig().subBackgroundBlack(),
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
                                      padding:
                                          const EdgeInsets.only(left: 33.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              if (getSubReplyList['child']
                                                  [index - 1]['isMe']) {
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
                                                          getSubReplyList[
                                                                      'child']
                                                                  [index - 1]
                                                              ['user_index'],
                                                      'user_nickname':
                                                          getSubReplyList[
                                                                      'child']
                                                                  [index - 1]
                                                              ['nick'],
                                                    });
                                              }
                                            },
                                            child: Column(
                                              children: [
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
                                                        getSubReplyList['child']
                                                                [index - 1]
                                                            ['avatar'],
                                                        scale: 7.0,
                                                      ),
                                                      filterQuality:
                                                          FilterQuality.high,
                                                      fit: BoxFit.none,
                                                      alignment:
                                                          const Alignment(
                                                              0.0, -0.3),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                76.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 6.0),
                                                          child:
                                                              CustomTextBuilder(
                                                            text: getSubReplyList[
                                                                        'child']
                                                                    [index - 1]
                                                                ['parent_nick'],
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
                                                                  getSubReplyList[
                                                                              'child']
                                                                          [
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'reg_dt']),
                                                          fontColor:
                                                              ColorsConfig
                                                                  .defaultGray,
                                                          fontSize: 14.0.sp,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          height: 1.5,
                                                        ),
                                                      ],
                                                    ),
                                                    getSubReplyList['child']
                                                                    [index - 1]
                                                                ['message'] !=
                                                            '삭제 된 메시지입니다.'
                                                        ? InkWell(
                                                            onTap: () async {
                                                              final _prefs =
                                                                  await SharedPreferences
                                                                      .getInstance();

                                                              if (getSubReplyList[
                                                                          'child']
                                                                      [
                                                                      index - 1]
                                                                  ['isMe']) {
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
                                                                            context) {
                                                                      return SafeArea(
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              const BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.only(
                                                                              topLeft: Radius.circular(12.0),
                                                                              topRight: Radius.circular(12.0),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
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
                                                                                  text: '대댓글',
                                                                                  fontColor: ColorsConfig().textWhite1(),
                                                                                  fontSize: 18.0.sp,
                                                                                  fontWeight: FontWeight.w600,
                                                                                ),
                                                                              ),
                                                                              getSubReplyList['child'][index - 1]['type'] == 0
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
                                                                  if (_val[
                                                                          'select'] ==
                                                                      1) {
                                                                    setState(
                                                                        () {
                                                                      useReplyChange[
                                                                              index] =
                                                                          true;
                                                                      replyChangeControllers[index]
                                                                              [
                                                                              'controller']
                                                                          .text = getSubReplyList[
                                                                              'child']
                                                                          [
                                                                          index -
                                                                              1]['message'];
                                                                    });
                                                                  } else if (_val[
                                                                          'select'] ==
                                                                      2) {
                                                                    DeleteReplyDataAPI()
                                                                        .deleteReply(
                                                                            accesToken: _prefs.getString(
                                                                                'AccessToken')!,
                                                                            replyIndex: getSubReplyList['child'][index - 1][
                                                                                'reply_index'],
                                                                            isParent:
                                                                                1)
                                                                        .then(
                                                                            (_v) {
                                                                      setState(
                                                                          () {
                                                                        getSubReplyList['child']
                                                                            [
                                                                            index -
                                                                                1]['type'] = 0;
                                                                        getSubReplyList['child'][index -
                                                                                1]['message'] =
                                                                            '삭제 된 메시지입니다.';
                                                                      });
                                                                    });
                                                                  }
                                                                });
                                                              } else {
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
                                                                            context) {
                                                                      return SafeArea(
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              const BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.only(
                                                                              topLeft: Radius.circular(12.0),
                                                                              topRight: Radius.circular(12.0),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
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
                                                                                  text: '${getSubReplyList['child'][index - 1]['parent_nick']}',
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
                                                                                    'targetIndex': getSubReplyList['child'][index - 1]['reply_index'],
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
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          20.0,
                                                                      vertical:
                                                                          13.0),
                                                              child: SvgAssets(
                                                                image:
                                                                    'assets/icon/more_horizontal.svg',
                                                                color: ColorsConfig()
                                                                    .textBlack2(),
                                                                width: 18.0,
                                                              ),
                                                            ),
                                                          )
                                                        : Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        13.0),
                                                          ),
                                                  ],
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 6.0,
                                                      bottom: 10.0,
                                                      right: 20.0),
                                                  child: getSubReplyList[
                                                                      'child']
                                                                  [index - 1]
                                                              ['type'] ==
                                                          0
                                                      ? Text.rich(
                                                          TextSpan(
                                                            children: <TextSpan>[
                                                              TextSpan(
                                                                text:
                                                                    '[${getSubReplyList['child'][index - 1]['parent_nick']} > ${getSubReplyList['child'][index - 1]['child_nick']}]',
                                                                style:
                                                                    TextStyle(
                                                                  color: ColorsConfig()
                                                                      .textBlack2(),
                                                                  fontSize:
                                                                      16.0.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                              const TextSpan(
                                                                text: ' ',
                                                              ),
                                                              TextSpan(
                                                                text: getSubReplyList[
                                                                            'child']
                                                                        [index -
                                                                            1]
                                                                    ['message'],
                                                                style:
                                                                    TextStyle(
                                                                  color: ColorsConfig()
                                                                      .textWhite1(),
                                                                  fontSize:
                                                                      16.0.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
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
                                                            CustomTextBuilder(
                                                              text:
                                                                  '[${getSubReplyList['child'][index - 1]['parent_nick']} > ${getSubReplyList['child'][index - 1]['child_nick']}]',
                                                              style: TextStyle(
                                                                color: ColorsConfig()
                                                                    .textBlack2(),
                                                                fontSize:
                                                                    16.0.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 10.0),
                                                            Image(
                                                              image:
                                                                  NetworkImage(
                                                                getSubReplyList[
                                                                        'child']
                                                                    [index -
                                                                        1]['gif'],
                                                              ),
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
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
                                    Row(
                                      children: [
                                        const SizedBox(width: 48.0),
                                        // 좋아요
                                        MaterialButton(
                                          onPressed: () async {
                                            final _prefs =
                                                await SharedPreferences
                                                    .getInstance();

                                            if (getSubReplyList['child']
                                                        [index - 1]['isLike'] ==
                                                    null ||
                                                getSubReplyList['child']
                                                        [index - 1]['isLike'] ==
                                                    false) {
                                              AddReplyLikeDataAPI()
                                                  .addReplyLike(
                                                accesToken: _prefs
                                                    .getString('AccessToken')!,
                                                replyIndex:
                                                    getSubReplyList['child']
                                                            [index - 1]
                                                        ['reply_index'],
                                              )
                                                  .then((_v) {
                                                if (_v.result['status'] ==
                                                    10720) {
                                                  setState(() {
                                                    getSubReplyList['child']
                                                            [index - 1]
                                                        ['isLike'] = true;
                                                    getSubReplyList['child']
                                                        [index - 1]['like']++;
                                                  });
                                                }
                                              });
                                            } else {
                                              DeleteReplyLikeDataAPI()
                                                  .deleteReplyLike(
                                                accesToken: _prefs
                                                    .getString('AccessToken')!,
                                                replyIndex:
                                                    getSubReplyList['child']
                                                            [index - 1]
                                                        ['reply_index'],
                                              )
                                                  .then((_v) {
                                                if (_v.result['status'] ==
                                                    10725) {
                                                  setState(() {
                                                    getSubReplyList['child']
                                                            [index - 1]
                                                        ['isLike'] = false;
                                                    getSubReplyList['child']
                                                        [index - 1]['like']--;
                                                  });
                                                }
                                              });
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              SvgAssets(
                                                image: 'assets/icon/like.svg',
                                                color: getSubReplyList['child']
                                                                    [index - 1]
                                                                ['isLike'] !=
                                                            null &&
                                                        getSubReplyList['child']
                                                                [index - 1]
                                                            ['isLike']
                                                    ? ColorsConfig().primary()
                                                    : ColorsConfig()
                                                        .textBlack1(),
                                                width: 18.0,
                                                height: 18.0,
                                              ),
                                              const SizedBox(width: 6.0),
                                              CustomTextBuilder(
                                                text: numberFormat.format(
                                                    getSubReplyList['child']
                                                        [index - 1]['like']),
                                                fontColor:
                                                    ColorsConfig().textBlack2(),
                                                fontSize: 12.0.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 댓글
                                        MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedUserIndex = index - 1;
                                              parentUserIndex =
                                                  getSubReplyList['child']
                                                      [index - 1]['user_index'];
                                              _textFocusNode.requestFocus();
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              SvgAssets(
                                                image: 'assets/icon/reply.svg',
                                                color:
                                                    ColorsConfig().textBlack2(),
                                                width: 18.0,
                                                height: 18.0,
                                              ),
                                              const SizedBox(width: 6.0),
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
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 0.0,
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: _textFocusNode.hasFocus ? 50.0 : 70.0,
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig().background(),
                          boxShadow: [
                            BoxShadow(
                              color: ColorsConfig().colorPicker(
                                  color: ColorsConfig.defaultBlack,
                                  opacity: 0.11),
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
                          autofocus: true,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
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
                                    backgroundColor:
                                        ColorsConfig().background(),
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

                                            _debounce = Timer(
                                                const Duration(
                                                    milliseconds: 150),
                                                () async {
                                              if (gifScrollController
                                                      .position.pixels >=
                                                  gifScrollController.position
                                                          .maxScrollExtent -
                                                      900.0) {
                                                getTenorGif(
                                                        search:
                                                            gifSearchController
                                                                .text,
                                                        useNext:
                                                            gifSearchController
                                                                    .text
                                                                    .isEmpty
                                                                ? _next
                                                                : 20)
                                                    .then((_value) {
                                                  state(() {
                                                    _next = _value['next'];

                                                    for (var tenorResult
                                                        in _value['media']) {
                                                      _gifs.add(tenorResult);
                                                    }
                                                  });
                                                });
                                              }
                                            });
                                          });

                                          return SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                1.2,
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: 127.0.h,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 18.3.r,
                                                      vertical: 22.8.r),
                                                  decoration: BoxDecoration(
                                                    color: ColorsConfig()
                                                        .background(),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(12.0),
                                                      topRight:
                                                          Radius.circular(12.0),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                CustomTextBuilder(
                                                                  text:
                                                                      'GIF 선택',
                                                                  fontColor:
                                                                      ColorsConfig()
                                                                          .textWhite1(),
                                                                  fontSize:
                                                                      16.0.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                                SizedBox(
                                                                    width:
                                                                        20.0.w),
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
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child:
                                                                CustomTextBuilder(
                                                              text: '완료',
                                                              fontColor:
                                                                  ColorsConfig()
                                                                      .textWhite1(),
                                                              fontSize: 16.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height: 34.0.h,
                                                        child: TextFormField(
                                                          controller:
                                                              gifSearchController,
                                                          focusNode:
                                                              gifSearchFocusNode,
                                                          keyboardType:
                                                              TextInputType
                                                                  .text,
                                                          onFieldSubmitted:
                                                              (_str) {
                                                            getTenorGif(
                                                                    search:
                                                                        _str)
                                                                .then((_value) {
                                                              // 검색시 스크롤 최상단으로 돌려줌
                                                              gifScrollController
                                                                  .jumpTo(0.0);
                                                              // 검색어 초기화
                                                              state(() {
                                                                // gif 데이터 초기화
                                                                _gifs.clear();
                                                                // 다음 스크롤링을 위한 데이터
                                                                _next = _value[
                                                                    'next'];

                                                                // gif 리스트를 담아줌
                                                                for (var tenorResult
                                                                    in _value[
                                                                        'media']) {
                                                                  _gifs.add(
                                                                      tenorResult);
                                                                }
                                                              });
                                                            });
                                                          },
                                                          decoration:
                                                              InputDecoration(
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        9.0),
                                                            filled: true,
                                                            fillColor:
                                                                ColorsConfig()
                                                                    .subBackgroundBlack(),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                width: 0.5,
                                                                color: ColorsConfig()
                                                                    .subBackgroundBlack(),
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          100.0),
                                                            ),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                width: 0.5,
                                                                color: ColorsConfig()
                                                                    .subBackgroundBlack(),
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          100.0),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                width: 0.5,
                                                                color: ColorsConfig()
                                                                    .subBackgroundBlack(),
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          100.0),
                                                            ),
                                                            hintText:
                                                                'GIF 검색...',
                                                            hintStyle:
                                                                TextStyle(
                                                              color: ColorsConfig()
                                                                  .textBlack2(),
                                                              fontSize: 14.0.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
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
                                                                              9.0),
                                                                  child:
                                                                      SvgAssets(
                                                                    image:
                                                                        'assets/icon/search.svg',
                                                                    color: ColorsConfig()
                                                                        .textBlack2(),
                                                                    width: 16.0,
                                                                    height:
                                                                        16.0,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          style: TextStyle(
                                                            color: ColorsConfig()
                                                                .textWhite1(),
                                                            fontSize: 14.0.sp,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          onChanged: (value) {},
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: GridView.builder(
                                                    controller:
                                                        gifScrollController,
                                                    itemCount: _gifs.length,
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount:
                                                          2, // 한개의 행에 보여줄 item 개수
                                                      crossAxisSpacing: 8.0,
                                                      mainAxisSpacing: 8.0,
                                                    ),
                                                    itemBuilder:
                                                        (context, index) {
                                                      return InkWell(
                                                        onTap: () async {
                                                          final _prefs =
                                                              await SharedPreferences
                                                                  .getInstance();

                                                          setState(() {
                                                            AddReplyDataAPI()
                                                                .addReply(
                                                              accesToken: _prefs
                                                                  .getString(
                                                                      'AccessToken')!,
                                                              type: 1,
                                                              postIndex:
                                                                  postIndex,
                                                              replyIndex: selectedUserIndex !=
                                                                      null
                                                                  ? getSubReplyList[
                                                                              'child']
                                                                          [
                                                                          selectedUserIndex]
                                                                      [
                                                                      'reply_index']
                                                                  : getSubReplyList[
                                                                      'reply_index'],
                                                              parentUserIndex:
                                                                  parentUserIndex ==
                                                                          0
                                                                      ? getSubReplyList[
                                                                          'user_index']
                                                                      : parentUserIndex,
                                                              topIndex:
                                                                  getSubReplyList[
                                                                      'reply_index'],
                                                              gif: _gifs[index],
                                                            )
                                                                .then((value) {
                                                              setState(() {
                                                                getSubReplyList[
                                                                        'child']
                                                                    .add(value
                                                                        .result);
                                                                _textFocusNode
                                                                    .unfocus();
                                                                _textController
                                                                    .clear();
                                                                _scrollController.jumpTo(
                                                                    _scrollController
                                                                        .position
                                                                        .maxScrollExtent);
                                                              });
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ColorsConfig()
                                                                .textBlack2(),
                                                            image:
                                                                DecorationImage(
                                                              image: NetworkImage(
                                                                  '${_gifs[index]}'),
                                                              fit: BoxFit.cover,
                                                            ),
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
                                    padding: const EdgeInsets.only(
                                        left: 20.0, right: 15.0),
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
                                final _prefs =
                                    await SharedPreferences.getInstance();

                                if (_textController.text.trim().isNotEmpty) {
                                  AddReplyDataAPI()
                                      .addReply(
                                    accesToken:
                                        _prefs.getString('AccessToken')!,
                                    type: 0,
                                    postIndex: postIndex,
                                    replyIndex: selectedUserIndex != null
                                        ? getSubReplyList['child']
                                            [selectedUserIndex]['reply_index']
                                        : getSubReplyList['reply_index'],
                                    parentUserIndex: parentUserIndex == 0
                                        ? getSubReplyList['user_index']
                                        : parentUserIndex,
                                    topIndex: getSubReplyList['reply_index'],
                                    message: _textController.text,
                                  )
                                      .then((value) {
                                    setState(() {
                                      getSubReplyList['child']
                                          .add(value.result);
                                      useReplyChange.add(false);
                                      _textFocusNode.unfocus();
                                      _textController.clear();
                                      _scrollController.jumpTo(_scrollController
                                          .position.maxScrollExtent);
                                      replyChangeControllers.add({
                                        "controller": TextEditingController(),
                                        "focus_node": FocusNode(),
                                        "hasText": true,
                                      });
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
                    ),
                  ],
                ),
              )
            : Container(),
      ),
    );
  }
}
