import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:DRPublic/api/live/live_join_check.dart';
import 'package:DRPublic/api/user/profile.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oktoast/oktoast.dart';
import 'package:app_links/app_links.dart';

import 'package:DRPublic/splash/splash.dart';
import 'package:DRPublic/conf/route.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/component/bottom_navigation/bottom_navigation.dart';
import 'package:DRPublic/api/auth/get_status.dart';
import 'package:DRPublic/view/controller_con.dart';
import 'package:DRPublic/view/detail/news_detail.dart';
import 'package:DRPublic/view/main/main_home.dart';
import 'package:DRPublic/view/main/main_live.dart';
import 'package:DRPublic/view/detail/post_detail.dart';
import 'package:DRPublic/view/detail/vote_detail.dart';
import 'package:DRPublic/view/profile/my/profile.dart';
import 'package:DRPublic/view/restricted/restricted_page.dart';
import 'package:DRPublic/view/first.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // flutterLocalNotificationsPlugin.show(
  //   message.hashCode,
  //   message.data['title'],
  //   message.data['description'],
  //   NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       channel.id,
  //       channel.name,
  //       channelDescription: channel.description,
  //       icon: '@mipmap/ic_launcher',
  //       priority: Priority.high,
  //       importance: Importance.max,
  //       // largeIcon: android!.imageUrl != null ? FilePathAndroidBitmap(largeIconPath) : null,
  //       // styleInformation: android.imageUrl != null ? BigPictureStyleInformation(
  //       //   FilePathAndroidBitmap(bigPicturePath),
  //       //   largeIcon: FilePathAndroidBitmap(largeIconPath),
  //       // ) : BigTextStyleInformation(
  //       //   message.notification!.body!,
  //       // ),
  //     ),
  //     iOS: const IOSNotificationDetails(
  //       presentAlert: true,
  //       presentBadge: true,
  //       presentSound: true,
  //     ),
  //   ),
  // );
  // print('Handling a background message ${message.data}');
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final _prefs = await SharedPreferences.getInstance();

  if (_prefs.getString('PostLayout') == null) {
    _prefs.setString('PostLayout', 'card');
  }
  ThemeMode theme = _prefs.getString('AppThemeColor') != null
      ? _prefs.getString('AppThemeColor') == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light
      : ThemeMode.dark;

  bool _hasNickname = _prefs.getBool('HasNickname') ?? false;
  bool _hasAvatar = _prefs.getBool('HasAvatar') ?? false;

  String? _hasAccessToken = _prefs.getString('AccessToken');

  // 백그라운드 메시징 처리를 초기에 설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  runApp(OKToast(
      child: DRPublicApp(
          themes: theme,
          hasNickname: _hasNickname,
          hasAvatar: _hasAvatar,
          hasAccessToken: _hasAccessToken)));
}

class DRPublicApp extends StatelessWidget with WidgetsBindingObserver {
  DRPublicApp({
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

  static late ValueNotifier<ThemeMode> themeNotifier;

  @override
  Widget build(BuildContext context) {
    DRPublicApp.themeNotifier = ValueNotifier(themes!);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DRPublicApp.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ScreenUtilInit(
          designSize: const Size(428.0, 926.0),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (BuildContext context, Widget? child) {
            return MaterialApp(
              title: 'DR-Public',
              theme: ThemeData(
                appBarTheme: const AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                ),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                scaffoldBackgroundColor: ColorsConfig.transparent,
              ),
              // builder: (context, child) {
              //   return MediaQuery(
              //     data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
              //     child: child!,
              //   );
              // },
              darkTheme: ThemeData(
                appBarTheme: const AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                ),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                scaffoldBackgroundColor: ColorsConfig.transparent,
              ),
              themeMode: currentMode,
              home: child,
              routes: routes,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ko', 'KR'),
              ],
              locale: const Locale('ko'),
              // navigatorObservers: [
              // ],
            );
          },
          child: SplashScreen(
              themes: themes,
              hasNickname: hasNickname,
              hasAvatar: hasAvatar,
              hasAccessToken: hasAccessToken),
        );
      },
    );
  }
}

class MainScreenBuilder extends StatefulWidget {
  const MainScreenBuilder({Key? key}) : super(key: key);

  @override
  State<MainScreenBuilder> createState() => _MainScreenBuilderState();
}

