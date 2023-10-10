import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/api/auth/refresh.dart';

class AuthenticateInterceptor implements InterceptorContract {
  @override
  Future<RequestData> interceptRequest({required RequestData data}) async {
    try {
      //   data.headers.clear();
      //   data.headers['authorization'] = 'Bearer ' + token;
      //   data.headers['content-type'] = 'application/json';
    } catch (e) {
      log('$e');
    }
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    return data;
  }
}

class ExpiredTokenRetryPolicy extends RetryPolicy {
  @override
  int maxRetryAttempts = 1;

  @override
  Future<bool> shouldAttemptRetryOnResponse(ResponseData response) async {
    final _prefs = await SharedPreferences.getInstance();

    if (response.statusCode == 401) {
      // Perform your token refresh here.
      await RefreshTokenAPI()
          .refresh(accesToken: _prefs.getString('AccessToken')!)
          .then((refresh) {
        if (refresh.result['status'] == 0) {
          _prefs.setString('AccessToken', refresh.result['access_token']);
        } else {
          Future.wait([
            _prefs.remove('HasNickname'),
            _prefs.remove('HasAvatar'),
            _prefs.remove('AccessToken'),
          ]).then((_) {
            final GlobalKey<NavigatorState> navigatorKey =
                GlobalKey<NavigatorState>();
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/login', (route) => false);
          });
        }
      });

      return true;
    }

    return false;
  }
}
