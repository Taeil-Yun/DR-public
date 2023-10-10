import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date/date_calculator.dart';
import 'package:DRPublic/component/image_picker/image_picker.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/api/block/add_user_block.dart';
import 'package:DRPublic/api/chatting/chatting_detail.dart';
import 'package:DRPublic/api/chatting/chatting_send.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class ChattingDetailScreen extends StatefulWidget {
  const ChattingDetailScreen({Key? key}) : super(key: key);

  @override
  State<ChattingDetailScreen> createState() => _ChattingDetailScreenState();
}

class _ChattingDetailScreenState extends State<ChattingDetailScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool inputHasFocus = false;

  int userIndex = 0;

  String userNickname = '';

  List<dynamic> chattingDatas = [];

  Color sendButtonColor = ColorsConfig().textBlack2();

  @override
  void initState() {
    _textEditingController.addListener(() {
      if (_textEditingController.text.trim().isNotEmpty) {
        setState(() => sendButtonColor = ColorsConfig().primary());
      } else {
        setState(() => sendButtonColor = ColorsConfig().textBlack2());
      }
    });

    apiInitialize();

    Future.delayed(Duration.zero, () {
      setState(() {
        userIndex = RouteGetArguments().getArgs(context)['userIndex'];
        userNickname = RouteGetArguments().getArgs(context)['nickname'];
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  double bottomPaddingSize() {
    return MediaQuery.of(context).padding.bottom;
  }

  double topPaddingWithAppBarSize() {
    return const DRAppBar().preferredSize.height +
        MediaQuery.of(context).padding.top;
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetChattingDetailDataAPI()
        .chattingData(
            accesToken: _prefs.getString('AccessToken')!,
            userIndex: RouteGetArguments().getArgs(context)['userIndex'])
        .then((value) {
      setState(() {
        chattingDatas = value.result;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        backgroundColor: ColorsConfig().subBackground1(),
        appBar: DRAppBar(
          leading: DRAppBarLeading(
            press: () => Navigator.pop(context),
          ),
          title: DRAppBarTitle(
            title: '${RouteGetArguments().getArgs(context)['nickname']}',
          ),
          actions: [
            IconButton(
              onPressed: () {
                showRoomSettingBottomSheet();
              },
              icon: Center(
                child: SvgAssets(
                  image: 'assets/icon/more_vertical.svg',
                  color: ColorsConfig().textWhite1(),
                  width: 18.0,
                  height: 18.0,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            chatDataView(),
            textInputWithSendView(),
          ],
        ),
      ),
    );
  }

  Widget chatDataView() {
    bool keyboardFocusCheck = false;

    return Expanded(
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: ColorsConfig().background(),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          itemCount: chattingDatas.length,
          itemBuilder: (context, index) {
            // 키보드가 올라왔을 때 화면 밀어 올려주는 코드
            if (!keyboardFocusCheck) {
              if (inputHasFocus) {
                _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 10),
                    curve: Curves.easeIn);
                keyboardFocusCheck = true;
              } else {
                keyboardFocusCheck = false;
              }
            }

            // 같은 날짜에 보냈을 때 처리코드
            bool isSameDate = true;
            if (index == 0) {
              isSameDate = false;
            } else {
              if (DateFormat('yyyy년 MM월 dd일 E', 'ko_KR').format(
                      DateTime.parse(chattingDatas[index]['last_send_date'])
                          .toLocal()) ==
                  DateFormat('yyyy년 MM월 dd일 E', 'ko_KR').format(
                      DateTime.parse(chattingDatas[index - 1]['last_send_date'])
                          .toLocal())) {
                isSameDate = true;
              } else {
                isSameDate = false;
              }
            }
            // 같은날짜가 아닐경우
            if (index == 0 || !(isSameDate)) {
              return Column(children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15.0),
                  child: CustomTextBuilder(
                    text: DateFormat('yyyy년 MM월 dd일 E', 'ko_KR').format(
                            DateTime.parse(
                                    chattingDatas[index]['last_send_date'])
                                .toLocal()) +
                        '요일',
                    fontColor: ColorsConfig().textBlack2(),
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                // your message
                chattingDatas[index]['owner'] == false
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 7.5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/your_profile',
                                        arguments: {
                                          'user_index': userIndex,
                                          'user_nickname': userNickname,
                                        });
                                  },
                                  child: Container(
                                    width: 35.0,
                                    height: 35.0,
                                    margin: const EdgeInsets.only(right: 12.0),
                                    decoration: BoxDecoration(
                                      color:
                                          ColorsConfig().userIconBackground(),
                                      borderRadius: BorderRadius.circular(17.5),
                                      image: DecorationImage(
                                          image: NetworkImage(
                                            RouteGetArguments()
                                                .getArgs(context)['avatar'],
                                            scale: 7.0,
                                          ),
                                          filterQuality: FilterQuality.high,
                                          fit: BoxFit.none,
                                          alignment:
                                              const Alignment(0.0, -0.3)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                chattingDatas[index]['image'] != null
                                    ? Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.4,
                                          maxHeight: 400.0,
                                        ),
                                        child: Image(
                                          image: NetworkImage(
                                            chattingDatas[index]['image'],
                                          ),
                                          filterQuality: FilterQuality.high,
                                        ),
                                      )
                                    : Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 6.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().border1(),
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8.0),
                                            bottomLeft: Radius.circular(8.0),
                                            bottomRight: Radius.circular(8.0),
                                          ),
                                        ),
                                        child: CustomTextBuilder(
                                          text:
                                              '${chattingDatas[index]['message']}',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 16.0.sp,
                                          fontWeight: FontWeight.w500,
                                          textWidthBasis:
                                              TextWidthBasis.longestLine,
                                        ),
                                      ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4.0),
                                  child: CustomTextBuilder(
                                    text: DateCalculatorWrapper()
                                        .calculatorAMPM(
                                            chattingDatas[index]
                                                ['last_send_date'],
                                            useAMPM: true),
                                    fontColor: ColorsConfig().textBlack2(),
                                    fontSize: 12.0.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Container(),
                // my message
                chattingDatas[index]['owner'] == true
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 7.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                chattingDatas[index]['image'] != null
                                    ? Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.4,
                                          maxHeight: 400.0,
                                        ),
                                        child: chattingDatas[index]['image']
                                                .toString()
                                                .startsWith('https')
                                            ? Image(
                                                image: NetworkImage(
                                                  chattingDatas[index]['image'],
                                                ),
                                                filterQuality:
                                                    FilterQuality.high,
                                              )
                                            : Image(
                                                image: FileImage(File(
                                                    chattingDatas[index]
                                                        ['image'])),
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                      )
                                    : Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 6.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8.0),
                                            bottomLeft: Radius.circular(8.0),
                                            bottomRight: Radius.circular(8.0),
                                          ),
                                        ),
                                        child: CustomTextBuilder(
                                          text:
                                              '${chattingDatas[index]['message']}',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 16.0.sp,
                                          fontWeight: FontWeight.w500,
                                          textWidthBasis:
                                              TextWidthBasis.longestLine,
                                        ),
                                      ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4.0),
                                  child: CustomTextBuilder(
                                    text: DateCalculatorWrapper()
                                        .calculatorAMPM(
                                            chattingDatas[index]
                                                ['last_send_date'],
                                            useAMPM: true),
                                    fontColor: ColorsConfig().textBlack2(),
                                    fontSize: 12.0.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Container(),
              ]);
              // 같은날짜일경우
            } else {
              return Column(
                children: [
                  // your message
                  chattingDatas[index]['owner'] == false
                      ? Container(
                          margin: const EdgeInsets.symmetric(vertical: 7.5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/your_profile',
                                      arguments: {
                                        'user_index': userIndex,
                                        'user_nickname': userNickname,
                                      });
                                },
                                child: Container(
                                  width: 35.0,
                                  height: 35.0,
                                  margin: const EdgeInsets.only(right: 12.0),
                                  decoration: BoxDecoration(
                                    color: ColorsConfig().userIconBackground(),
                                    borderRadius: BorderRadius.circular(17.5),
                                    image: DecorationImage(
                                        image: NetworkImage(
                                          RouteGetArguments()
                                              .getArgs(context)['avatar'],
                                          scale: 7.0,
                                        ),
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.none,
                                        alignment: const Alignment(0.0, -0.3)),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  chattingDatas[index]['image'] != null
                                      ? Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.4,
                                            maxHeight: 400.0,
                                          ),
                                          child: Image(
                                            image: NetworkImage(
                                              chattingDatas[index]['image'],
                                            ),
                                            filterQuality: FilterQuality.high,
                                          ),
                                        )
                                      : Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 0.5,
                                              color: ColorsConfig().border1(),
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topRight: Radius.circular(8.0),
                                              bottomLeft: Radius.circular(8.0),
                                              bottomRight: Radius.circular(8.0),
                                            ),
                                          ),
                                          child: CustomTextBuilder(
                                            text:
                                                '${chattingDatas[index]['message']}',
                                            fontColor:
                                                ColorsConfig().textWhite1(),
                                            fontSize: 16.0.sp,
                                            fontWeight: FontWeight.w500,
                                            textWidthBasis:
                                                TextWidthBasis.longestLine,
                                          ),
                                        ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4.0),
                                    child: CustomTextBuilder(
                                      text: DateCalculatorWrapper()
                                          .calculatorAMPM(
                                              chattingDatas[index]
                                                  ['last_send_date'],
                                              useAMPM: true),
                                      fontColor: ColorsConfig().textBlack2(),
                                      fontSize: 12.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  // my message
                  chattingDatas[index]['owner'] == true
                      ? Container(
                          margin: const EdgeInsets.symmetric(vertical: 7.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  chattingDatas[index]['image'] != null
                                      ? Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.4,
                                            maxHeight: 400.0,
                                          ),
                                          child: chattingDatas[index]['image']
                                                  .toString()
                                                  .startsWith('https')
                                              ? Image(
                                                  image: NetworkImage(
                                                    chattingDatas[index]
                                                        ['image'],
                                                  ),
                                                  filterQuality:
                                                      FilterQuality.high,
                                                )
                                              : Image(
                                                  image: FileImage(File(
                                                      chattingDatas[index]
                                                          ['image'])),
                                                  filterQuality:
                                                      FilterQuality.high,
                                                ),
                                        )
                                      : Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 0.5,
                                              color: ColorsConfig().primary(),
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(8.0),
                                              bottomLeft: Radius.circular(8.0),
                                              bottomRight: Radius.circular(8.0),
                                            ),
                                          ),
                                          child: CustomTextBuilder(
                                            text:
                                                '${chattingDatas[index]['message']}',
                                            fontColor:
                                                ColorsConfig().textWhite1(),
                                            fontSize: 16.0.sp,
                                            fontWeight: FontWeight.w500,
                                            textWidthBasis:
                                                TextWidthBasis.longestLine,
                                          ),
                                        ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4.0),
                                    child: CustomTextBuilder(
                                      text: DateCalculatorWrapper()
                                          .calculatorAMPM(
                                              chattingDatas[index]
                                                  ['last_send_date'],
                                              useAMPM: true),
                                      fontColor: ColorsConfig().textBlack2(),
                                      fontSize: 12.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Container(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget textInputWithSendView() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 61.0,
      decoration: BoxDecoration(
        color: ColorsConfig().background(),
        border: Border(
          top: BorderSide(
            width: 0.5,
            color: ColorsConfig().border1(),
          ),
        ),
      ),
      child: Center(
        child: Focus(
          onFocusChange: (value) {
            setState(() {
              inputHasFocus = value;
            });
          },
          child: TextFormField(
            controller: _textEditingController,
            focusNode: _focusNode,
            cursorColor: ColorsConfig().primary(),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              // fillColor: ColorsConfig().subBackgroundBlack(),
              // filled: true,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              hintText: '메시지를 입력하세요.',
              hintStyle: TextStyle(
                color: ColorsConfig().textBlack2(),
                fontSize: 14.0.sp,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: InkWell(
                onTap: () {
                  ImagePickerSelector().imagePicker().then((pickImage) async {
                    final _prefs = await SharedPreferences.getInstance();

                    SendChattingDataAPI()
                        .send(
                      accessToken: _prefs.getString('AccessToken')!,
                      type: 1,
                      userIndex:
                          RouteGetArguments().getArgs(context)['userIndex'],
                      image: pickImage,
                    )
                        .then((value) {
                      if (value.result['status'] == 10500) {
                        setState(() {
                          chattingDatas.add({
                            'type': 1,
                            'owner': true,
                            'image': pickImage.path,
                            'last_send_date': DateTime.now().toIso8601String(),
                          });
                          _textEditingController.clear();
                        });
                      }
                    });
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SvgAssets(
                        image: 'assets/icon/picture.svg',
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
                  if (_textEditingController.text.trim().isNotEmpty) {
                    final _prefs = await SharedPreferences.getInstance();

                    SendChattingDataAPI()
                        .send(
                      accessToken: _prefs.getString('AccessToken')!,
                      type: 0,
                      userIndex:
                          RouteGetArguments().getArgs(context)['userIndex'],
                      message: _textEditingController.text,
                    )
                        .then((value) {
                      if (value.result['status'] == 10500) {
                        setState(() {
                          Future.delayed(Duration.zero, () {
                            chattingDatas.add({
                              'type': 0,
                              'owner': true,
                              'message': _textEditingController.text,
                              'last_send_date':
                                  DateTime.now().toIso8601String(),
                            });
                            _textEditingController.clear();
                          }).then((_) {
                            _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeIn);
                          });
                        });
                      }
                    });
                  }
                },
                child: CustomTextBuilder(
                  text: '보내기',
                  fontColor: sendButtonColor,
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
    );
  }

  Future showRoomSettingBottomSheet() {
    BuildContext dialogContext = context;
    BuildContext dataContext = context;
    return showModalBottomSheet(
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
                    padding: const EdgeInsets.only(
                        top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 0.5,
                          color: ColorsConfig().border1(),
                        ),
                      ),
                    ),
                    child: CustomTextBuilder(
                      text: userNickname.toString(),
                      fontColor: ColorsConfig().textWhite1(),
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report', arguments: {
                        'type': 3,
                        'targetIndex': userIndex,
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
                                color: ColorsConfig().subBackground1(),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8.0),
                                  topRight: Radius.circular(8.0),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomTextBuilder(
                                    text: '$userNickname님을 차단하시겠습니까?',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  const SizedBox(height: 10.0),
                                  CustomTextBuilder(
                                    text:
                                        '차단 시 $userNickname님과 관련된 메시지, 모든 게시글이 차단되며, 구독중인 경우 구독이 해제됩니다.',
                                    fontColor: ColorsConfig().textBlack2(),
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
                                    color: ColorsConfig().border1(),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.pop(dialogContext),
                                    child: Container(
                                      width: (MediaQuery.of(dataContext)
                                                  .size
                                                  .width -
                                              80.5) /
                                          2,
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
                                          fontColor:
                                              ColorsConfig().textWhite1(),
                                          fontSize: 16.0,
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
                                          await SharedPreferences.getInstance();

                                      AddUserBlockAPI()
                                          .addBlock(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              targetIndex: userIndex)
                                          .then((res) {
                                        if (res.result['status'] == 11100) {
                                          Navigator.pop(dialogContext);
                                          ToastBuilder().toast(
                                            Container(
                                              width: MediaQuery.of(dataContext)
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
                                                text: '$userNickname님이 차단되었습니다',
                                                fontColor:
                                                    ColorsConfig.defaultWhite,
                                                fontSize: 14.0.sp,
                                              ),
                                            ),
                                          );
                                        } else if (res.result['status'] ==
                                            11101) {
                                          Navigator.pop(dialogContext);
                                          ToastBuilder().toast(
                                            Container(
                                              width: MediaQuery.of(dataContext)
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
                                                text: '이미 차단된 유저입니다.',
                                                fontColor:
                                                    ColorsConfig.defaultWhite,
                                                fontSize: 14.0.sp,
                                              ),
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: (MediaQuery.of(dataContext)
                                                  .size
                                                  .width -
                                              80.5) /
                                          2,
                                      height: 43.0,
                                      decoration: BoxDecoration(
                                        color: ColorsConfig().subBackground1(),
                                        borderRadius: const BorderRadius.only(
                                          bottomRight: Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Center(
                                        child: CustomTextBuilder(
                                          text: '차단',
                                          fontColor: ColorsConfig().textRed1(),
                                          fontSize: 16.0,
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
                      ).dialog(dialogContext);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
}
