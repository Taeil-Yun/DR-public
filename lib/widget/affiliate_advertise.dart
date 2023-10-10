import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendAffiliateAdvertisingEmail {
  void affiliateAdvertisingEmail(BuildContext context) async {
    String body = '';

    final Email email = Email(
      body: body,
      subject: 'DR-Public 제휴/광고 문의합니다.',
      recipients: ['support@weclipse.co.kr'],
      cc: [],
      bcc: [],
      attachmentPaths: [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {
      PopUpModal(
        barrierDismissible: true,
        barrierColor: ColorsConfig()
            .colorPicker(color: ColorsConfig.defaultBlack, opacity: 0.8),
        useAndroidBackButton: false,
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
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: ColorsConfig().subBackground1(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Center(
                child: CustomTextBuilder(
                  text:
                      '메일 앱을 사용할 수 없기 때문에 앱에서 바로 문의를 전송하기 어려운 상황입니다.\n\n아래 이메일로 문의 부탁드리겠습니다.\n\nsupport@weclipse.co.kr',
                  fontColor: ColorsConfig().textWhite1(),
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
                    color: ColorsConfig().border1(),
                  ),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 80.0,
                      height: 43.0,
                      decoration: BoxDecoration(
                        color: ColorsConfig().subBackground1(),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Center(
                        child: CustomTextBuilder(
                          text: '확인',
                          fontColor: ColorsConfig().textWhite1(),
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).dialog(context);
    }
  }
}
