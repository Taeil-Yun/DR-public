// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';

/* 아임포트 휴대폰 본인인증 모듈을 불러옵니다. */
import 'package:iamport_flutter/iamport_certification.dart';
/* 아임포트 휴대폰 본인인증 데이터 모델을 불러옵니다. */
import 'package:iamport_flutter/model/certification_data.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/api/certification/certification_cancel.dart';
import 'package:DRPublic/api/certification/certification_complete.dart';
import 'package:DRPublic/api/payment/get_merchant.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/widget/text_widget.dart';

class PhoneCertification extends StatefulWidget {
  const PhoneCertification({Key? key}) : super(key: key);

  @override
  State<PhoneCertification> createState() => _PhoneCertificationState();
}

class _PhoneCertificationState extends State<PhoneCertification> {
  String merchantUid = '';
  String impCode = '';

  Map<String, dynamic> coinData = {};
  Map<String, dynamic> merchantData = {};

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();

    Future.delayed(Duration.zero, () {
      setState(() {
        merchantUid = RouteGetArguments().getArgs(context)['merchant_uid'];
        coinData = RouteGetArguments().getArgs(context)['selected_coin_data'];
      });
    });

    GetMerchantAPI()
        .merchant(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        merchantData = value.result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return merchantData.isNotEmpty
        ? IamportCertification(
            appBar: AppBar(
              backgroundColor: ColorsConfig().subBackground1(),
              title: CustomTextBuilder(
                text: '휴대폰 본인인증',
                fontColor: ColorsConfig().textWhite1(),
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            /* 웹뷰 로딩 컴포넌트 */
            initialChild: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image.asset('assets/images/iamport-logo.png'),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
                    child: const Text('잠시만 기다려주세요...',
                        style: TextStyle(fontSize: 20.0)),
                  ),
                ],
              ),
            ),
            /* [필수입력] 가맹점 식별코드 */
            userCode: '${merchantData['merchant_code']}',
            /* [필수입력] 본인인증 데이터 */
            data: CertificationData(
              merchantUid: merchantUid,
            ),
            /* [필수입력] 콜백 함수 */
            callback: (Map<String, String> result) async {
              final SharedPreferences _prefs =
                  await SharedPreferences.getInstance();

              if (result['success'] == 'false') {
                PhoneCertificationCancelAPI()
                    .cancel(
                        accessToken: _prefs.getString('AccessToken')!,
                        merchantUid: merchantUid)
                    .then((value) {
                  if (value.result['status'] == 13203) {
                    Navigator.pop(context);
                  } else {}
                });
              } else {
                PhoneCertificationCompleteAPI()
                    .complete(
                        accessToken: _prefs.getString('AccessToken')!,
                        merchantUid: result['merchant_uid']!,
                        impUid: result['imp_uid']!)
                    .then((value) {
                  if (value.result['status'] == 13200) {
                    Navigator.pushReplacementNamed(context, '/pay_pg',
                        arguments: {
                          "success": result['success'],
                          "selected_coin_data": coinData,
                          "merchant_uid": result['merchant_uid'],
                          "imp_uid": result['imp_uid'],
                        });
                  }
                });
              }
            },
          )
        : Container();
  }
}
