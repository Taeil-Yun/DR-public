import 'package:DRPublic/api/search/search.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/widget/text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealTimeTrendBuilder extends StatefulWidget {
  const RealTimeTrendBuilder({Key? key}) : super(key: key);

  @override
  State<RealTimeTrendBuilder> createState() => _RealTimeTrendBuilderState();
}

class _RealTimeTrendBuilderState extends State<RealTimeTrendBuilder> {
  Map<String, dynamic> getRecommendData = {};

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetRecommendDataList()
        .recommands(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getRecommendData = value.result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: getRecommendData.isNotEmpty
          ? Container(
              height: 60.0, // height = 46 + padding vertical = 14
              padding: const EdgeInsets.fromLTRB(6.0, 15.0, 6.0, 10.0),
              decoration: BoxDecoration(
                  color: ColorsConfig().subBackground1(),
                  border: Border(
                    top: BorderSide(
                      width: 0.5,
                      color: ColorsConfig().border1(),
                    ),
                  )),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: getRecommendData['recently'].length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => TestPage2()));
                    },
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 9.0),
                        margin: const EdgeInsets.symmetric(horizontal: 9.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig().subBackgroundBlack(),
                          border: Border.all(
                            width: 0.5,
                            color: ColorsConfig().border1(),
                          ),
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                        child: CustomTextBuilder(
                          text:
                              '#${getRecommendData['recently'][index]['text']}',
                          fontSize: 14.0.sp,
                          fontColor: ColorsConfig().textBlack1(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : Container(),
    );
  }
}
