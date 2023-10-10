import 'package:DRPublic/api/user/nickname_setting.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/view/auth/avatar_setting.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NicknameSettingInitializePage extends StatefulWidget {
  const NicknameSettingInitializePage({Key? key}) : super(key: key);

  @override
  State<NicknameSettingInitializePage> createState() =>
      _NicknameSettingInitializePageState();
}

class _NicknameSettingInitializePageState
    extends State<NicknameSettingInitializePage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // 이용약관 동의 체크박스 여부
  bool isTOSChecked = false;
  // 개인정보 수집 및 이용동의 체크박스 여부
  bool isPIAChecked = false;
  // 닉네임 설정 존재 여부
  bool existNickname = false;
  // 닉네임 설정 가능 여부
  bool? regNickname;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _textFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: ColorsConfig().background(),
        appBar: DRAppBar(
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          backgroundColor: ColorsConfig().background(),
          title: DRAppBarTitle(
            title: TextConstant.nicknameSettingTitleText,
            color: ColorsConfig().textWhite1(),
            size: 17.0.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        body: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 50.0.h),
                  child: CustomTextBuilder(
                    text: TextConstant.nicknameSettingDescriptText,
                    fontColor: ColorsConfig().textWhite1(),
                    fontSize: 28.0.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  height: 50.0,
                  margin: const EdgeInsets.only(top: 30.0, bottom: 10.0),
                  child: TextFormField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    keyboardType: TextInputType.text,
                    maxLength: 10,
                    onChanged: (text) {
                      if (text.isEmpty) {
                        setState(() {
                          regNickname = null;
                          existNickname = false;
                        });
                      } else {
                        if (text.length > 1 &&
                            text.length < 11 &&
                            text.contains(RegExp(r'^[가-힣0-9a-zA-Z]+$'))) {
                          setState(() {
                            regNickname = true;
                          });
                        } else {
                          setState(() {
                            regNickname = false;
                            existNickname = false;
                          });
                        }
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      isDense: false,
                      counterText: '',
                      hintText: TextConstant.nicknameSettingPlaceHolderText,
                      hintStyle: TextStyle(
                        color: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 0.5,
                          color: ColorsConfig().textBlack2(),
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 0.5,
                          color: ColorsConfig().textBlack2(),
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 0.5,
                          color: ColorsConfig().primary(),
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    style: TextStyle(
                      color: ColorsConfig().textWhite1(),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                CustomTextBuilder(
                  text: TextConstant.nicknameErrorText1,
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 14.0.sp,
                  fontWeight: FontWeight.w400,
                ),
                regNickname != null
                    ? !regNickname!
                        ? Container(
                            margin: const EdgeInsets.only(top: 5.0),
                            child: CustomTextBuilder(
                              text: TextConstant.nicknameErrorText2,
                              fontColor: ColorsConfig().textRed1(),
                            ),
                          )
                        : existNickname
                            ? Container(
                                margin: const EdgeInsets.only(top: 5.0),
                                child: CustomTextBuilder(
                                  text: TextConstant.nicknameErrorText3,
                                  fontColor: ColorsConfig().textRed1(),
                                ),
                              )
                            : Container()
                    : Container(),
                // 빈 공간
                Expanded(
                  child: Container(),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 25.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                isTOSChecked = !isTOSChecked;
                                _textFocusNode.unfocus();
                              });
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 25.0,
                                  height: 25.0,
                                  child: Checkbox(
                                    value: isTOSChecked,
                                    onChanged: (value) {
                                      setState(() {
                                        isTOSChecked = value!;
                                        _textFocusNode.unfocus();
                                      });
                                    },
                                    side: BorderSide(
                                      width: 0.5,
                                      color: ColorsConfig().border1(),
                                    ),
                                    checkColor: ColorsConfig().background(),
                                    activeColor: ColorsConfig().primary(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                CustomTextBuilder(
                                  text: TextConstant.requiredTermOfServiceText,
                                  fontColor: ColorsConfig().textWhite1(),
                                  fontSize: 14.0.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/terms_detail');
                            },
                            child: SvgAssets(
                              image: 'assets/icon/arrow_right.svg',
                              color: ColorsConfig().textWhite1(),
                              width: 12.0,
                              height: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 25.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                isPIAChecked = !isPIAChecked;
                                _textFocusNode.unfocus();
                              });
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 25.0,
                                  height: 25.0,
                                  child: Checkbox(
                                    value: isPIAChecked,
                                    onChanged: (value) {
                                      setState(() {
                                        isPIAChecked = value!;
                                        _textFocusNode.unfocus();
                                      });
                                    },
                                    side: BorderSide(
                                      width: 0.5,
                                      color: ColorsConfig().border1(),
                                    ),
                                    checkColor: ColorsConfig().background(),
                                    activeColor: ColorsConfig().primary(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                CustomTextBuilder(
                                  text: TextConstant.requiredPrivacyeText,
                                  fontColor: ColorsConfig().textWhite1(),
                                  fontSize: 14.0.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/privacy_detail');
                            },
                            child: SvgAssets(
                              image: 'assets/icon/arrow_right.svg',
                              color: ColorsConfig().textWhite1(),
                              width: 12.0,
                              height: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    InkWell(
                      onTap: () async {
                        if (_textController.text.isNotEmpty &&
                            isTOSChecked &&
                            isPIAChecked &&
                            (regNickname != null && regNickname!)) {
                          final _prefs = await SharedPreferences.getInstance();

                          NicknameSettingAPI()
                              .nickname(
                                  accesToken: _prefs.getString('AccessToken')!,
                                  nickname: _textController.text.trim())
                              .then((value) {
                            if (value.result['status'] == 10001) {
                              setState(() {
                                existNickname = true;
                              });
                            } else if (value.result['status'] == 10003) {
                              setState(() {
                                existNickname = true;
                              });
                            } else {
                              setState(() {
                                _prefs.setBool('HasNickname', true);
                                existNickname = false;
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AvatarSettingInitializePage()),
                                    (route) => false);
                              });
                            }
                          });
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 50.0,
                        margin: const EdgeInsets.only(bottom: 10.0),
                        decoration: BoxDecoration(
                          color: _textController.text.isNotEmpty &&
                                  isTOSChecked &&
                                  isPIAChecked &&
                                  (regNickname != null && regNickname!)
                              ? ColorsConfig().primary()
                              : ColorsConfig().textBlack2(),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Center(
                          child: CustomTextBuilder(
                            text: TextConstant.nextText,
                            fontColor: ColorsConfig().background(),
                            fontSize: 18.0.sp,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
