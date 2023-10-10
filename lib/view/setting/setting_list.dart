import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/api/user/user_setting.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/switch/switch.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/enumerated.dart';
import 'package:DRPublic/main.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/util/theme.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingListScreen extends StatefulWidget {
  const SettingListScreen({Key? key}) : super(key: key);

  @override
  State<SettingListScreen> createState() => _SettingListScreenState();
}

class _SettingListScreenState extends State<SettingListScreen> {
  bool pushSubscribePerson = false;
  bool pushComment = false;
  bool pushNewNote = false;
  bool pushNewSubscribe = false;
  bool pushNoteSendPermit = false;
  bool currentDarkTheme = false;
  bool hasChangeOptions = false;
  bool pushSwitch = true;
  bool marketingEmailOption = false;

  LayoutType postLayout = LayoutType.card;

  Map<String, dynamic> getSettingData = {};
  Map<String, dynamic> getProfileData = {};

  @override
  void initState() {
    apiInitialize();
    getLocalSettingValue();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    UserSettingAPI()
        .getSetting(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getSettingData = value.result;
      });
    });

    UserProfileInfoAPI()
        .getProfile(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getProfileData = value?.result;
        marketingEmailOption = value?.result['agreement_email'];
      });
    });
  }

  Future<void> getLocalSettingValue() async {
    final _prefs = await SharedPreferences.getInstance();

    if (_prefs.getString('AppThemeColor') == 'dark') {
      setState(() => currentDarkTheme = true);
    } else {
      setState(() => currentDarkTheme = false);
    }

    if (_prefs.getString('PostLayout') == 'card') {
      setState(() => postLayout = LayoutType.card);
    } else {
      setState(() => postLayout = LayoutType.headline);
    }

    if (_prefs.getBool('PushSettingAll') != null) {
      if (_prefs.getBool('PushSettingAll') == true) {
        setState(() => pushSwitch = true);
      } else {
        setState(() => pushSwitch = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '설정',
        ),
      ),
      body: getSettingData.isNotEmpty
          ? Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: ColorsConfig().background(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    settingCategories('계정정보'),
                    settingContent('계정',
                        widget: Row(
                          children: [
                            SvgAssets(
                                image: RouteGetArguments()
                                            .getArgs(context)['loginType'] ==
                                        'g'
                                    ? 'assets/img/google_logo.svg'
                                    : RouteGetArguments().getArgs(
                                                context)['loginType'] ==
                                            'k'
                                        ? 'assets/img/kakao_logo.svg'
                                        : RouteGetArguments().getArgs(
                                                    context)['loginType'] ==
                                                'n'
                                            ? 'assets/img/naver_logo.svg'
                                            : 'assets/img/apple_logo.svg'),
                            const SizedBox(width: 8.0),
                            CustomTextBuilder(
                              text:
                                  '${RouteGetArguments().getArgs(context)['email']}',
                              fontColor: ColorsConfig().border1(),
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        )),
                    settingContent('닉네임',
                        widget: CustomTextBuilder(
                          text:
                              '${RouteGetArguments().getArgs(context)['nickname']}',
                          fontColor: ColorsConfig().border1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        )),
                    settingContent('가입일',
                        widget: CustomTextBuilder(
                          text: DateFormat('yyyy.MM.dd').format(DateTime.parse(
                              RouteGetArguments().getArgs(context)['regDate'])),
                          fontColor: ColorsConfig().border1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        )),
                    settingContent(
                      '계정관리',
                      widget: SvgAssets(
                        image: 'assets/icon/arrow_right.svg',
                        color: ColorsConfig().textBlack2(),
                        height: 18.0,
                      ),
                      useAllTap: true,
                      press: () {
                        Navigator.pushNamed(context, '/account_list',
                            arguments: {
                              "login_type": RouteGetArguments()
                                  .getArgs(context)['loginType'],
                            });
                      },
                    ),
                    settingCategories('알림설정'),
                    settingContent('푸시알림 받기',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: pushSwitch,
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              _prefs.setBool('PushSettingAll', value);

                              pushSwitch = value;
                              getSettingData['setting_reply'] = value;
                              getSettingData['setting_message'] = value;
                              getSettingData['setting_follow'] = value;
                              getSettingData['setting_news'] = value;
                              getSettingData['setting_recommend'] = value;

                              UserSettingAPI().setSetting(
                                accesToken: _prefs.getString('AccessToken')!,
                                settingReply: value == false ? 0 : 1,
                                settingMessage: value == false ? 0 : 1,
                                settingFollow: value == false ? 0 : 1,
                                settingNews: value == false ? 0 : 1,
                                settingRecommend: value == false ? 0 : 1,
                              );
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingContent('댓글 알림',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: getSettingData['setting_reply'],
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              getSettingData['setting_reply'] = value;

                              UserSettingAPI().setSetting(
                                accesToken: _prefs.getString('AccessToken')!,
                                settingReply: value == false ? 0 : 1,
                                settingMessage:
                                    getSettingData['setting_message'] == false
                                        ? 0
                                        : 1,
                                settingFollow:
                                    getSettingData['setting_follow'] == false
                                        ? 0
                                        : 1,
                                settingNews:
                                    getSettingData['setting_news'] == false
                                        ? 0
                                        : 1,
                                settingRecommend:
                                    getSettingData['setting_recommend'] == false
                                        ? 0
                                        : 1,
                              );
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingContent('메시지 알림',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: getSettingData['setting_message'],
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              getSettingData['setting_message'] = value;

                              UserSettingAPI().setSetting(
                                accesToken: _prefs.getString('AccessToken')!,
                                settingReply:
                                    getSettingData['setting_reply'] == false
                                        ? 0
                                        : 1,
                                settingMessage: value == false ? 0 : 1,
                                settingFollow:
                                    getSettingData['setting_follow'] == false
                                        ? 0
                                        : 1,
                                settingNews:
                                    getSettingData['setting_news'] == false
                                        ? 0
                                        : 1,
                                settingRecommend:
                                    getSettingData['setting_recommend'] == false
                                        ? 0
                                        : 1,
                              );
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingContent('신규 구독 알림',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: getSettingData['setting_follow'],
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              getSettingData['setting_follow'] = value;

                              UserSettingAPI().setSetting(
                                accesToken: _prefs.getString('AccessToken')!,
                                settingReply:
                                    getSettingData['setting_reply'] == false
                                        ? 0
                                        : 1,
                                settingMessage:
                                    getSettingData['setting_message'] == false
                                        ? 0
                                        : 1,
                                settingFollow: value == false ? 0 : 1,
                                settingNews:
                                    getSettingData['setting_news'] == false
                                        ? 0
                                        : 1,
                                settingRecommend:
                                    getSettingData['setting_recommend'] == false
                                        ? 0
                                        : 1,
                              );
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingContent('DR-Public 소식 / 뉴스레터',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: getSettingData['setting_news'],
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              getSettingData['setting_news'] = value;

                              UserSettingAPI().setSetting(
                                accesToken: _prefs.getString('AccessToken')!,
                                settingReply:
                                    getSettingData['setting_reply'] == false
                                        ? 0
                                        : 1,
                                settingMessage:
                                    getSettingData['setting_message'] == false
                                        ? 0
                                        : 1,
                                settingFollow:
                                    getSettingData['setting_follow'] == false
                                        ? 0
                                        : 1,
                                settingNews: value == false ? 0 : 1,
                                settingRecommend:
                                    getSettingData['setting_recommend'] == false
                                        ? 0
                                        : 1,
                              );
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingContent('추천/인기글',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: getSettingData['setting_recommend'],
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              getSettingData['setting_recommend'] = value;

                              UserSettingAPI().setSetting(
                                accesToken: _prefs.getString('AccessToken')!,
                                settingReply:
                                    getSettingData['setting_reply'] == false
                                        ? 0
                                        : 1,
                                settingMessage:
                                    getSettingData['setting_message'] == false
                                        ? 0
                                        : 1,
                                settingFollow:
                                    getSettingData['setting_follow'] == false
                                        ? 0
                                        : 1,
                                settingNews:
                                    getSettingData['setting_news'] == false
                                        ? 0
                                        : 1,
                                settingRecommend: value == false ? 0 : 1,
                              );
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingContent('마케팅 정보 이메일 수신 동의',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: marketingEmailOption,
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            UserProfileInfoAPI()
                                .setProfile(
                                    accesToken:
                                        _prefs.getString('AccessToken')!,
                                    agreementEmail: value ? 1 : 0)
                                .then((rt) {
                              if (rt.result['status'] == 10005) {
                                setState(() {
                                  marketingEmailOption = value;
                                });
                              }
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingCategories('화면 설정'),
                    settingContent('다크모드',
                        widget: SwitchBuilder(
                          type: SwitchType.cupertino,
                          value: currentDarkTheme,
                          onChanged: (value) async {
                            final _prefs =
                                await SharedPreferences.getInstance();

                            DRPublicThemes().getDartTheme();

                            if (await DRPublicThemes().getDartTheme() ==
                                ThemeMode.dark) {
                              DRPublicApp.themeNotifier.value = ThemeMode.light;
                              _prefs.setString('AppThemeColor', 'light');
                            } else {
                              DRPublicApp.themeNotifier.value = ThemeMode.dark;
                              _prefs.setString('AppThemeColor', 'dark');
                            }

                            setState(() {
                              currentDarkTheme = value;
                            });
                          },
                          activeColor: ColorsConfig().primary(),
                        )),
                    settingCategories('유저 관리'),
                    settingContent(
                      '차단목록',
                      widget: SvgAssets(
                        image: 'assets/icon/arrow_right.svg',
                        color: ColorsConfig().textBlack2(),
                        height: 18.0,
                      ),
                      useAllTap: true,
                      press: () {
                        Navigator.pushNamed(context, '/block_list');
                      },
                    ),
                    Container(
                      height: 20.0,
                      color: ColorsConfig().subBackground1(),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
    );
  }

  Widget settingCategories(String category) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 55.0.h,
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
      decoration: BoxDecoration(
        color: ColorsConfig().background(),
        border: Border.symmetric(
          horizontal: BorderSide(
            width: 0.5,
            color: ColorsConfig().border1(),
          ),
        ),
      ),
      child: Row(
        children: [
          CustomTextBuilder(
            text: category,
            fontColor: ColorsConfig().textWhite1(),
            fontSize: 18.0.sp,
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  Widget settingContent(String text,
      {required Widget widget, bool useAllTap = false, Function()? press}) {
    if (useAllTap) {
      return InkWell(
        onTap: press,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 52.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          color: ColorsConfig().subBackground1(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTextBuilder(
                text: text,
                fontColor: ColorsConfig().textWhite1(),
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w400,
              ),
              widget,
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: 52.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        color: ColorsConfig().subBackground1(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextBuilder(
              text: text,
              fontColor: ColorsConfig().textWhite1(),
              fontSize: 16.0.sp,
              fontWeight: FontWeight.w400,
            ),
            widget,
          ],
        ),
      );
    }
  }
}

// SwitchBuilder(
//                       type: SwitchType.cupertino,
//                       value: index == 0
//                         ? getSettingData['setting_post'] ?? false
//                         : index == 1
//                           ? getSettingData['setting_message'] ?? false
//                           : index == 2
//                             ? getSettingData['setting_follow'] ?? false
//                             : index == 3
//                               ? getSettingData['setting_reciver'] ?? false
//                               : index == 5
//                                 ? getSettingData['setting_reply'] ?? false
//                                 : false,
//                       onChanged: (value) async {
//                         final _prefs = await SharedPreferences.getInstance();
                        
//                         setState(() {
//                           switch (index) {
//                             case 0:
//                               getSettingData['setting_post'] = value;
//                               UserSettingAPI().setSetting(
//                                 accesToken: _prefs.getString('AccessToken')!,
//                                 settingPost: getSettingData['setting_post'] == false ? 0 : 1,
//                                 settingMessage: getSettingData['setting_message'] == false ? 0 : 1,
//                                 settingFollow: getSettingData['setting_follow'] == false ? 0 : 1,
//                                 settingReceiver: getSettingData['setting_reciver'] == false ? 0 : 1,
//                                 settingReply: getSettingData['setting_reply'] == false ? 0 : 1,
//                               );
//                               break;
//                             case 1:
//                               getSettingData['setting_message'] = value;
//                               UserSettingAPI().setSetting(
//                                 accesToken: _prefs.getString('AccessToken')!,
//                                 settingPost: getSettingData['setting_post'] == false ? 0 : 1,
//                                 settingMessage: getSettingData['setting_message'] == false ? 0 : 1,
//                                 settingFollow: getSettingData['setting_follow'] == false ? 0 : 1,
//                                 settingReceiver: getSettingData['setting_reciver'] == false ? 0 : 1,
//                                 settingReply: getSettingData['setting_reply'] == false ? 0 : 1,
//                               );
//                               break;
//                             case 2:
//                               getSettingData['setting_follow'] = value;
//                               UserSettingAPI().setSetting(
//                                 accesToken: _prefs.getString('AccessToken')!,
//                                 settingPost: getSettingData['setting_post'] == false ? 0 : 1,
//                                 settingMessage: getSettingData['setting_message'] == false ? 0 : 1,
//                                 settingFollow: getSettingData['setting_follow'] == false ? 0 : 1,
//                                 settingReceiver: getSettingData['setting_reciver'] == false ? 0 : 1,
//                                 settingReply: getSettingData['setting_reply'] == false ? 0 : 1,
//                               );
//                               break;
//                             case 3:
//                               getSettingData['setting_reciver'] = value;
//                               UserSettingAPI().setSetting(
//                                 accesToken: _prefs.getString('AccessToken')!,
//                                 settingPost: getSettingData['setting_post'] == false ? 0 : 1,
//                                 settingMessage: getSettingData['setting_message'] == false ? 0 : 1,
//                                 settingFollow: getSettingData['setting_follow'] == false ? 0 : 1,
//                                 settingReceiver: getSettingData['setting_reciver'] == false ? 0 : 1,
//                                 settingReply: getSettingData['setting_reply'] == false ? 0 : 1,
//                               );
//                               break;
//                             case 5:
//                               getSettingData['setting_reply'] = value;
//                               UserSettingAPI().setSetting(
//                                 accesToken: _prefs.getString('AccessToken')!,
//                                 settingPost: getSettingData['setting_post'] == false ? 0 : 1,
//                                 settingMessage: getSettingData['setting_message'] == false ? 0 : 1,
//                                 settingFollow: getSettingData['setting_follow'] == false ? 0 : 1,
//                                 settingReceiver: getSettingData['setting_reciver'] == false ? 0 : 1,
//                                 settingReply: getSettingData['setting_reply'] == false ? 0 : 1,
//                               );
//                               break;
//                           }
//                         });
//                       },
//                     ),