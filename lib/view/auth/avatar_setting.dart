import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:DRPublic/api/character/character_set.dart';
import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/api/character/character_get.dart';
import 'package:DRPublic/widget/text_widget.dart';

class AvatarSettingInitializePage extends StatefulWidget {
  const AvatarSettingInitializePage({Key? key}) : super(key: key);

  @override
  State<AvatarSettingInitializePage> createState() =>
      _AvatarSettingInitializePageState();
}

class _AvatarSettingInitializePageState
    extends State<AvatarSettingInitializePage> {
  GlobalKey globalKey = GlobalKey();

  List<dynamic> avatarDatas = [];

  int bodyIndex = 1;
  int hairIndex = 0;
  int faceIndex = 2;
  int topIndex = 0;
  int bottomIndex = 0;
  int footIndex = 0;
  int itemIndex = 0;

  @override
  void initState() {
    getAvatars();

    super.initState();
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

  Future<void> getAvatars() async {
    final _prefs = await SharedPreferences.getInstance();

    GetRandomCharacterAPI()
        .character(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        avatarDatas = value.result;
        for (int i = 0; i < value.result.length; i++) {
          if (value.result[i]['type'] == 1) {
            bodyIndex = value.result[i]['body_index'];
          } else if (value.result[i]['type'] == 2) {
            faceIndex = value.result[i]['face_index'];
          } else if (value.result[i]['type'] == 3) {
            footIndex = value.result[i]['foot_index'];
          } else if (value.result[i]['type'] == 4) {
            bottomIndex = value.result[i]['bottom_index'];
          } else if (value.result[i]['type'] == 5) {
            topIndex = value.result[i]['top_index'];
          } else if (value.result[i]['type'] == 6) {
            hairIndex = value.result[i]['hair_index'];
          } else if (value.result[i]['type'] == 7) {
            itemIndex = value.result[i]['item_index'];
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConfig().background(),
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        backgroundColor: ColorsConfig().background(),
        title: DRAppBarTitle(
          title: TextConstant.avatarSettingText,
          color: ColorsConfig().textWhite1(),
          size: 17.0.sp,
          fontWeight: FontWeight.w500,
        ),
        actions: [
          TextButton(
            onPressed: () {
              itemToPNG().then((file) async {
                final _prefs = await SharedPreferences.getInstance();

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

                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainScreenBuilder()),
                        (route) => false);
                  }
                });
              });
            },
            child: CustomTextBuilder(
              text: TextConstant.successText,
              fontColor: ColorsConfig().primary(),
              fontSize: 17.0.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          margin: EdgeInsets.only(top: 50.0.h),
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              CustomTextBuilder(
                text: TextConstant.avatarSettingDescriptText,
                fontColor: ColorsConfig().textWhite1(),
                fontSize: 28.0.sp,
                fontWeight: FontWeight.w600,
              ),
              Container(
                margin: const EdgeInsets.only(top: 50.0),
                height: 397,
                child: avatarDatas.isNotEmpty
                    ? RepaintBoundary(
                        key: globalKey,
                        child: Stack(
                          alignment: Alignment.center,
                          children: List.generate(avatarDatas.length, (index) {
                            return Image(
                              image: NetworkImage(
                                  '${avatarDatas[index]['image']}'),
                              filterQuality: FilterQuality.high,
                            );
                          }),
                        ),
                      )
                    : Container(),
              ),
              Expanded(
                child: Container(),
              ),
              InkWell(
                onTap: () async {
                  final _prefs = await SharedPreferences.getInstance();

                  GetRandomCharacterAPI()
                      .character(accesToken: _prefs.getString('AccessToken')!)
                      .then((value) {
                    setState(() {
                      avatarDatas = value.result;
                      for (int i = 0; i < value.result.length; i++) {
                        if (value.result[i]['type'] == 1) {
                          bodyIndex = value.result[i]['body_index'];
                        } else if (value.result[i]['type'] == 2) {
                          faceIndex = value.result[i]['face_index'];
                        } else if (value.result[i]['type'] == 3) {
                          footIndex = value.result[i]['foot_index'];
                        } else if (value.result[i]['type'] == 4) {
                          bottomIndex = value.result[i]['bottom_index'];
                        } else if (value.result[i]['type'] == 5) {
                          topIndex = value.result[i]['top_index'];
                        } else if (value.result[i]['type'] == 6) {
                          hairIndex = value.result[i]['hair_index'];
                        } else if (value.result[i]['type'] == 7) {
                          itemIndex = value.result[i]['item_index'];
                        }
                      }
                    });
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50.0,
                  margin: const EdgeInsets.only(bottom: 10.0),
                  decoration: BoxDecoration(
                    color: ColorsConfig().textWhite1(),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Center(
                    child: CustomTextBuilder(
                      text: TextConstant.changeText,
                      fontColor: ColorsConfig().background(),
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
