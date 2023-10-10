import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:DRPublic/conf/colors.dart';
import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/api/chatting/chatting_create.dart';
import 'package:DRPublic/api/chatting/chatting_user_search.dart';
import 'package:DRPublic/widget/svg_asset.dart';
import 'package:DRPublic/widget/text_widget.dart';

class ChattingCreateScreen extends StatefulWidget {
  const ChattingCreateScreen({Key? key}) : super(key: key);

  @override
  State<ChattingCreateScreen> createState() => _ChattingCreateScreenState();
}

class _ChattingCreateScreenState extends State<ChattingCreateScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;

  int selectUserIndex = 0;

  List<dynamic> searchUserResult = [];

  Map<String, dynamic> selectUserData = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  Future<void> getSearchUsers(String text) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (text.isNotEmpty) {
        final _prefs = await SharedPreferences.getInstance();

        ChattingSearchUserAPI()
            .searchUser(
                accesToken: _prefs.getString('AccessToken')!,
                search: text.trim())
            .then((value) {
          setState(() {
            selectUserIndex = 0;
            searchUserResult = value.result;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        appBar: DRAppBar(
          systemUiOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle,
          backgroundColor: ColorsConfig().subBackground1(),
          leading: DRAppBarLeading(
            press: () => Navigator.pop(context),
          ),
          title: DRAppBarTitle(
            title: '메시지 보내기',
            color: ColorsConfig().textWhite1(),
            size: 18.0.sp,
            fontWeight: FontWeight.w700,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectUserIndex != 0) {
                  final _prefs = await SharedPreferences.getInstance();

                  ChattingCreateAPI()
                      .create(
                          accesToken: _prefs.getString('AccessToken')!,
                          userIndex: selectUserIndex)
                      .then((value) {
                    Navigator.pushReplacementNamed(context, '/note_detail',
                        arguments: {
                          'userIndex': selectUserData['user_index'],
                          'nickname': selectUserData['nick'],
                          'avatar': selectUserData['avatar_url'],
                        });
                  });
                }
              },
              child: CustomTextBuilder(
                text: '다음',
                fontColor: selectUserIndex != 0
                    ? ColorsConfig().primary()
                    : ColorsConfig().border1(),
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        body: Container(
          color: ColorsConfig().background(),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                height: 62.0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                    color: ColorsConfig().subBackground1(),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        width: 0.5,
                        color: ColorsConfig().border1(),
                      ),
                    )),
                child: Center(
                  child: SizedBox(
                    height: 42.0,
                    child: TextFormField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        isDense: true,
                        fillColor: ColorsConfig().subBackgroundBlack(),
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                        hintText: '받는사람',
                        hintStyle: TextStyle(
                          color: ColorsConfig().textBlack2(),
                          fontSize: 18.0.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                        ),
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: SvgAssets(
                                image: 'assets/icon/search.svg',
                                color: ColorsConfig().textBlack2(),
                                width: 22.0,
                                height: 22.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      cursorColor: ColorsConfig().primary(),
                      style: TextStyle(
                        color: ColorsConfig().textWhite1(),
                        fontSize: 18.0.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (text) {
                        if (text.length >= 2) {
                          getSearchUsers(text);
                        }
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _textEditingController.text.isNotEmpty
                      ? searchUserResult.length
                      : 0,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectUserIndex =
                              searchUserResult[index]['user_index'];
                          selectUserData = searchUserResult[index];
                        });
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 76.5,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: ColorsConfig().subBackground1(),
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: ColorsConfig().border1(),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45.0,
                              height: 45.0,
                              margin: const EdgeInsets.only(right: 11.0),
                              decoration: BoxDecoration(
                                color: ColorsConfig().userIconBackground(),
                                borderRadius: BorderRadius.circular(22.5),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    searchUserResult[index]['avatar_url'],
                                    scale: 5.0,
                                  ),
                                  filterQuality: FilterQuality.high,
                                  fit: BoxFit.none,
                                  alignment: const Alignment(0.0, -0.3),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 160.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  CustomTextBuilder(
                                    text: '${searchUserResult[index]['nick']}',
                                    fontColor: ColorsConfig().textWhite1(),
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  searchUserResult[index]['description'] != null
                                      ? CustomTextBuilder(
                                          text:
                                              '${searchUserResult[index]['description']}',
                                          fontColor:
                                              ColorsConfig().textBlack2(),
                                          fontSize: 14.0.sp,
                                          fontWeight: FontWeight.w400,
                                          maxLines: 1,
                                          textOverflow: TextOverflow.ellipsis,
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(),
                            ),
                            Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: BoxDecoration(
                                color: selectUserIndex ==
                                        searchUserResult[index]['user_index']
                                    ? ColorsConfig().primary()
                                    : ColorsConfig().radioButtonColor(),
                                border: Border.all(
                                  width: 0.5,
                                  color: ColorsConfig().textWhite1(),
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
