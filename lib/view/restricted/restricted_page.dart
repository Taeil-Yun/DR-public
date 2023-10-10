import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/widget/text_widget.dart';

class RestrictedScreen extends StatelessWidget {
  RestrictedScreen({
    Key? key,
    required this.status,
    required this.type,
  }) : super(key: key);

  String type;

  int status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(20.0),
        color: ColorsConfig().background(),
        child: Stack(
          children: [
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 200.0),
                CustomTextBuilder(
                  text: 'DR-Public 이용이 정지된 계정',
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 26.0.sp,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 20.0),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: '이 계정은 DR-Public ',
                        style: TextStyle(
                          color: ColorsConfig().textWhite1(),
                          fontSize: 18.0.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'AppleSDGothicNeo',
                          inherit: true,
                        ),
                      ),
                      TextSpan(
                        text: '운영정책',
                        style: TextStyle(
                          color: ColorsConfig().primary(),
                          fontSize: 18.0.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'AppleSDGothicNeo',
                          inherit: true,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/operation_detail');
                          },
                      ),
                      TextSpan(
                        text: ' 위반으로 서비스 이용이 제한되었습니다.',
                        style: TextStyle(
                          color: ColorsConfig().textWhite1(),
                          fontSize: 18.0.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'AppleSDGothicNeo',
                          inherit: true,
                        ),
                      ),
                    ],
                  ),
                  textScaleFactor: 1.0,
                ),
              ],
            ),
            Positioned(
              bottom: 0.0,
              child: TextButton(
                onPressed: () async {
                  final _prefs = await SharedPreferences.getInstance();

                  switch (type) {
                    case 'g':
                    case 'k':
                      try {
                        await UserApi.instance.logout();
                      } catch (error) {
                        if (error is KakaoException &&
                            error.isInvalidTokenError()) {
                          log('토큰 만료 $error');
                        } else {
                          log('토큰 정보 조회 실패 $error');
                        }
                      }
                      break;
                    case 'n':
                      await FlutterNaverLogin.logOutAndDeleteToken();
                      break;
                    case 'a':
                  }

                  _prefs.clear();

                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width - 60.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: ColorsConfig().primary(),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Center(
                    child: CustomTextBuilder(
                      text: '확인',
                      fontColor: ColorsConfig().background(),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
