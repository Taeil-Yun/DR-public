import 'package:flutter/material.dart';

import 'package:DRPublic/conf/colors.dart';

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  SliverAppBarDelegate(this._tabBar, this._isCollapse);

  final TabBar _tabBar;
  final bool _isCollapse;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          color: ColorsConfig().subBackground1(),
          boxShadow: _isCollapse
              ? [
                  BoxShadow(
                    color: ColorsConfig().colorPicker(
                        color: ColorsConfig.defaultBlack, opacity: 0.16),
                    blurRadius: 8.0,
                    offset: const Offset(0.0, 2.0),
                  ),
                ]
              : null,
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
