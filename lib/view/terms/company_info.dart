import 'package:DRPublic/api/agreement/agreement.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyInformationScreen extends StatefulWidget {
  const CompanyInformationScreen({Key? key}) : super(key: key);

  @override
  State<CompanyInformationScreen> createState() =>
      _CompanyInformationScreenState();
}

class _CompanyInformationScreenState extends State<CompanyInformationScreen> {
  Map<String, dynamic> agreementData = {};

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetAgreementAPI()
        .agreement(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        agreementData = value.result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '회사정보',
        ),
      ),
      body: agreementData.isNotEmpty
          ? Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: ColorsConfig().background(),
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 25.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25.0),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      child: CustomTextBuilder(
                          text: '시장이 시작되는 공간, DR-Public',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 22.0.sp,
                          fontWeight: FontWeight.w700),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2.0),
                      child: CustomTextBuilder(
                        text: '주식회사 위클립스 | 대표 오세훈',
                        fontColor: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2.0),
                      child: CustomTextBuilder(
                        text: '서울시 영등포구 의사당대로 83, 서울핀테크랩 6층',
                        fontColor: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2.0),
                      child: CustomTextBuilder(
                        text: '사업자등록번호 702-86-02210 | 통신판매업 2022-서울마포-2200',
                        fontColor: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2.0),
                      child: CustomTextBuilder(
                        text:
                            '고객센터 운영시간 09:00 ~ 17:00 (1668-5602) | E-mail : support@DRPublic.co.kr',
                        fontColor: ColorsConfig().textBlack2(),
                        fontSize: 16.0.sp,
                      ),
                    ),
                    CustomTextBuilder(
                      text:
                          'Copyright © 2022 Weclipse Inc. All rights reserved.',
                      fontColor: ColorsConfig().textBlack2(),
                      fontSize: 16.0.sp,
                    ),
                  ],
                ),
              ),
            )
          : Container(),
    );
  }
}
