import 'package:flutter/material.dart';

class RouteGetArguments {
  Map<dynamic, dynamic> getArgs(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return args;
  }
}

Route routeMoveVertical({dynamic page}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = const Offset(0.0, 1.0);
      var end = Offset.zero;
      var curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route routeMoveFade({dynamic page, int animationDuration = 300}) {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: animationDuration),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}