class _MainScreenBuilderState extends State<MainScreenBuilder> {
  late final List<dynamic> _children;
  late AppLinks _appLinks;

  late final ScrollController cardScrollController;
  late final ScrollController headlineScrollController;
  late final ScrollController galleryScrollController;
  late final ScrollController allListScrollController;

  StreamSubscription<Uri>? _linkSubscription;

  FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

  int _currentIndex = 0;
  int _prevIndex = 0;

  Future<void> firebaseCloudMessagingListener() async {
    await Firebase.initializeApp();

    // get fcm token
    FirebaseMessaging.instance.getToken().then((token) async {
      // print('FCM token: $token');
    });

    // 종료된 상태에서 클릭이벤트
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      // print('asdasdasdasdasdasdasdasdsadasdasdasdasd ${message!.data}');
    });

    // app on foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // download when get image push
      Future<String> _downloadAndSaveFile(String? url, String fileName) async {
        final Directory directory = await getApplicationDocumentsDirectory();
        final String filePath = '${directory.path}/$fileName';
        final http.Response response = await http.get(Uri.parse(url!));
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }

      final String? largeIconPath;
      if (Platform.isAndroid &&
          message.notification!.android!.imageUrl != null) {
        largeIconPath = await _downloadAndSaveFile(android!.imageUrl,
            'largeIcon_${DateTime.now().millisecondsSinceEpoch.toString()}');
      } else {
        largeIconPath = '';
      }
      final String? bigPicturePath;
      if (Platform.isAndroid &&
          message.notification!.android!.imageUrl != null) {
        bigPicturePath = await _downloadAndSaveFile(android!.imageUrl,
            'bigPicture_${DateTime.now().millisecondsSinceEpoch.toString()}');
      } else {
        bigPicturePath = '';
      }

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              largeIcon: android.imageUrl != null
                  ? FilePathAndroidBitmap(largeIconPath)
                  : null,
              styleInformation: android.imageUrl != null
                  ? BigPictureStyleInformation(
                      FilePathAndroidBitmap(bigPicturePath),
                      largeIcon: FilePathAndroidBitmap(largeIconPath),
                    )
                  : BigTextStyleInformation(
                      message.notification!.body!,
                    ),
            ),
            iOS: const IOSNotificationDetails(
              presentAlert: false,
              presentBadge: false,
              presentSound: false,
            ),
          ),
        );
      }

      // 앱이 포그라운드에 있을 때 호출
      var adn = const AndroidInitializationSettings('@mipmap/ic_launcher');
      var ios = const IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        // onDidReceiveLocalNotification: onDidReceiveLocalNotification,
      );
      var initializationSettings =
          InitializationSettings(android: adn, iOS: ios);

      // flutterLocalNotificationsPlugin.show(
      //   message.hashCode,
      //   message.data['title'],
      //   message.data['description'],
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       channel.id,
      //       channel.name,
      //       channelDescription: channel.description,
      //       icon: '@mipmap/ic_launcher',
      //       priority: Priority.high,
      //       importance: Importance.max,
      //       // largeIcon: android!.imageUrl != null ? FilePathAndroidBitmap(largeIconPath) : null,
      //       // styleInformation: android.imageUrl != null ? BigPictureStyleInformation(
      //       //   FilePathAndroidBitmap(bigPicturePath),
      //       //   largeIcon: FilePathAndroidBitmap(largeIconPath),
      //       // ) : BigTextStyleInformation(
      //       //   message.notification!.body!,
      //       // ),
      //     ),
      //     iOS: const IOSNotificationDetails(
      //       presentAlert: true,
      //       presentBadge: true,
      //       presentSound: true,
      //     ),
      //   ),
      // );

      // 포그라운드에서 클릭이벤트
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (payload) async {
        final NotificationAppLaunchDetails? details =
            await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails();

        if (message.data['category'] == null) {
          if (message.data['postType'] == 4) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewsDetailScreen(
                        postIndex: int.parse(message.data['idx']))));
          } else if (message.data['postType'] == 5) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => VoteDetailScreen(
                        postIndex: int.parse(message.data['idx']))));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PostingDetailScreen(
                        postIndex: int.parse(message.data['idx']))));
          }
        } else {
          if (message.data['category'] == 'chatting') {
            setState(() {
              _currentIndex = 4;
            });
          } else if (message.data['category'] == 'subscribe') {
            Navigator.pushNamed(context, '/subscribe',
                arguments: {'tabIndex': 0});
          } else if (message.data['category'] == 'reply') {
            if (message.data['postType'] == 4) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(
                          postIndex: int.parse(message.data['index']))));
            } else if (message.data['postType'] == 5) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VoteDetailScreen(
                          postIndex: int.parse(message.data['index']))));
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostingDetailScreen(
                          postIndex: int.parse(message.data['index']))));
            }
          }
        }

        // print("test:${details!.payload}");
        // print('datas ${details.payload}');
        // print('datas ${message}');
      });
    });

    // 백그라운드에서 클릭이벤트
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['category'] == null) {
        if (message.data['postType'] == 4) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewsDetailScreen(
                      postIndex: int.parse(message.data['idx']))));
        } else if (message.data['postType'] == 5) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VoteDetailScreen(
                      postIndex: int.parse(message.data['idx']))));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PostingDetailScreen(
                      postIndex: int.parse(message.data['idx']))));
        }
      } else {
        if (message.data['category'] == 'chatting') {
          setState(() {
            _currentIndex = 4;
          });
        } else if (message.data['category'] == 'subscribe') {
          Navigator.pushNamed(context, '/subscribe',
              arguments: {'tabIndex': 0});
        } else if (message.data['category'] == 'reply') {
          if (message.data['postType'] == 4) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewsDetailScreen(
                        postIndex: int.parse(message.data['index']))));
          } else if (message.data['postType'] == 5) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => VoteDetailScreen(
                        postIndex: int.parse(message.data['index']))));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PostingDetailScreen(
                        postIndex: int.parse(message.data['index']))));
          }
        }
      }

      // print('--------------------asass: ${message.data}-------------------------------');
    });
  }

  Future<void> initDynamicLinks() async {
    final _prefs = await SharedPreferences.getInstance();

    dynamicLinks.onLink.listen((dynamicLinkData) {
      if (dynamicLinkData.link.query.contains('?rid')) {
        UserProfileInfoAPI()
            .getProfile(accesToken: _prefs.getString('AccessToken')!)
            .then((profile) {
          LiveJoinCheckAPI()
              .join(
                  accesToken: _prefs.getString('AccessToken')!,
                  roomIndex: int.parse(dynamicLinkData.link.query
                      .replaceAll('rid%3D', '')
                      .split('&apn')[0]
                      .split('share?')[1]))
              .then((joined) {
            if (joined.result['status'] == 14007) {
              Navigator.pushNamed(context, 'live_room', arguments: {
                "room_index": int.parse(dynamicLinkData.link.query
                    .replaceAll('rid%3D', '')
                    .split('&apn')[0]
                    .split('share?')[1]),
                "user_index": profile?.result['id'],
                "nickname": profile?.result['nick'],
                "avatar": profile?.result['avatar'],
                "is_header": false,
              });
            } else if (joined.result['status'] == 14008) {
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
                          text: '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
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
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 80.0,
                              height: 43.0,
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                              ),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: '확인',
                                  fontColor: ColorsConfig().textWhite1(),
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
          });
        });
      }

      if (dynamicLinkData.link.query.contains('?id%3D')) {
        int _targetId = int.parse(dynamicLinkData.link.query
            .toString()
            .split('id%3D')[1]
            .split('%26')[0]);
        int _type = int.parse(dynamicLinkData.link.query
            .toString()
            .split('type%3D')[1]
            .substring(0, 1));

        if (_type == 1 || _type == 2 || _type == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostingDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoteDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        }
      }
    }).onError((error) {
      log(error.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      if (deepLink.query.contains('?rid')) {
        UserProfileInfoAPI()
            .getProfile(accesToken: _prefs.getString('AccessToken')!)
            .then((profile) {
          LiveJoinCheckAPI()
              .join(
                  accesToken: _prefs.getString('AccessToken')!,
                  roomIndex: int.parse(deepLink.query
                      .replaceAll('rid%3D', '')
                      .split('&apn')[0]
                      .split('share?')[1]))
              .then((joined) {
            if (joined.result['status'] == 14007) {
              Navigator.pushNamed(context, 'live_room', arguments: {
                "room_index": int.parse(deepLink.query
                    .replaceAll('rid%3D', '')
                    .split('&apn')[0]
                    .split('share?')[1]),
                "user_index": profile?.result['id'],
                "nickname": profile?.result['nick'],
                "avatar": profile?.result['avatar'],
                "is_header": false,
              });
            } else if (joined.result['status'] == 14008) {
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
                          text: '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
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
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 80.0,
                              height: 43.0,
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                              ),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: '확인',
                                  fontColor: ColorsConfig().textWhite1(),
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
          });
        });
      }

      if (deepLink.query.contains('?id%3D')) {
        int _targetId = int.parse(
            deepLink.query.toString().split('id%3D')[1].split('%26')[0]);
        int _type = int.parse(
            deepLink.query.toString().split('type%3D')[1].substring(0, 1));

        if (_type == 1 || _type == 2 || _type == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostingDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoteDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> initDeepLinks() async {
    final _prefs = await SharedPreferences.getInstance();

    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      if (appLink.query.contains('?rid')) {
        UserProfileInfoAPI()
            .getProfile(accesToken: _prefs.getString('AccessToken')!)
            .then((profile) {
          LiveJoinCheckAPI()
              .join(
                  accesToken: _prefs.getString('AccessToken')!,
                  roomIndex: int.parse(appLink.query
                      .replaceAll('rid%3D', '')
                      .split('&apn')[0]
                      .split('share?')[1]))
              .then((joined) {
            if (joined.result['status'] == 14007) {
              Navigator.pushNamed(context, 'live_room', arguments: {
                "room_index": int.parse(appLink.query
                    .replaceAll('rid%3D', '')
                    .split('&apn')[0]
                    .split('share?')[1]),
                "user_index": profile?.result['id'],
                "nickname": profile?.result['nick'],
                "avatar": profile?.result['avatar'],
                "is_header": false,
              });
            } else if (joined.result['status'] == 14008) {
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
                          text: '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
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
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 80.0,
                              height: 43.0,
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                              ),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: '확인',
                                  fontColor: ColorsConfig().textWhite1(),
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
          });
        });
      }

      if (appLink.query.contains('?id%3D')) {
        int _targetId = int.parse(
            appLink.query.toString().split('id%3D')[1].split('%26')[0]);
        int _type = int.parse(
            appLink.query.toString().split('type%3D')[1].substring(0, 1));

        if (_type == 1 || _type == 2 || _type == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostingDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoteDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        }
      }
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      // final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getDynamicLink(uri);

      if (uri.query.contains('?rid')) {
        UserProfileInfoAPI()
            .getProfile(accesToken: _prefs.getString('AccessToken')!)
            .then((profile) {
          LiveJoinCheckAPI()
              .join(
                  accesToken: _prefs.getString('AccessToken')!,
                  roomIndex: int.parse(uri.query
                      .replaceAll('rid%3D', '')
                      .split('&apn')[0]
                      .split('share?')[1]))
              .then((joined) {
            if (joined.result['status'] == 14007) {
              Navigator.pushNamed(context, 'live_room', arguments: {
                "room_index": int.parse(uri.query
                    .replaceAll('rid%3D', '')
                    .split('&apn')[0]
                    .split('share?')[1]),
                "user_index": profile?.result['id'],
                "nickname": profile?.result['nick'],
                "avatar": profile?.result['avatar'],
                "is_header": false,
              });
            } else if (joined.result['status'] == 14008) {
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
                          text: '방장에 의해 내보내기 되어\n참여할 수 없는 채팅방입니다.',
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
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width - 80.0,
                              height: 43.0,
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                              ),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: '확인',
                                  fontColor: ColorsConfig().textWhite1(),
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
          });
        });
      }

      if (uri.query.contains('?id%3D')) {
        int _targetId =
            int.parse(uri.query.toString().split('id%3D')[1].split('%26')[0]);
        int _type =
            int.parse(uri.query.toString().split('type%3D')[1].substring(0, 1));

        if (_type == 1 || _type == 2 || _type == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostingDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        } else if (_type == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoteDetailScreen(
                postIndex: _targetId,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    initializeApi();

    firebaseCloudMessagingListener();

    if (Platform.isIOS) {
      initDeepLinks();
    } else {
      initDynamicLinks();
    }

    cardScrollController = ScrollControllerModel().cardScrollController;
    headlineScrollController = ScrollControllerModel().headlineScrollController;
    galleryScrollController = ScrollControllerModel().galleryScrollController;
    allListScrollController = ScrollControllerModel().allListScrollController;

    _children = [
      const MainHomeScreenBuilder(),
      const LiveListScreenBuilder(),
      Container(),
      FirstScreenBuilder(
        cardScrollController: cardScrollController,
        headlineScrollController: headlineScrollController,
        galleryScrollController: galleryScrollController,
        allListScrollController: allListScrollController,
      ),
      const MyProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    cardScrollController.dispose();
    headlineScrollController.dispose();
    galleryScrollController.dispose();
    allListScrollController.dispose();
    super.dispose();
  }

  Future<void> initializeApi() async {
    final _prefs = await SharedPreferences.getInstance();

    GetUserStatusAPI()
        .status(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      if (value.result['status'] == 11201 || value.result['status'] == 11202) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => RestrictedScreen(
                      status: value.result['status'],
                      type: value.result['type'],
                    )),
            (route) => false);
      }
    });
  }

  Future<void> _scrollableController() async {
    final _prefs = await SharedPreferences.getInstance();

    if (_prefs.getBool('SubscribeClicked')!) {
      allListScrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      if (_prefs.getString('PostLayout')! == 'card') {
        cardScrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else if (_prefs.getString('PostLayout')! == 'headline') {
        headlineScrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        galleryScrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    }
  }

  void _onTap(int index) {
    if (index == 0 && _prevIndex == 0) {
      _scrollableController();
    } else {
      setState(() {
        _prevIndex = index;
      });
    }

    setState(() {
      if (index == 2) {
        showModalBottomSheet(
            context: context,
            backgroundColor: ColorsConfig().subBackground1(),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            builder: (BuildContext context) {
              return SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50.0,
                        height: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig().textBlack2(),
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(
                            top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: ColorsConfig().border1(),
                            ),
                          ),
                        ),
                        child: CustomTextBuilder(
                          text: '만들기',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 18.0.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/create_live_room');
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0),
                          child: CustomTextBuilder(
                            text: '라이브 만들기',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 16.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);

                          Navigator.pushNamed(context, '/writing', arguments: {
                            'type': 1,
                            'onPatch': false,
                          });
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50.0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0),
                          alignment: Alignment.centerLeft,
                          child: CustomTextBuilder(
                            text: '포스트 올리기',
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
            });
      } else {
        _currentIndex = index;
      }
    });
  }

  // void _dsad() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: ColorsConfig().subBackground1(),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(12.0),
  //         topRight: Radius.circular(12.0),
  //       ),
  //     ),
  //     builder: (BuildContext context) {
  //       return SafeArea(
  //         child: Container(
  //           decoration: const BoxDecoration(
  //             borderRadius: BorderRadius.only(
  //               topLeft: Radius.circular(12.0),
  //               topRight: Radius.circular(12.0),
  //             ),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 width: 50.0,
  //                 height: 4.0,
  //                 margin: const EdgeInsets.symmetric(vertical: 8.0),
  //                 decoration: BoxDecoration(
  //                   color: ColorsConfig().textBlack2(),
  //                   borderRadius: BorderRadius.circular(100.0),
  //                 ),
  //               ),
  //               InkWell(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.pushNamed(context, '/writing', arguments: {
  //                     'type': 1,
  //                     'onPatch': false,
  //                   });
  //                 },
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width,
  //                   height: 50.0,
  //                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: CustomTextBuilder(
  //                     text: TextConstant.postTypeText,
  //                     fontColor: ColorsConfig().textWhite1(),
  //                     fontSize: 16.0.sp,
  //                     fontWeight: FontWeight.w400,
  //                   ),
  //                 ),
  //               ),
  //               InkWell(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.pushNamed(context, '/writing', arguments: {
  //                     'type': 2,
  //                     'onPatch': false,
  //                   });
  //                 },
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width,
  //                   height: 50.0,
  //                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: CustomTextBuilder(
  //                     text: TextConstant.analysisTypeText,
  //                     fontColor: ColorsConfig().textWhite1(),
  //                     fontSize: 16.0.sp,
  //                     fontWeight: FontWeight.w400,
  //                   ),
  //                 ),
  //               ),
  //               InkWell(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.pushNamed(context, '/writing', arguments: {
  //                     'type': 3,
  //                     'onPatch': false,
  //                   });
  //                 },
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width,
  //                   height: 50.0,
  //                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: CustomTextBuilder(
  //                     text: TextConstant.debateTypeText,
  //                     fontColor: ColorsConfig().textWhite1(),
  //                     fontSize: 16.0.sp,
  //                     fontWeight: FontWeight.w400,
  //                   ),
  //                 ),
  //               ),
  //               InkWell(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.pushNamed(context, '/writing', arguments: {
  //                     'type': 4,
  //                     'onPatch': false,
  //                   });
  //                 },
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width,
  //                   height: 50.0,
  //                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: CustomTextBuilder(
  //                     text: TextConstant.newsTypeText,
  //                     fontColor: ColorsConfig().textWhite1(),
  //                     fontSize: 16.0.sp,
  //                     fontWeight: FontWeight.w400,
  //                   ),
  //                 ),
  //               ),
  //               InkWell(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.pushNamed(context, '/writing', arguments: {
  //                     'type': 5,
  //                     'onPatch': false,
  //                   });
  //                 },
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width,
  //                   height: 50.0,
  //                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: CustomTextBuilder(
  //                     text: TextConstant.voteTypeText,
  //                     fontColor: ColorsConfig().textWhite1(),
  //                     fontSize: 16.0.sp,
  //                     fontWeight: FontWeight.w400,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     }
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0.5,
              color: ColorsConfig().border1(),
            ),
          ),
        ),
        child: _children[_currentIndex],
      ),
      bottomNavigationBar: SizedBox(
        height: 80.0,
        child: DRBottomNavigationBar().bottomNavigation(
          context,
          items: [
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  const SizedBox(height: 8.0),
                  SvgAssets(
                    image: _currentIndex == 0
                        ? 'assets/icon/home_active.svg'
                        : 'assets/icon/home.svg',
                    color: ColorsConfig().textBlack2(),
                    width: 21.0,
                    height: 21.0,
                  ),
                  const SizedBox(height: 3.0),
                  CustomTextBuilder(
                    text: '홈',
                    fontColor: ColorsConfig().textBlack2(),
                    fontSize: 10.0,
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  const SizedBox(height: 8.0),
                  SvgAssets(
                    image: _currentIndex == 1
                        ? 'assets/icon/live_active.svg'
                        : 'assets/icon/live.svg',
                    color: ColorsConfig().textBlack2(),
                    width: 21.0,
                    height: 21.0,
                  ),
                  const SizedBox(height: 3.0),
                  CustomTextBuilder(
                    text: '라이브',
                    fontColor: ColorsConfig().textBlack2(),
                    fontSize: 10.0,
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  const SizedBox(height: 6.0),
                  Container(
                    width: 35.0,
                    height: 35.0,
                    decoration: BoxDecoration(
                      color: ColorsConfig.subscribeBtnPrimary,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: SvgAssets(
                        image: 'assets/icon/plus.svg',
                        color: ColorsConfig().background(),
                        width: 21.0,
                        height: 21.0,
                      ),
                    ),
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  const SizedBox(height: 8.0),
                  SvgAssets(
                    image: _currentIndex == 3
                        ? 'assets/icon/post_active.svg'
                        : 'assets/icon/post.svg',
                    color: ColorsConfig().textBlack2(),
                    width: 21.0,
                    height: 21.0,
                  ),
                  const SizedBox(height: 3.0),
                  CustomTextBuilder(
                    text: '포스트',
                    fontColor: ColorsConfig().textBlack2(),
                    fontSize: 10.0,
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  const SizedBox(height: 8.0),
                  SvgAssets(
                    image: _currentIndex == 4
                        ? 'assets/icon/profile_active.svg'
                        : 'assets/icon/profile.svg',
                    color: ColorsConfig().textBlack2(),
                    width: 21.0,
                    height: 21.0,
                  ),
                  const SizedBox(height: 3.0),
                  CustomTextBuilder(
                    text: '내 채널',
                    fontColor: ColorsConfig().textBlack2(),
                    fontSize: 10.0,
                  ),
                ],
              ),
              label: '',
            ),
          ],
          itemLength: _children.length,
          currentIndex: _currentIndex,
          onTap: _onTap,
          selectedFontSize: 0.0,
          unselectedFontSize: 0.0,
        ),
      ),
    );
  }
}
