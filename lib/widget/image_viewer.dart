import 'package:DRPublic/component/appbar/appbar.dart';
import 'package:DRPublic/component/appbar/appbar_leading.dart';
import 'package:DRPublic/component/appbar/appbar_title.dart';
import 'package:DRPublic/conf/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImageViewerSingleBuilder extends StatefulWidget {
  ImageViewerSingleBuilder({
    Key? key,
    required this.image,
  }) : super(key: key);

  String image;

  @override
  State<ImageViewerSingleBuilder> createState() =>
      _ImageViewerSingleBuilderState();
}

class _ImageViewerSingleBuilderState extends State<ImageViewerSingleBuilder> {
  bool isTap = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          setState(() {
            isTap = !isTap;
          });
        },
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              panEnabled: true,
              clipBehavior: Clip.none,
              onInteractionUpdate: (detail) {
                setState(() {
                  isTap = false;
                });
              },
              child: Hero(
                tag: 'imageView',
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: ColorsConfig().subBackground1(),
                  child: Center(
                    child: Image(
                      image: NetworkImage(widget.image),
                    ),
                  ),
                ),
              ),
            ),
            isTap
                ? SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 100.0,
                    child: DRAppBar(
                      backgroundColor:
                          ColorsConfig().subBackground1(opacity: 0.4),
                      leading: DRAppBarLeading(
                        press: () {},
                        using: false,
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: ColorsConfig().textWhite1(),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}

class ImageViewerMultipleBuilder extends StatefulWidget {
  ImageViewerMultipleBuilder({
    Key? key,
    required this.images,
  }) : super(key: key);

  List<dynamic> images;

  @override
  State<ImageViewerMultipleBuilder> createState() =>
      _ImageViewerMultipleBuilderState();
}

class _ImageViewerMultipleBuilderState extends State<ImageViewerMultipleBuilder>
    with TickerProviderStateMixin {
  TransformationController controller = TransformationController();

  late Animation<Matrix4>? _animationReset;
  late AnimationController? _controllerReset;

  bool isTap = true;
  bool scaleState = false;

  int currentImageIndex = 1;

  void _onAnimateReset() {
    controller.value = _animationReset!.value;
    if (!_controllerReset!.isAnimating) {
      _animationReset?.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset?.reset();
    }
  }

  void _animateResetInitialize() {
    _controllerReset?.reset();
    _animationReset = Matrix4Tween(
      begin: controller.value,
      end: Matrix4.identity(),
    ).animate(_controllerReset!);
    _animationReset?.addListener(_onAnimateReset);
    _controllerReset?.forward();
  }

  @override
  void initState() {
    super.initState();
    _controllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
  }

  @override
  void dispose() {
    _controllerReset?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          setState(() {
            isTap = !isTap;
          });
        },
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: controller,
              minScale: 0.5,
              maxScale: 4.0,
              panEnabled: true,
              clipBehavior: Clip.none,
              onInteractionUpdate: (details) {
                setState(() {
                  isTap = false;

                  if (details.scale > 1.0) {
                    scaleState = true;
                  } else if (details.scale < 1.0) {
                    scaleState = false;
                  }
                });
              },
              child: Hero(
                tag: 'imageView',
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: ColorsConfig().subBackground1(),
                  child: PageView.builder(
                    physics: scaleState
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: widget.images.length,
                    onPageChanged: (int page) {
                      _animateResetInitialize();
                      setState(() {
                        currentImageIndex = page + 1;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Center(
                        child: Image(
                          image: NetworkImage(widget.images[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            isTap
                ? SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 100.0,
                    child: DRAppBar(
                      backgroundColor:
                          ColorsConfig().subBackground1(opacity: 0.4),
                      leading: DRAppBarLeading(
                        press: () {},
                        using: false,
                      ),
                      title: DRAppBarTitle(
                        onWidget: true,
                        wd: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$currentImageIndex',
                                style: TextStyle(
                                  color: ColorsConfig().textWhite1(),
                                  fontSize: 18.0.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' / ',
                                style: TextStyle(
                                  color: ColorsConfig().textWhite1(),
                                  fontSize: 18.0.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: '${widget.images.length}',
                                style: TextStyle(
                                  color: ColorsConfig().textWhite1(),
                                  fontSize: 18.0.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: ColorsConfig().textWhite1(),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
