import 'dart:io';

import 'package:DRPublic/widget/url_launcher.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/main.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/api/wallet/get_balance.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class HoldingBalanceWidget extends StatefulWidget {
  const HoldingBalanceWidget({Key? key}) : super(key: key);

  @override
  State<HoldingBalanceWidget> createState() => _HoldingBalanceWidgetState();
}

class _HoldingBalanceWidgetState extends State<HoldingBalanceWidget> {
  var numberFormat = NumberFormat('###,###,###,###');

  Map<String, dynamic> balanceData = {};

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

    GetBalanceDataAPI()
        .balance(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        balanceData = value.result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        onTap: () {
          if (Platform.isAndroid) {
            Navigator.pushNamed(context, '/pay_charge', arguments: {
              'coin_amount': int.parse(balanceData['charge_count']),
            });
          } else {
            UrlLauncherBuilder().launchURL('https://DRPublic.co.kr/');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: DRPublicApp.themeNotifier.value == ThemeMode.dark
                ? ColorsConfig().subBackgroundBlack()
                : null,
            border: DRPublicApp.themeNotifier.value == ThemeMode.light
                ? Border.all(
                    width: 0.5,
                    color: ColorsConfig().textWhite1(),
                  )
                : null,
            borderRadius: BorderRadius.circular(100.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(8.0, 5.0, 5.0, 5.0),
                child: Row(
                  children: [
                    Container(
                      width: 18.0,
                      height: 16.0,
                      margin: const EdgeInsets.only(right: 6.0),
                      child: SvgAssets(
                        image: 'assets/img/D-coin.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    balanceData.isNotEmpty
                        ? CustomTextBuilder(
                            text: numberFormat
                                .format(int.parse(balanceData['charge_count'])),
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 16.0.sp,
                            fontWeight: FontWeight.w700,
                          )
                        : Container(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(5.0, 5.0, 8.0, 5.0),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 0.5,
                      color: DRPublicApp.themeNotifier.value == ThemeMode.dark
                          ? ColorsConfig().border1()
                          : ColorsConfig().textWhite1(),
                    ),
                  ),
                ),
                child: CustomTextBuilder(
                  text: '+',
                  fontColor: ColorsConfig().textWhite1(),
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
