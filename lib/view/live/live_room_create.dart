import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/dotted_border.dart/dotted_border.dart';
import 'package:DRPublic/component/image_picker/image_picker.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/live/create_room.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class LiveRoomCreateScreen extends StatefulWidget {
  const LiveRoomCreateScreen({Key? key}) : super(key: key);

  @override
  State<LiveRoomCreateScreen> createState() => _LiveRoomCreateScreenState();
}

class _LiveRoomCreateScreenState extends State<LiveRoomCreateScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final FocusNode titleFocusNode;
  late final FocusNode descriptionFocusNode;

  final TextfieldTagsController tagController = TextfieldTagsController();
  final FocusNode tagFocusNode = FocusNode();

  XFile? imageData;

  String tagString = '';

  bool titleErrorStringState = false;
  bool descriptionErrorStringState = false;
  bool tagErrorStringState = false;
  bool thumbnailErrorStringState = false;
  bool categoryFirstChoiceState = false;
  bool titleFirstChoiceState = false;
  bool descriptionFirstChoiceState = false;
  bool tagFirstChoiceState = false;
  bool thumbnailFirstChoiceState = false;

  List<String> tagValues = [];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController();
    descriptionController = TextEditingController();
    titleFocusNode = FocusNode();
    descriptionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();

    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    descriptionFocusNode.dispose();
  }

  bool contentsEmptyStatus() {
    bool _state;

    _state = tagValues.isNotEmpty &&
            titleController.text.trim().isNotEmpty &&
            descriptionController.text.trim().isNotEmpty &&
            imageData != null
        ? false
        : true;

    return _state;
  }

  void checkFocusing() {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (titleFocusNode.hasFocus) {
          titleFocusNode.unfocus();
        }

        if (descriptionFocusNode.hasFocus) {
          descriptionFocusNode.unfocus();
        }

        if (tagFocusNode.hasFocus) {
          tagFocusNode.unfocus();
        }
      },
      child: Scaffold(
        appBar: DRAppBar(
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          leading: DRAppBarLeading(
            press: () => Navigator.pop(context),
            icon: CustomTextBuilder(
              text: '취소',
              fontColor: ColorsConfig().border1(),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: !contentsEmptyStatus()
                  ? () {
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
                                  text: '방을 개설하시겠습니까?',
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

                                      CreateLiveRoomAPI()
                                          .createRoom(
                                        accessToken:
                                            _prefs.getString('AccessToken')!,
                                        title: titleController.text,
                                        description: descriptionController.text,
                                        tag: tagValues
                                            .toString()
                                            .replaceAll('[', '')
                                            .replaceAll(']', '')
                                            .replaceAll('#', ''),
                                        image: imageData!,
                                      )
                                          .then((value) {
                                        if (value.result['status'] == 14000) {
                                          Navigator.pop(context);
                                          Navigator.pop(context);

                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              'live_room',
                                              (route) => false,
                                              arguments: {
                                                "room_index":
                                                    value.result['data']['idx'],
                                                "user_index":
                                                    value.result['data']
                                                        ['user_index'],
                                                "nickname": value.result['data']
                                                    ['nick'],
                                                "avatar": value.result['data']
                                                    ['avatar'],
                                                "is_header": true,
                                              });
                                        } else {
                                          // 14004
                                        }
                                      });
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
                    }
                  : () {
                      setState(() {
                        titleErrorStringState =
                            titleController.text.trim().isEmpty ? true : false;
                        descriptionErrorStringState =
                            descriptionController.text.trim().isEmpty
                                ? true
                                : false;
                        tagErrorStringState = tagValues.isEmpty ? true : false;
                        thumbnailErrorStringState =
                            imageData == null ? true : false;
                      });
                    },
              child: CustomTextBuilder(
                text: '만들기',
                fontColor: contentsEmptyStatus()
                    ? ColorsConfig().textBlack2()
                    : ColorsConfig.subscribeBtnPrimary,
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: ColorsConfig().avatarPartsWrapBackground(),
            border: Border(
              top: BorderSide(
                width: 1.0,
                color: ColorsConfig().border1(),
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  subjectTextWidget('제목'),
                  titleTextFieldWidget(context),
                  titleErrorStringState
                      ? validatorErrorString('4자 이상 입력해주세요.')
                      : Container(),
                  subjectTextWidget('설명'),
                  descriptionTextFieldWidget(context),
                  descriptionErrorStringState
                      ? validatorErrorString('10자 이상 입력해주세요.')
                      : Container(),
                  subjectTextWidget('해시태그'),
                  tagInputEditorWidget(context),
                  !tagErrorStringState
                      ? const SizedBox(height: 30.0)
                      : Container(),
                  tagErrorStringState
                      ? validatorErrorString('태그를 1개이상 입력해주세요.')
                      : Container(),
                  subjectTextWidget('썸네일'),
                  selectThumbnailWidget(context),
                  thumbnailErrorStringState
                      ? validatorErrorString('썸네일을 업로드해주세요.')
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget subjectTextWidget(String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: CustomTextBuilder(
        text: subject,
        fontColor: ColorsConfig().textWhite1(),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget titleTextFieldWidget(BuildContext context) {
    if (titleFirstChoiceState &&
        !titleFocusNode.hasFocus &&
        titleController.text.trim().length < 4) {
      setState(() {
        titleErrorStringState = true;
      });
    }

    if (titleFirstChoiceState &&
        !titleFocusNode.hasFocus &&
        titleController.text.trim().length >= 4) {
      setState(() {
        titleErrorStringState = false;
      });
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 54.0,
      margin:
          !titleErrorStringState ? const EdgeInsets.only(bottom: 30.0) : null,
      child: TextFormField(
        controller: titleController,
        focusNode: titleFocusNode,
        cursorColor: ColorsConfig.subscribeBtnPrimary,
        onTap: !titleFirstChoiceState
            ? () {
                setState(() {
                  titleFirstChoiceState = true;
                });
              }
            : null,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 17.0, vertical: 18.0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1.0,
              color: ColorsConfig().border1(),
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 1.0,
              color: ColorsConfig.subscribeBtnPrimary,
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          hintText: '제목을 입력해주세요.',
          hintStyle: TextStyle(
            color: ColorsConfig().textBlack2(),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            height: 1.0,
          ),
        ),
        style: TextStyle(
          color: ColorsConfig().textWhite1(),
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget descriptionTextFieldWidget(BuildContext context) {
    if (descriptionFirstChoiceState &&
        !descriptionFocusNode.hasFocus &&
        descriptionController.text.trim().length < 10) {
      setState(() {
        descriptionErrorStringState = true;
      });
    }

    if (descriptionFirstChoiceState &&
        !descriptionFocusNode.hasFocus &&
        descriptionController.text.trim().length >= 10) {
      setState(() {
        descriptionErrorStringState = false;
      });
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 114.0,
      margin: !descriptionErrorStringState
          ? const EdgeInsets.only(bottom: 30.0)
          : null,
      child: TextFormField(
        controller: descriptionController,
        focusNode: descriptionFocusNode,
        cursorColor: ColorsConfig.subscribeBtnPrimary,
        expands: true,
        maxLines: null,
        onTap: () {
          if (!descriptionFirstChoiceState) {
            setState(() {
              descriptionFirstChoiceState = true;
            });
          }
        },
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 17.0, vertical: 10.0),
          isCollapsed: true,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1.0,
              color: ColorsConfig().border1(),
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 1.0,
              color: ColorsConfig.subscribeBtnPrimary,
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          hintText: '설명을 입력해주세요.',
          hintStyle: TextStyle(
            color: ColorsConfig().textBlack2(),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            height: 1.0,
          ),
        ),
        style: TextStyle(
          color: ColorsConfig().textWhite1(),
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget tagInputEditorWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 54.0,
      padding: const EdgeInsets.symmetric(horizontal: 17.0),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: tagFocusNode.hasFocus
              ? ColorsConfig.subscribeBtnPrimary
              : ColorsConfig().border1(),
        ),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: TextFieldTags(
        textfieldTagsController: tagController,
        focusNode: tagFocusNode,
        inputfieldBuilder: (context, tec, fn, error, onChanged, onSubmitted) {
          return ((context, sc, tags, onTagDelete) {
            return TextField(
              controller: tec,
              focusNode: fn,
              cursorColor: ColorsConfig().primary(),
              style: TextStyle(
                color: ColorsConfig().textWhite1(),
                fontSize: 16.0,
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
                hintText: '태그를 입력해주세요.',
                hintStyle: TextStyle(
                  color: ColorsConfig().textBlack2(),
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                ),
                errorText: error,
                prefixIconConstraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6),
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
                                  fontSize: 16.0,
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

                                      if (tagValues.isEmpty) {
                                        tagErrorStringState = true;
                                      }
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
                          tagString += splitSpaceStr + ',';
                          tagController.addTag = splitSpaceStr;
                          tagErrorStringState = false;
                        }
                      } else {
                        tagValues.add('#' + splitSpaceStr);
                        tagString += splitSpaceStr + ',';
                        tagController.addTag = splitSpaceStr;
                        tagErrorStringState = false;
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
                            fontSize: 14.0,
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
                        tagString += text + ',';
                        tagController.addTag = text;
                        tagErrorStringState = false;

                        fn.requestFocus();
                      }
                    } else {
                      tagValues.add('#' + text);
                      tagString += text + ',';
                      tagController.addTag = text;
                      tagErrorStringState = false;

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
                          fontSize: 14.0,
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
    );
  }

  Widget selectThumbnailWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: !thumbnailErrorStringState
          ? const EdgeInsets.only(bottom: 30.0)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageData == null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 15.0),
                  child: CustomTextBuilder(
                    text: '방의 컨셉을 나타낼 수 있는 이미지를 업로드해주세요',
                    fontColor: ColorsConfig().textBlack2(),
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                  ),
                )
              : Container(),
          imageData == null
              ? InkWell(
                  onTap: () {
                    ImagePickerSelector().imagePicker().then((_img) {
                      setState(() {
                        imageData = _img;
                        thumbnailErrorStringState = false;
                      });
                    });
                  },
                  child: CustomDottedBorderBuilder(
                    color: ColorsConfig().border1(),
                    radius: const Radius.circular(8.0),
                    borderType: BorderType.rrect,
                    child: SizedBox(
                      width: 177.0,
                      height: 131.0,
                      child: Center(
                        child: CustomTextBuilder(
                          text: '+',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 70.0,
                        ),
                      ),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Container(
                      width: 177.0,
                      height: 131.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: FileImage(File(imageData!.path)),
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5.0,
                      top: 5.0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            imageData = null;
                          });
                        },
                        child: Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: SvgAssets(
                              image: 'assets/icon/close.svg',
                              width: 24.0,
                              height: 24.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget validatorErrorString(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 5.0, left: 5.0, bottom: 30.0),
      child: CustomTextBuilder(
        text: text,
        fontColor: ColorsConfig().textRed2(),
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
