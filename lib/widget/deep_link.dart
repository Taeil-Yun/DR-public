import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DeepLinkBuilder {
  Future<String> getShortLink(String screenName, String id, int type) async {
    String dynamicLinkPrefix = 'https://link.DRPublic.co.kr';

    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: dynamicLinkPrefix,
      link: Uri.parse('$dynamicLinkPrefix/$screenName?id=$id&type=$type'),
      androidParameters: const AndroidParameters(
        packageName: 'co.kr.weclipse.DRPublic',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.weclipse.DRPublic',
        minimumVersion: '0',
      ),
    );
    final dynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);

    return dynamicLink.shortUrl.toString();
    // return '${dynamicLinkParams.link}';
  }

  Future<String> getShortLinkForLiveRoom({
    String screenName = 'share',
    required int roomId,
  }) async {
    String dynamicLinkPrefix = 'https://link.DRPublic.co.kr';

    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: dynamicLinkPrefix,
      link: Uri.parse('$dynamicLinkPrefix/$screenName?rid=$roomId'),
      androidParameters: const AndroidParameters(
        packageName: 'co.kr.weclipse.DRPublic',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.weclipse.DRPublic',
        minimumVersion: '0',
      ),
    );

    final dynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);

    return dynamicLink.shortUrl.toString();
    // return '${dynamicLinkParams.link}';
  }
}
