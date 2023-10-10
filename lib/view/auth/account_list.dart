import 'dart:developer';

import 'package:DRPublic/api/auth/logout.dart';
import 'package:DRPublic/api/auth/withdraw.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSetListScreen extends StatelessWidget {
  const AccountSetListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: TextConstant.accountManageText,
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: ColorsConfig().background(),
          border: Border(
            top: BorderSide(
              width: 0.5,
              color: ColorsConfig().border1(),
            ),
          ),
        ),
        child: Column(
          children: [
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
                            text: TextConstant.checkLogoutText,
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
                                    text: TextConstant.cancelText,
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
                                final _prefs =
                                    await SharedPreferences.getInstance();

                                Future.delayed(Duration.zero, () async {
                                  switch (RouteGetArguments()
                                      .getArgs(context)['login_type']) {
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
                                      await FlutterNaverLogin
                                          .logOutAndDeleteToken();
                                      break;
                                    case 'a':
                                  }
                                });

                                Future.wait([
                                  SendLogoutDataAPI().logout(
                                      accesToken:
                                          _prefs.getString('AccessToken')!),
                                  _prefs.remove('HasNickname'),
                                  _prefs.remove('HasAvatar'),
                                  _prefs.remove('AccessToken'),
                                  _prefs.remove('SearchList'),
                                ]).then((_) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/login', (route) => false);
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
                                    text: TextConstant.logoutText,
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
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 47.0,
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: CustomTextBuilder(
                  text: TextConstant.logoutText,
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
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
                        height: 226.0.h,
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig().subBackground1(),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8.0),
                            topRight: Radius.circular(8.0),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextBuilder(
                                text: TextConstant.withdrawerGuideText1,
                                fontColor: ColorsConfig().textRed1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              const SizedBox(height: 10.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 10.0,
                                    child: CustomTextBuilder(
                                      text: '-',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        140.0,
                                    child: CustomTextBuilder(
                                      text: TextConstant.withdrawerGuideText2,
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 10.0,
                                    child: CustomTextBuilder(
                                      text: '-',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        140.0,
                                    child: CustomTextBuilder(
                                      text: TextConstant.withdrawerGuideText3,
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              CustomTextBuilder(
                                text: TextConstant.withdrawerGuideText4,
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w400,
                              )
                            ],
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
                                    text: TextConstant.cancelText,
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
                                final _prefs =
                                    await SharedPreferences.getInstance();

                                WithdarwSendAPI()
                                    .withdraw(
                                        accesToken:
                                            _prefs.getString('AccessToken')!)
                                    .then((_) {
                                  Navigator.pop(context);

                                  ToastBuilder().toast(
                                    Container(
                                      width: MediaQuery.of(context).size.width,
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
                                        text: TextConstant
                                            .withdrawerRequestSuccessText,
                                        fontColor: ColorsConfig.defaultWhite,
                                        fontSize: 14.0.sp,
                                      ),
                                    ),
                                  );
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
                                    text: TextConstant.withdrawerRequestText,
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
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 47.0,
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: CustomTextBuilder(
                  text: TextConstant.withdrawerText,
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
  }
}
