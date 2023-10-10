import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/conf/texts.dart';
import 'package:DRPublic/widget/text_widget.dart';

class LabelCategoryWidgetBuilder extends StatelessWidget {
  LabelCategoryWidgetBuilder({
    Key? key,
    required this.data,
  }) : super(key: key);

  dynamic data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 13.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: data == 1
            ? ColorsConfig().postLabel()
            : data == 2
                ? ColorsConfig().analyticsLabel()
                : data == 3
                    ? ColorsConfig().debateLabel()
                    : data == 4
                        ? ColorsConfig().newsLabel()
                        : data == 5
                            ? ColorsConfig().voteLabel()
                            : ColorsConfig().promotionLabel(),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: CustomTextBuilder(
        text: data == 1
            ? TextConstant.postTypeText
            : data == 2
                ? TextConstant.analysisTypeTextSpace
                : data == 3
                    ? TextConstant.debateTypeTextSpace
                    : data == 4
                        ? TextConstant.newsTypeTextSpace
                        : data == 5
                            ? TextConstant.voteTypeTextSpace
                            : TextConstant.promotionTypeText,
        fontColor: ColorsConfig.defaultWhite,
        fontSize: 11.0.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
