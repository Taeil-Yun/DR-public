import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/api/certification/certification_request.dart';
import 'package:DRPublic/api/payment/get_price_list.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class PaymentChargeScreen extends StatefulWidget {
  const PaymentChargeScreen({Key? key}) : super(key: key);

  @override
  State<PaymentChargeScreen> createState() => _PaymentChargeScreenState();
}

class _PaymentChargeScreenState extends State<PaymentChargeScreen> {
  var numberFormat = NumberFormat('###,###,###,###');

  int coinAmount = 0;

  List<dynamic> coinDatas = [];

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    Future.delayed(Duration.zero, () {
      setState(() {
        if (RouteGetArguments().getArgs(context)['coin_amount'] != null) {
          coinAmount = RouteGetArguments().getArgs(context)['coin_amount'];
        }
      });
    });

    GetCoinPriceAPI()
        .price(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        coinDatas = value.result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        backgroundColor: ColorsConfig().subBackground1(),
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: 'D코인 충전하기',
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
        decoration: BoxDecoration(
          color: ColorsConfig().subBackground1(),
          border: Border(
            top: BorderSide(
              width: 0.5,
              color: ColorsConfig().border1(),
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30.0),
              holdBalance(context, coinAmount),
              Column(
                children: List.generate(coinDatas.length, (index) {
                  return amountOfCharge(context,
                      amount: coinDatas[index]['amount'],
                      price: coinDatas[index]['price'],
                      index: index);
                }),
              ),
              const SizedBox(height: 20.0),
              guideTextWidget(context, 'D코인의 유효기간은 구매한 날 또는 선물 받은 날로부터 5년입니다.'),
              guideTextWidget(context, '청소년 이용자는 D코인 구매 시 법정대리인의 동의를 받아야 합니다.'),
              guideTextWidget(context,
                  'D코인은 구매일로부터 7일 이내에 취소할 수 있으며, 회사는 사유 확인 후 취소 접수일로부터 3영업일 이내에 환불을 진행합니다.'),
              guideTextWidget(context, '세부내용은 유료서비스 이용약관을 통해 확인할 수 있습니다.'),
              const SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget holdBalance(BuildContext context, int haveCash) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 58.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: ColorsConfig().textWhite1(),
        borderRadius: BorderRadius.circular(11.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomTextBuilder(
            text: '보유 D코인',
            fontColor: ColorsConfig().background(),
            fontSize: 16.0.sp,
            fontWeight: FontWeight.w700,
          ),
          Row(
            children: [
              Container(
                width: 23.5,
                height: 21.0,
                margin: const EdgeInsets.only(right: 7.5),
                child: SvgAssets(
                  image: 'assets/img/D-coin.svg',
                  fit: BoxFit.contain,
                ),
              ),
              CustomTextBuilder(
                text: numberFormat.format(haveCash),
                fontColor: ColorsConfig().background(),
                fontSize: 24.0.sp,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget amountOfCharge(
    BuildContext context, {
    required int amount,
    required int price,
    required int index,
  }) {
    return InkWell(
      onTap: () async {
        // final _prefs = await SharedPreferences.getInstance();

        // showModalBottomSheet(
        //   context: context,
        //   backgroundColor: ColorsConfig().subBackground1(),
        //   shape: const RoundedRectangleBorder(
        //     borderRadius: BorderRadius.only(
        //       topLeft: Radius.circular(12.0),
        //       topRight: Radius.circular(12.0),
        //     ),
        //   ),
        //   builder: (BuildContext context) {
        //     return SafeArea(
        //       child: Container(
        //         decoration: const BoxDecoration(
        //           borderRadius: BorderRadius.only(
        //             topLeft: Radius.circular(12.0),
        //             topRight: Radius.circular(12.0),
        //           ),
        //         ),
        //         child: Column(
        //           mainAxisSize: MainAxisSize.min,
        //           children: [
        //             Container(
        //               width: 50.0,
        //               height: 4.0,
        //               margin: const EdgeInsets.symmetric(vertical: 8.0),
        //               decoration: BoxDecoration(
        //                 color: ColorsConfig().textBlack2(),
        //                 borderRadius: BorderRadius.circular(100.0),
        //               ),
        //             ),
        //             Container(
        //               width: MediaQuery.of(context).size.width,
        //               padding: const EdgeInsets.only(top: 10.0, bottom: 15.0, left: 30.0, right: 30.0),
        //               decoration: BoxDecoration(
        //                 border: Border(
        //                   bottom: BorderSide(
        //                     width: 0.5,
        //                     color: ColorsConfig().border1(),
        //                   ),
        //                 ),
        //               ),
        //               child: CustomTextBuilder(
        //                 text: '결제방법',
        //                 fontColor: ColorsConfig().textWhite1(),
        //                 fontSize: 18.0.sp,
        //                 fontWeight: FontWeight.w600,
        //               ),
        //             ),
        //             InkWell(
        //               onTap: () {
        //                 PhoneCertificationRequestAPI().request(accessToken: _prefs.getString('AccessToken')!).then((value) {
        //                   Navigator.pushReplacementNamed(context, '/phone_certification', arguments: {
        //                     "selected_coin_data" : coinDatas[index],
        //                     "merchant_uid" : value.result['merchant_uid'],
        //                   });
        //                 });
        //               },
        //               child: Container(
        //                 width: MediaQuery.of(context).size.width,
        //                 padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
        //                 child: CustomTextBuilder(
        //                   text: 'DR-Public - DRPublic',
        //                   fontColor: ColorsConfig().textWhite1(),
        //                   fontSize: 16.0.sp,
        //                   fontWeight: FontWeight.w400,
        //                 ),
        //               ),
        //             ),
        //             InkWell(
        //               onTap: () {
        //                 Navigator.pop(context);

        //                 a
        //               },
        //               child: Container(
        //                 width: MediaQuery.of(context).size.width,
        //                 height: 50.0,
        //                 padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
        //                 alignment: Alignment.centerLeft,
        //                 child: CustomTextBuilder(
        //                   text: Platform.isAndroid ? 'Google Play' : 'App Store',
        //                   fontColor: ColorsConfig().textWhite1(),
        //                   fontSize: 16.0.sp,
        //                   fontWeight: FontWeight.w400,
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     );
        //   }
        // );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 55.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        margin: const EdgeInsets.only(top: 15.0),
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.0,
            color: ColorsConfig().border1(),
          ),
          borderRadius: BorderRadius.circular(13.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 23.5,
                  height: 21.0,
                  margin: const EdgeInsets.only(right: 7.5),
                  child: SvgAssets(
                    image: 'assets/img/D-coin.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                CustomTextBuilder(
                  text: '$amount',
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 24.0.sp,
                  fontWeight: FontWeight.w700,
                ),
                // bonus != null ? CustomTextBuilder(
                //   text: ' +$bonus% Bonus',
                //   fontColor: ColorsConfig().dcoinColors(),
                //   fontSize: 16.0.sp,
                //   fontWeight: FontWeight.w400,
                // ) : Container(),
              ],
            ),
            Row(
              children: [
                CustomTextBuilder(
                  text: '₩ ${numberFormat.format(price)}',
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(width: 10.0),
                Icon(
                  Icons.arrow_forward_ios_outlined,
                  color: ColorsConfig().textBlack2(),
                  size: 20.0.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget guideTextWidget(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextBuilder(
            text: '· ',
            fontColor: ColorsConfig().textBlack2(),
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 48.0,
            child: CustomTextBuilder(
              text: text,
              fontColor: ColorsConfig().textBlack1(),
              fontSize: 14.0.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
