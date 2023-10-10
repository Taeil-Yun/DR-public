import 'dart:async';
import 'dart:io';

import 'package:DRPublic/api/write/add_news.dart';
import 'package:DRPublic/api/write/add_post.dart';
import 'package:DRPublic/api/write/add_vote.dart';
import 'package:DRPublic/api/write/patch_news.dart';
import 'package:DRPublic/api/write/patch_post.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/image_picker/image_picker.dart';
import 'package:DRPublic/component/meta_parser/meta_parser.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/tenor/tenor.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/enumerated.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/widget/svg_asset.dart';

import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textfield_tags/textfield_tags.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({Key? key}) : super(key: key);

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  // 폼의 상태를 얻기 위한 키
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController mainTextController = TextEditingController();
  final TextEditingController gifSearchController = TextEditingController();
  final TextEditingController tagTextController = TextEditingController();
  final TextEditingController youtubeTextController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode mainTextFocusNode = FocusNode();
  final FocusNode gifSearchFocusNode = FocusNode();
  final FocusNode tagTextFocusNode = FocusNode();
  final FocusNode youtubeTextFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController wrapperScrollController = ScrollController();
  final ScrollController gifScrollController = ScrollController();

  TextfieldTagsController tagCtr = TextfieldTagsController();
  FocusNode tagFN = FocusNode();

  Timer? _debounce;

  WritingType? inSelectType;

  int titleLength = 0;
  int postType = 0;
  int postIndex = 0;

  bool isMainTextFocus = false;
  bool onYoutubeLink = false;

  String dropdownSelectDayValue = '일';
  String dropdownSelectTimeValue = '시간';
  String postCategoryType = '';
  String gifStr = '';
  String youtubeStr = '';
  String hashTags = '';
  String categoryValue = '';

  List allSelectImage = [];
  List<XFile> imageList = [];
  List<dynamic> patchImageList = [];
  List<String> tagValues = [];
  List<TextEditingController> voteOptionController = [];
  List<FocusNode> voteOptionFocusNode = [];

  @override
  void initState() {
    super.initState();

    voteOptionController = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];

    voteOptionFocusNode = [
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode(),
    ];

    // 글쓰기 페이지 only 세로모드
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    mainTextController.addListener(() {
      mainTextController.value.copyWith(
          text: mainTextController.text,
          selection:
              TextSelection.collapsed(offset: mainTextController.text.length));
    });

    tagTextController.addListener(() {
      if (tagTextController.text.isEmpty) {}
    });

    Future.delayed(Duration.zero, () {
      if (RouteGetArguments().getArgs(context)['onPatch']) {
        var _tags =
            RouteGetArguments().getArgs(context)['tag'].toString().split(',');
        if (RouteGetArguments().getArgs(context)['type'] == 4) {
          setState(() {
            titleController.text =
                RouteGetArguments().getArgs(context)['title'];
            titleLength = titleController.text.length;
            mainTextController.text =
                RouteGetArguments().getArgs(context)['link'];
            hashTags = RouteGetArguments().getArgs(context)['tag'];
            postType = RouteGetArguments().getArgs(context)['type'];
            postIndex = RouteGetArguments().getArgs(context)['post_index'];

            for (int i = 0; i < _tags.length; i++) {
              tagValues.add('#' + _tags[i]);
              tagCtr.addTag = _tags[i];
            }
          });
        } else {
          setState(() {
            titleController.text =
                RouteGetArguments().getArgs(context)['title'];
            titleLength = titleController.text.length;
            mainTextController.text =
                RouteGetArguments().getArgs(context)['description'];
            hashTags = RouteGetArguments().getArgs(context)['tag'];
            postType = RouteGetArguments().getArgs(context)['type'];
            postIndex = RouteGetArguments().getArgs(context)['post_index'];

            for (int i = 0; i < _tags.length; i++) {
              tagValues.add('#' + _tags[i]);
              tagCtr.addTag = _tags[i];
            }

            if (RouteGetArguments().getArgs(context)['category'] == 'i') {
              patchImageList = RouteGetArguments().getArgs(context)['image'];
              allSelectImage = patchImageList;
            } else if (RouteGetArguments().getArgs(context)['category'] ==
                'g') {
              gifStr = RouteGetArguments().getArgs(context)['sub_link'];
            } else if (RouteGetArguments().getArgs(context)['category'] ==
                'y') {
              youtubeStr = RouteGetArguments().getArgs(context)['sub_link'];
            }

            if (RouteGetArguments().getArgs(context)['isCategory']) {
              categoryValue = RouteGetArguments().getArgs(context)['category'];
            }

            if (RouteGetArguments().getArgs(context)['type'] == 1 ||
                RouteGetArguments().getArgs(context)['type'] == 2 ||
                RouteGetArguments().getArgs(context)['type'] == 3) {
              postCategoryType = RouteGetArguments()
                          .getArgs(context)['post_category'] ==
                      1
                  ? '국내증시'
                  : RouteGetArguments().getArgs(context)['post_category'] == 2
                      ? '해외증시'
                      : RouteGetArguments().getArgs(context)['post_category'] ==
                              3
                          ? '파생상품'
                          : RouteGetArguments()
                                      .getArgs(context)['post_category'] ==
                                  4
                              ? '암호화폐'
                              : RouteGetArguments()
                                          .getArgs(context)['post_category'] ==
                                      5
                                  ? '커뮤니티'
                                  : '';
            }
          });
        }
      } else {
        postType = RouteGetArguments().getArgs(context)['type'];
      }

      if (RouteGetArguments().getArgs(context)['onPatch'] == false) {
        writingTypeSelectBottomSheet(RouteGetArguments().getArgs(context))
            .then((_) {
          selectCategoryBottomSheet();
        });
      }
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    mainTextController.dispose();
    gifSearchController.dispose();
    // tagTextController.dispose();
    youtubeTextController.dispose();
    titleFocusNode.dispose();
    mainTextFocusNode.dispose();
    gifSearchFocusNode.dispose();
    // tagTextFocusNode.dispose();
    youtubeTextFocusNode.dispose();
    _scrollController.dispose();
    wrapperScrollController.dispose();
    gifScrollController.dispose();

    for (var _controller in voteOptionController) {
      _controller.dispose();
    }

    for (var _node in voteOptionFocusNode) {
      _node.dispose();
    }

    // 세로모드 해제
    SystemChrome.setPreferredOrientations([]);

    super.dispose();
  }

  Future getTenorGif({String search = '', dynamic useNext}) async {
    return useNext != null
        ? await TenorCustomBuilder().getTenorDatas(search, pos: useNext)
        : await TenorCustomBuilder().getTenorDatas(search);
  }

  Color writingButtonColor() {
    Color _color;

    _color = tagValues.isNotEmpty &&
            titleController.text.isNotEmpty &&
            mainTextController.text.isNotEmpty &&
            postCategoryType.isNotEmpty
        ? ColorsConfig().primary()
        : ColorsConfig().textBlack2();

    return _color;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        titleFocusNode.unfocus();
        mainTextFocusNode.unfocus();

        for (var _node in voteOptionFocusNode) {
          _node.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: ColorsConfig().background(),
        appBar: DRAppBar(
          backgroundColor: ColorsConfig().subBackground1(),
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          leading: DRAppBarLeading(
            press: () {
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
                          text: '취소 시 작성중인 내용이\n모두 삭제됩니다.',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center,
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
                                  (MediaQuery.of(context).size.width - 80.5) /
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
                                  text: '돌아가기',
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
                              Navigator.pop(context);
                            },
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 80.5) /
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
                                  fontColor: ColorsConfig().textRed1(),
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
            icon: CustomTextBuilder(
              text: '취소',
              fontColor: ColorsConfig().border1(),
              fontSize: 16.0.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          title: DRAppBarTitle(
            onWidget: true,
            wd: InkWell(
              onTap: () {
                if (RouteGetArguments().getArgs(context)['onPatch'] == false) {
                  writingTypeSelectBottomSheet(
                      RouteGetArguments().getArgs(context));
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomTextBuilder(
                    text: inSelectType == null
                        ? RouteGetArguments().getArgs(context)['type'] == 1
                            ? '포스트'
                            : RouteGetArguments().getArgs(context)['type'] == 4
                                ? '뉴스'
                                : RouteGetArguments()
                                            .getArgs(context)['type'] ==
                                        5
                                    ? '투표'
                                    : RouteGetArguments()
                                                .getArgs(context)['type'] ==
                                            2
                                        ? '분석'
                                        : RouteGetArguments()
                                                    .getArgs(context)['type'] ==
                                                3
                                            ? '토론'
                                            : ''
                        : inSelectType == WritingType.post
                            ? '포스트'
                            : inSelectType == WritingType.news
                                ? '뉴스'
                                : inSelectType == WritingType.vote
                                    ? '투표'
                                    : inSelectType == WritingType.analytics
                                        ? '분석'
                                        : inSelectType == WritingType.debate
                                            ? '토론'
                                            : '',
                    fontColor: ColorsConfig().textWhite1(),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    margin: const EdgeInsets.only(top: 4.0),
                    child: SvgAssets(
                      image: 'assets/icon/arrow_down.svg',
                      color: ColorsConfig().textWhite1(),
                    ),
                  ),
                ],
              ),
              splashColor: ColorsConfig.transparent,
              highlightColor: ColorsConfig.transparent,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    hashTags.isNotEmpty &&
                    (mainTextController.text.isNotEmpty ||
                        (voteOptionController[0].text.isNotEmpty &&
                            voteOptionController[1].text.isNotEmpty &&
                            dropdownSelectDayValue
                                .replaceAll('일', '')
                                .isNotEmpty &&
                            dropdownSelectTimeValue
                                .replaceAll('시간', '')
                                .isNotEmpty))) {
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
                              text: '공유글을 등록하시겠습니까?',
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
                                  width: (MediaQuery.of(context).size.width -
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
                                onTap: () async {
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();

                                  _debounce =
                                      Timer(const Duration(milliseconds: 700),
                                          () async {
                                    final _prefs =
                                        await SharedPreferences.getInstance();

                                    // 수정하기로 접근시
                                    if (RouteGetArguments()
                                        .getArgs(context)['onPatch']) {
                                      // 포스트, 분석, 토론 공유하기 버튼 (수정)
                                      if ((inSelectType == null &&
                                                  RouteGetArguments().getArgs(
                                                          context)['type'] ==
                                                      1 ||
                                              inSelectType ==
                                                  WritingType.post) ||
                                          (inSelectType == null &&
                                                  RouteGetArguments().getArgs(
                                                          context)['type'] ==
                                                      2 ||
                                              inSelectType ==
                                                  WritingType.analytics) ||
                                          (inSelectType == null &&
                                                  RouteGetArguments().getArgs(
                                                          context)['type'] ==
                                                      3 ||
                                              inSelectType ==
                                                  WritingType.debate)) {
                                        if (titleController.text.isNotEmpty &&
                                                hashTags.isNotEmpty &&
                                                mainTextController
                                                    .text.isNotEmpty ||
                                            postCategoryType.isNotEmpty) {
                                          // 이미지, gif, youtube 중 하나의 값도 존재하지 않을 경우
                                          if (categoryValue == '') {
                                            PatchPostDataAPI()
                                                .patchPost(
                                              accessToken: _prefs
                                                  .getString('AccessToken')!,
                                              postIndex: RouteGetArguments()
                                                  .getArgs(
                                                      context)['post_index'],
                                              type: postType,
                                              title: titleController.text,
                                              tag: RouteGetArguments().getArgs(
                                                          context)['tag'] !=
                                                      hashTags
                                                  ? tagValues
                                                      .toString()
                                                      .replaceAll('[', '')
                                                      .replaceAll(']', '')
                                                      .replaceAll('#', '')
                                                  : RouteGetArguments()
                                                      .getArgs(context)['tag'],
                                              description:
                                                  mainTextController.text,
                                              postCategoryType: postCategoryType ==
                                                      '국내증시'
                                                  ? 1
                                                  : postCategoryType == '해외증시'
                                                      ? 2
                                                      : postCategoryType ==
                                                              '파생상품'
                                                          ? 3
                                                          : postCategoryType ==
                                                                  '암호화폐'
                                                              ? 4
                                                              : postCategoryType ==
                                                                      '커뮤니티'
                                                                  ? 5
                                                                  : 0,
                                            )
                                                .then((_val) {
                                              if (_val.result['status'] ==
                                                  10105) {
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                                Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            PostingDetailScreen(
                                                              postIndex:
                                                                  postIndex,
                                                              postType:
                                                                  postType,
                                                            )));
                                              }
                                            });
                                            // 타입이 gif, youtube일 경우
                                          } else {
                                            if (categoryValue != 'i') {
                                              PatchPostDataAPI()
                                                  .patchPost(
                                                accessToken: _prefs
                                                    .getString('AccessToken')!,
                                                postIndex: RouteGetArguments()
                                                    .getArgs(
                                                        context)['post_index'],
                                                type: postType,
                                                title: titleController.text,
                                                tag: RouteGetArguments()
                                                                .getArgs(
                                                                    context)[
                                                            'tag'] !=
                                                        hashTags
                                                    ? tagValues
                                                        .toString()
                                                        .replaceAll('[', '')
                                                        .replaceAll(']', '')
                                                        .replaceAll('#', '')
                                                    : RouteGetArguments()
                                                        .getArgs(
                                                            context)['tag'],
                                                description:
                                                    mainTextController.text,
                                                category: categoryValue,
                                                subLink: categoryValue == 'g'
                                                    ? gifStr
                                                    : categoryValue == 'y'
                                                        ? youtubeStr
                                                        : null,
                                                postCategoryType: postCategoryType ==
                                                        '국내증시'
                                                    ? 1
                                                    : postCategoryType == '해외증시'
                                                        ? 2
                                                        : postCategoryType ==
                                                                '파생상품'
                                                            ? 3
                                                            : postCategoryType ==
                                                                    '암호화폐'
                                                                ? 4
                                                                : postCategoryType ==
                                                                        '커뮤니티'
                                                                    ? 5
                                                                    : 0,
                                              )
                                                  .then((_val) {
                                                if (_val.result['status'] ==
                                                    10105) {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              PostingDetailScreen(
                                                                postIndex:
                                                                    postIndex,
                                                                postType:
                                                                    postType,
                                                              )));
                                                }
                                              });
                                              // 타입이 이미지인경우
                                            } else {
                                              PatchPostDataAPI()
                                                  .patchPost(
                                                accessToken: _prefs
                                                    .getString('AccessToken')!,
                                                postIndex: RouteGetArguments()
                                                    .getArgs(
                                                        context)['post_index'],
                                                type: postType,
                                                title: titleController.text,
                                                tag: RouteGetArguments()
                                                                .getArgs(
                                                                    context)[
                                                            'tag'] !=
                                                        hashTags
                                                    ? tagValues
                                                        .toString()
                                                        .replaceAll('[', '')
                                                        .replaceAll(']', '')
                                                        .replaceAll('#', '')
                                                    : RouteGetArguments()
                                                        .getArgs(
                                                            context)['tag'],
                                                description:
                                                    mainTextController.text,
                                                category: categoryValue,
                                                file:
                                                    patchImageList + imageList,
                                                postCategoryType: postCategoryType ==
                                                        '국내증시'
                                                    ? 1
                                                    : postCategoryType == '해외증시'
                                                        ? 2
                                                        : postCategoryType ==
                                                                '파생상품'
                                                            ? 3
                                                            : postCategoryType ==
                                                                    '암호화폐'
                                                                ? 4
                                                                : postCategoryType ==
                                                                        '커뮤니티'
                                                                    ? 5
                                                                    : 0,
                                              )
                                                  .then((_val) {
                                                if (_val.result['status'] ==
                                                    10105) {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              PostingDetailScreen(
                                                                postIndex:
                                                                    postIndex,
                                                                postType:
                                                                    postType,
                                                              )));
                                                }
                                              });
                                            }
                                          }
                                        }
                                      }
                                      // 뉴스 공유하기 버튼 (수정)
                                      else if (inSelectType == null &&
                                              RouteGetArguments().getArgs(
                                                      context)['type'] ==
                                                  4 ||
                                          inSelectType == WritingType.news) {
                                        if (titleController.text.isNotEmpty &&
                                            hashTags.isNotEmpty &&
                                            mainTextController
                                                .text.isNotEmpty) {
                                          PatchNewsDataAPI()
                                              .patchNews(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            postIndex: RouteGetArguments()
                                                .getArgs(context)['post_index'],
                                            title: titleController.text,
                                            link: mainTextController.text,
                                            tag: RouteGetArguments().getArgs(
                                                        context)['tag'] !=
                                                    hashTags
                                                ? tagValues
                                                    .toString()
                                                    .replaceAll('[', '')
                                                    .replaceAll(']', '')
                                                    .replaceAll('#', '')
                                                : RouteGetArguments()
                                                    .getArgs(context)['tag'],
                                          )
                                              .then((_val) {
                                            if (_val.result['status'] ==
                                                10105) {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          PostingDetailScreen(
                                                            postIndex:
                                                                postIndex,
                                                            postType: postType,
                                                          )));
                                            }
                                          });
                                        }
                                      }
                                    } else {
                                      // 포스트, 분석, 토론 공유하기 버튼
                                      if ((inSelectType == null &&
                                                  RouteGetArguments().getArgs(
                                                          context)['type'] ==
                                                      1 ||
                                              inSelectType ==
                                                  WritingType.post) ||
                                          (inSelectType == null &&
                                                  RouteGetArguments().getArgs(
                                                          context)['type'] ==
                                                      2 ||
                                              inSelectType ==
                                                  WritingType.analytics) ||
                                          (inSelectType == null &&
                                                  RouteGetArguments().getArgs(
                                                          context)['type'] ==
                                                      3 ||
                                              inSelectType ==
                                                  WritingType.debate)) {
                                        if (titleController.text.isNotEmpty &&
                                            hashTags.isNotEmpty &&
                                            mainTextController
                                                .text.isNotEmpty &&
                                            postCategoryType.isNotEmpty) {
                                          AddPostDataAPI()
                                              .addPost(
                                                  accessToken: _prefs.getString(
                                                      'AccessToken')!,
                                                  type: postType,
                                                  title: titleController.text,
                                                  tag: tagValues
                                                      .toString()
                                                      .replaceAll('[', '')
                                                      .replaceAll(']', '')
                                                      .replaceAll('#', ''),
                                                  description:
                                                      mainTextController.text,
                                                  category:
                                                      categoryValue.isNotEmpty
                                                          ? categoryValue
                                                          : null,
                                                  postCategoryType: postCategoryType ==
                                                          '국내증시'
                                                      ? 1
                                                      : postCategoryType ==
                                                              '해외증시'
                                                          ? 2
                                                          : postCategoryType ==
                                                                  '파생상품'
                                                              ? 3
                                                              : postCategoryType ==
                                                                      '암호화폐'
                                                                  ? 4
                                                                  : postCategoryType ==
                                                                          '커뮤니티'
                                                                      ? 5
                                                                      : 0,
                                                  subLink: categoryValue == 'g'
                                                      ? gifStr
                                                      : categoryValue == 'y'
                                                          ? youtubeStr
                                                          : null,
                                                  file: categoryValue == 'i'
                                                      ? imageList
                                                      : null)
                                              .then((_val) {
                                            if (_val.result['status'] ==
                                                10100) {
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          PostingDetailScreen(
                                                            postIndex: _val
                                                                    .result[
                                                                'post_index'],
                                                            postType: postType,
                                                          )));
                                            }
                                          });
                                        }
                                      }
                                      // 뉴스 공유하기 버튼
                                      else if (inSelectType == null &&
                                              RouteGetArguments().getArgs(
                                                      context)['type'] ==
                                                  4 ||
                                          inSelectType == WritingType.news) {
                                        if (titleController.text.isNotEmpty &&
                                            hashTags.isNotEmpty &&
                                            mainTextController
                                                .text.isNotEmpty) {
                                          AddNewsAPI()
                                              .addNews(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            title: titleController.text,
                                            link: mainTextController.text,
                                            tag: tagValues
                                                .toString()
                                                .replaceAll('[', '')
                                                .replaceAll(']', '')
                                                .replaceAll('#', ''),
                                          )
                                              .then((_val) {
                                            if (_val.result['status'] ==
                                                10100) {
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          NewsDetailScreen(
                                                            postIndex: _val
                                                                    .result[
                                                                'post_index'],
                                                            postType: postType,
                                                          )));
                                            }
                                          });
                                        }
                                      }
                                      // 투표 공유하기 버튼
                                      else if (inSelectType == null &&
                                              RouteGetArguments().getArgs(
                                                      context)['type'] ==
                                                  5 ||
                                          inSelectType == WritingType.vote) {
                                        List<String> _voteTextNotNull = [];
                                        for (var votes
                                            in voteOptionController) {
                                          if (votes.text.isNotEmpty) {
                                            _voteTextNotNull.add(votes.text);
                                          }
                                        }
                                        if (titleController.text.isNotEmpty &&
                                            hashTags.isNotEmpty &&
                                            voteOptionController[0]
                                                .text
                                                .isNotEmpty &&
                                            voteOptionController[1]
                                                .text
                                                .isNotEmpty) {
                                          AddVoteAPI()
                                              .addVote(
                                            accesToken: _prefs
                                                .getString('AccessToken')!,
                                            title: titleController.text,
                                            votes: _voteTextNotNull,
                                            tag: tagValues
                                                .toString()
                                                .replaceAll('[', '')
                                                .replaceAll(']', '')
                                                .replaceAll('#', ''),
                                            days: int.parse(
                                                dropdownSelectDayValue
                                                    .replaceAll('일', '')),
                                            hours: int.parse(
                                                        dropdownSelectDayValue
                                                            .replaceAll(
                                                                '일', '')) ==
                                                    7
                                                ? 0
                                                : int.parse(
                                                    dropdownSelectTimeValue
                                                        .replaceAll('시간', '')),
                                          )
                                              .then((_val) {
                                            if (_val.result['status'] ==
                                                10100) {
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          VoteDetailScreen(
                                                            postIndex: _val
                                                                    .result[
                                                                'post_index'],
                                                            postType: postType,
                                                          )));
                                            }
                                          });
                                        }
                                      }
                                    }
                                  });

                                  // if (postListData[index]['type'] == 4) {
                                  //   Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) => NewsDetailScreen(
                                  //         postIndex: postListData[index]['post_index'],
                                  //         postType: postListData[index]['type'],
                                  //       ),
                                  //     ),
                                  //   );
                                  // } else if (postListData[index]['type'] == 5) {
                                  //   Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) => VoteDetailScreen(
                                  //         postIndex: postListData[index]['post_index'],
                                  //         postType: postListData[index]['type'],
                                  //       ),
                                  //     ),
                                  //   );
                                  // } else {
                                  //   Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) => PostingDetailScreen(
                                  //         postIndex: postListData[index]['post_index'],
                                  //         postType: postListData[index]['type'],
                                  //       ),
                                  //     ),
                                  //   );
                                  // }
                                },
                                child: Container(
                                  width: (MediaQuery.of(context).size.width -
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
                                      text: '등록',
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
                }
              },
              child: CustomTextBuilder(
                text: '공유',
                fontColor: writingButtonColor(),
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            (inSelectType == null &&
                            RouteGetArguments().getArgs(context)['type'] == 1 ||
                        inSelectType == WritingType.post) ||
                    (inSelectType == null &&
                            RouteGetArguments().getArgs(context)['type'] == 2 ||
                        inSelectType == WritingType.analytics) ||
                    (inSelectType == null &&
                            RouteGetArguments().getArgs(context)['type'] == 3 ||
                        inSelectType == WritingType.debate)
                ? SingleChildScrollView(
                    controller: wrapperScrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Container(
                      color: ColorsConfig().background(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height / 1.1,
                          maxHeight: double.infinity,
                        ),
                        child: Column(
                          children: [
                            titleTextInputWidget(WritingType.post),
                            categoryValue == 'i'
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 166.0,
                                    padding: const EdgeInsets.all(10.0),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: allSelectImage.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 108.0,
                                          height: 70.0,
                                          margin: index != 9
                                              ? const EdgeInsets.only(
                                                  right: 10.0)
                                              : null,
                                          padding: const EdgeInsets.all(7.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig().background(),
                                            border: Border.all(
                                              width: 0.5,
                                              color: ColorsConfig().border1(),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            image: patchImageList.isNotEmpty &&
                                                        allSelectImage[index]
                                                            .toString()
                                                            .startsWith(
                                                                'https://') ||
                                                    allSelectImage[index]
                                                        .toString()
                                                        .startsWith('http://')
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        '${allSelectImage[index]}'),
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    fit: BoxFit.cover,
                                                  )
                                                : DecorationImage(
                                                    image: FileImage(File(
                                                        allSelectImage[index]
                                                            .path)),
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          alignment: Alignment.topRight,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (allSelectImage.isNotEmpty) {
                                                  allSelectImage
                                                      .removeAt(index);
                                                }

                                                if (imageList.isNotEmpty) {
                                                  imageList.removeAt(index);
                                                }

                                                if (patchImageList.isNotEmpty) {
                                                  patchImageList
                                                      .removeAt(index);
                                                }

                                                if (allSelectImage.isEmpty &&
                                                    imageList.isEmpty &&
                                                    patchImageList.isEmpty) {
                                                  categoryValue = '';
                                                }
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(50.0),
                                              ),
                                              child: SvgAssets(
                                                image: 'assets/icon/close.svg',
                                                width: 18.0,
                                                height: 18.0,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(),
                            categoryValue == 'g' && gifStr.isNotEmpty
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 166.0,
                                    padding: const EdgeInsets.all(10.0),
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
                                        Container(
                                          width: 108.0,
                                          height: 170.0,
                                          padding: const EdgeInsets.all(7.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig().background(),
                                            border: Border.all(
                                              width: 0.5,
                                              color: ColorsConfig().border1(),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            image: DecorationImage(
                                              image: NetworkImage(gifStr),
                                              filterQuality: FilterQuality.high,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          alignment: Alignment.topRight,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                gifStr = '';
                                                categoryValue = '';
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 1.0,
                                                  color: Colors.black,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(50.0),
                                              ),
                                              child: SvgAssets(
                                                image: 'assets/icon/close.svg',
                                                width: 18.0,
                                                height: 18.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                            categoryValue == 'y' && youtubeStr.isNotEmpty
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 166.0,
                                    padding: const EdgeInsets.all(10.0),
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
                                        Container(
                                          width: 108.0,
                                          height: 70.0,
                                          padding: const EdgeInsets.all(7.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig().background(),
                                            border: Border.all(
                                              width: 0.5,
                                              color: ColorsConfig().border1(),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  'https://img.youtube.com/vi/${youtubeStr.startsWith('https://youtu.be/') ? youtubeStr.split('youtu.be/')[1] : youtubeStr.split('v=')}/0.jpg'),
                                              filterQuality: FilterQuality.high,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          alignment: Alignment.topRight,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                youtubeStr = '';
                                                categoryValue = '';
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 1.0,
                                                  color: Colors.black,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(50.0),
                                              ),
                                              child: SvgAssets(
                                                image: 'assets/icon/close.svg',
                                                width: 18.0,
                                                height: 18.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                            postTextInputWidget(),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(),
            (inSelectType == null &&
                            RouteGetArguments().getArgs(context)['type'] == 1 ||
                        inSelectType == WritingType.post) ||
                    (inSelectType == null &&
                            RouteGetArguments().getArgs(context)['type'] == 2 ||
                        inSelectType == WritingType.analytics) ||
                    (inSelectType == null &&
                            RouteGetArguments().getArgs(context)['type'] == 3 ||
                        inSelectType == WritingType.debate)
                ? onYoutubeLink
                    ? Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        color: ColorsConfig().colorPicker(
                            color: ColorsConfig.defaultBlack, opacity: 0.26),
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width / 1.2,
                            height: 170,
                            padding: const EdgeInsets.only(top: 20.0),
                            decoration: BoxDecoration(
                              color: ColorsConfig().subBackground1(),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20.0, 0.0, 20.0, 10.0),
                                  child: CustomTextBuilder(
                                    text: '유튜브 URL을 입력해주세요.',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 14.0.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Form(
                                  key: formKey,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: TextFormField(
                                      controller: youtubeTextController,
                                      focusNode: youtubeTextFocusNode,
                                      autofocus: true,
                                      validator: (val) {
                                        if (!val!.startsWith(
                                                'https://www.youtube.com/watch') ||
                                            !val.startsWith(
                                                'https://youtu.be')) {
                                          return '올바른 유튜브 링크가 아닙니다.';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            width: 0.5,
                                            color: ColorsConfig().border1(),
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            width: 0.5,
                                            color: ColorsConfig().border1(),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          ),
                                        ),
                                        counterText: '',
                                        hintText: '유튜브 링크를 입력해주세요.',
                                        hintStyle: TextStyle(
                                          color: ColorsConfig().textBlack2(),
                                          fontSize: 14.0.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: ColorsConfig().textWhite1(),
                                        fontSize: 14.0.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      onChanged: (value) {},
                                    ),
                                  ),
                                ),
                                // 빈 공간
                                Expanded(
                                  child: Container(),
                                ),
                                // border 영역
                                Container(
                                  height: 0.5,
                                  color: ColorsConfig().border1(),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8.0),
                                      bottomRight: Radius.circular(8.0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            onYoutubeLink = false;
                                          });
                                        },
                                        child: Container(
                                          width: (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      1.2) /
                                                  2 -
                                              0.5,
                                          height: 43.0,
                                          decoration: BoxDecoration(
                                            color:
                                                ColorsConfig().subBackground1(),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(8.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: CustomTextBuilder(
                                              text: '취소',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // border 영역
                                      Container(
                                        width: 0.5,
                                        height: 43.0,
                                        color: ColorsConfig().border1(),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (!formKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              youtubeStr =
                                                  youtubeTextController.text;
                                              categoryValue = 'y';
                                              onYoutubeLink = false;
                                            });
                                          } else {}
                                        },
                                        child: Container(
                                          width: (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      1.2) /
                                                  2 -
                                              0.5,
                                          height: 43.0,
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(8.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: CustomTextBuilder(
                                              text: '확인',
                                              fontColor:
                                                  ColorsConfig().primary(),
                                              fontSize: 16.0.sp,
                                              fontWeight: FontWeight.w700,
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
                      )
                    : Container()
                : Container(),
            inSelectType == null &&
                        RouteGetArguments().getArgs(context)['type'] == 4 ||
                    inSelectType == WritingType.news
                ? SingleChildScrollView(
                    controller: wrapperScrollController,
                    child: Container(
                      color: ColorsConfig().background(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height / 1.1,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              titleTextInputWidget(WritingType.news),
                              newsTextInputWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            inSelectType == null &&
                        RouteGetArguments().getArgs(context)['type'] == 5 ||
                    inSelectType == WritingType.vote
                ? SingleChildScrollView(
                    controller: wrapperScrollController,
                    child: Container(
                      color: ColorsConfig().background(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height / 1.1,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              titleTextInputWidget(WritingType.vote),
                              Column(
                                children: List.generate(6, (index) {
                                  if (index + 1 == 6) {
                                    return Container(
                                      height: 43.0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0),
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
                                          Container(
                                            margin: const EdgeInsets.only(
                                                right: 15.0),
                                            child: CustomTextBuilder(
                                              text: '투표기간',
                                              fontColor:
                                                  ColorsConfig().textWhite1(),
                                              fontSize: 14.0.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Container(
                                            width: 100.0,
                                            margin: const EdgeInsets.only(
                                                right: 15.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(4.0)),
                                            ),
                                            child: DropdownButton(
                                              value: dropdownSelectDayValue,
                                              icon: Container(
                                                margin: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: SvgAssets(
                                                  image:
                                                      'assets/icon/arrow_down.svg',
                                                  color: ColorsConfig()
                                                      .textBlack2(),
                                                  width: 12.0,
                                                ),
                                              ),
                                              menuMaxHeight: 200.0,
                                              isExpanded: true,
                                              isDense: true,
                                              dropdownColor: ColorsConfig()
                                                  .subBackground1(),
                                              underline:
                                                  DropdownButtonHideUnderline(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      width: 0.0,
                                                      color: ColorsConfig
                                                          .transparent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              style: TextStyle(
                                                  color: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 14.0.sp,
                                                  fontWeight: FontWeight.w400),
                                              items: List.generate(9, (item) {
                                                if (item == 0) {
                                                  return DropdownMenuItem(
                                                    value: '일',
                                                    alignment: Alignment.center,
                                                    child: CustomTextBuilder(
                                                      text: '일',
                                                    ),
                                                  );
                                                }
                                                return DropdownMenuItem(
                                                  value: '${item - 1} 일',
                                                  alignment: Alignment.center,
                                                  child: CustomTextBuilder(
                                                    text: '${item - 1} 일',
                                                  ),
                                                );
                                              }),
                                              onChanged: (value) {
                                                setState(() {
                                                  dropdownSelectDayValue =
                                                      value.toString();
                                                });
                                              },
                                            ),
                                          ),
                                          Container(
                                            width: 100.0,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(4.0)),
                                            ),
                                            child: DropdownButton(
                                              value: dropdownSelectTimeValue,
                                              icon: Container(
                                                margin: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: SvgAssets(
                                                  image:
                                                      'assets/icon/arrow_down.svg',
                                                  color: ColorsConfig()
                                                      .textBlack2(),
                                                  width: 12.0,
                                                ),
                                              ),
                                              menuMaxHeight: 200.0,
                                              isDense: true,
                                              isExpanded: true,
                                              dropdownColor: ColorsConfig()
                                                  .subBackground1(),
                                              underline:
                                                  DropdownButtonHideUnderline(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      width: 0.0,
                                                      color: ColorsConfig
                                                          .transparent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              style: TextStyle(
                                                  color: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 14.0.sp,
                                                  fontWeight: FontWeight.w400),
                                              items: List.generate(24, (item) {
                                                if (item == 0) {
                                                  return DropdownMenuItem(
                                                    value: '시간',
                                                    alignment: Alignment.center,
                                                    child: CustomTextBuilder(
                                                      text: '시간',
                                                    ),
                                                  );
                                                }
                                                return DropdownMenuItem(
                                                  value: '$item시간',
                                                  alignment: Alignment.center,
                                                  child: CustomTextBuilder(
                                                    text: '$item시간',
                                                  ),
                                                );
                                              }),
                                              onChanged: (value) {
                                                setState(() {
                                                  dropdownSelectTimeValue =
                                                      value.toString();
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Container(
                                    height: 43.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    margin: index == 0
                                        ? const EdgeInsets.only(
                                            top: 15.0, bottom: 4.0)
                                        : index == 4
                                            ? const EdgeInsets.only(
                                                top: 4.0, bottom: 15.0)
                                            : const EdgeInsets.only(
                                                top: 4.0, bottom: 4.0),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: TextFormField(
                                        controller: voteOptionController[index],
                                        focusNode: voteOptionFocusNode[index],
                                        maxLength: 100,
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14.0),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig().border1(),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 0.5,
                                                color: ColorsConfig().primary(),
                                              ),
                                            ),
                                            counterText: '',
                                            hintText: index == 0 || index == 1
                                                ? '투표 항목 ${index + 1}'
                                                : '항목 ${index + 1}(선택 사항)',
                                            hintStyle: TextStyle(
                                              color:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 14.0.sp,
                                              fontWeight: FontWeight.w400,
                                            )),
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
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            Positioned(
              bottom: 0.0,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  tagInputWidget(),
                  (inSelectType == null &&
                                  RouteGetArguments()
                                          .getArgs(context)['type'] ==
                                      1 ||
                              inSelectType == WritingType.post) ||
                          (inSelectType == null &&
                                  RouteGetArguments()
                                          .getArgs(context)['type'] ==
                                      2 ||
                              inSelectType == WritingType.analytics) ||
                          (inSelectType == null &&
                                  RouteGetArguments()
                                          .getArgs(context)['type'] ==
                                      3 ||
                              inSelectType == WritingType.debate)
                      ? Container(
                          height: 50.0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: ColorsConfig().background(),
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
                                  ImagePickerSelector()
                                      .multiImagePicker()
                                      .then((_img) {
                                    if (_img.length > 5 ||
                                        patchImageList.length +
                                                imageList.length +
                                                _img.length >
                                            5) {
                                      PopUpModal(
                                        content: '이미지는 최대 5개까지 업로드 가능합니다.',
                                        title: '이미지 최대 개수를 초과',
                                        actions: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 43.0,
                                              color: ColorsConfig().primary(),
                                              child: Center(
                                                child: CustomTextBuilder(
                                                  text: '확인',
                                                  fontColor: ColorsConfig()
                                                      .background(),
                                                  fontSize: 16.0.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ).dialog(context);
                                    } else if (_img.length == 1 &&
                                            _img[0].path.endsWith('.gif') ||
                                        _img.length == 2 &&
                                            (_img[0].path.endsWith('.gif') ||
                                                _img[1]
                                                    .path
                                                    .endsWith('.gif')) ||
                                        _img.length == 3 &&
                                            (_img[0].path.endsWith('.gif') ||
                                                _img[1].path.endsWith('.gif') ||
                                                _img[2]
                                                    .path
                                                    .endsWith('.gif')) ||
                                        _img.length == 4 &&
                                            (_img[0].path.endsWith('.gif') ||
                                                _img[1].path.endsWith('.gif') ||
                                                _img[2].path.endsWith('.gif') ||
                                                _img[3]
                                                    .path
                                                    .endsWith('.gif')) ||
                                        _img.length == 5 &&
                                            (_img[0].path.endsWith('.gif') ||
                                                _img[1].path.endsWith('.gif') ||
                                                _img[2].path.endsWith('.gif') ||
                                                _img[3].path.endsWith('.gif') ||
                                                _img[4]
                                                    .path
                                                    .endsWith('.gif'))) {
                                      ToastBuilder().toast(
                                        Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          padding: const EdgeInsets.all(14.0),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 30.0),
                                          decoration: BoxDecoration(
                                            color: ColorsConfig.defaultToast
                                                .withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                          child: CustomTextBuilder(
                                            text: '지원하지 않는 이미지 포맷입니다',
                                            fontColor:
                                                ColorsConfig.defaultWhite,
                                            fontSize: 14.0.sp,
                                          ),
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        for (int i = 0; i < _img.length; i++) {
                                          imageList.add(_img[i]);
                                        }
                                        allSelectImage =
                                            patchImageList + imageList;
                                        categoryValue = 'i';
                                      });
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 14.0),
                                  child: SvgAssets(
                                    image: 'assets/icon/picture.svg',
                                    color: ColorsConfig().textBlack2(),
                                    width: 20.0,
                                    height: 20.0,
                                  ),
                                ),
                              ),
                              InkWell(
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
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 18.3.r,
                                                            vertical: 22.8.r),
                                                    decoration: BoxDecoration(
                                                      color: ColorsConfig()
                                                          .background(),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        topLeft:
                                                            Radius.circular(
                                                                12.0),
                                                        topRight:
                                                            Radius.circular(
                                                                12.0),
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
                                                                      width: 20.0
                                                                          .w),
                                                                  SvgAssets(
                                                                    image:
                                                                        'assets/icon/arrow_down.svg',
                                                                    color: ColorsConfig()
                                                                        .textWhite1(),
                                                                    width: 14.0,
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
                                                                fontSize:
                                                                    16.0.sp,
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
                                                                  .then(
                                                                      (_value) {
                                                                // 검색시 스크롤 최상단으로 돌려줌
                                                                gifScrollController
                                                                    .jumpTo(
                                                                        0.0);
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
                                                                      .subBackground1(),
                                                              enabledBorder:
                                                                  OutlineInputBorder(
                                                                borderSide:
                                                                    BorderSide(
                                                                  width: 0.5,
                                                                  color: ColorsConfig()
                                                                      .border1(),
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
                                                                      .border1(),
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
                                                                      .border1(),
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
                                                                fontSize:
                                                                    14.0.sp,
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
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            15.0),
                                                                    child:
                                                                        SvgAssets(
                                                                      image:
                                                                          'assets/icon/search.svg',
                                                                      color: ColorsConfig()
                                                                          .textBlack2(),
                                                                      width:
                                                                          18.0,
                                                                      height:
                                                                          18.0,
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
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                            textAlignVertical:
                                                                TextAlignVertical
                                                                    .center,
                                                            onChanged:
                                                                (value) {},
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
                                                          onTap: () {
                                                            setState(() {
                                                              gifStr =
                                                                  _gifs[index];
                                                              categoryValue =
                                                                  'g';
                                                              Navigator.pop(
                                                                  context);
                                                            });
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ColorsConfig()
                                                                  .textBlack2(),
                                                              image: DecorationImage(
                                                                  image: NetworkImage(
                                                                      '${_gifs[index]}'),
                                                                  fit: BoxFit
                                                                      .cover),
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
                                child: Container(
                                  margin: const EdgeInsets.only(right: 14.0),
                                  child: SvgAssets(
                                    image: 'assets/icon/gif.svg',
                                    color: ColorsConfig().textBlack2(),
                                    width: 20.0,
                                    height: 20.0,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  mainTextFocusNode.unfocus();
                                  setState(() {
                                    onYoutubeLink = true;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 14.0),
                                  child: SvgAssets(
                                    image: 'assets/icon/youtube_link.svg',
                                    color: ColorsConfig().textBlack2(),
                                    width: 20.0,
                                    height: 20.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget titleTextInputWidget(WritingType _type) {
    return Column(
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
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                              text: '카테고리',
                              fontColor: ColorsConfig().textWhite1(),
                              fontSize: 18.0.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                postCategoryType = '국내증시';
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
                                text: '국내증시',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                postCategoryType = '해외증시';
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
                                text: '해외증시',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                postCategoryType = '파생상품';
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
                                text: '파생상품',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                postCategoryType = '암호화폐';
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
                                text: '암호화폐',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                postCategoryType = '커뮤니티';
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
                                text: '커뮤니티',
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
                    text: postCategoryType.isEmpty ? '카테고리' : postCategoryType,
                    fontColor: postCategoryType.isEmpty
                        ? ColorsConfig().textBlack2()
                        : ColorsConfig().textWhite1(),
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
          height: 50.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                child: TextFormField(
                  controller: titleController,
                  focusNode: titleFocusNode,
                  keyboardType: TextInputType.text,
                  maxLength: _type != WritingType.vote ? 300 : 100,
                  autofocus: true,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                    hintText: _type == WritingType.post
                        ? '제목을 입력해주세요.'
                        : _type == WritingType.news
                            ? '제목은 자동으로 입력됩니다.'
                            : '투표 제목',
                    hintStyle: TextStyle(
                      color: ColorsConfig().textBlack2(),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  style: TextStyle(
                    color: ColorsConfig().textWhite1(),
                    fontSize: 16.0.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  // onChanged: (value) {
                  //   setState(() {
                  //     titleLength = value.length;
                  //   });
                  // },
                ),
              ),
              // CustomTextBuilder(
              //   text: '$titleLength/20',
              //   fontColor: ColorsConfig().textBlack2(),
              //   fontSize: 12.0.sp,
              //   fontWeight: FontWeight.w400,
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget postTextInputWidget() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
      constraints: const BoxConstraints(
        minHeight: 220.0,
        // maxHeight: youtubeStr.isNotEmpty || gifStr.isNotEmpty || imageList.isNotEmpty ? 280.0 : double.infinity,
      ),
      child: Focus(
        onFocusChange: (value) {
          setState(() {
            isMainTextFocus = value;
          });
        },
        child: TextFormField(
          controller: mainTextController,
          focusNode: mainTextFocusNode,
          scrollPhysics:
              youtubeStr.isNotEmpty || gifStr.isNotEmpty || imageList.isNotEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
          scrollPadding: isMainTextFocus
              ? const EdgeInsets.only(bottom: 60.0)
              : EdgeInsets.zero,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          maxLength: 5000,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            isDense: true,
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            counterText: '',
            hintText: '본문 내용을 입력해주세요.',
            hintStyle: TextStyle(
              color: ColorsConfig().textBlack2(),
              fontSize: 16.0.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          style: TextStyle(
            color: ColorsConfig().textWhite1(),
            fontSize: 16.0.sp,
            fontWeight: FontWeight.w400,
          ),
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) {},
        ),
      ),
    );
  }

  Widget newsTextInputWidget() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        minHeight: 400.0.h,
        maxHeight: double.infinity,
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
      child: Focus(
        onFocusChange: (value) {
          setState(() {
            isMainTextFocus = value;
          });
        },
        child: TextFormField(
          controller: mainTextController,
          focusNode: mainTextFocusNode,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          scrollPadding: EdgeInsets.zero,
          keyboardType: TextInputType.url,
          maxLines: null,
          style: TextStyle(
            color: ColorsConfig().textWhite1(),
            fontSize: 14.0.sp,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              isDense: true,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              counterText: '',
              hintText: 'URL을 입력하세요',
              hintStyle: TextStyle(
                color: ColorsConfig().textBlack2(),
                fontSize: 14.0.sp,
                fontWeight: FontWeight.w400,
              )),
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();

            _debounce = Timer(const Duration(milliseconds: 400), () async {
              MetaDataParser().checkUrl(value).then((_b) {
                if (_b != null) {
                  if (_b) {
                    MetaDataParser().parser(value).then((_r) {
                      if (_r != null) {
                        titleController.text = _r['title'];
                      } else {
                        ToastBuilder().toast(
                          Container(
                            color: ColorsConfig().textWhite1(),
                            padding: const EdgeInsets.all(14.0),
                            child: CustomTextBuilder(
                              text: '올바른 뉴스 URL을 입력해주세요.',
                              fontColor: ColorsConfig().background(),
                              fontSize: 14.0.sp,
                            ),
                          ),
                        );
                      }
                    });
                  } else {
                    ToastBuilder().toast(
                      Container(
                        color: ColorsConfig().textWhite1(),
                        padding: const EdgeInsets.all(14.0),
                        child: CustomTextBuilder(
                          text: '올바른 뉴스 URL을 입력해주세요.',
                          fontColor: ColorsConfig().background(),
                          fontSize: 14.0.sp,
                        ),
                      ),
                    );
                  }
                }
              });
            });
          },
        ),
      ),
    );
  }

  Widget tagInputWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: ColorsConfig().background(),
        border: Border(
          top: BorderSide(
            width: 0.5,
            color: ColorsConfig().border1(),
          ),
        ),
      ),
      child: TextFieldTags(
        textfieldTagsController: tagCtr,
        focusNode: tagFN,
        inputfieldBuilder: (context, tec, fn, error, onChanged, onSubmitted) {
          return ((context, sc, tags, onTagDelete) {
            return TextField(
              controller: tec,
              focusNode: fn,
              cursorColor: ColorsConfig().primary(),
              style: TextStyle(
                color: ColorsConfig().textWhite1(),
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 15.0),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                hintText: '태그입력..',
                hintStyle: TextStyle(
                  color: ColorsConfig().textBlack2(),
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.w400,
                ),
                errorText: error,
                prefixIconConstraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                prefixIcon: tags.isNotEmpty
                    ? SingleChildScrollView(
                        controller: sc,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: tags.map((String tag) {
                          return Container(
                            decoration: BoxDecoration(
                              color: ColorsConfig().subBackground3(),
                              border: Border.all(
                                width: 1.0,
                                color: ColorsConfig().border2(),
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20.0)),
                            ),
                            margin: const EdgeInsets.only(right: 5.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomTextBuilder(
                                  text: '#$tag',
                                  fontColor: ColorsConfig().textBlack1(),
                                  fontSize: 16.0.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                const SizedBox(width: 4.0),
                                InkWell(
                                  child: SvgAssets(
                                    image: 'assets/icon/close_btn.svg',
                                    color: ColorsConfig().textBlack2(),
                                    width: 8.0,
                                    height: 8.0,
                                  ),
                                  onTap: () {
                                    onTagDelete(tag);

                                    setState(() {
                                      tagValues.remove('#' + tag);
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList()),
                      )
                    : null,
              ),
              onChanged: (text) {
                if (text.contains(' ')) {
                  setState(() {
                    String splitSpaceStr = text.substring(0, text.length - 1);

                    if (splitSpaceStr.contains(RegExp(r'^[가-힣0-9a-zA-Z]+$'))) {
                      if (tagValues.isNotEmpty) {
                        if (!tagValues.contains('#' + splitSpaceStr)) {
                          tagValues.add('#' + splitSpaceStr);
                          hashTags += splitSpaceStr + ',';
                          tagCtr.addTag = splitSpaceStr;
                        }
                      } else {
                        tagValues.add('#' + splitSpaceStr);
                        hashTags += splitSpaceStr + ',';
                        tagCtr.addTag = splitSpaceStr;
                      }
                    } else {
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
                            text: '자음/모음/특수문자/공백 사용불가',
                            fontColor: ColorsConfig.defaultWhite,
                            fontSize: 14.0.sp,
                          ),
                        ),
                      );
                    }

                    tec.clear();
                    fn.requestFocus();
                  });
                }
              },
              onSubmitted: (text) {
                setState(() {
                  if (text.contains(RegExp(r'^[가-힣0-9a-zA-Z]+$'))) {
                    if (tagValues.isNotEmpty) {
                      if (!tagValues.contains('#' + text)) {
                        tagValues.add('#' + text);
                        hashTags += text + ',';
                        tagCtr.addTag = text;

                        fn.requestFocus();
                      }
                    } else {
                      tagValues.add('#' + text);
                      hashTags += text + ',';
                      tagCtr.addTag = text;

                      fn.requestFocus();
                    }
                  } else {
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
                          text: '자음/모음/특수문자/공백 사용불가',
                          fontColor: ColorsConfig.defaultWhite,
                          fontSize: 14.0.sp,
                        ),
                      ),
                    );
                  }

                  tec.clear();
                  fn.requestFocus();
                });
              },
            );
          });
        },
      ),
      // child: SingleChildScrollView(
      //   physics: const NeverScrollableScrollPhysics(),
      //   // scrollDirection: Axis.horizontal,
      //   child: TagEditor(
      //     controller: tagTextController,
      //     focusNode: tagTextFocusNode,
      //     length: tagValues.length,
      //     onSubmitted: (text) {
      //       setState(() {
      //         if (text.contains(RegExp(r'^[가-힣0-9a-zA-Z]+$'))) {
      //           tagValues.add('#' + text);
      //           hashTags += text + ',';

      //           tagTextFocusNode.requestFocus();
      //         } else {
      //           ToastBuilder().toast(
      //             Container(
      //               width: MediaQuery.of(context).size.width,
      //               padding: const EdgeInsets.all(14.0),
      //               margin: const EdgeInsets.symmetric(horizontal: 30.0),
      //               decoration: BoxDecoration(
      //                 color: ColorsConfig.defaultToast.withOpacity(0.9),
      //                 borderRadius: BorderRadius.circular(6.0),
      //               ),
      //               child: CustomTextBuilder(
      //                 text: '자음/모음/특수문자/공백 사용불가',
      //                 fontColor: ColorsConfig.defaultWhite,
      //                 fontSize: 14.0.sp,
      //               ),
      //             ),
      //           );
      //         }

      //         tagTextController.clear();
      //       });
      //     },
      //     delimiters: const [' '],
      //     hasAddButton: false,
      //     inputDecoration: InputDecoration(
      //       border: InputBorder.none,
      //       hintText: '태그를 입력해주세요.',
      //       hintStyle: TextStyle(
      //         color: ColorsConfig().textBlack2(),
      //         fontSize: 16.0.sp,
      //         fontWeight: FontWeight.w400,
      //       ),
      //     ),
      //     textStyle: TextStyle(
      //       color: ColorsConfig().textWhite1(),
      //       fontSize: 16.0.sp,
      //       fontWeight: FontWeight.w400,
      //     ),
      //     onTagChanged: (newValue) {
      //       setState(() {
      //         if (newValue.contains(RegExp(r'^[가-힣0-9a-zA-Z]+$'))) {
      //           tagValues.add('#' + newValue);
      //           hashTags += newValue + ',';
      //         } else {
      //           ToastBuilder().toast(
      //             Container(
      //               width: MediaQuery.of(context).size.width,
      //               padding: const EdgeInsets.all(14.0),
      //               margin: const EdgeInsets.symmetric(horizontal: 30.0),
      //               decoration: BoxDecoration(
      //                 color: ColorsConfig.defaultToast.withOpacity(0.9),
      //                 borderRadius: BorderRadius.circular(6.0),
      //               ),
      //               child: CustomTextBuilder(
      //                 text: '자음/모음/특수문자/공백 사용불가',
      //                 fontColor: ColorsConfig.defaultWhite,
      //                 fontSize: 14.0.sp,
      //               ),
      //             ),
      //           );
      //         }
      //       });
      //     },
      //     tagBuilder: (context, index) => _Chip(
      //       index: index,
      //       label: tagValues[index],
      //       onDeleted: (idx) {
      //         setState(() {
      //           tagValues.removeAt(index);
      //         });
      //       },
      //     ),
      //   ),
      // ),
    );
  }

  Future writingTypeSelectBottomSheet(Map<dynamic, dynamic> args) {
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
                      text: '글 종류 선택',
                      fontColor: ColorsConfig().textWhite1(),
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        inSelectType = WritingType.post;
                        postType = 1;
                        if (!args['onPatch']) {
                          titleController.clear();
                          tagTextController.clear();
                          mainTextController.clear();
                          hashTags = '';
                          tagValues.clear();
                          tagCtr.clearTags();
                        }
                        // 투표 컨트롤러 및 배열 초기화
                        // voteOptionController1.clear();
                        // voteOptionController2.clear();
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
                        text: '포스트',
                        // fontColor: ColorsConfig().textWhite1(),
                        fontColor: inSelectType != null
                            ? inSelectType == WritingType.post
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1()
                            : args['type'] == 1
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        inSelectType = WritingType.analytics;
                        postType = 2;
                        if (!args['onPatch']) {
                          titleController.clear();
                          tagTextController.clear();
                          mainTextController.clear();
                          hashTags = '';
                          tagValues.clear();
                          tagCtr.clearTags();
                        }
                        // 투표 컨트롤러 및 배열 초기화
                        // voteOptionController1.clear();
                        // voteOptionController2.clear();
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
                        text: '분석',
                        // fontColor: ColorsConfig().textWhite1(),
                        fontColor: inSelectType != null
                            ? inSelectType == WritingType.analytics
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1()
                            : args['type'] == 2
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        inSelectType = WritingType.debate;
                        postType = 3;
                        if (!args['onPatch']) {
                          titleController.clear();
                          tagTextController.clear();
                          mainTextController.clear();
                          hashTags = '';
                          tagValues.clear();
                          tagCtr.clearTags();
                        }
                        // 투표 컨트롤러 및 배열 초기화
                        // voteOptionController1.clear();
                        // voteOptionController2.clear();
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
                        text: '토론',
                        // fontColor: ColorsConfig().textWhite1(),
                        fontColor: inSelectType != null
                            ? inSelectType == WritingType.debate
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1()
                            : args['type'] == 3
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        inSelectType = WritingType.news;
                        postType = 4;
                        titleController.clear();
                        mainTextController.clear();
                        tagTextController.clear();
                        hashTags = '';
                        tagValues.clear();
                        tagCtr.clearTags();
                        // 투표 컨트롤러 및 배열 초기화
                        // voteOptionController1.clear();
                        // voteOptionController2.clear();
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
                        text: '뉴스',
                        // fontColor: ColorsConfig().textWhite1(),
                        fontColor: inSelectType != null
                            ? inSelectType == WritingType.news
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1()
                            : args['type'] == 4
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        inSelectType = WritingType.vote;
                        postType = 5;
                        titleController.clear();
                        mainTextController.clear();
                        tagTextController.clear();
                        hashTags = '';
                        tagValues.clear();
                        tagCtr.clearTags();
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
                        text: '투표',
                        // fontColor: ColorsConfig().textWhite1(),
                        fontColor: inSelectType != null
                            ? inSelectType == WritingType.vote
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1()
                            : args['type'] == 5
                                ? ColorsConfig().primary()
                                : ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future selectCategoryBottomSheet() async {
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
                      text: '카테고리',
                      fontColor: ColorsConfig().textWhite1(),
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        postCategoryType = '국내증시';
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
                        text: '국내증시',
                        fontColor: ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        postCategoryType = '해외증시';
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
                        text: '해외증시',
                        fontColor: ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        postCategoryType = '파생상품';
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
                        text: '파생상품',
                        fontColor: ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        postCategoryType = '암호화폐';
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
                        text: '암호화폐',
                        fontColor: ColorsConfig().textWhite1(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        postCategoryType = '커뮤니티';
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
                        text: '커뮤니티',
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
