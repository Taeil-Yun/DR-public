import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/image_picker/image_picker.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/question/add_question.dart';
import 'package:DRPublic/api/question/question_list.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:DRPublic/widget/svg_asset.dart';

class ServiceCenterScreen extends StatefulWidget {
  const ServiceCenterScreen({Key? key}) : super(key: key);

  @override
  State<ServiceCenterScreen> createState() => _ServiceCenterScreenState();
}

class _ServiceCenterScreenState extends State<ServiceCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentsController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode contentsFocusNode = FocusNode();
  final List<AnimationController> _controllers = [];

  int _currentIndex = 0;
  int selectIndex = -1;
  int titleLength = 0;

  String inquireType = '';

  List<bool> listStates = [];
  List<dynamic> questionList = [];

  XFile? imageData;

  Color _color = ColorsConfig.transparent;

  @override
  void initState() {
    _tabController = TabController(
      length: 2,
      vsync: this, //vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

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

    titleController.addListener(() {
      setState(() {
        _color = inquireType.isNotEmpty &&
                titleController.text.isNotEmpty &&
                contentsController.text.isNotEmpty
            ? ColorsConfig().primary()
            : ColorsConfig().textBlack2();
      });
    });

    contentsController.addListener(() {
      setState(() {
        _color = inquireType.isNotEmpty &&
                titleController.text.isNotEmpty &&
                contentsController.text.isNotEmpty
            ? ColorsConfig().primary()
            : ColorsConfig().textBlack2();
      });
    });

    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetQuestionList()
        .question(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      List<dynamic> reverseList = [];
      setState(() {
        reverseList = value.result;

        questionList = reverseList.reversed.toList();

        for (int i = 0; i < value.result.length; i++) {
          listStates.add(false);

          _controllers.add(AnimationController(
            duration: const Duration(milliseconds: 250),
            vsync: this,
          ));
        }
      });
    });
  }

  @override
  void dispose() {
    for (int i = 0; i < questionList.length; i++) {
      _controllers[i].dispose();
    }
    _tabController.dispose();
    titleController.dispose();
    contentsController.dispose();
    titleFocusNode.dispose();
    contentsFocusNode.dispose();

    super.dispose();
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

  Color onButton() {
    if (inquireType.isNotEmpty &&
        titleController.text.isNotEmpty &&
        contentsController.text.isNotEmpty) {
      _color = ColorsConfig().primary();
    } else {
      _color = ColorsConfig().textBlack2();
    }

    return _color;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        titleFocusNode.unfocus();
        contentsFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: DRAppBar(
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          leading: DRAppBarLeading(
            press: () => Navigator.pop(context),
          ),
          title: const DRAppBarTitle(
            title: '고객센터',
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46.0),
            child: Container(
              height: 46.0,
              decoration: BoxDecoration(
                color: ColorsConfig().subBackground1(),
                border: Border(
                  bottom: BorderSide(
                    width: 0.5,
                    color: ColorsConfig().border1(),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: ColorsConfig().primary(),
                unselectedLabelColor: ColorsConfig().textBlack2(),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                ),
                labelColor: ColorsConfig().textWhite1(),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(
                    child: CustomTextBuilder(
                      text: '문의하기',
                    ),
                  ),
                  Tab(
                    child: CustomTextBuilder(
                      text: 'MY문의내역',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: _currentIndex == 0
              ? [
                  TextButton(
                    onPressed: () {
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
                                  text: '문의를 제출하시겠습니까?',
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
                                      width:
                                          (MediaQuery.of(context).size.width -
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
                                          await SharedPreferences.getInstance();

                                      if (inquireType.isNotEmpty &&
                                          titleController.text.isNotEmpty &&
                                          contentsController.text.isNotEmpty) {
                                        AddQuestionDataAPI()
                                            .addQuestion(
                                                accessToken: _prefs
                                                    .getString('AccessToken')!,
                                                file: imageData,
                                                type: inquireType == '일반'
                                                    ? 1
                                                    : inquireType == '계정'
                                                        ? 2
                                                        : inquireType == '제휴'
                                                            ? 3
                                                            : inquireType ==
                                                                    '기타'
                                                                ? 4
                                                                : inquireType ==
                                                                        '환불'
                                                                    ? 5
                                                                    : 0,
                                                subject:
                                                    titleController.text.trim(),
                                                content: contentsController.text
                                                    .trim())
                                            .then((value) {
                                          setState(() {
                                            contentsFocusNode.unfocus();
                                            GetQuestionList()
                                                .question(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!)
                                                .then((value) {
                                              List<dynamic> reverseList = [];
                                              setState(() {
                                                listStates.clear();
                                                _controllers.clear();

                                                reverseList = value.result;

                                                questionList = reverseList
                                                    .reversed
                                                    .toList();

                                                for (int i = 0;
                                                    i < value.result.length;
                                                    i++) {
                                                  listStates.add(false);

                                                  _controllers
                                                      .add(AnimationController(
                                                    duration: const Duration(
                                                        milliseconds: 250),
                                                    vsync: this,
                                                  ));
                                                }
                                              });
                                            });
                                            setState(() {
                                              _tabController.index = 1;
                                              _currentIndex = 1;
                                            });
                                          });
                                        });
                                      }

                                      Navigator.pop(context);

                                      ToastBuilder().toast(
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 40.0),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 13.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig()
                                                .textWhite1(opacity: 0.8),
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 28.0,
                                                height: 28.0,
                                                margin: const EdgeInsets.only(
                                                    right: 15.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .subBackgroundBlack(),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14.0),
                                                ),
                                                child: Center(
                                                  child: SvgAssets(
                                                    image:
                                                        'assets/icon/check.svg',
                                                    color: ColorsConfig()
                                                        .textWhite1(),
                                                  ),
                                                ),
                                              ),
                                              CustomTextBuilder(
                                                text: '문의가 접수되었습니다.',
                                                fontColor:
                                                    ColorsConfig().background(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
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
                                          text: '확인',
                                          fontColor: ColorsConfig().primary(),
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
                      // final _prefs = await SharedPreferences.getInstance();

                      // if (inquireType.isNotEmpty && titleController.text.isNotEmpty && contentsController.text.isNotEmpty) {
                      //   RefreshTokenAPI().refresh(accesToken: _prefs.getString('AccessToken')!).then((refresh) {
                      //     if (refresh.result['status'] == 0) {
                      //       _prefs.setString('AccessToken', refresh.result['access_token']);

                      //       AddQuestionDataAPI().addQuestion(
                      //         accessToken: refresh.result['access_token'],
                      //         file: imageData,
                      //         type: inquireType == '일반'
                      //           ? 1
                      //           : inquireType == '계정'
                      //             ? 2
                      //             : inquireType == '제휴'
                      //               ? 3
                      //               : inquireType == '기타'
                      //                 ? 4
                      //                 : 0,
                      //         subject: titleController.text.trim(),
                      //         content: contentsController.text.trim()
                      //       ).then((value) {
                      //         print(value);
                      //       });
                      //     }
                      //   });
                      // }
                    },
                    child: CustomTextBuilder(
                      text: '제출',
                      fontColor: onButton(),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ]
              : null,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            inquireWidget(),
            myQuestionsWidget(),
          ],
        ),
      ),
    );
  }

  Widget inquireWidget() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: ColorsConfig().subBackground1(),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
          // width: MediaQuery.of(context).size.width,
          color: ColorsConfig().subBackground1(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
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
                                    text: '문의유형',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 18.0.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      inquireType = '일반';
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0, vertical: 15.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '일반',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      inquireType = '계정';
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0, vertical: 15.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '계정',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      inquireType = '제휴';
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0, vertical: 15.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '제휴',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      inquireType = '환불';
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0, vertical: 15.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '환불',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      inquireType = '기타';
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 50.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30.0, vertical: 15.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextBuilder(
                                      text: '기타',
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
                },
                child: Container(
                  height: 48.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 0.5,
                        color: ColorsConfig().border1(),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomTextBuilder(
                          text: inquireType.isNotEmpty ? inquireType : '문의유형',
                          fontColor: inquireType.isNotEmpty
                              ? ColorsConfig().textWhite1()
                              : ColorsConfig().textBlack2(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        SvgAssets(
                          image: 'assets/icon/arrow_down.svg',
                          color: ColorsConfig().textBlack2(),
                          width: 14.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: 48.0,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  ),
                ),
                child: Center(
                  child: TextFormField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    keyboardType: TextInputType.text,
                    cursorColor: ColorsConfig().primary(),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      hintText: '제목을 입력하세요',
                      hintStyle: TextStyle(
                        color: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: ColorsConfig().textWhite1(),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Container(
                height: 210.0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 15.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  ),
                ),
                child: TextFormField(
                  controller: contentsController,
                  focusNode: contentsFocusNode,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  cursorColor: ColorsConfig().primary(),
                  decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                      hintText: '내용을 입력하세요',
                      hintStyle: TextStyle(
                        color: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      )),
                  style: TextStyle(
                    color: ColorsConfig().textWhite1(),
                    fontSize: 16.0.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: (value) {},
                ),
              ),
              imageData == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextButton(
                        onPressed: () {
                          ImagePickerSelector().imagePicker().then((_img) {
                            setState(() {
                              imageData = _img;
                            });
                          });
                        },
                        child: Row(
                          children: [
                            SvgAssets(
                              image: 'assets/icon/picture.svg',
                              color: ColorsConfig().textBlack2(),
                              width: 18.0,
                              height: 18.0,
                            ),
                            const SizedBox(width: 8.0),
                            CustomTextBuilder(
                              text: '첨부파일',
                              fontColor: ColorsConfig().textBlack2(),
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Container(
                          width: 200.0.w,
                          height: 144.0.h,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: ColorsConfig().subBackground1(),
                            borderRadius: BorderRadius.circular(8.0),
                            image: DecorationImage(
                              image: FileImage(File(imageData!.path)),
                              filterQuality: FilterQuality.high,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20.0,
                          top: 15.0,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                imageData = null;
                              });
                            },
                            child: Container(
                              width: 19.0,
                              height: 19.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9.5),
                              ),
                              child: Center(
                                child: SvgAssets(
                                  image: 'assets/icon/close.svg',
                                  color: ColorsConfig().textWhite1(),
                                  width: 19.0,
                                  height: 19.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget myQuestionsWidget() {
    if (questionList.isEmpty) {
      return Container(
        color: ColorsConfig().background(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 114.0,
                height: 114.0,
                child: Image(
                  image: AssetImage('assets/img/none_data.png'),
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 20.0),
              CustomTextBuilder(
                text: '문의내역이 없습니다.',
                fontColor: ColorsConfig().textWhite1(),
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w400,
              )
            ],
          ),
        ),
      );
    }

    return Container(
      color: ColorsConfig().background(),
      child: ListView.builder(
        itemCount: questionList.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 0.5,
                  color: ColorsConfig().border1(),
                ),
              ),
            ),
            child: ExpansionTile(
              backgroundColor: ColorsConfig().subBackground1(),
              collapsedBackgroundColor: ColorsConfig().subBackground1(),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              childrenPadding: EdgeInsets.zero,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: questionList[index]['isReply']
                          ? ColorsConfig().primary()
                          : ColorsConfig().border1(),
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                    child: CustomTextBuilder(
                      text: questionList[index]['isReply'] ? '답변완료' : '답변대기',
                      fontColor: questionList[index]['isReply']
                          ? ColorsConfig().subBackground1()
                          : ColorsConfig().textWhite1(),
                      fontSize: 14.0,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10.0),
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5)
                          .animate(_controllers[index]), //_animation,
                      child: SvgAssets(
                        image: 'assets/icon/arrow_down.svg',
                        color: questionList[index]['isReply']
                            ? ColorsConfig().primary()
                            : ColorsConfig().textBlack2(),
                        width: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
              onExpansionChanged: (isOpen) {
                // 선택되었을때 icon animation
                if (isOpen) {
                  _controllers[index].forward();
                } else {
                  _controllers[index].reverse();
                }
              },
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 20.0),
                    child: CustomTextBuilder(
                      text: 'Q',
                      fontColor: ColorsConfig().textBlack2(),
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomTextBuilder(
                            text: DateFormat('yyyy.MM.dd').format(
                                DateTime.parse(
                                    questionList[index]['question_date'])),
                            fontColor: ColorsConfig().textBlack2(),
                            fontSize: 12.0.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(width: 16.0),
                          CustomTextBuilder(
                            text: questionList[index]['question_type'] == 1
                                ? '일반문의'
                                : questionList[index]['question_type'] == 2
                                    ? '계정문의'
                                    : questionList[index]['question_type'] == 3
                                        ? '제휴문의'
                                        : '기타문의',
                            fontColor: ColorsConfig().textBlack2(),
                            fontSize: 12.0.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width - 167.0,
                        margin: const EdgeInsets.only(top: 8.0),
                        child: CustomTextBuilder(
                          text: '${questionList[index]['subject']}',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Container(
                  color: ColorsConfig().subBackgroundBlack(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 32.0,
                            child: CustomTextBuilder(
                              text: 'Q',
                              fontColor: ColorsConfig().textBlack2(),
                              fontSize: 18.0.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 72.0,
                            child: CustomTextBuilder(
                              text: '${questionList[index]['subject']}',
                              fontSize: 16.0,
                              fontColor: ColorsConfig().textWhite1(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        child: Divider(color: ColorsConfig().border1()),
                        padding: const EdgeInsets.only(left: 32.0),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 32.0),
                          Container(
                            width: MediaQuery.of(context).size.width - 72.0,
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: CustomTextBuilder(
                              text: '${questionList[index]['content']}',
                              fontColor: ColorsConfig().textBlack2(),
                              fontSize: 14.0.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      questionList[index]['question_image'] != false
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  32.0, 18.0, 0.0, 18.0),
                              child: Container(
                                width: 102.0,
                                height: 67.0,
                                decoration: BoxDecoration(
                                  color: ColorsConfig().textBlack2(),
                                  borderRadius: BorderRadius.circular(4.0),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      questionList[index]['question_image'],
                                    ),
                                    filterQuality: FilterQuality.high,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      questionList[index]['isReply']
                          ? Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: Divider(color: ColorsConfig().border1()),
                            )
                          : Container(),
                      questionList[index]['isReply']
                          ? const SizedBox(height: 20.0)
                          : Container(),
                      questionList[index]['isReply']
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 32.0,
                                  child: CustomTextBuilder(
                                    text: 'A',
                                    fontColor: ColorsConfig().textBlack2(),
                                    fontSize: 18.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CustomTextBuilder(
                                          text: DateFormat('yyyy.MM.dd').format(
                                              DateTime.parse(questionList[index]
                                                  ['answer_date'])),
                                          fontColor:
                                              ColorsConfig().textBlack2(),
                                          fontSize: 12.0.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        const SizedBox(width: 16.0),
                                        CustomTextBuilder(
                                          text: questionList[index]
                                                      ['question_type'] ==
                                                  1
                                              ? '일반문의'
                                              : questionList[index]
                                                          ['question_type'] ==
                                                      2
                                                  ? '계정문의'
                                                  : questionList[index][
                                                              'question_type'] ==
                                                          3
                                                      ? '제휴문의'
                                                      : '기타문의',
                                          fontColor:
                                              ColorsConfig().textBlack2(),
                                          fontSize: 12.0.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width -
                                          72.0,
                                      margin: const EdgeInsets.only(top: 8.0),
                                      child: CustomTextBuilder(
                                        text:
                                            '${questionList[index]['answer_content']}',
                                        fontSize: 16.0.sp,
                                        fontColor: ColorsConfig().textWhite1(),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
