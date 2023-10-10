import 'package:DRPublic/env/environment.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

main() async {
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

  Environment.newInstance(BuildType.development).run(
      theme: theme,
      hasNickname: _hasNickname,
      hasAvatar: _hasAvatar,
      hasAccessToken: _hasAccessToken);
}
