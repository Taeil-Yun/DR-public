import 'package:flutter/material.dart';

class LoadingProgressScreen extends StatelessWidget {
  const LoadingProgressScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Image(
        image: AssetImage('assets/img/loading.webp'),
        width: 100.0,
        height: 100.0,
      ),
    );
  }
}