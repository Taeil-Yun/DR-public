import 'dart:developer';
import 'dart:io';

import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/view/auth/avatar_setting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/main.dart';
import 'package:DRPublic/component/get_fcm_token.dart';
import 'package:DRPublic/api/auth/google.dart';
import 'package:DRPublic/api/auth/apple.dart';
import 'package:DRPublic/api/auth/kakao.dart';
import 'package:DRPublic/api/auth/naver.dart';
import 'package:DRPublic/view/auth/nickname_setting.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '',
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

class DRPublicLoginPage extends StatelessWidget {
  const DRPublicLoginPage({Key? key}) : super(key: key);

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.signIn().then((value) async {
        final _fcmToken = await FirebaseFunctionSet().getFCMToken();
        await value?.authentication.then((va) async {
          log('----------------------------------------');
          log('${va.idToken?.split('.')[0]}.');
          log('${va.idToken?.split('.')[1]}');
          log('.${va.idToken?.split('.')[2]}');
          log('----------------------------------------');
          GoogleSignInAPI()
              .google(idToken: va.idToken!, fcmToken: _fcmToken)
              .then((_value) async {
            final _prefs = await SharedPreferences.getInstance();

            _prefs.setString('AccessToken', _value.result['access_token']);
            _prefs.setBool('HasNickname', _value.result['nick']);
            _prefs.setBool('HasAvatar', _value.result['avatar']);

            if (_value.result['nick'] == true &&
                _value.result['avatar'] == true) {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainScreenBuilder()),
                  (route) => false);
            } else {
              if (_value.result['nick'] == false) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const NicknameSettingInitializePage()),
                    (route) => false);
              } else if (_value.result['nick'] == true &&
                  _value.result['avatar'] == false) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AvatarSettingInitializePage()),
                    (route) => false);
              }
            }
          });
        });
      });
    } catch (error) {
      log(error.toString());
    }
  }

  Future<void> signInWithKakao(BuildContext context) async {
    KakaoSdk.init(
      // nativeAppKey: '557be2c99b874095a13ec73cb230a295',  // dev
      // javaScriptAppKey: '0b4354b4531634c833478c058d74016e',  // dev
      nativeAppKey: 'e914cacc8e1f097955d513c1d5a04ec0', // prod
      javaScriptAppKey: '5ff6929a29f5c5006227fad6b136abee', // prod
      loggingEnabled: false,
    );

    final _fcmToken = await FirebaseFunctionSet().getFCMToken();
    if (await isKakaoTalkInstalled()) {
      if (await AuthApi.instance.hasToken()) {
        try {
          await UserApi.instance.logout();
          // UserApi.instance.revokeScopes(scopes: ['account_email']);
          // AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
          // log('토큰 유효성 체크 성공 ${tokenInfo.id} ${tokenInfo.expiresIn}');

          // try {
          //   User user = await UserApi.instance.me();
          //   OAuthToken _scope = await UserApi.instance.loginWithNewScopes(['account_email', 'openid'], nonce: 'dev_DRPublic');
          //   log(_scope.idToken);
          //   log('사용자 정보 요청 성공'
          //         '\n회원번호: ${user.id}'
          //         '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
          //         '\n이메일: ${user.kakaoAccount?.email}'
          //         '\n이름: ${user.kakaoAccount?.profile?.toJson()['nickname']}'
          //         '\n프로퍼티: ${user.properties}'
          //   );
          // } catch (error) {
          //   log('사용자 정보 요청 실패 $error');
          // }
        } catch (error) {
          if (error is KakaoException && error.isInvalidTokenError()) {
            log('토큰 만료 $error');
          } else {
            log('토큰 정보 조회 실패 $error');
          }

          try {
            // 카카오 계정으로 로그인
            await UserApi.instance
                .loginWithKakaoTalk(nonce: 'dev_DRPublic')
                .then((_r) async {
              log('로그인 성공 ${_r.accessToken}');
              log('로그인 성공 ${_r.idToken}');

              var prof = await UserApi.instance.me();
              KakaoSignInAPI()
                  .kakao(
                      idToken: _r.idToken,
                      fcmToken: _fcmToken,
                      profile: prof.kakaoAccount)
                  .then((_v) async {
                final _prefs = await SharedPreferences.getInstance();

                _prefs.setString('AccessToken', _v.result['access_token']);
                _prefs.setBool('HasNickname', _v.result['nick']);
                _prefs.setBool('HasAvatar', _v.result['avatar']);

                log('API호출 성공: ${_v.result}');
                if (_v.result['nick'] == true && _v.result['avatar'] == true) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainScreenBuilder()),
                      (route) => false);
                } else {
                  if (_v.result['nick'] == false) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const NicknameSettingInitializePage()),
                        (route) => false);
                  } else if (_v.result['nick'] == true &&
                      _v.result['avatar'] == false) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AvatarSettingInitializePage()),
                        (route) => false);
                  }
                }
              });
            });
          } catch (error) {
            log('로그인 실패 $error');
          }
        }
      } else {
        log('발급된 토큰 없1음');
        try {
          await UserApi.instance.loginWithKakaoTalk(
              serviceTerms: ['service'],
              nonce: 'dev_DRPublic').then((_r) async {
            var prof = await UserApi.instance.me();
            KakaoSignInAPI()
                .kakao(
                    idToken: _r.idToken,
                    fcmToken: _fcmToken,
                    profile: prof.kakaoAccount)
                .then((_v) async {
              final _prefs = await SharedPreferences.getInstance();

              _prefs.setString('AccessToken', _v.result['access_token']);
              _prefs.setBool('HasNickname', _v.result['nick']);
              _prefs.setBool('HasAvatar', _v.result['avatar']);

              if (_v.result['nick'] == true && _v.result['avatar'] == true) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MainScreenBuilder()),
                    (route) => false);
              } else {
                if (_v.result['nick'] == false) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NicknameSettingInitializePage()),
                      (route) => false);
                } else if (_v.result['nick'] == true &&
                    _v.result['avatar'] == false) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const AvatarSettingInitializePage()),
                      (route) => false);
                }
              }
            });
          });
        } catch (error) {
          log('로그인 실패 $error');
        }
      }
    } else {
      if (await AuthApi.instance.hasToken()) {
        try {
          // AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
          await UserApi.instance
              .loginWithKakaoAccount(nonce: 'dev_DRPublic')
              .then((_r) async {
            var prof = await UserApi.instance.me();
            KakaoSignInAPI()
                .kakao(
                    idToken: _r.idToken,
                    fcmToken: _fcmToken,
                    profile: prof.kakaoAccount)
                .then((_v) async {
              final _prefs = await SharedPreferences.getInstance();

              _prefs.setString('AccessToken', _v.result['access_token']);
              _prefs.setBool('HasNickname', _v.result['nick']);
              _prefs.setBool('HasAvatar', _v.result['avatar']);

              if (_v.result['nick'] == true && _v.result['avatar'] == true) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MainScreenBuilder()),
                    (route) => false);
              } else {
                if (_v.result['nick'] == false) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NicknameSettingInitializePage()),
                      (route) => false);
                } else if (_v.result['nick'] == true &&
                    _v.result['avatar'] == false) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const AvatarSettingInitializePage()),
                      (route) => false);
                }
              }
            });
          });

          try {
            // User user = await UserApi.instance.me();
          } catch (error) {
            log('사용자 정보 요청 실패 $error');
          }
        } catch (error) {
          if (error is KakaoException && error.isInvalidTokenError()) {
            log('토큰 만료 $error');
          } else {
            log('토큰 정보 조회 실패 $error');
          }

          try {
            // 카카오 계정으로 로그인
            await UserApi.instance
                .loginWithKakaoAccount(nonce: 'dev_DRPublic')
                .then((_r) async {
              var prof = await UserApi.instance.me();
              KakaoSignInAPI()
                  .kakao(
                      idToken: _r.idToken,
                      fcmToken: _fcmToken,
                      profile: prof.kakaoAccount)
                  .then((_v) async {
                final _prefs = await SharedPreferences.getInstance();

                _prefs.setString('AccessToken', _v.result['access_token']);
                _prefs.setBool('HasNickname', _v.result['nick']);
                _prefs.setBool('HasAvatar', _v.result['avatar']);

                if (_v.result['nick'] == true && _v.result['avatar'] == true) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainScreenBuilder()),
                      (route) => false);
                } else {
                  if (_v.result['nick'] == false) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const NicknameSettingInitializePage()),
                        (route) => false);
                  } else if (_v.result['nick'] == true &&
                      _v.result['avatar'] == false) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AvatarSettingInitializePage()),
                        (route) => false);
                  }
                }
              });
            });
          } catch (error) {
            log('로그인 실패 $error');
          }
        }
      } else {
        log('발급된 토큰 없음');
        try {
          await UserApi.instance
              .loginWithKakaoAccount(nonce: 'dev_DRPublic')
              .then((_r) async {
            var prof = await UserApi.instance.me();
            KakaoSignInAPI()
                .kakao(
                    idToken: _r.idToken,
                    fcmToken: _fcmToken,
                    profile: prof.kakaoAccount)
                .then((_v) async {
              final _prefs = await SharedPreferences.getInstance();

              _prefs.setString('AccessToken', _v.result['access_token']);
              _prefs.setBool('HasNickname', _v.result['nick']);
              _prefs.setBool('HasAvatar', _v.result['avatar']);

              if (_v.result['nick'] == true && _v.result['avatar'] == true) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MainScreenBuilder()),
                    (route) => false);
              } else {
                if (_v.result['nick'] == false) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NicknameSettingInitializePage()),
                      (route) => false);
                } else if (_v.result['nick'] == true &&
                    _v.result['avatar'] == false) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const AvatarSettingInitializePage()),
                      (route) => false);
                }
              }
            });
          });
        } catch (error) {
          log('로그인 실패 $error');
        }
      }
    }
  }

  Future<void> signInWithNaver(BuildContext context) async {
    // await FlutterNaverLogin.logOutAndDeleteToken();
    final _fcmToken = await FirebaseFunctionSet().getFCMToken();
    await FlutterNaverLogin.logIn().then((value) async {
      NaverAccessToken _res = await FlutterNaverLogin.currentAccessToken;

      NaverSignInAPI()
          .naver(accessToken: _res.accessToken, fcmToken: _fcmToken)
          .then((_v) async {
        final _prefs = await SharedPreferences.getInstance();

        _prefs.setString('AccessToken', _v.result['access_token']);
        _prefs.setBool('HasNickname', _v.result['nick']);
        _prefs.setBool('HasAvatar', _v.result['avatar']);

        if (_v.result['nick'] == true && _v.result['avatar'] == true) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const MainScreenBuilder()),
              (route) => false);
        } else {
          if (_v.result['nick'] == false) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const NicknameSettingInitializePage()),
                (route) => false);
          } else if (_v.result['nick'] == true &&
              _v.result['avatar'] == false) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const AvatarSettingInitializePage()),
                (route) => false);
          }
        }
      });
    });
  }

  Future<void> signInWithApple(BuildContext context) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: 'dev_DRPublic',
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: 'de.lunaone.flutter.signinwithappleexample.service',
        redirectUri: Uri.parse(
          'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
        ),
      ),
      // state: 'example-state',
    );

    SignInWithApple.isAvailable().then((value) {
      // print('af: $value');
    });

    final _fcmToken = await FirebaseFunctionSet().getFCMToken();

    AppleSignInAPI()
        .apple(idToken: credential.identityToken, fcmToken: _fcmToken)
        .then((_v) async {
      final _prefs = await SharedPreferences.getInstance();

      _prefs.setString('AccessToken', _v.result['access_token']);
      _prefs.setBool('HasNickname', _v.result['nick']);
      _prefs.setBool('HasAvatar', _v.result['avatar']);

      if (_v.result['nick'] == true && _v.result['avatar'] == true) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreenBuilder()),
            (route) => false);
      } else {
        if (_v.result['nick'] == false) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const NicknameSettingInitializePage()),
              (route) => false);
        } else if (_v.result['nick'] == true && _v.result['avatar'] == false) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const AvatarSettingInitializePage()),
              (route) => false);
        }
      }
    });

    final signInWithAppleEndpoint = Uri(
      scheme: 'https',
      host: 'flutter-sign-in-with-apple-example.glitch.me',
      path: '/sign_in_with_apple',
      queryParameters: <String, String>{
        'code': credential.authorizationCode,
        if (credential.givenName != null) 'firstName': credential.givenName!,
        if (credential.familyName != null) 'lastName': credential.familyName!,
        'useBundleId':
            !kIsWeb && (Platform.isIOS || Platform.isMacOS) ? 'true' : 'false',
        if (credential.state != null) 'state': credential.state!,
      },
    );

    final session = await http.Client().post(
      signInWithAppleEndpoint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        body: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(51.0, kToolbarHeight, 51.0, 20.0),
          color: const Color(0xFF1e1e1e),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextBuilder(
                text: TextConstant.welcomeText,
                fontColor: ColorsConfig.defaultWhite,
                fontSize: 34.0.sp,
                fontWeight: FontWeight.w400,
              ),
              InkWell(
                onTap: () => signInWithGoogle(context),
                child: const SizedBox(
                  width: 15.0,
                  height: 30.0,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 396.0,
                  maxHeight: 364.0,
                ),
                child: const Image(
                  image: AssetImage('assets/img/login_back_img.png'),
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
              Container(
                height: 186.0,
                margin: const EdgeInsets.only(top: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // InkWell(
                    //   // onTap: () => signInWithGoogle(context),
                    //   child: Container(
                    //     width: MediaQuery.of(context).size.width,
                    //     height: 46.0,
                    //     // decoration: BoxDecoration(
                    //     //   color: ColorsConfig.defaultWhite,
                    //     //   borderRadius: BorderRadius.circular(5.0),
                    //     //   boxShadow: [
                    //     //     BoxShadow(
                    //     //       color: ColorsConfig().colorPicker(color: ColorsConfig.defaultBlack, opacity: 0.16),
                    //     //       offset: const Offset(0.0 , 3.0),
                    //     //       blurRadius: 6,
                    //     //     ),
                    //     //   ],
                    //     // ),
                    //     child: Stack(
                    //       children: [
                    //         Container(
                    //           width: 27.0,
                    //           height: 27.0,
                    //           margin: const EdgeInsets.only(left: 30.0, top: 9.0),
                    //           // child: SvgAssets(image: 'assets/img/google_logo.svg'),
                    //         ),
                    //         Center(
                    //           child: CustomTextBuilder(
                    //             text: '구글로 시작하기',
                    //             fontColor: const Color(0xFF1e1e1e),
                    //             fontSize: 17.0.sp,
                    //             fontWeight: FontWeight.w700,
                    //             textAlign: TextAlign.right,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    InkWell(
                      onTap: () => signInWithKakao(context),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 52.0,
                        decoration: BoxDecoration(
                          color: ColorsConfig().kakaoBackground(),
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: [
                            BoxShadow(
                              color: ColorsConfig().colorPicker(
                                  color: ColorsConfig.defaultBlack,
                                  opacity: 0.16),
                              offset: const Offset(0.0, 3.0),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 27.0,
                              height: 27.0,
                              margin:
                                  const EdgeInsets.only(left: 30.0, top: 13.0),
                              child:
                                  SvgAssets(image: 'assets/img/kakao_logo.svg'),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.only(left: 12.0),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: TextConstant.loginForKakaoText,
                                  fontColor: const Color(0xFF1e1e1e),
                                  fontSize: 17.0.sp,
                                  fontWeight: FontWeight.w700,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => signInWithNaver(context),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 52.0,
                        decoration: BoxDecoration(
                          color: ColorsConfig().naverBackground(),
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: [
                            BoxShadow(
                              color: ColorsConfig().colorPicker(
                                  color: ColorsConfig.defaultBlack,
                                  opacity: 0.16),
                              offset: const Offset(0.0, 3.0),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 38.0,
                              height: 38.0,
                              margin:
                                  const EdgeInsets.only(left: 27.0, top: 6.0),
                              child:
                                  SvgAssets(image: 'assets/img/naver_logo.svg'),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.only(left: 12.0),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: TextConstant.loginForNaverText,
                                  fontColor: ColorsConfig.defaultWhite,
                                  fontSize: 17.0.sp,
                                  fontWeight: FontWeight.w700,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => signInWithApple(context),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 52.0,
                        decoration: BoxDecoration(
                          color: ColorsConfig().appleBackground(),
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: [
                            BoxShadow(
                              color: ColorsConfig().colorPicker(
                                  color: ColorsConfig.defaultBlack,
                                  opacity: 0.16),
                              offset: const Offset(0.0, 3.0),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 27.0,
                              height: 27.0,
                              margin:
                                  const EdgeInsets.only(left: 33.0, top: 12.0),
                              child:
                                  SvgAssets(image: 'assets/img/apple_logo.svg'),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.only(left: 12.0),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: TextConstant.loginForAppleText,
                                  fontColor: ColorsConfig.defaultWhite,
                                  fontSize: 17.0.sp,
                                  fontWeight: FontWeight.w700,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
