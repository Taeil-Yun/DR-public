import 'dart:io';

import 'package:DRPublic/api/wallet/get_deposit_info.dart';
import 'package:DRPublic/api/wallet/get_payment_list.dart';
import 'package:DRPublic/widget/loading.dart';
import 'package:DRPublic/widget/url_launcher.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/date_picker/date_picker.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/api/wallet/get_balance.dart';
import 'package:DRPublic/api/wallet/get_wallet_history.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class MyWalletAndPayHistoryScreen extends StatefulWidget {
  const MyWalletAndPayHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MyWalletAndPayHistoryScreen> createState() =>
      MyWalletAndPayHistoryScreenState();
}

class MyWalletAndPayHistoryScreenState
    extends State<MyWalletAndPayHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  var numberFormat = NumberFormat('###,###,###,###');

  List<dynamic> walletHistoryData = [];
  List<dynamic> paymentListData = [];

  Map<String, dynamic> balanceData = {};

  int thisYear = DateTime.now().toLocal().year;
  int thisMonth = DateTime.now().toLocal().month;
  int _currentTabIndex = 0;

  bool isLoading = false;

  @override
  void initState() {
    apiInitialize();

    tabController = TabController(
      length: 2,
      vsync: this,
    )..addListener(_handleTabSelection);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    Future.wait([
      GetBalanceDataAPI()
          .balance(accesToken: _prefs.getString('AccessToken')!)
          .then((value) {
        setState(() {
          balanceData = value.result;
        });
      }),
      GetWalletHistoryDataAPI()
          .history(
              accesToken: _prefs.getString('AccessToken')!,
              year: thisYear,
              month: thisMonth)
          .then((value) {
        setState(() {
          walletHistoryData = value.result;
        });
      }),
      GetPaymentListAPI()
          .paymentList(
              accesToken: _prefs.getString('AccessToken')!,
              year: thisYear,
              month: thisMonth)
          .then((value) {
        setState(() {
          paymentListData = value.result;
        });
      }),
    ]).then((_) {
      setState(() {
        isLoading = true;
      });
    });
  }

  Future<void> _handleTabSelection() async {
    final _prefs = await SharedPreferences.getInstance();

    if (tabController.indexIsChanging ||
        tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = tabController.index;

        if (_currentTabIndex == 1) {
          _prefs.setBool('SubscribeClicked', true);
        } else {
          _prefs.setBool('SubscribeClicked', false);
        }

        if (_currentTabIndex == 1) {
          thisYear = DateTime.now().toLocal().year;
          thisMonth = DateTime.now().toLocal().month;

          GetPaymentListAPI()
              .paymentList(
                  accesToken: _prefs.getString('AccessToken')!,
                  year: thisYear,
                  month: thisMonth)
              .then((value) {
            setState(() {
              paymentListData = value.result;
            });
          });
        } else {
          thisYear = DateTime.now().toLocal().year;
          thisMonth = DateTime.now().toLocal().month;

          GetWalletHistoryDataAPI()
              .history(
                  accesToken: _prefs.getString('AccessToken')!,
                  year: thisYear,
                  month: thisMonth)
              .then((value) {
            setState(() {
              walletHistoryData = value.result;
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        systemUiOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '내 지갑',
        ),
      ),
      body: isLoading
          ? Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: 0.5,
                    color: ColorsConfig().border1(),
                  ),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _currentTabIndex == 0
                    ? walletHistoryData.isNotEmpty
                        ? walletHistoryData.length
                        : 1
                    : paymentListData.isNotEmpty
                        ? paymentListData.length
                        : 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 170.0,
                          padding:
                              const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 15.0),
                          color: ColorsConfig().subBackground1(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 보유내역 텍스트
                              CustomTextBuilder(
                                text: '보유내역',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 18.0,
                                fontWeight: FontWeight.w700,
                              ),
                              // d코인 보유량
                              Container(
                                margin: const EdgeInsets.fromLTRB(
                                    35.0, 30.0, 35.0, 15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomTextBuilder(
                                      text: 'D코인',
                                      fontColor: ColorsConfig().textWhite1(),
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 21.0,
                                          height: 19.0,
                                          margin:
                                              const EdgeInsets.only(right: 7.0),
                                          child: SvgAssets(
                                            image: 'assets/img/D-coin.svg',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        balanceData.isNotEmpty
                                            ? CustomTextBuilder(
                                                text: numberFormat.format(
                                                    int.parse(balanceData[
                                                        'charge_count'])),
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w400,
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 환전하기, 충전하기 버튼
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: Row(
                                  children: [
                                    // 환전하기 버튼
                                    InkWell(
                                      onTap: () {
                                        PopUpModal(
                                          title: '',
                                          titlePadding: EdgeInsets.zero,
                                          onTitleWidget: Container(),
                                          content: '',
                                          contentPadding: EdgeInsets.zero,
                                          backgroundColor:
                                              ColorsConfig.transparent,
                                          onContentWidget: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 136.0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 35.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .subBackground1(),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(8.0),
                                                    topRight:
                                                        Radius.circular(8.0),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: CustomTextBuilder(
                                                    text:
                                                        '환전 가능한 디코인이 500개 이상이어야 디코인 환전 신청이 가능합니다.',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
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
                                                      color: ColorsConfig()
                                                          .border1(),
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            81.0,
                                                        height: 43.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: ColorsConfig()
                                                              .subBackground1(),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    8.0),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    8.0),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child:
                                                              CustomTextBuilder(
                                                            text: '닫기',
                                                            fontColor:
                                                                ColorsConfig()
                                                                    .textWhite1(),
                                                            fontSize: 16.0.sp,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // InkWell(
                                                    //   onTap: () => Navigator.pop(context),
                                                    //   child: Container(
                                                    //     width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                    //     height: 43.0,
                                                    //     decoration: BoxDecoration(
                                                    //       color: ColorsConfig().subBackground1(),
                                                    //       borderRadius: const BorderRadius.only(
                                                    //         bottomLeft: Radius.circular(8.0),
                                                    //       ),
                                                    //     ),
                                                    //     child: Center(
                                                    //       child: CustomTextBuilder(
                                                    //         text: '취소',
                                                    //         fontColor: ColorsConfig().textWhite1(),
                                                    //         fontSize: 16.0.sp,
                                                    //         fontWeight: FontWeight.w400,
                                                    //       ),
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                    // Container(
                                                    //   width: 0.5,
                                                    //   height: 43.0,
                                                    //   color: ColorsConfig().border1(),
                                                    // ),
                                                    // InkWell(
                                                    //   onTap: () async {
                                                    //     // final _prefs = await SharedPreferences.getInstance();

                                                    //     Navigator.pop(context);
                                                    //   },
                                                    //   child: Container(
                                                    //     width: (MediaQuery.of(context).size.width - 80.5) / 2,
                                                    //     height: 43.0,
                                                    //     decoration: BoxDecoration(
                                                    //       color: ColorsConfig().subBackground1(),
                                                    //       borderRadius: const BorderRadius.only(
                                                    //         bottomRight: Radius.circular(8.0),
                                                    //       ),
                                                    //     ),
                                                    //     child: Center(
                                                    //       child: CustomTextBuilder(
                                                    //         text: '확인',
                                                    //         fontColor: ColorsConfig.subscribeBtnPrimary,
                                                    //         fontSize: 16.0.sp,
                                                    //         fontWeight: FontWeight.w400,
                                                    //       ),
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).dialog(context);
                                      },
                                      child: Container(
                                        width:
                                            (MediaQuery.of(context).size.width /
                                                    2) -
                                                47.5,
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: ColorsConfig().button1(),
                                          borderRadius:
                                              BorderRadius.circular(9.0),
                                        ),
                                        child: Center(
                                          child: CustomTextBuilder(
                                            text: '환전하기',
                                            fontColor:
                                                ColorsConfig().textBlack2(),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15.0),
                                    // 충전하기 버튼
                                    InkWell(
                                      onTap: () {
                                        if (Platform.isAndroid) {
                                          Navigator.pushNamed(
                                              context, '/pay_charge',
                                              arguments: {
                                                'coin_amount': int.parse(
                                                    balanceData[
                                                        'charge_count']),
                                              });
                                        } else {
                                          UrlLauncherBuilder().launchURL(
                                              'https://DRPublic.co.kr/');
                                        }
                                      },
                                      child: Container(
                                        width:
                                            (MediaQuery.of(context).size.width /
                                                    2) -
                                                47.5,
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color:
                                              ColorsConfig.subscribeBtnPrimary,
                                          borderRadius:
                                              BorderRadius.circular(9.0),
                                        ),
                                        child: Center(
                                          child: CustomTextBuilder(
                                            text: '충전하기',
                                            fontColor:
                                                ColorsConfig.defaultWhite,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        // 상새내역 리스트
                        Container(
                          width: MediaQuery.of(context).size.width,
                          color: ColorsConfig().subBackground1(),
                          child: TabBar(
                            controller: tabController,
                            indicatorColor: ColorsConfig().primary(),
                            unselectedLabelColor: ColorsConfig().textWhite1(),
                            unselectedLabelStyle: TextStyle(
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            labelColor: ColorsConfig().textWhite1(),
                            labelStyle: TextStyle(
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: [
                              Tab(
                                child: CustomTextBuilder(text: '이용내역'),
                              ),
                              Tab(
                                child: CustomTextBuilder(
                                  text: '결제내역',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 날짜 선택기
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 20.0),
                          decoration: BoxDecoration(
                            color: ColorsConfig().subBackground1(),
                            border: _currentTabIndex == 1
                                ? Border(
                                    bottom: BorderSide(
                                      width: 1.0,
                                      color: ColorsConfig().border1(),
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final _prefs =
                                      await SharedPreferences.getInstance();

                                  setState(() {
                                    thisMonth--;
                                    if (thisMonth < 1) {
                                      thisYear--;
                                      thisMonth = 12;
                                    }

                                    if (_currentTabIndex == 0) {
                                      GetWalletHistoryDataAPI()
                                          .history(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              year: thisYear,
                                              month: thisMonth)
                                          .then((value) {
                                        setState(() {
                                          walletHistoryData = value.result;
                                        });
                                      });
                                    } else {
                                      GetPaymentListAPI()
                                          .paymentList(
                                              accesToken: _prefs
                                                  .getString('AccessToken')!,
                                              year: thisYear,
                                              month: thisMonth)
                                          .then((value) {
                                        setState(() {
                                          paymentListData = value.result;
                                        });
                                      });
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 5.0),
                                  child: SvgAssets(
                                    image: 'assets/icon/arrow_left.svg',
                                    color: ColorsConfig().textWhite1(),
                                    width: 18.0.sp,
                                    height: 18.0.sp,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                      context: context,
                                      backgroundColor:
                                          ColorsConfig().subBackground1(),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12.0),
                                          topRight: Radius.circular(12.0),
                                        ),
                                      ),
                                      builder: (BuildContext context) {
                                        return SizedBox(
                                          height: 400.0,
                                          child: CustomDatePickerBuilder(
                                            selectedDate: DateTime.now()
                                                            .toLocal()
                                                            .year ==
                                                        thisYear &&
                                                    DateTime.now()
                                                            .toLocal()
                                                            .month ==
                                                        thisMonth
                                                ? DateTime.now().toLocal()
                                                : DateTime(thisYear, thisMonth),
                                            minimumDate: DateTime(2020, 1, 1),
                                            maximumDate:
                                                DateTime.now().toLocal(),
                                            onDateTimeChanged:
                                                (DateTime _date) {},
                                            onSelectedPress:
                                                (DateTime _date) async {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              setState(() {
                                                thisYear = _date.year;
                                                thisMonth = _date.month;
                                              });

                                              if (_currentTabIndex == 0) {
                                                GetWalletHistoryDataAPI()
                                                    .history(
                                                        accesToken:
                                                            _prefs.getString(
                                                                'AccessToken')!,
                                                        year: thisYear,
                                                        month: thisMonth)
                                                    .then((value) {
                                                  setState(() {
                                                    walletHistoryData =
                                                        value.result;
                                                  });
                                                });
                                              } else {
                                                GetPaymentListAPI()
                                                    .paymentList(
                                                        accesToken:
                                                            _prefs.getString(
                                                                'AccessToken')!,
                                                        year: thisYear,
                                                        month: thisMonth)
                                                    .then((value) {
                                                  setState(() {
                                                    paymentListData =
                                                        value.result;
                                                  });
                                                });
                                              }

                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      });
                                },
                                child: CustomTextBuilder(
                                  text: DateFormat('yyyy-MM')
                                      .format(DateTime(thisYear, thisMonth)),
                                  fontColor: ColorsConfig().textWhite1(),
                                  fontSize: 16.0.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              thisYear != DateTime.now().toLocal().year ||
                                      thisMonth !=
                                          DateTime.now().toLocal().month
                                  ? InkWell(
                                      onTap: () async {
                                        final _prefs = await SharedPreferences
                                            .getInstance();

                                        setState(() {
                                          thisMonth++;
                                          if (thisMonth > 12) {
                                            thisYear++;
                                            thisMonth = 1;
                                          }

                                          if (_currentTabIndex == 0) {
                                            GetWalletHistoryDataAPI()
                                                .history(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    year: thisYear,
                                                    month: thisMonth)
                                                .then((value) {
                                              setState(() {
                                                walletHistoryData =
                                                    value.result;
                                              });
                                            });
                                          } else {
                                            GetPaymentListAPI()
                                                .paymentList(
                                                    accesToken:
                                                        _prefs.getString(
                                                            'AccessToken')!,
                                                    year: thisYear,
                                                    month: thisMonth)
                                                .then((value) {
                                              setState(() {
                                                paymentListData = value.result;
                                              });
                                            });
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 5.0),
                                        child: SvgAssets(
                                          image: 'assets/icon/arrow_right.svg',
                                          color: ColorsConfig().textWhite1(),
                                          width: 18.0.sp,
                                          height: 18.0.sp,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 5.0),
                                      child: SvgAssets(
                                        image: 'assets/icon/arrow_right.svg',
                                        color: ColorsConfig().textBlack2(),
                                        width: 18.0.sp,
                                        height: 18.0.sp,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        // 사용내역
                        Container(
                          color: ColorsConfig().subBackground1(),
                          child: _currentTabIndex == 0
                              ? walletHistoryData.isNotEmpty
                                  ? Column(
                                      children: List.generate(
                                          walletHistoryData[index]['data']
                                              .length, (historyIndex) {
                                        if (historyIndex == 0) {
                                          return Column(
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15.0,
                                                        vertical: 10.0),
                                                decoration: BoxDecoration(
                                                  color: ColorsConfig()
                                                      .subBackground1(),
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      width: 1.0,
                                                      color: ColorsConfig()
                                                          .border1(),
                                                    ),
                                                  ),
                                                ),
                                                child: CustomTextBuilder(
                                                  text:
                                                      '${walletHistoryData[index]['date']}',
                                                  fontColor: ColorsConfig()
                                                      .textBlack2(),
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 25.0,
                                                        vertical: 15.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    CustomTextBuilder(
                                                      text:
                                                          '${walletHistoryData[index]['data'][historyIndex]['memo']}',
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                    CustomTextBuilder(
                                                      text: numberFormat.format(
                                                          walletHistoryData[
                                                                          index]
                                                                      ['data']
                                                                  [historyIndex]
                                                              ['amount']),
                                                      fontColor: ColorsConfig()
                                                          .textWhite1(),
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        return Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 25.0, vertical: 15.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              CustomTextBuilder(
                                                text:
                                                    '${walletHistoryData[index]['data'][historyIndex]['memo']}',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              CustomTextBuilder(
                                                text: numberFormat.format(
                                                    walletHistoryData[index]
                                                                ['data']
                                                            [historyIndex]
                                                        ['amount']),
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    )
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0, vertical: 20.0),
                                      child: CustomTextBuilder(
                                        text: '상세내역이 존재하지 않습니다.',
                                        fontColor: ColorsConfig().textWhite1(),
                                      ),
                                    )
                              : paymentListData.isNotEmpty
                                  ? Column(
                                      children: List.generate(
                                          paymentListData[index]['data'].length,
                                          (paymentIndex) {
                                        return InkWell(
                                          onTap: paymentListData[index]['data']
                                                              [paymentIndex]
                                                          ['name'] ==
                                                      '가상계좌' &&
                                                  paymentListData[index]['data']
                                                              [paymentIndex]
                                                          ['status'] ==
                                                      4
                                              ? () async {
                                                  final SharedPreferences
                                                      _prefs =
                                                      await SharedPreferences
                                                          .getInstance();

                                                  GetDepositInfoDataAPI()
                                                      .deposit(
                                                          accesToken: _prefs
                                                              .getString(
                                                                  'AccessToken')!,
                                                          merchantUid: paymentListData[
                                                                          index]
                                                                      ['data']
                                                                  [paymentIndex]
                                                              ['order_code'])
                                                      .then((depositData) {
                                                    showModalBottomSheet(
                                                        context: context,
                                                        backgroundColor:
                                                            ColorsConfig()
                                                                .subBackground1(),
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    12.0),
                                                            topRight:
                                                                Radius.circular(
                                                                    12.0),
                                                          ),
                                                        ),
                                                        builder: (BuildContext
                                                            context) {
                                                          return SafeArea(
                                                            child: Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          12.0),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          12.0),
                                                                ),
                                                              ),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    width: 50.0,
                                                                    height: 4.0,
                                                                    margin: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: ColorsConfig()
                                                                          .textBlack2(),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              100.0),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            10.0,
                                                                        bottom:
                                                                            15.0,
                                                                        left:
                                                                            30.0,
                                                                        right:
                                                                            30.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border:
                                                                          Border(
                                                                        bottom:
                                                                            BorderSide(
                                                                          width:
                                                                              0.5,
                                                                          color:
                                                                              ColorsConfig().border1(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text:
                                                                          '입금정보',
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textWhite1(),
                                                                      fontSize:
                                                                          18.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            30.0,
                                                                        vertical:
                                                                            25.0),
                                                                    constraints:
                                                                        const BoxConstraints(
                                                                      minHeight:
                                                                          285.0,
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금금액',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['price'] != null ? '${numberFormat.format(depositData.result['price'])}원' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금은행',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_bank'] != null ? '${depositData.result['deposit_bank']}' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금은행예금주',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_holder'] != null ? '${depositData.result['deposit_holder']}' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금계좌번호',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_num'] != null ? '${depositData.result['deposit_num']}' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금기한',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(depositData.result['deposit_date']).toLocal()) : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                  });
                                                }
                                              : null,
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 25.0,
                                                vertical: 15.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: (MediaQuery.of(context)
                                                              .size
                                                              .width -
                                                          110.0) /
                                                      3,
                                                  child: CustomTextBuilder(
                                                    text:
                                                        'D코인 ${numberFormat.format(paymentListData[index]['data'][paymentIndex]['amount'])}개',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 16.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(width: 10.0),
                                                Container(
                                                  alignment: Alignment.center,
                                                  width: (MediaQuery.of(context)
                                                              .size
                                                              .width +
                                                          30.0) /
                                                      3,
                                                  child: CustomTextBuilder(
                                                    text:
                                                        '${paymentListData[index]['data'][paymentIndex]['name']}(${numberFormat.format(paymentListData[index]['data'][paymentIndex]['price'])}원)',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 16.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(width: 10.0),
                                                Container(
                                                  width: (MediaQuery.of(context)
                                                              .size
                                                              .width -
                                                          130.0) /
                                                      3,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: CustomTextBuilder(
                                                    text: paymentListData[index]
                                                                            [
                                                                            'data']
                                                                        [
                                                                        paymentIndex]
                                                                    [
                                                                    'status'] !=
                                                                0 &&
                                                            paymentListData[index]
                                                                            [
                                                                            'data']
                                                                        [
                                                                        paymentIndex]
                                                                    [
                                                                    'status'] !=
                                                                3
                                                        ? '${paymentListData[index]['data'][paymentIndex]['reg_date']}'
                                                        : '${paymentListData[index]['data'][paymentIndex]['status_name']}',
                                                    fontColor: ColorsConfig()
                                                        .textWhite1(),
                                                    fontSize: 16.0.sp,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    )
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0, vertical: 20.0),
                                      child: CustomTextBuilder(
                                        text: '결제내역이 존재하지 않습니다.',
                                        fontColor: ColorsConfig().textWhite1(),
                                      ),
                                    ),
                        ),
                      ],
                    );
                  } else {
                    return Container(
                      color: ColorsConfig().subBackground1(),
                      child: _currentTabIndex == 0
                          ? walletHistoryData.isNotEmpty
                              ? Column(
                                  children: List.generate(
                                      walletHistoryData[index]['data'].length,
                                      (historyIndex) {
                                    if (historyIndex == 0) {
                                      return Column(
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color: ColorsConfig()
                                                  .subBackground1(),
                                              border: Border(
                                                bottom: BorderSide(
                                                  width: 1.0,
                                                  color:
                                                      ColorsConfig().border1(),
                                                ),
                                              ),
                                            ),
                                            child: CustomTextBuilder(
                                              text:
                                                  '${walletHistoryData[index]['date']}',
                                              fontColor:
                                                  ColorsConfig().textBlack2(),
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 25.0,
                                                vertical: 15.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                CustomTextBuilder(
                                                  text:
                                                      '${walletHistoryData[index]['data'][historyIndex]['memo']}',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                CustomTextBuilder(
                                                  text: numberFormat.format(
                                                      walletHistoryData[index]
                                                                  ['data']
                                                              [historyIndex]
                                                          ['amount']),
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25.0, vertical: 15.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomTextBuilder(
                                            text:
                                                '${walletHistoryData[index]['data'][historyIndex]['memo']}',
                                            fontColor:
                                                ColorsConfig().textWhite1(),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          CustomTextBuilder(
                                            text: numberFormat.format(
                                                walletHistoryData[index]['data']
                                                    [historyIndex]['amount']),
                                            fontColor:
                                                ColorsConfig().textWhite1(),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                )
                              : Container()
                          : paymentListData.isNotEmpty
                              ? Column(
                                  children: List.generate(
                                      paymentListData[index]['data'].length,
                                      (paymentIndex) {
                                    return InkWell(
                                      onTap:
                                          paymentListData[index]['data']
                                                              [paymentIndex]
                                                          ['name'] ==
                                                      '가상계좌' &&
                                                  paymentListData[index]['data']
                                                              [paymentIndex]
                                                          ['status'] ==
                                                      4
                                              ? () async {
                                                  final SharedPreferences
                                                      _prefs =
                                                      await SharedPreferences
                                                          .getInstance();

                                                  GetDepositInfoDataAPI()
                                                      .deposit(
                                                          accesToken: _prefs
                                                              .getString(
                                                                  'AccessToken')!,
                                                          merchantUid: paymentListData[
                                                                          index]
                                                                      ['data']
                                                                  [paymentIndex]
                                                              ['order_code'])
                                                      .then((depositData) {
                                                    showModalBottomSheet(
                                                        context: context,
                                                        backgroundColor:
                                                            ColorsConfig()
                                                                .subBackground1(),
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    12.0),
                                                            topRight:
                                                                Radius.circular(
                                                                    12.0),
                                                          ),
                                                        ),
                                                        builder: (BuildContext
                                                            context) {
                                                          return SafeArea(
                                                            child: Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          12.0),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          12.0),
                                                                ),
                                                              ),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    width: 50.0,
                                                                    height: 4.0,
                                                                    margin: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: ColorsConfig()
                                                                          .textBlack2(),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              100.0),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            10.0,
                                                                        bottom:
                                                                            15.0,
                                                                        left:
                                                                            30.0,
                                                                        right:
                                                                            30.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border:
                                                                          Border(
                                                                        bottom:
                                                                            BorderSide(
                                                                          width:
                                                                              0.5,
                                                                          color:
                                                                              ColorsConfig().border1(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        CustomTextBuilder(
                                                                      text:
                                                                          '입금정보',
                                                                      fontColor:
                                                                          ColorsConfig()
                                                                              .textWhite1(),
                                                                      fontSize:
                                                                          18.0.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            30.0,
                                                                        vertical:
                                                                            25.0),
                                                                    constraints:
                                                                        const BoxConstraints(
                                                                      minHeight:
                                                                          285.0,
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금금액',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['price'] != null ? '${numberFormat.format(depositData.result['price'])}원' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금은행',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_bank'] != null ? '${depositData.result['deposit_bank']}' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금은행예금주',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_holder'] != null ? '${depositData.result['deposit_holder']}' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금계좌번호',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_num'] != null ? '${depositData.result['deposit_num']}' : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            CustomTextBuilder(
                                                                              text: '입금기한',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 16.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                            CustomTextBuilder(
                                                                              text: depositData.result['deposit_date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(depositData.result['deposit_date']).toLocal()) : '-',
                                                                              fontColor: ColorsConfig().textWhite1(),
                                                                              fontSize: 14.0.sp,
                                                                              fontWeight: FontWeight.w400,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                  });
                                                }
                                              : null,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 25.0, vertical: 15.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      110.0) /
                                                  3,
                                              child: CustomTextBuilder(
                                                text:
                                                    'D코인 ${numberFormat.format(paymentListData[index]['data'][paymentIndex]['amount'])}개',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(width: 10.0),
                                            Container(
                                              alignment: Alignment.center,
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width +
                                                      30.0) /
                                                  3,
                                              child: CustomTextBuilder(
                                                text:
                                                    '${paymentListData[index]['data'][paymentIndex]['name']}(${numberFormat.format(paymentListData[index]['data'][paymentIndex]['price'])}원)',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(width: 10.0),
                                            Container(
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      130.0) /
                                                  3,
                                              alignment: Alignment.centerRight,
                                              child: CustomTextBuilder(
                                                text: paymentListData[index]
                                                                        ['data']
                                                                    [
                                                                    paymentIndex]
                                                                ['status'] !=
                                                            0 &&
                                                        paymentListData[index]
                                                                        ['data']
                                                                    [
                                                                    paymentIndex]
                                                                ['status'] !=
                                                            3
                                                    ? '${paymentListData[index]['data'][paymentIndex]['reg_date']}'
                                                    : '${paymentListData[index]['data'][paymentIndex]['status_name']}',
                                                fontColor:
                                                    ColorsConfig().textWhite1(),
                                                fontSize: 16.0.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                )
                              : Container(),
                    );
                  }
                },
              ),
            )
          : const LoadingProgressScreen(),
      backgroundColor: ColorsConfig().background(),
    );
  }
}
