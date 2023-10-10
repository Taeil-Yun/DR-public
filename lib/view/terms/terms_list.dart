import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';

import 'package:DRPublic/conf/colors.dart';

import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsListScreen extends StatelessWidget {
  const TermsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '약관 및 정책',
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: ColorsConfig().background(),
        child: Column(
          children: [
            datasWidget(
                text: '이용약관',
                press: () {
                  Navigator.pushNamed(context, '/terms_detail');
                }),
            datasWidget(
                text: '유료서비스 이용약관',
                press: () {
                  Navigator.pushNamed(context, '/priced_terms_detail');
                }),
            datasWidget(
                text: '개인정보처리방침',
                press: () {
                  Navigator.pushNamed(context, '/privacy_detail');
                }),
            datasWidget(
                text: '운영정책',
                press: () {
                  Navigator.pushNamed(context, '/operation_detail');
                }),
            datasWidget(
                text: '회사정보',
                press: () {
                  Navigator.pushNamed(context, '/company_info_detail');
                }),
          ],
        ),
      ),
    );
  }

  Widget datasWidget({required String text, required Function() press}) {
    return InkWell(
      onTap: press,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0.5,
              color: ColorsConfig().userIconBackground(),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextBuilder(
              text: text,
              fontColor: ColorsConfig().textWhite1(),
              fontSize: 16.0.sp,
              fontWeight: FontWeight.w500,
            ),
            SvgAssets(
              image: 'assets/icon/arrow_right.svg',
              width: 12.0,
              height: 16.0,
              color: ColorsConfig().textBlack2(),
            ),
          ],
        ),
      ),
    );
  }
}
