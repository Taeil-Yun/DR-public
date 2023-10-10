// ignore_for_file: avoid_unnecessary_containers

import 'package:DRPublic/api/payment/order_complete.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/api/payment/order_cancel.dart';

/* 아임포트 결제 모듈을 불러옵니다. */
import 'package:iamport_flutter/iamport_payment.dart';
/* 아임포트 결제 데이터 모델을 불러옵니다. */
import 'package:iamport_flutter/model/payment_data.dart';

class Payment extends StatefulWidget {
  Map<String, dynamic> coinData;
  Map<String, dynamic> methodData;
  Map<String, dynamic> merchantData;
  Map<String, dynamic> requestOrderReturnData;

  Payment({
    Key? key,
    required this.coinData,
    required this.methodData,
    required this.merchantData,
    required this.requestOrderReturnData,
  }) : super(key: key);

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final String dateFormat = "yyyyMMddhhmmss";
  var addFor7Days = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return IamportPayment(
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        backgroundColor: ColorsConfig().subBackground1(),
        title: const DRAppBarTitle(
          title: '결제',
        ),
      ),
      /* 웹뷰 로딩 컴포넌트 */
      initialChild: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image.asset('assets/images/iamport-logo.png'),
              Container(
                padding: const EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
                child: const Text(
                  '잠시만 기다려주세요...',
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      /* [필수입력] 가맹점 식별코드 */
      userCode: '${widget.merchantData['merchant_code']}',
      /* [필수입력] 결제 데이터 */
      data: PaymentData(
        pg: '${widget.methodData['pg']}',
        payMethod: widget.methodData['code'],
        name: '${widget.requestOrderReturnData['name']}',
        merchantUid: widget.requestOrderReturnData['merchant_uid'],
        amount: widget.requestOrderReturnData['amount'],
        buyerName: widget.requestOrderReturnData['buyer_name'],
        buyerTel: '${widget.requestOrderReturnData['buyer_tel']}',
        buyerEmail: widget.requestOrderReturnData['buyer_email'],
        digital: true,
        // escrow: widget.methodData['code'] == 'trans' ? true : null,
        appScheme: 'DRPublic1634698800',
        vbankDue: DateFormat(dateFormat).format(addFor7Days),
      ),
      /* [필수입력] 콜백 함수 */
      callback: (Map<String, String> result) async {
        final _prefs = await SharedPreferences.getInstance();

        if (result['imp_success'] == 'false') {
          OrderCancelAPI()
              .cancel(
                  accesToken: _prefs.getString('AccessToken')!,
                  merchantUid: result['merchant_uid']!)
              .then((value) {
            Navigator.pop(context);
          });
        } else {
          OrderCompleteAPI()
              .complete(
                  accesToken: _prefs.getString('AccessToken')!,
                  impUid: result['imp_uid']!,
                  merchantUid: result['merchant_uid']!)
              .then((value) {
            PopUpModal(
              useAndroidBackButton: true,
              barrierDismissible: false,
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
                    height: 98.0,
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2b2b2b),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0),
                      ),
                    ),
                    child: Center(
                      child: CustomTextBuilder(
                        text: '결제가 완료되었습니다.',
                        fontColor: const Color(0xFFffffff),
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w400,
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
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width - 80.5,
                        height: 43.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2b2b2b),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                        ),
                        child: Center(
                          child: CustomTextBuilder(
                            text: '확인',
                            fontColor: const Color(0xFF32e855),
                            fontSize: 16.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).dialog(context);
          });
        }
      },
    );
  }
}
