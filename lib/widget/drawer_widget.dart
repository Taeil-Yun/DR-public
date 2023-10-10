import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

import 'package:DRPublic/main.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/api/auth/logout.dart';
import 'package:DRPublic/util/theme.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:DRPublic/widget/affiliate_advertise.dart';
import 'package:DRPublic/widget/holding_balance.dart';
import 'package:DRPublic/widget/svg_asset.dart';

class DrawerBuilderWidget extends StatefulWidget {
  const DrawerBuilderWidget({Key? key}) : super(key: key);

  @override
  State<DrawerBuilderWidget> createState() => _DrawerBuilderWidgetState();
}

class _DrawerBuilderWidgetState extends State<DrawerBuilderWidget> {
  Map<String, dynamic> getProfileData = {};

  dynamic yamlData;

  @override
  void initState() {
    apiInitialize();
    readYamlFile();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    UserProfileInfoAPI()
        .getProfile(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getProfileData = value?.result;
      });
    });
  }

  Future<void> readYamlFile() async {
    rootBundle.loadString('pubspec.yaml').then((yaml) {
      setState(() {
        yamlData = loadYaml(yaml);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Container(
          width: MediaQuery.of(context).size.width / 1.3,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.only(top: kToolbarHeight),
          decoration: BoxDecoration(
            color: ColorsConfig().subBackground1(),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12.0),
              bottomRight: Radius.circular(12.0),
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      getProfileData['avatar'] != null
                          ? Container(
                              width:
                                  (MediaQuery.of(context).size.width / 2.6).w,
                              constraints: const BoxConstraints(
                                maxHeight: 400.0,
                              ),
                              child: Image(
                                image:
                                    NetworkImage('${getProfileData['avatar']}'),
                                filterQuality: FilterQuality.high,
                              ),
                            )
                          : Container(),
                      getProfileData.isNotEmpty
                          ? CustomTextBuilder(
                              text: '${getProfileData['nick']}',
                              fontColor: ColorsConfig().textWhite1(),
                              fontSize: 18.0.sp,
                              fontWeight: FontWeight.w700,
                            )
                          : Container(),
                      Container(
                        margin: const EdgeInsets.only(top: 15.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/avatar_change',
                                arguments: {'tabIndex': 0}).then((ret) async {
                              if (ret
                                      .toString()
                                      .replaceAll('{', '')
                                      .replaceAll('}', '') ==
                                  'result_avatar: true') {
                                final _prefs =
                                    await SharedPreferences.getInstance();

                                UserProfileInfoAPI()
                                    .getProfile(
                                        accesToken:
                                            _prefs.getString('AccessToken')!)
                                    .then((value) {
                                  setState(() {
                                    getProfileData = value?.result;
                                  });
                                });
                              }
                            });
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.0),
                              gradient: LinearGradient(
                                colors: [
                                  ColorsConfig().primary(),
                                  ColorsConfig().primarySub1(),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: CustomTextBuilder(
                                text: '아바타 변경',
                                fontColor: ColorsConfig().subBackground1(),
                                fontSize: 15.0.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/my_profile',
                                  arguments: {
                                    'onNavigator': true,
                                  });
                            },
                            child: SizedBox(
                              height: 45.0,
                              child: Row(
                                children: [
                                  SvgAssets(
                                    image: 'assets/icon/profile.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 22.0,
                                    height: 22.0,
                                  ),
                                  const SizedBox(width: 20.0),
                                  CustomTextBuilder(
                                    text: '내 채널',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/fourth');
                            },
                            child: SizedBox(
                              height: 45.0,
                              child: Row(
                                children: [
                                  SvgAssets(
                                    image: 'assets/icon/message.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 22.0,
                                    height: 22.0,
                                  ),
                                  const SizedBox(width: 20.0),
                                  CustomTextBuilder(
                                    text: '쪽지',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, 'my_wallet');
                            },
                            child: SizedBox(
                              height: 45.0,
                              child: Row(
                                children: [
                                  SvgAssets(
                                    image: 'assets/icon/wallet.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 22.0,
                                    height: 22.0,
                                  ),
                                  const SizedBox(width: 20.0),
                                  CustomTextBuilder(
                                    text: '내 지갑',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/setting_list',
                                  arguments: {
                                    'loginType': getProfileData['type'],
                                    'email': getProfileData['email'],
                                    'nickname': getProfileData['nick'],
                                    'regDate': getProfileData['reg_date'],
                                  });
                            },
                            child: SizedBox(
                              height: 45.0,
                              child: Row(
                                children: [
                                  SvgAssets(
                                    image: 'assets/icon/setting.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 22.0,
                                    height: 22.0,
                                  ),
                                  const SizedBox(width: 20.0),
                                  CustomTextBuilder(
                                    text: '설정',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/service_center');
                            },
                            child: SizedBox(
                              height: 45.0,
                              child: Row(
                                children: [
                                  SvgAssets(
                                    image: 'assets/icon/help.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 22.0,
                                    height: 22.0,
                                  ),
                                  const SizedBox(width: 18.0),
                                  CustomTextBuilder(
                                    text: '고객센터',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // InkWell(
                          //   onTap: () async {

                          //   },
                          //   child: SizedBox(
                          //     height: 45.0,
                          //     child: Row(
                          //       children: [
                          //         SvgAssets(
                          //           image: 'assets/icon/service_center.svg',
                          //           color: ColorsConfig().textWhite1(),
                          //           width: 22.0,
                          //           height: 22.0,
                          //         ),
                          //         SizedBox(width: 16.8.w),
                          //         CustomTextBuilder(
                          //           text: '도움말',
                          //           fontColor: ColorsConfig().textWhite1(),
                          //           fontSize: 16.0.sp,
                          //           fontWeight: FontWeight.w500,
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
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
                                        color: ColorsConfig().subBackground1(),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8.0),
                                          topRight: Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Center(
                                        child: CustomTextBuilder(
                                          text: '로그아웃 하시겠습니까?',
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

                                              switch (getProfileData['type']) {
                                                case 'g':
                                                case 'k':
                                                  try {
                                                    await UserApi.instance
                                                        .logout();
                                                  } catch (error) {
                                                    if (error
                                                            is KakaoException &&
                                                        error
                                                            .isInvalidTokenError()) {
                                                      log('토큰 만료 $error');
                                                    } else {
                                                      log('토큰 정보 조회 실패 $error');
                                                    }
                                                  }
                                                  break;
                                                case 'n':
                                                  await FlutterNaverLogin
                                                      .logOutAndDeleteToken();
                                                  break;
                                                case 'a':
                                              }

                                              Future.wait([
                                                SendLogoutDataAPI().logout(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!),
                                                _prefs.remove('HasNickname'),
                                                _prefs.remove('HasAvatar'),
                                                _prefs.remove('AccessToken'),
                                                _prefs.remove('SearchList'),
                                              ]).then((_) {
                                                Navigator
                                                    .pushNamedAndRemoveUntil(
                                                        context,
                                                        '/login',
                                                        (route) => false);
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
                                                  text: '로그아웃',
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
                            child: Container(
                              height: 45.0,
                              margin: const EdgeInsets.only(left: 2.0),
                              child: Row(
                                children: [
                                  SvgAssets(
                                    image: 'assets/icon/logout.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 22.0,
                                    height: 22.0,
                                  ),
                                  const SizedBox(width: 16.0),
                                  CustomTextBuilder(
                                    text: '로그아웃',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            color: ColorsConfig().border1(),
                          ),
                          Column(
                            children: List.generate(3, (_e) {
                              if (_e == 2) {
                                return SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 30.0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CustomTextBuilder(
                                        text: '버전 정보',
                                        fontColor: ColorsConfig().textBlack2(),
                                        fontSize: 16.0.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      CustomTextBuilder(
                                        text: yamlData != null
                                            ? Platform.isAndroid
                                                ? 'v' +
                                                    yamlData['version']
                                                        .toString()
                                                        .split('+')[0]
                                                : 'v' +
                                                    yamlData['ios_version']
                                                        .toString()
                                                        .split('+')[0]
                                            : '',
                                        fontColor: ColorsConfig().textBlack2(),
                                        fontSize: 16.0.sp,
                                        fontWeight: FontWeight.w500,
                                      )
                                    ],
                                  ),
                                );
                              }
                              return InkWell(
                                onTap: () {
                                  if (_e == 0) {
                                    Navigator.pushNamed(context, '/terms_list');
                                  } else if (_e == 1) {
                                    SendAffiliateAdvertisingEmail()
                                        .affiliateAdvertisingEmail(context);
                                  }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 30.0,
                                  alignment: Alignment.centerLeft,
                                  child: CustomTextBuilder(
                                    text: _e == 0
                                        ? '약관 및 정책'
                                        : _e == 1
                                            ? '제휴/광고'
                                            : '',
                                    fontColor: ColorsConfig().textBlack2(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 50.0),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // 포인트 부분
              const Positioned(
                top: 20.0,
                right: 15.0,
                child: HoldingBalanceWidget(),
              ),
              // 테마 변경 부분
              Positioned(
                bottom: 0.0,
                right: 0.0,
                child: InkWell(
                  onTap: () async {
                    final _prefs = await SharedPreferences.getInstance();

                    DRPublicThemes().getDartTheme();

                    if (await DRPublicThemes().getDartTheme() ==
                        ThemeMode.dark) {
                      DRPublicApp.themeNotifier.value = ThemeMode.light;
                      _prefs.setString('AppThemeColor', 'light');
                    } else {
                      DRPublicApp.themeNotifier.value = ThemeMode.dark;
                      _prefs.setString('AppThemeColor', 'dark');
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    padding: const EdgeInsets.only(right: 15.0),
                    decoration: BoxDecoration(
                      color: ColorsConfig().subBackground1(),
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    alignment: Alignment.centerRight,
                    child: SvgAssets(
                      image: 'assets/icon/dark_mode.svg',
                      color: ColorsConfig().textWhite1(),
                      width: 22.0,
                      height: 22.0,
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
