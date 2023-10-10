import 'package:DRPublic/api/agreement/agreement.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermDetailScreen extends StatefulWidget {
  const TermDetailScreen({Key? key}) : super(key: key);

  @override
  State<TermDetailScreen> createState() => _TermDetailScreenState();
}

class _TermDetailScreenState extends State<TermDetailScreen> {
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
          title: '이용약관',
        ),
      ),
      body: agreementData.isNotEmpty
          ? Container(
              color: ColorsConfig().background(),
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 25.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25.0),
                    Container(
                      margin: const EdgeInsets.only(left: 5.0, bottom: 20.0),
                      child: CustomTextBuilder(
                          text: 'DR-Public 이용약관',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 20.0.sp,
                          fontWeight: FontWeight.w400),
                    ),
                    Html(
                      data: agreementData['terms'],
                    ),
                  ],
                ),
              ),
            )
          : Container(),
    );
  }
}
