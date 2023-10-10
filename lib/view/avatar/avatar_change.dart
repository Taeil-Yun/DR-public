import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/character/character_get.dart';
import 'package:DRPublic/api/character/character_get_my.dart';
import 'package:DRPublic/api/character/character_get_parts.dart';
import 'package:DRPublic/api/character/character_set.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class AvatarChangeScreen extends StatefulWidget {
  const AvatarChangeScreen({Key? key}) : super(key: key);

  @override
  State<AvatarChangeScreen> createState() => _AvatarChangeScreenState();
}

class _AvatarChangeScreenState extends State<AvatarChangeScreen>
    with TickerProviderStateMixin {
  GlobalKey globalKey = GlobalKey();

  late TabController _tabController;

  int _currentTabIndex = 0;
  int bodyIndex = 1;
  int hairIndex = 0;
  int faceIndex = 2;
  int topIndex = 0;
  int bottomIndex = 0;
  int footIndex = 0;
  int itemIndex = 0;

  bool bodyParts = false;
  bool hairParts = false;
  bool faceParts = false;
  bool topParts = false;
  bool bottomParts = false;
  bool footParts = false;
  bool itemParts = false;

  int? selectBody;
  int? selectHair;
  int? selectFace;
  int? selectTop;
  int? selectBottom;
  int? selectFoot;
  int? selectItem;

  List<dynamic> myCharacterData = [];
  List<dynamic> defaultAvatarData = [];

  Map<String, dynamic> getCharacterData = {};

  @override
  void initState() {
    _tabController = TabController(
      length: 7,
      vsync: this, // vsync에 this 형태로 전달해야 애니메이션이 정상 처리됨
    );
    _tabController.addListener(_handleTabSelection);

    apiInitialize();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetCharacterPartsAPI()
        .parts(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getCharacterData = value.result;
      });
    });

    GetCharacterMyAPI()
        .myAvatar(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        myCharacterData = value.result;
        defaultAvatarData = value.result;

        for (int i = 0; i < value.result.length; i++) {
          if (value.result[i].toString().contains('body_index')) {
            bodyParts = true;
            bodyIndex = value.result[i]['body_index'];
          } else if (value.result[i].toString().contains('face_index')) {
            faceParts = true;
            faceIndex = value.result[i]['face_index'];
          } else if (value.result[i].toString().contains('hair_index')) {
            hairParts = true;
            hairIndex = value.result[i]['hair_index'];
          } else if (value.result[i].toString().contains('top_index')) {
            topParts = true;
            topIndex = value.result[i]['top_index'];
          } else if (value.result[i].toString().contains('bottom_index')) {
            bottomParts = true;
            bottomIndex = value.result[i]['bottom_index'];
          } else if (value.result[i].toString().contains('foot_index')) {
            footParts = true;
            footIndex = value.result[i]['foot_index'];
          } else if (value.result[i].toString().contains('item_index')) {
            itemParts = true;
            itemIndex = value.result[i]['item_index'];
          }
        }
      });
    });
  }

  List<dynamic> mergeAvatarSort() {
    myCharacterData.sort((a, b) => a['gravity'].compareTo(b['gravity']));

    return myCharacterData;
  }

  Future<File> itemToPNG() async {
    final RenderRepaintBoundary boundary =
        globalKey.currentContext?.findRenderObject()! as RenderRepaintBoundary;
    ui.Image? image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData?.buffer.asUint8List();
    var bs64 = base64Encode(pngBytes!);

    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final File file = File(filePath);
    await file.writeAsBytes(pngBytes);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '',
        ),
        backgroundColor: ColorsConfig().subBackground1(),
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        actions: [
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
                          text: '저장하시겠습니까?',
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
                              itemToPNG().then((file) async {
                                final _prefs =
                                    await SharedPreferences.getInstance();

                                SetUserCharacterAPI()
                                    .setCharacter(
                                  accessToken: _prefs.getString('AccessToken')!,
                                  body: bodyIndex,
                                  hair: hairIndex,
                                  face: faceIndex,
                                  top: topIndex,
                                  bottom: bottomIndex,
                                  foot: footIndex,
                                  item: itemIndex,
                                  image: file,
                                )
                                    .then((value) {
                                  if (value.result['status'] == 10015) {
                                    _prefs.setBool('HasAvatar', true);

                                    Navigator.pop(context);
                                    Navigator.pop(context, {
                                      'result_avatar': true,
                                    });

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
                                          text: '아바타 변경이 완료되었습니다.',
                                          fontColor: ColorsConfig.defaultWhite,
                                          fontSize: 14.0.sp,
                                        ),
                                      ),
                                    );
                                  }
                                });
                              });
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
            },
            child: CustomTextBuilder(
              text: '저장',
              fontColor: ColorsConfig().primary(),
              fontSize: 18.0.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 400.h,
            color: ColorsConfig().subBackground1(),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: 372.h,
                    margin: const EdgeInsets.only(bottom: 25.0),
                    child: RepaintBoundary(
                      key: globalKey,
                      child: Stack(
                        alignment: Alignment.center,
                        children: List.generate(
                            myCharacterData.isNotEmpty
                                ? myCharacterData.length
                                : 0, (index) {
                          return Image(
                            image: NetworkImage(
                                '${myCharacterData[index]['image']}'),
                            filterQuality: ui.FilterQuality.high,
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 25.0,
                  right: 25.0,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            myCharacterData = [
                              {
                                'body_index': 1,
                                'gravity': '1.00000',
                                'image': getCharacterData['basic_body'],
                              },
                              {
                                'face_index': 2,
                                'gravity': '2.00000',
                                'image':
                                    'https://image.DRPublic.co.kr/character/face/1.png',
                              }
                            ];

                            bodyIndex = 1;
                            hairIndex = 0;
                            faceIndex = 2;
                            topIndex = 0;
                            bottomIndex = 0;
                            footIndex = 0;
                            itemIndex = 0;

                            bodyParts = true;
                            hairParts = false;
                            faceParts = true;
                            topParts = false;
                            bottomParts = false;
                            footParts = false;
                            itemParts = false;
                          });
                        },
                        child: Container(
                          width: 35.0,
                          height: 35.0,
                          margin: const EdgeInsets.only(bottom: 15.0),
                          decoration: BoxDecoration(
                            color: ColorsConfig().avatarIconBackground(),
                            borderRadius: BorderRadius.circular(17.5),
                          ),
                          child: Center(
                            child: SvgAssets(
                              image: 'assets/icon/return.svg',
                              color: ColorsConfig().avatarIconColor(),
                              width: 18.0,
                              height: 18.0,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final _prefs = await SharedPreferences.getInstance();

                          setState(() {
                            GetRandomCharacterAPI()
                                .character(
                                    accesToken:
                                        _prefs.getString('AccessToken')!)
                                .then((value) {
                              setState(() {
                                myCharacterData = value.result;
                                for (int i = 0; i < value.result.length; i++) {
                                  if (value.result[i]['type'] == 1) {
                                    bodyParts = true;
                                    bodyIndex = value.result[i]['body_index'];
                                  } else if (value.result[i]['type'] == 2) {
                                    faceParts = true;
                                    faceIndex = value.result[i]['face_index'];
                                  } else if (value.result[i]['type'] == 3) {
                                    footParts = true;
                                    footIndex = value.result[i]['foot_index'];
                                  } else if (value.result[i]['type'] == 4) {
                                    bottomParts = true;
                                    bottomIndex =
                                        value.result[i]['bottom_index'];
                                  } else if (value.result[i]['type'] == 5) {
                                    topParts = true;
                                    topIndex = value.result[i]['top_index'];
                                  } else if (value.result[i]['type'] == 6) {
                                    hairParts = true;
                                    hairIndex = value.result[i]['hair_index'];
                                  } else if (value.result[i]['type'] == 7) {
                                    itemParts = true;
                                    itemIndex = value.result[i]['item_index'];
                                  }
                                }
                              });
                            });
                          });
                        },
                        child: Container(
                          width: 35.0,
                          height: 35.0,
                          decoration: BoxDecoration(
                            color: ColorsConfig().avatarIconBackground(),
                            borderRadius: BorderRadius.circular(17.5),
                          ),
                          child: Center(
                            child: SvgAssets(
                              image: 'assets/icon/random.svg',
                              color: ColorsConfig().avatarIconColor(),
                              width: 16.0,
                              height: 16.0,
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
          Container(
            decoration: BoxDecoration(
              color: ColorsConfig().subBackground1(),
              border: Border.symmetric(
                horizontal: BorderSide(
                  width: 0.5,
                  color: ColorsConfig().border1(),
                ),
              ),
            ),
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
                    text: '컬러',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '머리',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '얼굴',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '상의',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '하의',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '신발',
                  ),
                ),
                Tab(
                  child: CustomTextBuilder(
                    text: '아이템',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: ColorsConfig().avatarPartsWrapBackground(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, //수평 Padding
                              crossAxisSpacing: 18.0, //수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['body'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  if (bodyParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('body_index')) {
                                          if (myCharacterData[i]
                                                  ['body_index'] !=
                                              getCharacterData['body'][index]
                                                  ['body_index']) {
                                            bodyParts = true;
                                            myCharacterData.removeAt(i);
                                            bodyIndex = getCharacterData['body']
                                                [index]['body_index'];
                                            selectBody = index;
                                            myCharacterData.add(
                                                getCharacterData['body']
                                                    [index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      bodyParts = true;
                                      bodyIndex = getCharacterData['body']
                                          [index]['body_index'];
                                      selectBody = index;
                                      myCharacterData
                                          .add(getCharacterData['body'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border: selectBody != null &&
                                            index == selectBody
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Image(
                                    image: NetworkImage(
                                      getCharacterData['body'][index]['image'],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, //수평 Padding
                              crossAxisSpacing: 18.0, //수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['hair'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  if (hairParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('hair_index')) {
                                          if (myCharacterData[i]
                                                  ['hair_index'] ==
                                              getCharacterData['hair'][index]
                                                  ['hair_index']) {
                                            hairParts = false;
                                            hairIndex = 0;
                                            selectHair = null;
                                            myCharacterData.removeAt(i);
                                            mergeAvatarSort();
                                            break;
                                          } else {
                                            hairParts = true;
                                            myCharacterData.removeAt(i);
                                            hairIndex = getCharacterData['hair']
                                                [index]['hair_index'];
                                            selectHair = index;
                                            myCharacterData.add(
                                                getCharacterData['hair']
                                                    [index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      hairParts = true;
                                      hairIndex = getCharacterData['hair']
                                          [index]['hair_index'];
                                      selectHair = index;
                                      myCharacterData
                                          .add(getCharacterData['hair'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border: selectHair != null &&
                                            index == selectHair
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['basic_body'],
                                          ),
                                        ),
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['hair'][index]
                                                ['image'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, //수평 Padding
                              crossAxisSpacing: 18.0, //수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['face'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  if (faceParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('face_index')) {
                                          if (myCharacterData[i]
                                                  ['face_index'] !=
                                              getCharacterData['face'][index]
                                                  ['face_index']) {
                                            faceParts = true;
                                            myCharacterData.removeAt(i);
                                            faceIndex = getCharacterData['face']
                                                [index]['face_index'];
                                            selectFace = index;
                                            myCharacterData.add(
                                                getCharacterData['face']
                                                    [index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      faceParts = true;
                                      faceIndex = getCharacterData['face']
                                          [index]['face_index'];
                                      selectFace = index;
                                      myCharacterData
                                          .add(getCharacterData['face'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border: selectFace != null &&
                                            index == selectFace
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['basic_body'],
                                          ),
                                        ),
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['face'][index]
                                                ['image'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, //수평 Padding
                              crossAxisSpacing: 18.0, //수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['top'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  if (topParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('top_index')) {
                                          if (myCharacterData[i]['top_index'] ==
                                              getCharacterData['top'][index]
                                                  ['top_index']) {
                                            topParts = false;
                                            topIndex = 0;
                                            selectTop = null;
                                            myCharacterData.removeAt(i);
                                            mergeAvatarSort();
                                            break;
                                          } else {
                                            topParts = true;
                                            myCharacterData.removeAt(i);
                                            topIndex = getCharacterData['top']
                                                [index]['top_index'];
                                            selectTop = index;
                                            myCharacterData.add(
                                                getCharacterData['top'][index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      topParts = true;
                                      topIndex = getCharacterData['top'][index]
                                          ['top_index'];
                                      selectTop = index;
                                      myCharacterData
                                          .add(getCharacterData['top'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border:
                                        selectTop != null && index == selectTop
                                            ? Border.all(
                                                width: 0.5,
                                                color: ColorsConfig().primary(),
                                              )
                                            : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['basic_body'],
                                          ),
                                        ),
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['top'][index]
                                                ['image'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, // 수평 Padding
                              crossAxisSpacing: 18.0, // 수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['bottom'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  if (bottomParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('bottom_index')) {
                                          if (myCharacterData[i]
                                                  ['bottom_index'] ==
                                              getCharacterData['bottom'][index]
                                                  ['bottom_index']) {
                                            bottomParts = false;
                                            bottomIndex = 0;
                                            selectBottom = null;
                                            myCharacterData.removeAt(i);
                                            mergeAvatarSort();
                                            break;
                                          } else {
                                            bottomParts = true;
                                            myCharacterData.removeAt(i);
                                            bottomIndex =
                                                getCharacterData['bottom']
                                                    [index]['bottom_index'];
                                            selectBottom = index;
                                            myCharacterData.add(
                                                getCharacterData['bottom']
                                                    [index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      bottomParts = true;
                                      bottomIndex = getCharacterData['bottom']
                                          [index]['bottom_index'];
                                      selectBottom = index;
                                      myCharacterData.add(
                                          getCharacterData['bottom'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border: selectBottom != null &&
                                            index == selectBottom
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['basic_body'],
                                          ),
                                        ),
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['bottom'][index]
                                                ['image'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, // 수평 Padding
                              crossAxisSpacing: 18.0, // 수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['foot'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  if (footParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('foot_index')) {
                                          if (myCharacterData[i]
                                                  ['foot_index'] ==
                                              getCharacterData['foot'][index]
                                                  ['foot_index']) {
                                            footParts = false;
                                            footIndex = 0;
                                            selectFoot = null;
                                            myCharacterData.removeAt(i);
                                            mergeAvatarSort();
                                            break;
                                          } else {
                                            footParts = true;
                                            myCharacterData.removeAt(i);
                                            footIndex = getCharacterData['foot']
                                                [index]['foot_index'];
                                            selectFoot = index;
                                            myCharacterData.add(
                                                getCharacterData['foot']
                                                    [index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      footParts = true;
                                      footIndex = getCharacterData['foot']
                                          [index]['foot_index'];
                                      selectFoot = index;
                                      myCharacterData
                                          .add(getCharacterData['foot'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border: selectFoot != null &&
                                            index == selectFoot
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['basic_body'],
                                          ),
                                        ),
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['foot'][index]
                                                ['image'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(15.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 1 개의 행에 보여줄 item 개수
                              mainAxisSpacing: 18.0, // 수평 Padding
                              crossAxisSpacing: 18.0, // 수직 Padding
                            ),
                            itemCount: getCharacterData.isNotEmpty
                                ? getCharacterData['item'].length
                                : 0,
                            itemBuilder: (centext, index) {
                              return InkWell(
                                splashColor: ColorsConfig.transparent,
                                highlightColor: ColorsConfig.transparent,
                                onTap: () {
                                  // for (int i=0; i<myCharacterData.length; i++) {
                                  //   if (myCharacterData[i].toString().contains('type') && myCharacterData[i]['type'] == 7) {
                                  //     setState(() {
                                  //       myCharacterData.removeAt(i);
                                  //       mergeAvatarSort();
                                  //     });
                                  //     break;
                                  //   }
                                  // }
                                  if (itemParts) {
                                    setState(() {
                                      for (int i = 0;
                                          i < myCharacterData.length;
                                          i++) {
                                        if (myCharacterData[i]
                                            .toString()
                                            .contains('item_index')) {
                                          if (myCharacterData[i]
                                                  ['item_index'] ==
                                              getCharacterData['item'][index]
                                                  ['item_index']) {
                                            itemParts = false;
                                            itemIndex = 0;
                                            selectItem = null;
                                            myCharacterData.removeAt(i);
                                            mergeAvatarSort();
                                            break;
                                          } else {
                                            myCharacterData.removeAt(i);
                                            itemIndex = getCharacterData['item']
                                                [index]['item_index'];
                                            selectItem = index;
                                            myCharacterData.add(
                                                getCharacterData['item']
                                                    [index]);
                                            mergeAvatarSort();
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      itemParts = true;
                                      itemIndex = getCharacterData['item']
                                          [index]['item_index'];
                                      selectItem = index;
                                      myCharacterData
                                          .add(getCharacterData['item'][index]);
                                      mergeAvatarSort();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsConfig().avatarPartsBackground(),
                                    border: selectItem != null &&
                                            index == selectItem
                                        ? Border.all(
                                            width: 0.5,
                                            color: ColorsConfig().primary(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        double.parse(getCharacterData['item']
                                                    [index]['gravity']) <
                                                1.00000
                                            ? Image(
                                                image: NetworkImage(
                                                  getCharacterData['item']
                                                      [index]['image'],
                                                ),
                                              )
                                            : Container(),
                                        Image(
                                          image: NetworkImage(
                                            getCharacterData['basic_body'],
                                          ),
                                        ),
                                        double.parse(getCharacterData['item']
                                                    [index]['gravity']) >
                                                1.00000
                                            ? Image(
                                                image: NetworkImage(
                                                  getCharacterData['item']
                                                      [index]['image'],
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}
