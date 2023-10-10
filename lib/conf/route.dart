import 'package:flutter/material.dart';

import 'package:DRPublic/component/iamport/certification.dart';
import 'package:DRPublic/view/live/live_room.dart';
import 'package:DRPublic/view/live/live_room_create.dart';
import 'package:DRPublic/view/payment/select_pg.dart';
import 'package:DRPublic/view/wallet/my_wallet.dart';
import 'package:DRPublic/view/terms/priced_term.dart';
import 'package:DRPublic/view/payment/pay_charge.dart';
import 'package:DRPublic/view/auth/login.dart';
import 'package:DRPublic/view/chatting/chatting_create.dart';
import 'package:DRPublic/view/chatting/chatting_detail.dart';
import 'package:DRPublic/view/detail/sub_reply_detail.dart';
import 'package:DRPublic/view/report/report.dart';
import 'package:DRPublic/view/search/search_home.dart';
import 'package:DRPublic/view/search/search_result.dart';
import 'package:DRPublic/view/service_center/service_center.dart';
import 'package:DRPublic/view/auth/account_list.dart';
import 'package:DRPublic/view/block/block_list.dart';
import 'package:DRPublic/view/controller_con.dart';
import 'package:DRPublic/view/terms/company_info.dart';
import 'package:DRPublic/view/terms/operation.dart';
import 'package:DRPublic/view/terms/privacy.dart';
import 'package:DRPublic/view/terms/term.dart';
import 'package:DRPublic/view/terms/terms_list.dart';
import 'package:DRPublic/view/first.dart';
import 'package:DRPublic/view/fourth.dart';
import 'package:DRPublic/view/notification/notification_list.dart';
import 'package:DRPublic/view/writing/posting.dart';
import 'package:DRPublic/view/avatar/avatar_change.dart';
import 'package:DRPublic/view/profile/my/profile.dart';
import 'package:DRPublic/view/profile/you/profile.dart';
import 'package:DRPublic/view/subscribe/subscribe.dart';
import 'package:DRPublic/view/setting/setting_list.dart';

Map<String, WidgetBuilder> routes = {
  // main
  '/first': (context) => FirstScreenBuilder(
        cardScrollController: ScrollControllerModel().cardScrollController,
        headlineScrollController:
            ScrollControllerModel().headlineScrollController,
        galleryScrollController:
            ScrollControllerModel().galleryScrollController,
        allListScrollController:
            ScrollControllerModel().allListScrollController,
      ),
  '/fourth': (context) => const FourthScreenBuilder(),

  // notification
  '/notification': (context) => const NotificationListScreen(),

  // writing
  '/writing': (context) => const WritingScreen(),

  // note detail
  '/note_detail': (context) => const ChattingDetailScreen(),
  '/chatting_create': (context) => const ChattingCreateScreen(),
  '/sub_reply_detail': (context) => const SubReplyDetailScreen(),

  // profile
  '/my_profile': (context) => const MyProfileScreen(),
  '/your_profile': (context) => const YourProfileScreen(),

  // subscribe
  '/subscribe': (context) => const SubScribeListScreen(),

  // avatar
  '/avatar_change': (context) => const AvatarChangeScreen(),

  // settings
  '/setting_list': (context) => const SettingListScreen(),

  // service center
  '/service_center': (context) => const ServiceCenterScreen(),

  // login
  '/login': (context) => const DRPublicLoginPage(),

  // search
  '/search': (context) => const SearchHomeScreen(),
  '/search_result': (context) => const SearchResultScreen(),

  // report
  '/report': (context) => const ReportScreen(),

  // terms
  '/terms_list': (context) => const TermsListScreen(),
  '/terms_detail': (context) => const TermDetailScreen(),
  '/priced_terms_detail': (context) => const PricedTermDetailScreen(),
  '/privacy_detail': (context) => const PrivacyDetailScreen(),
  '/operation_detail': (context) => const OperationDetailScreen(),
  '/company_info_detail': (context) => const CompanyInformationScreen(),

  // account
  '/account_list': (context) => const AccountSetListScreen(),

  // block
  '/block_list': (context) => const BlockListScreen(),

  // pay
  '/pay_charge': (context) => const PaymentChargeScreen(),
  '/pay_pg': (context) => const PGSelectingScreen(),

  // certification
  '/phone_certification': (context) => const PhoneCertification(),

  // wallet
  'my_wallet': (context) => const MyWalletAndPayHistoryScreen(),

  // LiveRoom
  'live_room': (context) => const LiveChartWithChattingScreen(),

  // Create Live Room
  '/create_live_room': (context) => const LiveRoomCreateScreen(),
};
