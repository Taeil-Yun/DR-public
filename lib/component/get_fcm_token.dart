import 'package:firebase_messaging/firebase_messaging.dart';

///
/// Firebase 기능 모음
/// ------------------------------------
/// ### List
/// - Get FCM Token
/// 
class FirebaseFunctionSet {
  /// 유저 FCM Token 가져오기
  Future<String> getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token!;
  }
}