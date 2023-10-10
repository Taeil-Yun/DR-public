import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:launch_review/launch_review.dart';
import 'package:yaml/yaml.dart';

import 'package:DRPublic/main.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/version/app_version.dart';
import 'package:DRPublic/view/auth/login.dart';
import 'package:DRPublic/view/auth/nickname_setting.dart';
import 'package:DRPublic/view/auth/avatar_setting.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:DRPublic/widget/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({
    Key? key,
    this.themes,
    required this.hasNickname,
    required this.hasAvatar,
    this.hasAccessToken,
  }) : super(key: key);

  ThemeMode? themes;
  bool hasNickname;
  bool hasAvatar;
  String? hasAccessToken;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    splashTimer();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void splashTimer() {
    rootBundle.loadString('pubspec.yaml').then((yaml) {
      var _yaml = loadYaml(yaml);

      GetAppVersionCheckAPI()
          .version(
              version: Platform.isAndroid
                  ? _yaml['version'].toString().split('+')[0]
                  : _yaml['ios_version'].toString().split('+')[0])
          .then((value) {
        if (value.result['type'] == 0) {
          PopUpModal(
            useAndroidBackButton: true,
            barrierDismissible: false,
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
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2b2b2b),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Center(
                    child: CustomTextBuilder(
                      text: '신규 업데이트',
                      fontColor: const Color(0xFFffffff),
                      fontSize: 20.0.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 40.0),
                  color: const Color(0xFF2b2b2b),
                  child: Center(
                    child: CustomTextBuilder(
                      text: '${value.result['content']}',
                      fontColor: const Color(0xFFffffff),
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
                  child: InkWell(
                    onTap: () {
                      if (Platform.isAndroid) {
                        LaunchReview.launch(
                          androidAppId: 'co.kr.weclipse.DRPublic',
                        );
                      } else {
                        UrlLauncherBuilder().launchURL(
                            'https://apps.apple.com/kr/app/%EB%94%9C%EB%A7%81%EB%A3%B8/id1638290200');
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width - 80.5,
                      height: 43.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2b2b2b),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Center(
                        child: CustomTextBuilder(
                          text: '업데이트',
                          fontColor: const Color(0xFF32e855),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).dialog(context);
        } else if (value.result['type'] == 1) {
          PopUpModal(
            useAndroidBackButton: true,
            barrierDismissible: false,
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
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2b2b2b),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Center(
                    child: CustomTextBuilder(
                      text: '신규 업데이트',
                      fontColor: const Color(0xFFffffff),
                      fontSize: 20.0.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  color: const Color(0xFF2b2b2b),
                  child: Center(
                    child: CustomTextBuilder(
                      text: '${value.result['content']}',
                      fontColor: const Color(0xFFffffff),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 0.5,
                        color: Color(0xFF707070),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                              context,
                              routeMoveFade(
                                page: widget.hasAccessToken != null
                                    ? widget.hasNickname == false
                                        ? const NicknameSettingInitializePage()
                                        : widget.hasAvatar == false
                                            ? const AvatarSettingInitializePage()
                                            : widget.hasNickname == true &&
                                                    widget.hasAvatar == true
                                                ? const MainScreenBuilder()
                                                : Container()
                                    : const DRPublicLoginPage(),
                                animationDuration: 350,
                              ),
                              (route) => false);
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 80.5) / 2,
                          height: 43.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2b2b2b),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8.0),
                            ),
                          ),
                          child: Center(
                            child: CustomTextBuilder(
                              text: '취소',
                              fontColor: const Color(0xFFffffff),
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        height: 43.0,
                        color: const Color(0xFF707070),
                      ),
                      InkWell(
                        onTap: () {
                          UrlLauncherBuilder().launchURL(Platform.isAndroid
                              ? 'https://play.google.com/store/apps/details?id=co.kr.weclipse.DRPublic'
                              : 'https://apps.apple.com/kr/app/%EB%94%9C%EB%A7%81%EB%A3%B8/id1638290200');
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 80.5) / 2,
                          height: 43.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2b2b2b),
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(8.0),
                            ),
                          ),
                          child: Center(
                            child: CustomTextBuilder(
                              text: '업데이트',
                              fontColor: const Color(0xFF32e855),
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
        } else {
          Timer(const Duration(milliseconds: 700), () {
            Navigator.pushAndRemoveUntil(
                context,
                routeMoveFade(
                  page: widget.hasAccessToken != null
                      ? widget.hasNickname == false
                          ? const NicknameSettingInitializePage()
                          : widget.hasAvatar == false
                              ? const AvatarSettingInitializePage()
                              : widget.hasNickname == true &&
                                      widget.hasAvatar == true
                                  ? const MainScreenBuilder()
                                  : Container()
                      : const DRPublicLoginPage(),
                  animationDuration: 350,
                ),
                (route) => false);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF1e1e1e),
        child: const Center(
          child: Image(
            image: AssetImage('assets/splash/splash2x.png'),
          ),
        ),
      ),
    );
  }
}
