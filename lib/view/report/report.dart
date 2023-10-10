import 'package:DRPublic/api/report/report.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/util/route_arguments.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int? selectType;
  int reportTargetIndex = 0;
  int reportType = 0;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setState(() {
        reportType = RouteGetArguments().getArgs(context)['type'];
        reportTargetIndex = RouteGetArguments().getArgs(context)['targetIndex'];
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DRAppBar(
        leading: DRAppBarLeading(
          press: () => Navigator.pop(context),
        ),
        title: const DRAppBarTitle(
          title: '신고',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final _prefs = await SharedPreferences.getInstance();

              if (selectType != null) {
                DataReportAPI()
                    .report(
                  accesToken: _prefs.getString('AccessToken')!,
                  category: reportType,
                  type: selectType!,
                  targetIndex: reportTargetIndex,
                )
                    .then((value) {
                  if (value.result['status'] == 10910) {
                    ToastBuilder().toast(
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(14.0),
                        margin: const EdgeInsets.symmetric(horizontal: 30.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig.defaultToast.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: CustomTextBuilder(
                          text: '신고가 정상적으로 접수되었습니다.',
                          fontColor: ColorsConfig.defaultWhite,
                          fontSize: 14.0.sp,
                        ),
                      ),
                    );
                  } else if (value.result['status'] == 10911) {
                    ToastBuilder().toast(
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(14.0),
                        margin: const EdgeInsets.symmetric(horizontal: 30.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig.defaultToast.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: CustomTextBuilder(
                          text: '이미 신고가 접수되었습니다.',
                          fontColor: ColorsConfig.defaultWhite,
                          fontSize: 14.0.sp,
                        ),
                      ),
                    );
                  }
                  Navigator.pop(context);
                });
              }
            },
            child: CustomTextBuilder(
              text: '접수',
              fontColor: selectType != null
                  ? ColorsConfig().primary()
                  : ColorsConfig().textBlack2(),
              fontSize: 18.0.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: ColorsConfig().background(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 25.0),
              child: CustomTextBuilder(
                text: '신고하는 이유를 선택하세요',
                fontColor: ColorsConfig().textWhite1(),
                fontSize: 17.0.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    width: 0.5,
                    color: ColorsConfig().border1(),
                  ),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectType = 1;
                      });
                    },
                    child: Container(
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomTextBuilder(
                            text: '스팸',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 17.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              color: selectType != null && selectType == 1
                                  ? ColorsConfig().primary()
                                  : ColorsConfig().radioButtonColor(),
                              border: Border.all(
                                width: 0.5,
                                color: ColorsConfig().border1(),
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectType = 2;
                      });
                    },
                    child: Container(
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomTextBuilder(
                            text: '신체 노출 게시물, 음란물',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 17.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              color: selectType != null && selectType == 2
                                  ? ColorsConfig().primary()
                                  : ColorsConfig().radioButtonColor(),
                              border: Border.all(
                                width: 0.5,
                                color: ColorsConfig().border1(),
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectType = 3;
                      });
                    },
                    child: Container(
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomTextBuilder(
                            text: '욕설, 폭언, 폭력, 위협',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 17.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              color: selectType != null && selectType == 3
                                  ? ColorsConfig().primary()
                                  : ColorsConfig().radioButtonColor(),
                              border: Border.all(
                                width: 0.5,
                                color: ColorsConfig().border1(),
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectType = 4;
                      });
                    },
                    child: Container(
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomTextBuilder(
                            text: '사칭',
                            fontColor: ColorsConfig().textWhite1(),
                            fontSize: 17.0.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              color: selectType != null && selectType == 4
                                  ? ColorsConfig().primary()
                                  : ColorsConfig().radioButtonColor(),
                              border: Border.all(
                                width: 0.5,
                                color: ColorsConfig().border1(),
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(top: 20.0),
              alignment: Alignment.center,
              child: CustomTextBuilder(
                text: '※ 신고하신 내용은 운영정책에 따라 검토 후 처리됩니다.',
                fontColor: ColorsConfig().textBlack2(),
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
