import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/component/popup/popup.dart';
import 'package:DRPublic/component/toast/toast.dart';
import 'package:DRPublic/api/block/cancel_user_block.dart';
import 'package:DRPublic/api/block/get_block_list.dart';
import 'package:DRPublic/widget/text_widget.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({Key? key}) : super(key: key);

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  List<dynamic> getBlockList = [];

  @override
  void initState() {
    apiInitialize();

    super.initState();
  }

  Future<void> apiInitialize() async {
    final _prefs = await SharedPreferences.getInstance();

    GetBlockListAPI()
        .blockList(accesToken: _prefs.getString('AccessToken')!)
        .then((value) {
      setState(() {
        getBlockList = value.result;
      });
    });
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
          title: '차단목록',
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: ColorsConfig().background(),
        child: getBlockList.isNotEmpty
            ? SafeArea(
                child: ListView.builder(
                  itemCount: getBlockList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: ColorsConfig().subBackground1(),
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
                          // 프로필 이미지, 닉네임
                          Row(
                            children: [
                              // 프로필 이미지
                              Container(
                                width: 45.0,
                                height: 45.0,
                                margin: const EdgeInsets.only(right: 11.0),
                                decoration: BoxDecoration(
                                  color: ColorsConfig().userIconBackground(),
                                  borderRadius: BorderRadius.circular(26.0),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      getBlockList[index]['avatar_image'],
                                      scale: 5.0,
                                    ),
                                    filterQuality: FilterQuality.high,
                                    fit: BoxFit.none,
                                    alignment: const Alignment(0.0, -0.3),
                                  ),
                                ),
                              ),
                              CustomTextBuilder(
                                text: '${getBlockList[index]['nick']}',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              PopUpModal(
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
                                      height: 136.0,
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
                                              '${getBlockList[index]['nick']}님의 차단을 해제하시겠습니까?',
                                          fontColor:
                                              ColorsConfig().textWhite1(),
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
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      80.5) /
                                                  2,
                                              height: 43.0,
                                              decoration: BoxDecoration(
                                                color: ColorsConfig()
                                                    .subBackground1(),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Center(
                                                child: CustomTextBuilder(
                                                  text: '취소',
                                                  fontColor: ColorsConfig()
                                                      .textWhite1(),
                                                  fontSize: 16.0.sp,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 0.5,
                                            height: 43.0,
                                            color: ColorsConfig().border1(),
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              final _prefs =
                                                  await SharedPreferences
                                                      .getInstance();

                                              CancelUserBlockAPI()
                                                  .cancelBlock(
                                                      accesToken:
                                                          _prefs.getString(
                                                              'AccessToken')!,
                                                      targetIndex:
                                                          getBlockList[index]
                                                              ['blockee_index'])
                                                  .then((res) {
                                                if (res.result['status'] ==
                                                    11104) {
                                                  setState(() {
                                                    getBlockList
                                                        .removeAt(index);
                                                  });
                                                } else {
                                                  ToastBuilder().toast(
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              14.0),
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 30.0),
                                                      decoration: BoxDecoration(
                                                        color: ColorsConfig
                                                            .defaultToast
                                                            .withOpacity(0.9),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6.0),
                                                      ),
                                                      child: CustomTextBuilder(
                                                        text:
                                                            '${res.result['message']}',
                                                        fontColor: ColorsConfig
                                                            .defaultWhite,
                                                        fontSize: 14.0.sp,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              });

                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      80.5) /
                                                  2,
                                              height: 43.0,
                                              decoration: BoxDecoration(
                                                color: ColorsConfig()
                                                    .subBackground1(),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Center(
                                                child: CustomTextBuilder(
                                                  text: '해제',
                                                  fontColor:
                                                      ColorsConfig().primary(),
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
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              decoration: BoxDecoration(
                                color: ColorsConfig().subBackground1(),
                                border: Border.all(
                                  width: 0.5,
                                  color: ColorsConfig().primary(),
                                ),
                                borderRadius: BorderRadius.circular(100.0),
                              ),
                              child: CustomTextBuilder(
                                text: '차단해제',
                                fontColor: ColorsConfig().textWhite1(),
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : Container(
                color: ColorsConfig().subBackground1(),
                child: Center(
                  child: CustomTextBuilder(
                    text: '차단한 유저가 없습니다.',
                    fontColor: ColorsConfig().textWhite1(),
                    fontSize: 16.0.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
      ),
    );
  }
}
