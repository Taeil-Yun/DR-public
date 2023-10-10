import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/component/iamport/payment.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/api/payment/get_merchant.dart';
import 'package:DRPublic/api/payment/get_pg.dart';
import 'package:DRPublic/api/payment/request_order.dart';
import 'package:DRPublic/widget/text_widget.dart';

class PGSelectingScreen extends StatefulWidget {
  const PGSelectingScreen({Key? key}) : super(key: key);

  @override
  State<PGSelectingScreen> createState() => _PGSelectingScreenState();
}

class _PGSelectingScreenState extends State<PGSelectingScreen> {
  String success = '';
  String impUid = '';
  String merchantUid = '';
  String isSelectedMethodType = '';

  List<dynamic> pgInfoData = [];

  Map<String, dynamic> selectedPGData = {};
  Map<String, dynamic> merchantData = {};
  Map<String, dynamic> selectMethodData = {};
  Map<String, dynamic> selectedCoinData = {};

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
        success = RouteGetArguments().getArgs(context)['success'];
        merchantUid = RouteGetArguments().getArgs(context)['merchant_uid'];
        selectedCoinData =
            RouteGetArguments().getArgs(context)['selected_coin_data'];
        impUid = RouteGetArguments().getArgs(context)['imp_uid'];
      });
    });

    GetPGDataAPI()
        .pg(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        pgInfoData = value.result;
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
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 26.5, vertical: 15.0),
                child: CustomTextBuilder(
                  text: '결제수단을 선택해주세요',
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 19.0.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // 결제수단 위젯
              pgInfoData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26.5),
                      child: Wrap(
                        children: List.generate(pgInfoData.length, (index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelectedMethodType.isEmpty) {
                                  isSelectedMethodType =
                                      pgInfoData[index]['name'];
                                  selectMethodData = pgInfoData[index];
                                } else if (isSelectedMethodType ==
                                    pgInfoData[index]['name']) {
                                  isSelectedMethodType = '';
                                  selectMethodData = {};
                                } else if (isSelectedMethodType !=
                                    pgInfoData[index]['name']) {
                                  isSelectedMethodType =
                                      pgInfoData[index]['name'];
                                  selectMethodData = pgInfoData[index];
                                }
                              });
                            },
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 68.0) /
                                      2,
                              margin: index.isEven
                                  ? const EdgeInsets.only(top: 15.0)
                                  : const EdgeInsets.only(
                                      top: 15.0, left: 15.0),
                              padding: isSelectedMethodType ==
                                      pgInfoData[index]['name']
                                  ? const EdgeInsets.symmetric(vertical: 28.0)
                                  : const EdgeInsets.symmetric(vertical: 29.5),
                              decoration: BoxDecoration(
                                color: isSelectedMethodType ==
                                        pgInfoData[index]['name']
                                    ? ColorsConfig.pgSelectBackground1
                                    : ColorsConfig().radioButtonColor(),
                                border: Border.all(
                                  width: isSelectedMethodType ==
                                          pgInfoData[index]['name']
                                      ? 2.0
                                      : 0.5,
                                  color: isSelectedMethodType ==
                                          pgInfoData[index]['name']
                                      ? ColorsConfig.subscribeBtnPrimary
                                      : ColorsConfig().lightOnlyBorder(),
                                ),
                                borderRadius: BorderRadius.circular(13.0),
                              ),
                              child: Center(
                                child: CustomTextBuilder(
                                  text: '${pgInfoData[index]['name']}',
                                  fontColor: isSelectedMethodType ==
                                          pgInfoData[index]['name']
                                      ? ColorsConfig.messageBtnBackground
                                      : ColorsConfig.noSelectButtonTextColor,
                                  fontSize: 16.0.sp,
                                  fontWeight: isSelectedMethodType ==
                                          pgInfoData[index]['name']
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  : Container(),
              // 결제하기 버튼
              InkWell(
                onTap: () async {
                  if (isSelectedMethodType.isNotEmpty &&
                      selectMethodData.isNotEmpty) {
                    final _prefs = await SharedPreferences.getInstance();

                    RequestOrderDataAPI()
                        .order(
                            accesToken: _prefs.getString('AccessToken')!,
                            coinIndex: selectedCoinData['idx'],
                            pgMethodIndex: selectMethodData['idx'])
                        .then((value) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Payment(
                                    coinData: selectedCoinData,
                                    merchantData: merchantData,
                                    methodData: selectMethodData,
                                    requestOrderReturnData: value.result,
                                  )));
                    });
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.fromLTRB(26.5, 20.0, 26.5, 15.0),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  decoration: BoxDecoration(
                    color: isSelectedMethodType.isNotEmpty
                        ? ColorsConfig.subscribeBtnPrimary
                        : ColorsConfig().buttonDisabled(),
                    borderRadius: BorderRadius.circular(11.0),
                  ),
                  child: Center(
                    child: CustomTextBuilder(
                      text: '결제하기',
                      fontColor: isSelectedMethodType.isNotEmpty
                          ? ColorsConfig().avatarPartsWrapBackground()
                          : ColorsConfig().textBlack2(),
                      fontSize: 16.0.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
